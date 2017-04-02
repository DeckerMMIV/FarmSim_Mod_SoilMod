--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-03-xx
--

soilmod = {}

-- "Register" this object in global environment, so other mods can "see" it.
getfenv(0)["modSoilMod"] = soilmod 

-- Plugin support. Array for plugins to add themself to, so SoilMod can later "call them back".
getfenv(0)["modSoilModPlugins"] = getfenv(0)["modSoilModPlugins"] or {}

--
local modItem = ModsUtil.findModItemByModName(g_currentModName);
soilmod.version = Utils.getNoNil(modItem.version, "?.?.?")
soilmod.modDir = g_currentModDirectory;

--
soilmod.pHScaleModifier = 0.17

-- For debugging
soilmod.logVerbose = true
function log(...)
    if soilmod.logVerbose then
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
    'LayerUtils.lua',
    'ModifyFSUtils.lua',
    'ModifySprayers.lua',
    --'ModifySowingMachines.lua',
    'ModifyFillTrigger.lua',
    --'ModifyMultiSiloTrigger.lua',
    'ModifyInGameMenu.lua',
    'ModifyManureBarrelCultivator.lua',
    'GrowthControl.lua',
    'GrowthPlugins.lua',
    'SoilModPlugins.lua',        -- SoilMod uses its own plugin facility to add its own effects.
    --'CompostPlugin.lua',         --
    --'ChoppedStrawPlugin.lua',    --
    'Display.lua',
}
if modItem.isDirectory then
    for i=1,#srcFiles do
        local srcFile = srcFolder..srcFiles[i]
        local fileHash = tostring(getFileMD5(srcFile, soilmod.modDir))
        print(string.format("Script load..: %s (v%s - %s)", srcFiles[i], soilmod.version, fileHash));
        source(srcFile)
    end
    soilmod.version = soilmod.version .. " - " .. getFileMD5(srcFolder..'SoilMod.lua', soilmod.modDir)
else
    for i=1,#srcFiles do
        print(string.format("Script load..: %s (v%s)", srcFiles[i], soilmod.version));
        source(srcFolder..srcFiles[i])
    end
    soilmod.version = soilmod.version .. " - " .. modItem.fileHash
end

--
function soilmod.loadMap(...)
    --if ModsSettings ~= nil then
    --    soilmod.logVerbose = ModsSettings.getBoolLocal("SoilMod","internals","logVerbose",soilmod.logVerbose)
    --end
    
    log("soilmod.loadMap()")
    
    --
    soilmod:modifyManureBarrelCultivator()

    -- Get the map-mod's g_i18n table, if its available.
    local mapSelf = select(1, ...)
    soilmod.i18n = (mapSelf.missionInfo.customEnvironment ~= nil) and _G[mapSelf.missionInfo.customEnvironment].g_i18n or nil;
--[[
    -- Try loading custom translations
    soilmod.loadCustomTranslations()
--]]    
    -- Register SoilMod's fill-types, before the map.I3D is loaded.
    soilmod:setupFillTypes(mapSelf)

    -- Now do the original loadMap()
    return soilmod.orig_loadMap(...)
end

