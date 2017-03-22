--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-01-xx
--

sm3SoilMod = {}

-- "Register" this object in global environment, so other mods can "see" it.
getfenv(0)["modSoilMod"] = sm3SoilMod 

-- Plugin support. Array for plugins to add themself to, so SoilMod can later "call them back".
getfenv(0)["modSoilModPlugins"] = getfenv(0)["modSoilModPlugins"] or {}

--
local modItem = ModsUtil.findModItemByModName(g_currentModName);
sm3SoilMod.version = Utils.getNoNil(modItem.version, "?.?.?")
sm3SoilMod.modDir = g_currentModDirectory;

--
sm3SoilMod.pHScaleModifier = 0.17

-- For debugging
sm3SoilMod.logVerbose = true
function log(...)
    if sm3SoilMod.logVerbose then
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

-- For loading
local srcFolder = g_currentModDirectory .. 'Scripts/'
local srcFiles = {
    'Settings.lua',
    'FillTypes.lua',
    'ModifyFSUtils.lua',
    'ModifySprayers.lua',
    --'ModifySowingMachines.lua',
    'ModifyFillTrigger.lua',
    --'ModifyMultiSiloTrigger.lua',
    'ModifyInGameMenu.lua',
    'GrowthControl.lua',
    'SoilModPlugins.lua',        -- SoilMod uses its own plugin facility to add its own effects.
    --'CompostPlugin.lua',         --
    --'ChoppedStrawPlugin.lua',    --
    'Display.lua',
}
if modItem.isDirectory then
    for i=1,#srcFiles do
        local srcFile = srcFolder..srcFiles[i]
        local fileHash = tostring(getFileMD5(srcFile, sm3SoilMod.modDir))
        print(string.format("Script load..: %s (v%s - %s)", srcFiles[i], sm3SoilMod.version, fileHash));
        source(srcFile)
    end
    sm3SoilMod.version = sm3SoilMod.version .. " - " .. getFileMD5(srcFolder..'SoilMod.lua', sm3SoilMod.modDir)
else
    for i=1,#srcFiles do
        print(string.format("Script load..: %s (v%s)", srcFiles[i], sm3SoilMod.version));
        source(srcFolder..srcFiles[i])
    end
    sm3SoilMod.version = sm3SoilMod.version .. " - " .. modItem.fileHash
end

--
function sm3SoilMod.loadMap(...)
    --if ModsSettings ~= nil then
    --    sm3SoilMod.logVerbose = ModsSettings.getBoolLocal("SoilMod","internals","logVerbose",sm3SoilMod.logVerbose)
    --end
    
    log("sm3SoilMod.loadMap()")

    -- Get the map-mod's g_i18n table, if its available.
    local mapSelf = select(1, ...)
    sm3SoilMod.i18n = (mapSelf.missionInfo.customEnvironment ~= nil) and _G[mapSelf.missionInfo.customEnvironment].g_i18n or nil;
--[[
    -- Try loading custom translations
    sm3SoilMod.loadCustomTranslations()
--]]    
    -- Register SoilMod's spray-/fill-types, before the map.I3D is loaded.
    sm3Filltypes.setup(mapSelf)

    -- Now do the original loadMap()
    return sm3SoilMod.orig_loadMap(...)
end

--
function sm3SoilMod.loadMapFinished(...)
    log("sm3SoilMod.loadMapFinished()")

    --
    sm3SoilMod.updateFunc = function(self, dt) end;
    sm3SoilMod.drawFunc   = function(self)     end;
    sm3SoilMod.enabled = false

    --
    sm3Filltypes.loadFillPlaneMaterials(select(1,...))

    --
    local ret = { sm3SoilMod.orig_loadMapFinished(...) }

    --    
    if not sm3Filltypes.postSetup() then
        -- SoilMod's spray-/fill-types not correctly registered
    else
        -- TODO - Clean up these functions calls.
        sm3GrowthControl.preSetup()
        sm3GrowthControl.setup()
        sm3ModifyFSUtils.preSetup()
        sm3ModifySprayers.preSetup()
        sm3Settings.loadFromSavegame()
        sm3Settings.updateCustomSettings()
        if sm3SoilMod.processPlugins() then
            sm3ModifySprayers.setup()
            --sm3ModifySowingMachines.setup()
            sm3GrowthControl.postSetup()
            sm3ModifyFSUtils.setup()
            sm3Filltypes.addMoreFillTypeOverlayIcons()
            sm3Filltypes.updateFillTypeOverlays()
            sm3Display:setup()
            sm3SoilMod.copy_l10n_texts_to_global()
            sm3SoilMod.initDenominationValues()
            sm3ModifyInGameMenu()
            sm3SoilMod.enabled = true
            if g_currentMission:getIsServer() then    
                addConsoleCommand("modSoilModPaint", "", "consoleCommandSoilModPaint", sm3SoilMod)
            end
        end
    end

    if not sm3SoilMod.enabled then
        logInfo("")
        logInfo("ERROR! Problem occurred during SoilMod's initial set-up. - Soil Management will NOT be available!")
        logInfo("")
    else
        -- This function modifies itself!
        sm3SoilMod.updateFunc = function(self, dt)
            -- First time run
            Utils.sm3BuildDensityMaps()
            sm3GrowthControl.update(sm3GrowthControl, dt)
            sm3Display:update(dt)
            --
            sm3SoilMod.updateFunc = function(self, dt)
                -- All subsequent runs
                sm3GrowthControl.update(sm3GrowthControl, dt)
                sm3Display:update(dt)
            end
        end
        --
        sm3SoilMod.drawFunc = function(self)
            if self.isRunning and g_gui.currentGui == nil then
                sm3GrowthControl.draw(sm3GrowthControl)
                sm3Display:draw()
            end
        end
    end

    return unpack(ret);
