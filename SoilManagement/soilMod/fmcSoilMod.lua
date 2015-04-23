--
--  The Soil Management and Growth Control Project - version 2 (FS15)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modhoster.com
-- @date    2015-01-xx
--

fmcSoilMod = {}

-- "Register" this object in global environment, so other mods can "see" it.
getfenv(0)["fmcSoilMod2"] = fmcSoilMod 

-- Plugin support. Array for plugins to add themself to, so SoilMod can later "call them back".
getfenv(0)["modSoilMod2Plugins"] = getfenv(0)["modSoilMod2Plugins"] or {}

--
local modItem = ModsUtil.findModItemByModName(g_currentModName);
fmcSoilMod.version = (modItem and modItem.version) and modItem.version or "?.?.?";
fmcSoilMod.modDir = g_currentModDirectory;

--
fmcSoilMod.pHScaleModifier = 0.17
fmcSoilMod.fillTypeSendNumBits = (Fillable.sendNumBits + 1)
fmcSoilMod.fillTypeAugmented = (2 ^ fmcSoilMod.fillTypeSendNumBits)

-- For debugging
fmcSoilMod.logVerbose = false
function log(...)
    if fmcSoilMod.logVerbose
    then
        local txt = ""
        for idx = 1,select("#", ...) do
            txt = txt .. tostring(select(idx, ...))
        end
        print(string.format("%7ums ", (g_currentMission ~= nil and g_currentMission.time or 0)) .. txt);
    end
end;

function logInfo(...)
    local txt = "SoilMod: "
    for idx = 1,select("#", ...) do
        txt = txt .. tostring(select(idx, ...))
    end
    print(txt);
end

--
source(g_currentModDirectory .. 'soilMod/fmcSettings.lua')
source(g_currentModDirectory .. 'soilMod/fmcFillTypes.lua')
source(g_currentModDirectory .. 'soilMod/fmcModifyFSUtils.lua')
source(g_currentModDirectory .. 'soilMod/fmcModifySprayers.lua')
source(g_currentModDirectory .. 'soilMod/fmcGrowthControl.lua')
source(g_currentModDirectory .. 'soilMod/fmcSoilModPlugins.lua')     -- SoilMod uses its own plugin facility to add its own effects.
source(g_currentModDirectory .. 'soilMod/fmcCompostPlugin.lua')      --
source(g_currentModDirectory .. 'soilMod/fmcChoppedStrawPlugin.lua') --
source(g_currentModDirectory .. 'soilMod/fmcDisplay.lua')

function fmcSoilMod.loadMap(...)
    log("fmcSoilMod.loadMap()")

    local mapSelf = select(1, ...)
    fmcFilltypes.setup(mapSelf.baseDirectory, nil)

    return fmcSoilMod.orig_loadMap(...)
end

--
function fmcSoilMod.loadMapFinished(...)
    log("fmcSoilMod.loadMapFinished()")

    fmcSoilMod.updateFunc = function(self, dt) end;
    fmcSoilMod.drawFunc   = function(self) end;
    fmcSoilMod.enabled = false
    
    local ret = { fmcSoilMod.orig_loadMapFinished(...) }
    
    if nil == InputBinding.SOILMOD_GROWNOW
    or nil == InputBinding.SOILMOD_GRIDOVERLAY then
        -- Hmm? Who modifies my script?
    else
        if ModsSettings ~= nil then
            fmcSoilMod.logVerbose = ModsSettings.getBoolLocal("fmcSoilMod","internals","logVerbose",fmcSoilMod.logVerbose)
        end
        -- TODO - Clean up these functions calls.
        fmcModifySprayers.setup()
        fmcGrowthControl.preSetup()
        fmcGrowthControl.setup()
        fmcModifyFSUtils.preSetup()
        fmcSettings.loadFromSavegame()
        if fmcSoilMod.processPlugins() then
            fmcGrowthControl.postSetup()
            fmcModifyFSUtils.setup()
            fmcFilltypes.addMoreFillTypeOverlayIcons()
            fmcFilltypes.updateFillTypeOverlays()
            fmcDisplay.setup()
            fmcSoilMod.copy_l10n_texts_to_global()
            fmcSoilMod.enabled = true
            if g_currentMission:getIsServer() then    
                addConsoleCommand("modSoilMod", "", "consoleCommandSoilMod", fmcSoilMod)
            end
        end
    end

    if not fmcSoilMod.enabled then
        logInfo("")
        logInfo("ERROR! Problem occurred during SoilMod's initial set-up. - Soil Management will NOT be available!")
        logInfo("")
    else
        -- This function modifies itself!
        fmcSoilMod.updateFunc = function(self, dt)
            -- First time run
            Utils.fmcBuildDensityMaps()
            fmcGrowthControl.update(fmcGrowthControl, dt)
            fmcDisplay.update(dt)
            --
            fmcSoilMod.updateFunc = function(self, dt)
                -- All subsequent runs
                fmcGrowthControl.update(fmcGrowthControl, dt)
                fmcDisplay.update(dt)
            end
        end
        --
        fmcSoilMod.drawFunc = function(self)
            if self.isRunning and g_gui.currentGui == nil then
                fmcGrowthControl.draw(fmcGrowthControl)
                fmcDisplay.draw()
            end
        end
    end

    return unpack(ret);