--
function soilmod.loadMapFinished(...)
    log("soilmod.loadMapFinished()")

    -- SoilMod is not yet truly enabled, due to further checks
    soilmod.enabled = false
    
    -- No-Operation functions, in case verification checks fail
    soilmod.updateFunc = function(self, dt) end;
    soilmod.drawFunc   = function(self)     end;
    
    --
    local mapSelf = select(1, ...)
    soilmod:loadFillPlaneMaterials(mapSelf)

    --
    local ret = { soilmod.orig_loadMapFinished(...) }

    --    
    if not soilmod:postSetupFillTypes() then
        -- SoilMod's spray-/fill-types not correctly registered
    else
        if soilmod:setupGrowthControl(mapSelf) then
            soilmod:preSetupFSUtils()
            soilmod:preSetupSprayers()
            soilmod:loadFromSavegame()
            soilmod:updateCustomSettings()
            if soilmod:processPlugins() then
                soilmod:setupSprayers()
                soilmod:postSetupGrowthControl()
                soilmod:setupFSUtils()
                soilmod:addMoreFillTypeOverlayIcons()
                soilmod:updateFillTypeOverlays()
                soilmod:setupDisplay()
                soilmod.copy_l10n_texts_to_global()
                soilmod:initDenominationValues()
                soilmod:modifyInGameMenu()
                if g_currentMission:getIsServer() then    
                    addConsoleCommand("modSoilModPaint", "", "consoleCommandSoilModPaint", soilmod)
                end
                -- Okay, things seems to be verified...
                soilmod.enabled = true
            end
        end
    end

    if not soilmod.enabled then
        logInfo("")
        logInfo("ERROR! Problem occurred during SoilMod's initial set-up. - SoilMod game-mode will NOT be available!")
        logInfo("")
    else
        -- This function modifies itself!
        soilmod.updateFunc = function(self, dt)
            -- First time run
            soilmod:buildDensityMaps()
            --
            if g_currentMission:getIsServer() then
                soilmod.updateFunc = function(self, dt)
                    soilmod:updateGrowthControl(dt)
                    soilmod:updateDisplay(dt)
                end
            else
                soilmod.updateFunc = function(self, dt)
                    soilmod:updateDisplay(dt)
                end
            end
        end
        --
        soilmod.drawFunc = function(self)
            if self.isRunning and g_gui.currentGui == nil then
                soilmod:drawGrowthControl()
                soilmod:drawDisplay()
            end
        end
    end

    return unpack(ret);
end

function soilmod.delete(...)
    log("soilmod.delete()")
    
    --sm3ModifyFSUtils.teardown()
    soilmod.enabled = false
    
    return soilmod.orig_delete(...)
end;

function soilmod.update(self, dt)
    soilmod.orig_update(self, dt)
    soilmod.updateFunc(self, dt);
end

function soilmod.draw(self)
    soilmod.orig_draw(self)
    soilmod.drawFunc(self);
end

-- Apparently trying to use Utils.prepended/appended/overwrittenFunction() seems not to work as I wanted it.
-- So we're doing it using the "brute-forced method" instead!
soilmod.orig_loadMap         = FSBaseMission.loadMap;
soilmod.orig_loadMapFinished = FSBaseMission.loadMapFinished;
soilmod.orig_delete          = FSBaseMission.delete;
soilmod.orig_update          = FSBaseMission.update;
soilmod.orig_draw            = FSBaseMission.draw;
--
FSBaseMission.loadMap           = soilmod.loadMap;
FSBaseMission.loadMapFinished   = soilmod.loadMapFinished;
FSBaseMission.delete            = soilmod.delete;
FSBaseMission.update            = soilmod.update;
FSBaseMission.draw              = soilmod.draw;


--
--
--
function soilmod:consoleCommandSoilModPaint(arg1, arg2, arg3)
    if not arg1 then
        print("modSoilModPaint <foliageName> <newValue|'inc'|'dec'> <fieldNum|'world'>")
        return
    end
    
    log("modSoilModPaint: ",arg1,", ",arg2,", ",arg3,", ",arg4)

--[[
    <foliage name>    <new value>|"inc"|"dec"   <field #>|"world"
--]]
    local foliageName = tostring(arg1)
    local foliageId = soilmod:getLayerId(foliageName)
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
function soilmod:density_to_pH(sumPixels, numPixels, numChannels)
    if numPixels <= 0 then
        return 0  -- No value to calculate
    end
    local offsetPct = ((sumPixels / ((2^numChannels - 1) * numPixels)) - 0.5) * 2
    return soilmod:offsetPct_to_pH(offsetPct)
end

function soilmod:offsetPct_to_pH(offsetPct)
    -- 'offsetPct' should be between -1.0 and +1.0
    local phValue = 7.0 + (3 * math.sin(offsetPct * (math.pi * soilmod.pHScaleModifier)))
    return math.floor(phValue * 10) / 10; -- Return with only one decimal-digit.
end

function soilmod:pH_to_Denomination(phValue)
    for _,elem in pairs(soilmod.pH2Denomination) do
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
function soilmod.loadCustomTranslations()
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
function soilmod:i18nText(textName)
    if self.i18n ~= nil and self.i18n:hasText(textName) then
        return self.i18n:getText(textName)
    elseif g_i18n:hasText(textName) then
        return g_i18n:getText(textName)
    end
    return textName
end

