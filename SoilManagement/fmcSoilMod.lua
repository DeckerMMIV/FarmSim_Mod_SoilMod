--
--  The Soil Management and Growth Control Project - version 2 (FS15)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modhoster.com
-- @date    2015-01-xx
--

fmcSoilMod = {}
addModEventListener(fmcSoilMod) -- For supporting vanilla maps that does NOT have the required elements in their SampleModMap.LUA

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

-- For debugging
fmcSoilMod.logEnabled = true
function log(...)
    if fmcSoilMod.logEnabled 
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

local function removeModEventListener(spec)
    for i,listener in ipairs(g_modEventListeners) do
        if listener == spec then
            log("removeModEventListener removed: ",spec)
            g_modEventListeners[i] = nil;
            break;
        end;
    end;
end

--
source(g_currentModDirectory .. 'fmcSettings.lua')
source(g_currentModDirectory .. 'fmcFilltypes.lua')
source(g_currentModDirectory .. 'fmcModifyFSUtils.lua')
source(g_currentModDirectory .. 'fmcModifySprayers.lua')
source(g_currentModDirectory .. 'fmcGrowthControl.lua')
source(g_currentModDirectory .. 'fmcSoilModPlugins.lua') -- SoilMod uses its own plugin facility to add its own effects.
source(g_currentModDirectory .. 'fmcDisplay.lua')

--
function fmcSoilMod:loadMap(name)
    log("fmcSoilMod:loadMap(",name,")")
    fmcSoilMod.enabled = false
    fmcFilltypes.setup()
    fmcModifySprayers.setup()    
    fmcGrowthControl.preSetup()
    fmcSoilMod.asModEventListener = true
end

function fmcSoilMod:deleteMap()
    log("fmcSoilMod:deleteMap()")
    fmcModifyFSUtils.teardown()
    fmcSoilMod.enabled = false
end;

function fmcSoilMod:mouseEvent(posX, posY, isDown, isUp, button) end;
function fmcSoilMod:keyEvent(unicode, sym, modifier, isDown) end;

--
function fmcSoilMod.setup_map_new(mapFilltypeOverlaysDirectory)
    log("fmcSoilMod - setup_map_new(", mapFilltypeOverlaysDirectory, ")")

    -- SampleModMap.LUA seems to have the required elements
    removeModEventListener(fmcSoilMod)

    --    
    fmcSoilMod.enabled = false
    fmcFilltypes.setup(mapFilltypeOverlaysDirectory)
    fmcModifySprayers.setup()    
    --fmcFilltypes.setupFruitFertilizerBoostHerbicideAffected()
    fmcGrowthControl.preSetup()
end

--
function fmcSoilMod.teardown_map_delete()
    log("fmcSoilMod - teardown_map_delete()")
    fmcModifyFSUtils.teardown()
    fmcSoilMod.enabled = false
end

--
--function fmcSoilMod.preInit_loadMapFinished()
--    log("fmcSoilMod - preInit_loadMapFinished()")
--end

--
function fmcSoilMod.postInit_loadMapFinished()
    log("fmcSoilMod - postInit_loadMapFinished()")

    fmcGrowthControl.setup()
    fmcModifyFSUtils.preSetup()

    fmcSettings.loadFromSavegame()

    if fmcSoilMod.processPlugins() then
        fmcGrowthControl.postSetup()
        fmcModifyFSUtils.setup()
        fmcFilltypes.updateFillTypeOverlays()
        fmcDisplay.setup()
        fmcSoilMod.copy_l10n_texts_to_global()
        fmcSoilMod.enabled = true
    
        if g_currentMission:getIsServer() then    
            addConsoleCommand("modSoilMod", "", "consoleCommandSoilMod", fmcSoilMod)
        end
    else
        logInfo("")
        logInfo("ERROR! Problem occurred during SoilMod's initial set-up. - Soil Management will NOT be available!")
        logInfo("")
        fmcSoilMod.enabled = false
    end
end

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
function fmcSoilMod.update(self, dt)
    if fmcSoilMod.enabled then
        fmcGrowthControl.update(fmcGrowthControl, dt)
        fmcDisplay.update(dt)
    elseif fmcSoilMod.asModEventListener then
        fmcSoilMod.asModEventListener = false
        fmcSoilMod.postInit_loadMapFinished()
    end
end

--
function fmcSoilMod.draw(self)
    if fmcSoilMod.enabled then
        fmcGrowthControl.draw(fmcGrowthControl)
        fmcDisplay.draw()
    end
end

----
--function fmcSoilMod.setMapProperty(keyName, value)
--    if not fmcSettings.updateKeyValueDesc(keyName, value) then
--        logInfo("WARNING! Can not set map-property with key-name: '",keyName,"'")
--        return false
--    end
--    logInfo("Map-property '", keyName, "' updated to value '", fmcSettings.getKeyValue(keyName), "'")
--    return true
--end

--function fmcSoilMod.setFruit_FertilizerBoost_HerbicideAffected(fruitName, fertilizerName, herbicideName)
--    if fmcSoilMod.simplisticMode then
--        -- Not used in 'simplistic mode'.
--        return
--    end
--    --
--    local fruitDesc = FruitUtil.fruitTypes[fruitName]
--    if fruitDesc == nil then
--        logInfo("ERROR! Fruit '"..tostring(fruitName).."' is not registered as a fruit-type.")
--        return
--    end
--    --
--    local attrsSet = nil
--    
--    if fertilizerName ~= nil and fertilizerName ~= "" then
--        local fillTypeFertilizer  = "FILLTYPE_"  .. tostring(fertilizerName):upper()
--        local sprayTypeFertilizer = "SPRAYTYPE_" .. tostring(fertilizerName):upper()
--        if Sprayer[sprayTypeFertilizer] == nil or Fillable[fillTypeFertilizer] == nil then
--            logInfo("ERROR! Fertilizer '"..tostring(fertilizerName).."' is not registered as a spray-type or fill-type.")
--        else
--            fruitDesc.fmcBoostFertilizer = Fillable[fillTypeFertilizer];
--            attrsSet = ((attrsSet == nil) and "" or attrsSet..", ") .. ("fertilizer-boost:'%s'"):format(fertilizerName)
--        end
--    end
--    --
--    if herbicideName ~= nil and herbicideName ~= "" then
--        local fillTypeHerbicide  = "FILLTYPE_"  .. tostring(herbicideName):upper()
--        local sprayTypeHerbicide = "SPRAYTYPE_" .. tostring(herbicideName):upper()
--        if Sprayer[sprayTypeHerbicide] == nil or Fillable[fillTypeHerbicide] == nil then
--            logInfo("ERROR! Herbicide '"..tostring(herbicideName).."' is not registered as a spray-type or fill-type.")
--        else
--            fruitDesc.fmcHerbicideAffected = Fillable[fillTypeHerbicide];
--            attrsSet = ((attrsSet == nil) and "" or attrsSet..", ") .. ("herbicide-affected:'%s'"):format(herbicideName)
--        end
--    end
--    --
--    logInfo(("Fruit '%s' attributes set; %s."):format(tostring(fruitName), (attrsSet == nil and "(none)" or tostring(attrsSet))))
--end


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

    --logInfo("Collecting plugins")

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