end

function fmcSoilMod.delete(...)
    log("fmcSoilMod.delete()")
    
    fmcModifyFSUtils.teardown()
    fmcSoilMod.enabled = false
    
    return fmcSoilMod.orig_delete(...)
end;

function fmcSoilMod.update(self, dt)
    fmcSoilMod.orig_update(self, dt)
    fmcSoilMod.updateFunc(self, dt);
end

function fmcSoilMod.draw(self)
    fmcSoilMod.orig_draw(self)
    fmcSoilMod.drawFunc(self);
end

-- Apparently trying to use Utils.prepended/appended/overwrittenFunction() seems not to work as I wanted it.
-- So we're doing it using the "brute-forced method" instead!
fmcSoilMod.orig_loadMap         = FSBaseMission.loadMap;
fmcSoilMod.orig_loadMapFinished = FSBaseMission.loadMapFinished;
fmcSoilMod.orig_delete          = FSBaseMission.delete;
fmcSoilMod.orig_update          = FSBaseMission.update;
fmcSoilMod.orig_draw            = FSBaseMission.draw;
--
FSBaseMission.loadMap           = fmcSoilMod.loadMap;
FSBaseMission.loadMapFinished   = fmcSoilMod.loadMapFinished;
FSBaseMission.delete            = fmcSoilMod.delete;
FSBaseMission.update            = fmcSoilMod.update;
FSBaseMission.draw              = fmcSoilMod.draw;


--
--
--
function fmcSoilMod.consoleCommandSoilMod(self, arg1, arg2, arg3)
    log("modSoilMod: ",arg1,", ",arg2,", ",arg3,", ",arg4)

--[[
    <foliage name>    <new value>|"inc"|"dec"   <field #>|"world"
--]]
    local foliageName = tostring(arg1)
    local foliageId = nil
    if foliageName ~= nil then
        foliageName = "fmcFoliage"..foliageName
        foliageId = g_currentMission[foliageName]
    end
    if foliageId == nil then
        logInfo("Foliage does not exist: ",foliageName)
        return
    end

    local method = nil
    local value = nil
    if arg2 == "inc" then
        method = 1
        value = 1
    elseif arg2 == "dec" then
        method = 1
        value = -1
    else
        method = 2
        value = tonumber(arg2)
    end
    if value == nil then
        logInfo("Second argument wrong: ",arg2)
        return
    end
    
    local areas = nil
    if arg3 == "world" then
        areas = {
            { x=-2048,z=-2048, wx=4096,wz=0, hx=0,hz=4096 }
        }
    else
        local fieldNo = tonumber(arg3)
        local fieldDef = g_currentMission.fieldDefinitionBase.fieldDefsByFieldNumber[fieldNo]
        if fieldDef ~= nil then
            areas = {}
            for i = 0, getNumOfChildren(fieldDef.fieldDimensions) - 1 do
                local pointHeight = getChildAt(fieldDef.fieldDimensions, i)
                local pointStart  = getChildAt(pointHeight, 0)
                local pointWidth  = getChildAt(pointHeight, 1)
                
                local vecStart  = { getWorldTranslation(pointStart)  }
                local vecWidth  = { getWorldTranslation(pointWidth)  }
                local vecHeight = { getWorldTranslation(pointHeight) }
                
                local sx,sz,wx,wz,hx,hz = Utils.getXZWidthAndHeight(nil, vecStart[1],vecStart[3], vecWidth[1],vecWidth[3], vecHeight[1],vecHeight[3]);
                
                table.insert(areas, { x=sx,z=sz, wx=wx,wz=wz, hx=hx,hz=hz } )
            end
        end
    end
    if areas==nil then
        logInfo("Third argument wrong: ",arg3)
        return
    end
    
    local numChnls = getTerrainDetailNumChannels(foliageId)
    if numChnls == nil or numChnls <= 0 then
        logInfo("Foliage number of channels wrong: ",numChnls)
        return
    end

    for _,area in pairs(areas) do
        logInfo("'Painting' area: ",area.x,"/",area.z,",",area.wx,"/",area.wz,",",area.hx,",",area.hz)
        if method == 1 then
            addDensityParallelogram(
                foliageId,
                area.x,area.z, area.wx,area.wz, area.hx,area.hz,
                0,numChnls,
                value
            )
        elseif method == 2 then
            setDensityParallelogram(
                foliageId,
                area.x,area.z, area.wx,area.wz, area.hx,area.hz,
                0,numChnls,
                value
            )
        end
    end