--
-- Utility function for copying this mod's <l10n> text-entries, into the game's global table.
--
function soilmod:copy_l10n_texts_to_global()
    soilmod.pH2Denomination = {}

    -- Copy the map-mod's customized or this mod's localization texts to global table - but only if they not already exist in global table.
    for textName,_ in pairs(g_i18n.texts) do
        if g_i18n.globalI18N.texts[textName] == nil then
            g_i18n.globalI18N.texts[textName] = soilmod:i18nText(textName)
        end
    end
end

function soilmod:initDenominationValues()
    soilmod.pH2Denomination = {}
    for textName,textValue in pairs(g_i18n.texts) do
        if Utils.startsWith(textName, "pH_") then
            local low,high = unpack( Utils.splitString("-", textName:sub(4)) )
            low,high=tonumber(low),tonumber(high)
            table.insert(soilmod.pH2Denomination, {low=low,high=high,textName=textName});
        end
    end
end

--
-- Plugin functionality
--
function soilmod:processPlugins()
    -- Initialize
    Utils.sm3Plugins_CutFruitArea_Setup         = {["0"]="cut-fruit-area(setup)"}
    Utils.sm3Plugins_CutFruitArea_PreFuncs      = {["0"]="cut-fruit-area(before)"}
    Utils.sm3Plugins_CutFruitArea_PostFuncs     = {["0"]="cut-fruit-area(after)"}

    Utils.sm3Plugins_CultivatorArea_Setup       = {["0"]="update-cultivator-area(setup)"}
    Utils.sm3Plugins_CultivatorArea_PreFuncs    = {["0"]="update-cultivator-area(before)"}
    Utils.sm3Plugins_CultivatorArea_PostFuncs   = {["0"]="update-cultivator-area(after)"}

    Utils.sm3Plugins_PloughArea_Setup           = {["0"]="update-plough-area(setup)"}
    Utils.sm3Plugins_PloughArea_PreFuncs        = {["0"]="update-plough-area(before)"}
    Utils.sm3Plugins_PloughArea_PostFuncs       = {["0"]="update-plough-area(after)"}
    
    Utils.sm3Plugins_SowingArea_Setup           = {["0"]="update-sowing-area(setup)"}
    Utils.sm3Plugins_SowingArea_PreFuncs        = {["0"]="update-sowing-area(before)"}
    Utils.sm3Plugins_SowingArea_PostFuncs       = {["0"]="update-sowing-area(after)"}
    
    Utils.sm3Plugins_WeederArea_Setup           = {["0"]="update-weeder-area(setup)"}
    Utils.sm3Plugins_WeederArea_PreFuncs        = {["0"]="update-weeder-area(before)"}
    Utils.sm3Plugins_WeederArea_PostFuncs       = {["0"]="update-weeder-area(after)"}

    Utils.sm3Plugins_RollerArea_Setup           = {["0"]="update-roller-area(setup)"}
    Utils.sm3Plugins_RollerArea_PreFuncs        = {["0"]="update-roller-area(before)"}
    Utils.sm3Plugins_RollerArea_PostFuncs       = {["0"]="update-roller-area(after)"}
    
    Utils.sm3Plugins_SprayArea_FillTypeFuncs    = {}
    
    --sm3GrowthControl.pluginsGrowthCycleFruits       = {["0"]="growth-cycle(fruits)"}
    --sm3GrowthControl.pluginsGrowthCycle             = {["0"]="growth-cycle"}
    --sm3GrowthControl.pluginsWeatherCycle            = {["0"]="weather-cycle"}
    
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
    local pluginFuncs = {}
    pluginFuncs.addPlugin_CutFruitArea_setup            = function(description,priority,pluginFunc) return addPlugin(Utils.sm3Plugins_CutFruitArea_Setup        ,description,priority,pluginFunc) end;
    pluginFuncs.addPlugin_CutFruitArea_before           = function(description,priority,pluginFunc) return addPlugin(Utils.sm3Plugins_CutFruitArea_PreFuncs     ,description,priority,pluginFunc) end;
    pluginFuncs.addPlugin_CutFruitArea_after            = function(description,priority,pluginFunc) return addPlugin(Utils.sm3Plugins_CutFruitArea_PostFuncs    ,description,priority,pluginFunc) end;

    pluginFuncs.addPlugin_UpdateCultivatorArea_setup    = function(description,priority,pluginFunc) return addPlugin(Utils.sm3Plugins_CultivatorArea_Setup      ,description,priority,pluginFunc) end;
    pluginFuncs.addPlugin_UpdateCultivatorArea_before   = function(description,priority,pluginFunc) return addPlugin(Utils.sm3Plugins_CultivatorArea_PreFuncs   ,description,priority,pluginFunc) end;
    pluginFuncs.addPlugin_UpdateCultivatorArea_after    = function(description,priority,pluginFunc) return addPlugin(Utils.sm3Plugins_CultivatorArea_PostFuncs  ,description,priority,pluginFunc) end;

    pluginFuncs.addPlugin_UpdatePloughArea_setup        = function(description,priority,pluginFunc) return addPlugin(Utils.sm3Plugins_PloughArea_Setup          ,description,priority,pluginFunc) end;
    pluginFuncs.addPlugin_UpdatePloughArea_before       = function(description,priority,pluginFunc) return addPlugin(Utils.sm3Plugins_PloughArea_PreFuncs       ,description,priority,pluginFunc) end;
    pluginFuncs.addPlugin_UpdatePloughArea_after        = function(description,priority,pluginFunc) return addPlugin(Utils.sm3Plugins_PloughArea_PostFuncs      ,description,priority,pluginFunc) end;
        
    pluginFuncs.addPlugin_UpdateSowingArea_setup        = function(description,priority,pluginFunc) return addPlugin(Utils.sm3Plugins_SowingArea_Setup          ,description,priority,pluginFunc) end;
    pluginFuncs.addPlugin_UpdateSowingArea_before       = function(description,priority,pluginFunc) return addPlugin(Utils.sm3Plugins_SowingArea_PreFuncs       ,description,priority,pluginFunc) end;
    pluginFuncs.addPlugin_UpdateSowingArea_after        = function(description,priority,pluginFunc) return addPlugin(Utils.sm3Plugins_SowingArea_PostFuncs      ,description,priority,pluginFunc) end;
    
    pluginFuncs.addPlugin_UpdateWeederArea_setup        = function(description,priority,pluginFunc) return addPlugin(Utils.sm3Plugins_WeederArea_Setup          ,description,priority,pluginFunc) end;
    pluginFuncs.addPlugin_UpdateWeederArea_before       = function(description,priority,pluginFunc) return addPlugin(Utils.sm3Plugins_WeederArea_PreFuncs       ,description,priority,pluginFunc) end;
    pluginFuncs.addPlugin_UpdateWeederArea_after        = function(description,priority,pluginFunc) return addPlugin(Utils.sm3Plugins_WeederArea_PostFuncs      ,description,priority,pluginFunc) end;
    
    pluginFuncs.addPlugin_UpdateRollerArea_setup        = function(description,priority,pluginFunc) return addPlugin(Utils.sm3Plugins_RollerArea_Setup          ,description,priority,pluginFunc) end;
    pluginFuncs.addPlugin_UpdateRollerArea_before       = function(description,priority,pluginFunc) return addPlugin(Utils.sm3Plugins_RollerArea_PreFuncs       ,description,priority,pluginFunc) end;
    pluginFuncs.addPlugin_UpdateRollerArea_after        = function(description,priority,pluginFunc) return addPlugin(Utils.sm3Plugins_RollerArea_PostFuncs      ,description,priority,pluginFunc) end;
    
    pluginFuncs.addPlugin_UpdateSprayArea_fillType      = function(description,priority,fillType,pluginFunc)
                                                              if fillType == nil or fillType <= 0 then
                                                                  return false;
                                                              end
                                                              if Utils.sm3Plugins_SprayArea_FillTypeFuncs[fillType] == nil then
                                                                  Utils.sm3Plugins_SprayArea_FillTypeFuncs[fillType] = { ["0"]=("update-spray-area(filltype=%d)"):format(fillType) }
                                                              end
                                                              return addPlugin(Utils.sm3Plugins_SprayArea_FillTypeFuncs[fillType], description,priority,pluginFunc)
                                                          end;

    --pluginFuncs.addPlugin_GrowthCycleFruits             = function(description,priority,pluginFunc) return addPlugin(sm3GrowthControl.pluginsGrowthCycleFruits      ,description,priority,pluginFunc) end;
    --pluginFuncs.addPlugin_GrowthCycle                   = function(description,priority,pluginFunc) return addPlugin(sm3GrowthControl.pluginsGrowthCycle            ,description,priority,pluginFunc) end;
    --pluginFuncs.addPlugin_WeatherCycle                  = function(description,priority,pluginFunc) return addPlugin(sm3GrowthControl.pluginsWeatherCycle           ,description,priority,pluginFunc) end;

    --pluginFuncs.addDestructibleFoliageId                = soilmod.addDestructibleFoliageId
    
    -- "We call you"
    local allOK = true
    for _,mod in pairs(getfenv(0)["modSoilModPlugins"]) do
        if mod ~= nil and type(mod)=="table" and mod.soilModPluginCallback ~= nil then
            allOK = mod.soilModPluginCallback(pluginFuncs,soilmod) and allOK
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
    Utils.sm3Plugins_CutFruitArea_Setup       = reorderArray(Utils.sm3Plugins_CutFruitArea_Setup      )
    Utils.sm3Plugins_CutFruitArea_PreFuncs    = reorderArray(Utils.sm3Plugins_CutFruitArea_PreFuncs   )
    Utils.sm3Plugins_CutFruitArea_PostFuncs   = reorderArray(Utils.sm3Plugins_CutFruitArea_PostFuncs  )

    Utils.sm3Plugins_CultivatorArea_Setup     = reorderArray(Utils.sm3Plugins_CultivatorArea_Setup    )
    Utils.sm3Plugins_CultivatorArea_PreFuncs  = reorderArray(Utils.sm3Plugins_CultivatorArea_PreFuncs )
    Utils.sm3Plugins_CultivatorArea_PostFuncs = reorderArray(Utils.sm3Plugins_CultivatorArea_PostFuncs)

    Utils.sm3Plugins_PloughArea_Setup         = reorderArray(Utils.sm3Plugins_PloughArea_Setup        )
    Utils.sm3Plugins_PloughArea_PreFuncs      = reorderArray(Utils.sm3Plugins_PloughArea_PreFuncs     )
    Utils.sm3Plugins_PloughArea_PostFuncs     = reorderArray(Utils.sm3Plugins_PloughArea_PostFuncs    )

    Utils.sm3Plugins_SowingArea_Setup         = reorderArray(Utils.sm3Plugins_SowingArea_Setup        )
    Utils.sm3Plugins_SowingArea_PreFuncs      = reorderArray(Utils.sm3Plugins_SowingArea_PreFuncs     )
    Utils.sm3Plugins_SowingArea_PostFuncs     = reorderArray(Utils.sm3Plugins_SowingArea_PostFuncs    )
    
    Utils.sm3Plugins_WeederArea_Setup         = reorderArray(Utils.sm3Plugins_WeederArea_Setup        )
    Utils.sm3Plugins_WeederArea_PreFuncs      = reorderArray(Utils.sm3Plugins_WeederArea_PreFuncs     )
    Utils.sm3Plugins_WeederArea_PostFuncs     = reorderArray(Utils.sm3Plugins_WeederArea_PostFuncs    )

    Utils.sm3Plugins_RollerArea_Setup         = reorderArray(Utils.sm3Plugins_RollerArea_Setup        )
    Utils.sm3Plugins_RollerArea_PreFuncs      = reorderArray(Utils.sm3Plugins_RollerArea_PreFuncs     )
    Utils.sm3Plugins_RollerArea_PostFuncs     = reorderArray(Utils.sm3Plugins_RollerArea_PostFuncs    )
    
    for k,v in pairs(Utils.sm3Plugins_SprayArea_FillTypeFuncs) do
        Utils.sm3Plugins_SprayArea_FillTypeFuncs[k] = reorderArray(v)
    end
    
    --sm3GrowthControl.pluginsGrowthCycleFruits     = reorderArray(sm3GrowthControl.pluginsGrowthCycleFruits    )
    --sm3GrowthControl.pluginsGrowthCycle           = reorderArray(sm3GrowthControl.pluginsGrowthCycle          )
    --sm3GrowthControl.pluginsWeatherCycle          = reorderArray(sm3GrowthControl.pluginsWeatherCycle         )

    --
    return allOK
end

--
print(("Script loaded: SoilMod.LUA (v%s)"):format(soilmod.version))

--
if soilmod.preSetupFillTypes ~= nil then
    -- Register fill-types, so they are available for "farm-silos" when game's base-script reads the careerSavegame.XML
    soilmod:preSetupFillTypes();
end