end

function sm3SoilMod.delete(...)
    log("sm3SoilMod.delete()")
    
    --sm3ModifyFSUtils.teardown()
    sm3SoilMod.enabled = false
    
    return sm3SoilMod.orig_delete(...)
end;

function sm3SoilMod.update(self, dt)
    sm3SoilMod.orig_update(self, dt)
    sm3SoilMod.updateFunc(self, dt);
end

function sm3SoilMod.draw(self)
    sm3SoilMod.orig_draw(self)
    sm3SoilMod.drawFunc(self);
end

-- Apparently trying to use Utils.prepended/appended/overwrittenFunction() seems not to work as I wanted it.
-- So we're doing it using the "brute-forced method" instead!
sm3SoilMod.orig_loadMap         = FSBaseMission.loadMap;
sm3SoilMod.orig_loadMapFinished = FSBaseMission.loadMapFinished;
sm3SoilMod.orig_delete          = FSBaseMission.delete;
sm3SoilMod.orig_update          = FSBaseMission.update;
sm3SoilMod.orig_draw            = FSBaseMission.draw;
--
FSBaseMission.loadMap           = sm3SoilMod.loadMap;
FSBaseMission.loadMapFinished   = sm3SoilMod.loadMapFinished;
FSBaseMission.delete            = sm3SoilMod.delete;
FSBaseMission.update            = sm3SoilMod.update;
FSBaseMission.draw              = sm3SoilMod.draw;


--
--
--
function sm3SoilMod.consoleCommandSoilModPaint(self, arg1, arg2, arg3)
    if not arg1 then
        print("modSoilModPaint <Foliage-Name> <newValue> <field# | 'world'>")
        return
    end
    
    log("modSoilModPaint: ",arg1,", ",arg2,", ",arg3,", ",arg4)

--[[
    <foliage name>    <new value>|"inc"|"dec"   <field #>|"world"
--]]
    local foliageName = tostring(arg1)
    local foliageId = nil
    if foliageName ~= nil then
        foliageName = "sm3Foliage"..foliageName
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
function sm3SoilMod.density_to_pH(sumPixels, numPixels, numChannels)
    if numPixels <= 0 then
        return 0  -- No value to calculate
    end
    local offsetPct = ((sumPixels / ((2^numChannels - 1) * numPixels)) - 0.5) * 2
    return sm3SoilMod.offsetPct_to_pH(offsetPct)
end

function sm3SoilMod.offsetPct_to_pH(offsetPct)
    -- 'offsetPct' should be between -1.0 and +1.0
    local phValue = 7.0 + (3 * math.sin(offsetPct * (math.pi * sm3SoilMod.pHScaleModifier)))
    return math.floor(phValue * 10) / 10; -- Return with only one decimal-digit.
end

function sm3SoilMod.pH_to_Denomination(phValue)
    for _,elem in pairs(sm3SoilMod.pH2Denomination) do
        if elem.low <= phValue and phValue < elem.high then
            return elem.textName
        end
    end
    return "unknown_pH"
end