end

--
-- Utillity functions for calculating pH value.
--
function fmcSoilMod.density_to_pH(sumPixels, numPixels, numChannels)
    if numPixels <= 0 then
        return 0  -- No value to calculate
    end
    local offsetPct = ((sumPixels / ((2^numChannels - 1) * numPixels)) - 0.5) * 2
    return fmcSoilMod.offsetPct_to_pH(offsetPct)
end

function fmcSoilMod.offsetPct_to_pH(offsetPct)
    -- 'offsetPct' should be between -1.0 and +1.0
    local phValue = 7.0 + (3 * math.sin(offsetPct * (math.pi * fmcSoilMod.pHScaleModifier)))
    return math.floor(phValue * 10) / 10; -- Return with only one decimal-digit.
end

function fmcSoilMod.pH_to_Denomination(phValue)
    for _,elem in pairs(fmcSoilMod.pH2Denomination) do
        if elem.low <= phValue and phValue < elem.high then
            return elem.textName
        end
    end
    return "unknown_pH"
end

--
-- Utility function for copying this mod's <l10n> text-entries, into the game's global table.
--
function fmcSoilMod.copy_l10n_texts_to_global()
    fmcSoilMod.pH2Denomination = {}

    -- Copy this mod's localization texts to global table - and hope they are unique enough, so not overwriting existing ones.
    for textName,textValue in pairs(g_i18n.texts) do
        g_i18n.globalI18N.texts[textName] = textValue
        
        -- Speciality regarding pH texts
        if Utils.startsWith(textName, "pH_") then
            local low,high = unpack( Utils.splitString("-", textName:sub(4)) )
            low,high=tonumber(low),tonumber(high)
            --log(low," ",high," ",textName)
            table.insert(fmcSoilMod.pH2Denomination, {low=low,high=high,textName=textName});
        end
    end
end

--
-- Plugin functionality
--
function fmcSoilMod.processPlugins()
    -- Initialize
    Utils.fmcPluginsCutFruitAreaSetup               = {["0"]="cut-fruit-area(setup)"}
    Utils.fmcPluginsCutFruitAreaPreFuncs            = {["0"]="cut-fruit-area(before)"}
    Utils.fmcPluginsCutFruitAreaPostFuncs           = {["0"]="cut-fruit-area(after)"}

    Utils.fmcPluginsUpdateCultivatorAreaSetup       = {["0"]="update-cultivator-area(setup)"}
    Utils.fmcPluginsUpdateCultivatorAreaPreFuncs    = {["0"]="update-cultivator-area(before)"}
    Utils.fmcPluginsUpdateCultivatorAreaPostFuncs   = {["0"]="update-cultivator-area(after)"}

    Utils.fmcPluginsUpdatePloughAreaSetup           = {["0"]="update-plough-area(setup)"}
    Utils.fmcPluginsUpdatePloughAreaPreFuncs        = {["0"]="update-plough-area(before)"}
    Utils.fmcPluginsUpdatePloughAreaPostFuncs       = {["0"]="update-plough-area(after)"}
    
    Utils.fmcPluginsUpdateSowingAreaSetup           = {["0"]="update-sowing-area(setup)"}
    Utils.fmcPluginsUpdateSowingAreaPreFuncs        = {["0"]="update-sowing-area(before)"}
    Utils.fmcPluginsUpdateSowingAreaPostFuncs       = {["0"]="update-sowing-area(after)"}
    
    fmcGrowthControl.pluginsGrowthCycleFruits       = {["0"]="growth-cycle(fruits)"}
    fmcGrowthControl.pluginsGrowthCycle             = {["0"]="growth-cycle"}
    fmcGrowthControl.pluginsWeatherCycle            = {["0"]="weather-cycle"}
    
    Utils.fmcUpdateSprayAreaFillTypeFuncs           = {}
    
    --
    local function addPlugin(pluginArray,description,priority,pluginFunc)
        if (pluginArray == nil or description == nil or priority == nil or pluginFunc == nil or priority < 1) then
            return false;
        end
        local prioTxt = tostring(priority)
        local subPrio = 0
        -- Add to array based on priority, without overwriting existing ones with same priority.
        while (pluginArray[prioTxt] ~= nil) do
            subPrio = subPrio + 1
            prioTxt = ("%d.%d"):format(priority,subPrio)
        end
        logInfo("Plugin for ", pluginArray["0"], ": (", prioTxt, ") ", description)
        pluginArray[prioTxt] = pluginFunc;
        return true
    end

    -- Build some functions that can register for specific plugin areas
    local soilMod = {}
    soilMod.addPlugin_CutFruitArea_setup            = function(description,priority,pluginFunc) return addPlugin(Utils.fmcPluginsCutFruitAreaSetup              ,description,priority,pluginFunc) end;
    soilMod.addPlugin_CutFruitArea_before           = function(description,priority,pluginFunc) return addPlugin(Utils.fmcPluginsCutFruitAreaPreFuncs           ,description,priority,pluginFunc) end;
    soilMod.addPlugin_CutFruitArea_after            = function(description,priority,pluginFunc) return addPlugin(Utils.fmcPluginsCutFruitAreaPostFuncs          ,description,priority,pluginFunc) end;

    soilMod.addPlugin_UpdateCultivatorArea_setup    = function(description,priority,pluginFunc) return addPlugin(Utils.fmcPluginsUpdateCultivatorAreaSetup      ,description,priority,pluginFunc) end;
    soilMod.addPlugin_UpdateCultivatorArea_before   = function(description,priority,pluginFunc) return addPlugin(Utils.fmcPluginsUpdateCultivatorAreaPreFuncs   ,description,priority,pluginFunc) end;
    soilMod.addPlugin_UpdateCultivatorArea_after    = function(description,priority,pluginFunc) return addPlugin(Utils.fmcPluginsUpdateCultivatorAreaPostFuncs  ,description,priority,pluginFunc) end;

    soilMod.addPlugin_UpdatePloughArea_setup        = function(description,priority,pluginFunc) return addPlugin(Utils.fmcPluginsUpdatePloughAreaSetup          ,description,priority,pluginFunc) end;
    soilMod.addPlugin_UpdatePloughArea_before       = function(description,priority,pluginFunc) return addPlugin(Utils.fmcPluginsUpdatePloughAreaPreFuncs       ,description,priority,pluginFunc) end;
    soilMod.addPlugin_UpdatePloughArea_after        = function(description,priority,pluginFunc) return addPlugin(Utils.fmcPluginsUpdatePloughAreaPostFuncs      ,description,priority,pluginFunc) end;
        
    soilMod.addPlugin_UpdateSowingArea_setup        = function(description,priority,pluginFunc) return addPlugin(Utils.fmcPluginsUpdateSowingAreaSetup          ,description,priority,pluginFunc) end;
    soilMod.addPlugin_UpdateSowingArea_before       = function(description,priority,pluginFunc) return addPlugin(Utils.fmcPluginsUpdateSowingAreaPreFuncs       ,description,priority,pluginFunc) end;
    soilMod.addPlugin_UpdateSowingArea_after        = function(description,priority,pluginFunc) return addPlugin(Utils.fmcPluginsUpdateSowingAreaPostFuncs      ,description,priority,pluginFunc) end;
    
    soilMod.addPlugin_GrowthCycleFruits             = function(description,priority,pluginFunc) return addPlugin(fmcGrowthControl.pluginsGrowthCycleFruits      ,description,priority,pluginFunc) end;
    soilMod.addPlugin_GrowthCycle                   = function(description,priority,pluginFunc) return addPlugin(fmcGrowthControl.pluginsGrowthCycle            ,description,priority,pluginFunc) end;
    soilMod.addPlugin_WeatherCycle                  = function(description,priority,pluginFunc) return addPlugin(fmcGrowthControl.pluginsWeatherCycle           ,description,priority,pluginFunc) end;

    soilMod.addDestructibleFoliageId                = fmcModifyFSUtils.addDestructibleFoliageId
    
    soilMod.addPlugin_UpdateSprayArea_fillType      = function(description,priority,augmentedFillType,pluginFunc)
                                                          if augmentedFillType == nil or augmentedFillType <= 0 then
                                                              return false;
                                                          end
                                                          if Utils.fmcUpdateSprayAreaFillTypeFuncs[augmentedFillType] == nil then
                                                              Utils.fmcUpdateSprayAreaFillTypeFuncs[augmentedFillType] = { ["0"]=("update-spray-area(filltype=%d)"):format(augmentedFillType) }
                                                          end
                                                          return addPlugin(Utils.fmcUpdateSprayAreaFillTypeFuncs[augmentedFillType], description,priority,pluginFunc)
                                                      end;
    
    -- "We call you"
    local allOK = true
    for _,mod in pairs(getfenv(0)["modSoilMod2Plugins"]) do
        if mod ~= nil and type(mod)=="table" and mod.soilModPluginCallback ~= nil then
            allOK = mod.soilModPluginCallback(soilMod,fmcSettings) and allOK
        end
    end

    --
    local function reorderArray(pluginArray)
        local keys = {}
        for k,v in pairs(pluginArray) do
            if type(v)=="function" then
                table.insert(keys, tonumber(k))
            end
        end
        table.sort(keys)
        local newArray = {}
        for _,k in pairs(keys) do
            table.insert(newArray, pluginArray[tostring(k)])
        end
        return newArray
    end

    -- Sort by priority
    Utils.fmcPluginsCutFruitAreaSetup             = reorderArray(Utils.fmcPluginsCutFruitAreaSetup            )
    Utils.fmcPluginsCutFruitAreaPreFuncs          = reorderArray(Utils.fmcPluginsCutFruitAreaPreFuncs         )
    Utils.fmcPluginsCutFruitAreaPostFuncs         = reorderArray(Utils.fmcPluginsCutFruitAreaPostFuncs        )

    Utils.fmcPluginsUpdateCultivatorAreaSetup     = reorderArray(Utils.fmcPluginsUpdateCultivatorAreaSetup    )
    Utils.fmcPluginsUpdateCultivatorAreaPreFuncs  = reorderArray(Utils.fmcPluginsUpdateCultivatorAreaPreFuncs )
    Utils.fmcPluginsUpdateCultivatorAreaPostFuncs = reorderArray(Utils.fmcPluginsUpdateCultivatorAreaPostFuncs)

    Utils.fmcPluginsUpdatePloughAreaSetup         = reorderArray(Utils.fmcPluginsUpdatePloughAreaSetup        )
    Utils.fmcPluginsUpdatePloughAreaPreFuncs      = reorderArray(Utils.fmcPluginsUpdatePloughAreaPreFuncs     )
    Utils.fmcPluginsUpdatePloughAreaPostFuncs     = reorderArray(Utils.fmcPluginsUpdatePloughAreaPostFuncs    )

    Utils.fmcPluginsUpdateSowingAreaSetup         = reorderArray(Utils.fmcPluginsUpdateSowingAreaSetup        )
    Utils.fmcPluginsUpdateSowingAreaPreFuncs      = reorderArray(Utils.fmcPluginsUpdateSowingAreaPreFuncs     )
    Utils.fmcPluginsUpdateSowingAreaPostFuncs     = reorderArray(Utils.fmcPluginsUpdateSowingAreaPostFuncs    )
    
    fmcGrowthControl.pluginsGrowthCycleFruits     = reorderArray(fmcGrowthControl.pluginsGrowthCycleFruits    )
    fmcGrowthControl.pluginsGrowthCycle           = reorderArray(fmcGrowthControl.pluginsGrowthCycle          )
    fmcGrowthControl.pluginsWeatherCycle          = reorderArray(fmcGrowthControl.pluginsWeatherCycle         )

    for k,v in pairs(Utils.fmcUpdateSprayAreaFillTypeFuncs) do
        Utils.fmcUpdateSprayAreaFillTypeFuncs[k] = reorderArray(v)
    end
    
    --
    return allOK
end

--
print(("Script loaded: fmcSoilMod.LUA (v%s)"):format(fmcSoilMod.version))