--[[
--
-- Player-local customizable translations.
--
function sm3SoilMod.loadCustomTranslations()
    local filename = g_modsDirectory .. "AAA_CustomTranslations/" .. "SoilManagement/" .. "modDesc_l10n.xml"

    if not fileExists(filename) then
        logInfo("Custom translations were not loaded. File not found: ",filename)
        return
    end
    
    local xmlFile = loadXMLFile("i18n", filename)
    
    --local updatedNames = {}
    local unknownNames = nil
    local i=0
    while true do
        local tag = ("l10n.texts.text(%d)"):format(i)
        i=i+1
        local itemName = getXMLString(xmlFile, tag.."#name")
        local itemText = getXMLString(xmlFile, tag.."#text")
        if itemName == nil or itemText == nil then
            break
        end
        --
        if g_i18n:hasText(itemName) then
            g_i18n:setText(itemName, itemText)
        else
            table.insert(Utils.getNoNil(unknownNames, {}), itemName)
        end
    end
    
    delete(xmlFile)
    xmlFile = nil;
    
    if unknownNames ~= nil then
        local txt = ""
        local delim = ""
        for _,t in pairs(unknownNames) do
            txt=txt..delim..t
            delim=", "
        end
        logInfo("WARNING: Custom translations has unknown 'name' elements: ",txt);
    end
end
--]]


--
-- Utility function, that attempts to extract l10n texts from map-mod first, 
-- else reverting to SoilMod's l10n texts, or if that also fails then just return the generic text-name.
--
function sm3SoilMod.i18nText(textName)
    if sm3SoilMod.i18n ~= nil and sm3SoilMod.i18n:hasText(textName) then
        return sm3SoilMod.i18n:getText(textName)
    elseif g_i18n:hasText(textName) then
        return g_i18n:getText(textName)
    end
    return textName
end

--
-- Utility function for copying this mod's <l10n> text-entries, into the game's global table.
--
function sm3SoilMod.copy_l10n_texts_to_global()
    sm3SoilMod.pH2Denomination = {}

    -- Copy the map-mod's customized or this mod's localization texts to global table - but only if they not already exist in global table.
    for textName,_ in pairs(g_i18n.texts) do
        if g_i18n.globalI18N.texts[textName] == nil then
            g_i18n.globalI18N.texts[textName] = sm3SoilMod.i18nText(textName)
        end
    end
end

function sm3SoilMod.initDenominationValues()
    sm3SoilMod.pH2Denomination = {}
    for textName,textValue in pairs(g_i18n.texts) do
        if Utils.startsWith(textName, "pH_") then
            local low,high = unpack( Utils.splitString("-", textName:sub(4)) )
            low,high=tonumber(low),tonumber(high)
            table.insert(sm3SoilMod.pH2Denomination, {low=low,high=high,textName=textName});
        end
    end
end

--
-- Plugin functionality
--
function sm3SoilMod.processPlugins()
    -- Initialize
    Utils.sm3PluginsCutFruitAreaSetup               = {["0"]="cut-fruit-area(setup)"}
    Utils.sm3PluginsCutFruitAreaPreFuncs            = {["0"]="cut-fruit-area(before)"}
    Utils.sm3PluginsCutFruitAreaPostFuncs           = {["0"]="cut-fruit-area(after)"}

    Utils.sm3PluginsUpdateCultivatorAreaSetup       = {["0"]="update-cultivator-area(setup)"}
    Utils.sm3PluginsUpdateCultivatorAreaPreFuncs    = {["0"]="update-cultivator-area(before)"}
    Utils.sm3PluginsUpdateCultivatorAreaPostFuncs   = {["0"]="update-cultivator-area(after)"}

    Utils.sm3PluginsUpdatePloughAreaSetup           = {["0"]="update-plough-area(setup)"}
    Utils.sm3PluginsUpdatePloughAreaPreFuncs        = {["0"]="update-plough-area(before)"}
    Utils.sm3PluginsUpdatePloughAreaPostFuncs       = {["0"]="update-plough-area(after)"}
    
    Utils.sm3PluginsUpdateSowingAreaSetup           = {["0"]="update-sowing-area(setup)"}
    Utils.sm3PluginsUpdateSowingAreaPreFuncs        = {["0"]="update-sowing-area(before)"}
    Utils.sm3PluginsUpdateSowingAreaPostFuncs       = {["0"]="update-sowing-area(after)"}
    
    sm3GrowthControl.pluginsGrowthCycleFruits       = {["0"]="growth-cycle(fruits)"}
    sm3GrowthControl.pluginsGrowthCycle             = {["0"]="growth-cycle"}
    sm3GrowthControl.pluginsWeatherCycle            = {["0"]="weather-cycle"}
    
    Utils.sm3UpdateSprayAreaFillTypeFuncs           = {}
    
    Utils.sm3PluginsUpdateWeederAreaSetup           = {["0"]="update-weeder-area(setup)"}
    Utils.sm3PluginsUpdateWeederAreaPreFuncs        = {["0"]="update-weeder-area(before)"}
    Utils.sm3PluginsUpdateWeederAreaPostFuncs       = {["0"]="update-weeder-area(after)"}
    
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
    soilMod.addPlugin_CutFruitArea_setup            = function(description,priority,pluginFunc) return addPlugin(Utils.sm3PluginsCutFruitAreaSetup              ,description,priority,pluginFunc) end;
    soilMod.addPlugin_CutFruitArea_before           = function(description,priority,pluginFunc) return addPlugin(Utils.sm3PluginsCutFruitAreaPreFuncs           ,description,priority,pluginFunc) end;
    soilMod.addPlugin_CutFruitArea_after            = function(description,priority,pluginFunc) return addPlugin(Utils.sm3PluginsCutFruitAreaPostFuncs          ,description,priority,pluginFunc) end;

    soilMod.addPlugin_UpdateCultivatorArea_setup    = function(description,priority,pluginFunc) return addPlugin(Utils.sm3PluginsUpdateCultivatorAreaSetup      ,description,priority,pluginFunc) end;
    soilMod.addPlugin_UpdateCultivatorArea_before   = function(description,priority,pluginFunc) return addPlugin(Utils.sm3PluginsUpdateCultivatorAreaPreFuncs   ,description,priority,pluginFunc) end;
    soilMod.addPlugin_UpdateCultivatorArea_after    = function(description,priority,pluginFunc) return addPlugin(Utils.sm3PluginsUpdateCultivatorAreaPostFuncs  ,description,priority,pluginFunc) end;

    soilMod.addPlugin_UpdatePloughArea_setup        = function(description,priority,pluginFunc) return addPlugin(Utils.sm3PluginsUpdatePloughAreaSetup          ,description,priority,pluginFunc) end;
    soilMod.addPlugin_UpdatePloughArea_before       = function(description,priority,pluginFunc) return addPlugin(Utils.sm3PluginsUpdatePloughAreaPreFuncs       ,description,priority,pluginFunc) end;
    soilMod.addPlugin_UpdatePloughArea_after        = function(description,priority,pluginFunc) return addPlugin(Utils.sm3PluginsUpdatePloughAreaPostFuncs      ,description,priority,pluginFunc) end;
        
    soilMod.addPlugin_UpdateSowingArea_setup        = function(description,priority,pluginFunc) return addPlugin(Utils.sm3PluginsUpdateSowingAreaSetup          ,description,priority,pluginFunc) end;
    soilMod.addPlugin_UpdateSowingArea_before       = function(description,priority,pluginFunc) return addPlugin(Utils.sm3PluginsUpdateSowingAreaPreFuncs       ,description,priority,pluginFunc) end;
    soilMod.addPlugin_UpdateSowingArea_after        = function(description,priority,pluginFunc) return addPlugin(Utils.sm3PluginsUpdateSowingAreaPostFuncs      ,description,priority,pluginFunc) end;
    
    soilMod.addPlugin_GrowthCycleFruits             = function(description,priority,pluginFunc) return addPlugin(sm3GrowthControl.pluginsGrowthCycleFruits      ,description,priority,pluginFunc) end;
    soilMod.addPlugin_GrowthCycle                   = function(description,priority,pluginFunc) return addPlugin(sm3GrowthControl.pluginsGrowthCycle            ,description,priority,pluginFunc) end;
    soilMod.addPlugin_WeatherCycle                  = function(description,priority,pluginFunc) return addPlugin(sm3GrowthControl.pluginsWeatherCycle           ,description,priority,pluginFunc) end;

    soilMod.addDestructibleFoliageId                = sm3ModifyFSUtils.addDestructibleFoliageId
    
    soilMod.addPlugin_UpdateSprayArea_fillType      = function(description,priority,augmentedFillType,pluginFunc)
                                                          if augmentedFillType == nil or augmentedFillType <= 0 then
                                                              return false;
                                                          end
                                                          if Utils.sm3UpdateSprayAreaFillTypeFuncs[augmentedFillType] == nil then
                                                              Utils.sm3UpdateSprayAreaFillTypeFuncs[augmentedFillType] = { ["0"]=("update-spray-area(filltype=%d)"):format(augmentedFillType) }
                                                          end
                                                          return addPlugin(Utils.sm3UpdateSprayAreaFillTypeFuncs[augmentedFillType], description,priority,pluginFunc)
                                                      end;
    
    soilMod.addPlugin_UpdateWeederArea_setup        = function(description,priority,pluginFunc) return addPlugin(Utils.sm3PluginsUpdateWeederAreaSetup      ,description,priority,pluginFunc) end;
    soilMod.addPlugin_UpdateWeederArea_before       = function(description,priority,pluginFunc) return addPlugin(Utils.sm3PluginsUpdateWeederAreaPreFuncs   ,description,priority,pluginFunc) end;
    soilMod.addPlugin_UpdateWeederArea_after        = function(description,priority,pluginFunc) return addPlugin(Utils.sm3PluginsUpdateWeederAreaPostFuncs  ,description,priority,pluginFunc) end;

    -- "We call you"
    local allOK = true
    for _,mod in pairs(getfenv(0)["modSoilModPlugins"]) do
        if mod ~= nil and type(mod)=="table" and mod.soilModPluginCallback ~= nil then
            allOK = mod.soilModPluginCallback(soilMod,sm3Settings) and allOK
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
    Utils.sm3PluginsCutFruitAreaSetup             = reorderArray(Utils.sm3PluginsCutFruitAreaSetup            )
    Utils.sm3PluginsCutFruitAreaPreFuncs          = reorderArray(Utils.sm3PluginsCutFruitAreaPreFuncs         )
    Utils.sm3PluginsCutFruitAreaPostFuncs         = reorderArray(Utils.sm3PluginsCutFruitAreaPostFuncs        )

    Utils.sm3PluginsUpdateCultivatorAreaSetup     = reorderArray(Utils.sm3PluginsUpdateCultivatorAreaSetup    )
    Utils.sm3PluginsUpdateCultivatorAreaPreFuncs  = reorderArray(Utils.sm3PluginsUpdateCultivatorAreaPreFuncs )
    Utils.sm3PluginsUpdateCultivatorAreaPostFuncs = reorderArray(Utils.sm3PluginsUpdateCultivatorAreaPostFuncs)

    Utils.sm3PluginsUpdatePloughAreaSetup         = reorderArray(Utils.sm3PluginsUpdatePloughAreaSetup        )
    Utils.sm3PluginsUpdatePloughAreaPreFuncs      = reorderArray(Utils.sm3PluginsUpdatePloughAreaPreFuncs     )
    Utils.sm3PluginsUpdatePloughAreaPostFuncs     = reorderArray(Utils.sm3PluginsUpdatePloughAreaPostFuncs    )

    Utils.sm3PluginsUpdateSowingAreaSetup         = reorderArray(Utils.sm3PluginsUpdateSowingAreaSetup        )
    Utils.sm3PluginsUpdateSowingAreaPreFuncs      = reorderArray(Utils.sm3PluginsUpdateSowingAreaPreFuncs     )
    Utils.sm3PluginsUpdateSowingAreaPostFuncs     = reorderArray(Utils.sm3PluginsUpdateSowingAreaPostFuncs    )
    
    sm3GrowthControl.pluginsGrowthCycleFruits     = reorderArray(sm3GrowthControl.pluginsGrowthCycleFruits    )
    sm3GrowthControl.pluginsGrowthCycle           = reorderArray(sm3GrowthControl.pluginsGrowthCycle          )
    sm3GrowthControl.pluginsWeatherCycle          = reorderArray(sm3GrowthControl.pluginsWeatherCycle         )

    for k,v in pairs(Utils.sm3UpdateSprayAreaFillTypeFuncs) do
        Utils.sm3UpdateSprayAreaFillTypeFuncs[k] = reorderArray(v)
    end
    
    Utils.sm3PluginsUpdateWeederAreaSetup         = reorderArray(Utils.sm3PluginsUpdateWeederAreaSetup        )
    Utils.sm3PluginsUpdateWeederAreaPreFuncs      = reorderArray(Utils.sm3PluginsUpdateWeederAreaPreFuncs     )
    Utils.sm3PluginsUpdateWeederAreaPostFuncs     = reorderArray(Utils.sm3PluginsUpdateWeederAreaPostFuncs    )

    --
    return allOK
end

--
print(("Script loaded: SoilMod.LUA (v%s)"):format(sm3SoilMod.version))

--
if sm3Filltypes ~= nil and sm3Filltypes.preSetupFillTypes ~= nil then
    -- Register fill-types, so they are available for "farm-silos" when game's base-script reads the careerSavegame.XML
    sm3Filltypes.preSetupFillTypes();
end
