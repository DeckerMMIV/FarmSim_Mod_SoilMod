--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-03-xx
--

--
-- DID YOU KNOW? - You should NOT change the values here in the LUA script!
--                 Instead do it in your savegame#/careerSavegame.XML file:
--     <modsSettings>
--         <sm3SoilMod>
--             <growth intervalIngameDays="1" startIngameHour="0" intervalDelayWeeds="0" />
--         </sm3SoilMod>
--     </modsSettings>
--
soilmod.growthIntervalIngameDays   = 1
soilmod.growthStartIngameHour      = 0
soilmod.growthIntervalDelayWeeds   = 0
--
soilmod.hudFontSize = 0.015
soilmod.hudPosX     = 0.5
soilmod.hudPosY     = (1 - soilmod.hudFontSize * 1.05)
--
soilmod.growthActive   = false
soilmod.weatherActive  = false
soilmod.canActivate    = false
soilmod.pctCompleted   = 0
--
soilmod.lastDay        = 1 -- environment.currentDay
soilmod.lastGrowth     = 0 -- cell
soilmod.lastWeed       = 0 -- cell
soilmod.lastWeather    = 0 -- cell
soilmod.lastMethod     = 0
soilmod.gridPow        = 6 -- 2^6 == 64
soilmod.updateDelayMs  = math.ceil(60000 / ((2 ^ soilmod.gridPow) ^ 2)); -- Minimum delay before next cell update. Consider network-latency/-updates
soilmod.updateDelayMs  = 0
--
soilmod.debugGrowthCycle = 1

--
soilmod.WEATHER_HOT    = 2^0
soilmod.WEATHER_RAIN   = 2^1
soilmod.WEATHER_HAIL   = 2^2
soilmod.WEATHER_SNOW   = 2^3

soilmod.weatherInfo    = 0;

--
function soilmod:setupGrowthControl(mapSelf)
    self.terrainTasks = Utils.getNoNil(self.terrainTasks, {})
    self.queuedTasks  = Utils.getNoNil(self.queuedTasks, {})

    if g_currentMission:getIsServer() then    
        addConsoleCommand("modSoilModQueueEffect", "", "consoleCommandSoilModQueueEffect", soilmod)
    end

    local configFiles = {
        { "SoilMod"                             , self.modDir           .. "SoilMod3_Config.xml" },
        { "modDesc.SoilMod"                     , mapSelf.baseDirectory .. "modDesc.xml" },
      --{ "careerSavegame.modsSettings.SoilMod" ,  .. "/careerSavegame.xml"  },
    }
    
    self.cropAspects = {}
    self.cropAspects["defaults"] = {}
    for _,cfg in pairs(configFiles) do
        local cfgFile = cfg[2]
        if fileExists(cfgFile) then
            local xmlFile = loadXMLFile("soilmod3", cfgFile)
            self:readConfigFile(xmlFile, cfg[1], cfgFile)
            delete(xmlFile)
        end
    end

    self:printCropAspects()
    
    self:setupFoliageGrowthLayers()
    self:setupGrowthPlugins()
    self.initializedGrowthControl = false;
    
    return true
end

--
function soilmod:postSetupGrowthControl()
    -- Sanitize the values
    soilmod.lastDay                    = math.floor(math.max(0, soilmod.lastDay ))
    soilmod.lastGrowth                 = math.floor(math.max(0, soilmod.lastGrowth))
    soilmod.lastWeed                   = math.floor(math.max(0, soilmod.lastWeed))
    soilmod.lastWeather                = math.floor(math.max(0, soilmod.lastWeather))
    soilmod.updateDelayMs              = Utils.clamp(math.floor(soilmod.updateDelayMs), 10, 100)
    soilmod.gridPow                    = Utils.clamp(math.floor(soilmod.gridPow), 4, 8)
    soilmod.growthIntervalIngameDays   = Utils.clamp(math.floor(soilmod.growthIntervalIngameDays), 1, 99)
    soilmod.growthStartIngameHour      = Utils.clamp(math.floor(soilmod.growthStartIngameHour), 0, 23)
    soilmod.growthIntervalDelayWeeds   = math.floor(soilmod.growthIntervalDelayWeeds)
    
    -- Pre-calculate
    soilmod.gridCells   = math.pow(2, soilmod.gridPow)
    soilmod.terrainSize = math.floor(g_currentMission.terrainSize / soilmod.gridCells) * soilmod.gridCells;
    soilmod.gridCellWH  = math.floor(soilmod.terrainSize / soilmod.gridCells);
    
    --
    local fruitsFoliageLayerSize = getDensityMapSize(g_currentMission.fruits[1].id)
    local foliageAspectRatio = soilmod.terrainSize / fruitsFoliageLayerSize
    soilmod.gridCellWH_adjust = math.min(0.75, foliageAspectRatio)
    
    --
    soilmod.growthActive   = soilmod.lastGrowth  > 0
    soilmod.weatherActive  = soilmod.lastWeather > 0

    if soilmod.weatherActive then
        soilmod:weatherActivation()
    end
    
    --
    log("fruitsFoliageLayerSize=",fruitsFoliageLayerSize)
    log("g_currentMission.terrainSize=",g_currentMission.terrainSize)
    log("soilmod.terrainSize=",soilmod.terrainSize)
    log("soilmod.gridCellWH_adjust=",soilmod.gridCellWH_adjust)
    log("soilmod.postSetup()",
        ",growthIntervalIngameDays=" ,soilmod.growthIntervalIngameDays,
        ",growthStartIngameHour="    ,soilmod.growthStartIngameHour   ,
        ",growthIntervalDelayWeeds=" ,soilmod.growthIntervalDelayWeeds,
        ",lastDay="      ,soilmod.lastDay      ,
        ",lastGrowth="   ,soilmod.lastGrowth   ,
        ",lastWeed="     ,soilmod.lastWeed     ,
        ",lastWeather="  ,soilmod.lastWeather  ,
        ",lastMethod="   ,soilmod.lastMethod   ,
        ",updateDelayMs=",soilmod.updateDelayMs,
        ",gridPow="      ,soilmod.gridPow      ,
        ",gridCells="    ,soilmod.gridCells    ,
        ",gridCellWH="   ,soilmod.gridCellWH
    )
end

function soilmod:readConfigFile(xmlFile, rootKey, filename)
    if not hasXMLProperty(xmlFile, rootKey .. ".cropAspects") then
        return
    end
    logInfo("Loading crop-aspects from ", filename)

    local function stringToValuesVector(txt)
        local result = nil
        if txt ~= nil then
            result = {}
            for _,elem in pairs(Utils.splitString(" ", txt)) do
                elem = Utils.trim(elem)
                if elem ~= "" then
                    local subParts = Utils.splitString(":", elem)
                    if #subParts == 2 then
                        table.insert(result, { tonumber(subParts[1]), tonumber(subParts[2]) } )
                    else
                        table.insert(result, tonumber(elem) )
                    end
                end
            end
        end
        return result
    end

    local function readCropAspect(xmlFile, rootKey, defaults)
        local cropAspect = {}
        
        local key = rootKey .. ".growthStateIncrement"
        cropAspect.growthIncrementIngameDays = Utils.getNoNil(getXMLInt(xmlFile, key .. "#ingameDays") ,defaults.growthIncrementIngameDays)
        cropAspect.growthIncrementHourOffset = Utils.getNoNil(getXMLInt(xmlFile, key .. "#hourOffset") ,defaults.growthIncrementHourOffset)
        cropAspect.growthIncrementSeedDelay  = Utils.getNoNil(getXMLInt(xmlFile, key .. "#seedDelay")  ,defaults.growthIncrementSeedDelay )
        
        key = rootKey..".healthEffects"
        cropAspect.healthEffectLime         = Utils.getNoNil(getXMLInt(xmlFile, key .. "#lime")   ,defaults.healthEffectLime  )
        cropAspect.healthEffectManure       = Utils.getNoNil(getXMLInt(xmlFile, key .. "#manure") ,defaults.healthEffectManure)
        cropAspect.healthEffectSlurry       = Utils.getNoNil(getXMLInt(xmlFile, key .. "#slurry") ,defaults.healthEffectSlurry)
        cropAspect.healthEffectHerbicide    = Utils.getNoNil(Utils.getVectorNFromString(getXMLString(xmlFile, key .. "#herbicide")  ,3) ,defaults.healthEffectHerbicide )
        cropAspect.healthEffectFertilizer   = Utils.getNoNil(Utils.getVectorNFromString(getXMLString(xmlFile, key .. "#fertilizer") ,7) ,defaults.healthEffectFertilizer)
        
        key = rootKey..".growthConsumeStates"
        cropAspect.growthConsumeNutrientN   = Utils.getNoNil(stringToValuesVector(getXMLString(xmlFile, key .. "#nutrientN" )) ,defaults.growthConsumeNutrientN )
        cropAspect.growthConsumeNutrientPK  = Utils.getNoNil(stringToValuesVector(getXMLString(xmlFile, key .. "#nutrientPK")) ,defaults.growthConsumeNutrientPK)
        cropAspect.growthConsumeMoisture    = Utils.getNoNil(stringToValuesVector(getXMLString(xmlFile, key .. "#moisture"  )) ,defaults.growthConsumeMoisture  )
        cropAspect.growthConsumeSoilpH      = Utils.getNoNil(stringToValuesVector(getXMLString(xmlFile, key .. "#soilpH"    )) ,defaults.growthConsumeSoilpH    )

        key = rootKey..".growthGoodValues"
        cropAspect.growthGoodNutrientN      = Utils.getNoNil(stringToValuesVector(getXMLString(xmlFile, key .. "#nutrientN" )) ,defaults.growthGoodNutrientN    )
        cropAspect.growthGoodNutrientPK     = Utils.getNoNil(stringToValuesVector(getXMLString(xmlFile, key .. "#nutrientPK")) ,defaults.growthGoodNutrientPK   )
        cropAspect.growthGoodMoisture       = Utils.getNoNil(stringToValuesVector(getXMLString(xmlFile, key .. "#moisture"  )) ,defaults.growthGoodMoisture     )
        cropAspect.growthGoodSoilpH         = Utils.getNoNil(stringToValuesVector(getXMLString(xmlFile, key .. "#soilpH"    )) ,defaults.growthGoodSoilpH       )

        key = rootKey..".growthBadValues"
        cropAspect.growthBadNutrientN       = Utils.getNoNil(stringToValuesVector(getXMLString(xmlFile, key .. "#nutrientN" )) ,defaults.growthBadNutrientN     )
        cropAspect.growthBadNutrientPK      = Utils.getNoNil(stringToValuesVector(getXMLString(xmlFile, key .. "#nutrientPK")) ,defaults.growthBadNutrientPK    )
        cropAspect.growthBadMoisture        = Utils.getNoNil(stringToValuesVector(getXMLString(xmlFile, key .. "#moisture"  )) ,defaults.growthBadMoisture      )
        cropAspect.growthBadSoilpH          = Utils.getNoNil(stringToValuesVector(getXMLString(xmlFile, key .. "#soilpH"    )) ,defaults.growthBadSoilpH        )
        
        return cropAspect
    end

    --
    local key = rootKey .. ".cropAspects"
    self.cropAspects["defaults"] = readCropAspect(xmlFile, key .. ".cropDefaults", self.cropAspects["defaults"])

    local i = 0
    while true do
        local subKey = key .. (".crop(%d)"):format(i)
        i=i+1
        if not hasXMLProperty(xmlFile, subKey) then
            break
        end
        local aspects = readCropAspect(xmlFile, subKey, self.cropAspects["defaults"])
        local fruitNames = getXMLString(xmlFile, subKey .. "#fruitNames")
        for _,name in pairs(Utils.splitString(" ", fruitNames)) do
            if FruitUtil.fruitTypes[name] == nil then
                logInfo("WARNING: Fruit-name '",name,"' is not valid. XML-key-path; ",subKey)
            else
                self.cropAspects[name] = aspects
            end
        end
    end
    
end

function soilmod:printCropAspects()
    local function vectorToString(vec)
        local txt = ""
        for _,elem in pairs(vec) do
            if txt ~= "" then
                txt = txt .. " "
            end
            if type(elem) == "table" then
                txt = txt .. tostring(elem[1])..":"..tostring(elem[2])
            else
                txt = txt .. tostring(elem)
            end
        end
        return txt
    end
    
    local function cropAspectsToString(fruitName, cropAspect)
        local txt = (" %s:"):format(fruitName)
        txt = txt .. ("\n  growthStateIncrement; ingameDays='%d' hourOffset='%d' seedDelay='%d'"):format(
            cropAspect.growthIncrementIngameDays,
            cropAspect.growthIncrementHourOffset,
            cropAspect.growthIncrementSeedDelay 
        )
        txt = txt .. ("\n  healthEffects; lime='%d' manure='%d' slurry='%d' herbicide='%s' fertilizer='%s'"):format(
            cropAspect.healthEffectLime,      
            cropAspect.healthEffectManure,    
            cropAspect.healthEffectSlurry,    
            vectorToString(cropAspect.healthEffectHerbicide), 
            vectorToString(cropAspect.healthEffectFertilizer)
        )
        txt = txt .. ("\n  growthConsumeStates; nutrientN='%s' nutrientPK='%s' moisture='%s' soilpH='%s'"):format(
            vectorToString(cropAspect.growthConsumeNutrientN ),
            vectorToString(cropAspect.growthConsumeNutrientPK),
            vectorToString(cropAspect.growthConsumeMoisture  ),
            vectorToString(cropAspect.growthConsumeSoilpH    )
        )
        txt = txt .. ("\n  growthGoodValues; nutrientN='%s' nutrientPK='%s' moisture='%s' soilpH='%s'"):format(
            vectorToString(cropAspect.growthGoodNutrientN ),
            vectorToString(cropAspect.growthGoodNutrientPK),
            vectorToString(cropAspect.growthGoodMoisture  ),
            vectorToString(cropAspect.growthGoodSoilpH    )
        )
        txt = txt .. ("\n  growthBadValues; nutrientN='%s' nutrientPK='%s' moisture='%s' soilpH='%s'"):format(
            vectorToString(cropAspect.growthBadNutrientN ),
            vectorToString(cropAspect.growthBadNutrientPK),
            vectorToString(cropAspect.growthBadMoisture  ),
            vectorToString(cropAspect.growthBadSoilpH    )
        )
        return txt
    end

    logInfo("== Crop Aspects ==")
    print(cropAspectsToString("(defaults)", self.cropAspects["defaults"]))
    for name,aspect in pairs(self.cropAspects) do
        if name ~= "defaults" then
            print(cropAspectsToString(name, aspect))
        end
    end
    logInfo("== Aspects end ==")
end


--
function soilmod:setupFoliageGrowthLayers()
    log("soilmod.setupFoliageGrowthLayers()")

    local function checkBounds(txt, value, min, max, valueName)
        local msg = (txt == nil) and "" or txt..", "
        if type(value) ~= type(123) then
            txt = msg .. "'" .. valueName .. "'("..tostring(value)..") is not a number"
        elseif value < min then
            txt = msg .. "'" .. valueName .. "'("..tostring(value)..") is lower than possible minimum(" .. min .. ")"
        elseif value > max then
            txt = msg .. "'" .. valueName .. "'("..tostring(value)..") is higher than possible maximum(" .. max .. ")"
        end
        return txt
    end
    
    soilmod.foliageGrowthLayers = {}
    local densityFileSubLayers = {}
    for i = 1, FruitUtil.NUM_FRUITTYPES do
        local fruitDesc = FruitUtil.fruitIndexToDesc[i]
        local fruitLayer = g_currentMission.fruits[fruitDesc.index];
        if fruitLayer ~= nil and fruitLayer.id ~= 0 and fruitDesc.minHarvestingGrowthState >= 0 then
            local densityFilename = getDensityMapFilename(fruitLayer.id)
        
            -- Sanity check of the fruitDesc, as apparently some map-authors completely mess up calls to
            -- registerFruitType() with very invalid/corrupted values compared to the fruit's foliage-layer.
            local numChannels = getTerrainDetailNumChannels(fruitLayer.id)
            local maxValueForLayer = math.pow(2,numChannels)-1

            local errMsgs = nil
            errMsgs = checkBounds(errMsgs, fruitDesc.minHarvestingGrowthState, 0, maxValueForLayer-1, "minHarvestingGrowthState")
            errMsgs = checkBounds(errMsgs, fruitDesc.maxHarvestingGrowthState, 0, maxValueForLayer-1, "maxHarvestingGrowthState")
            errMsgs = checkBounds(errMsgs, fruitDesc.minPreparingGrowthState, -1, maxValueForLayer-1, "minPreparingGrowthState") 
            errMsgs = checkBounds(errMsgs, fruitDesc.maxPreparingGrowthState, -1, maxValueForLayer-1, "maxPreparingGrowthState") 
            errMsgs = checkBounds(errMsgs, fruitDesc.cutState,                 0, maxValueForLayer-1, "cutState")                
            errMsgs = checkBounds(errMsgs, fruitDesc.preparedGrowthState,     -1, maxValueForLayer-1, "preparedGrowthState")     

            if errMsgs ~= nil then
                -- Some error has been detected with this "fruit"
                logInfo("Fruit foliage-layer: '",fruitDesc.name,"'"
                    ,", fruitNum=",      i
                    ,",id=",             fruitLayer.id,                 "/", (fruitLayer.id                 ~=0 and getTerrainDetailNumChannels(fruitLayer.id               ) or -1)
                    ,",preparingId=",    fruitLayer.preparingOutputId,  "/", (fruitLayer.preparingOutputId  ~=0 and getTerrainDetailNumChannels(fruitLayer.preparingOutputId) or -1)
                    ,",size=",           getDensityMapSize(fruitLayer.id)
                    ,",densityFile=",    densityFilename
                )

                logInfo("WARNING! Fruit '",fruitDesc.name,"' seems to be very wrongly set-up. SoilMod will attempt to ignore this fruit!")
                logInfo("WARNING! Fruit '",fruitDesc.name,"' has registerFruitType() problems; ",errMsgs)
            else
                local entry = {
                    fruitName       = fruitDesc.name,
                    fruitDescIndex  = fruitDesc.index,
                    fruitId         = fruitLayer.id,
                    preparingId     = fruitLayer.preparingOutputId,
                    minSeededValue  = 1,
                    minMatureValue  = (fruitDesc.minPreparingGrowthState>=0 and fruitDesc.minPreparingGrowthState or fruitDesc.minHarvestingGrowthState) + 1,
                    maxMatureValue  = (fruitDesc.maxPreparingGrowthState>=0 and fruitDesc.maxPreparingGrowthState or fruitDesc.maxHarvestingGrowthState) + 1,
                    cuttedValue     = fruitDesc.cutState + 1,
                    defoliagedValue = (fruitDesc.preparedGrowthState>=0 and (fruitDesc.preparedGrowthState + 1) or nil),
                    witheredValue   = nil,
                    --
                    layer    = { layerId=fruitLayer.id, channelOffset=0, numChannels=4, layerName=fruitDesc.name, foliageName=fruitDesc.name, },
                    getLayer = function(self) return self.layer; end,
                    --
                    get =   function(self, key, defaultValue)
                                if self[key] ~= nil then
                                    return self[key]
                                elseif defaultValue ~= nil then
                                    return defaultValue;
                                end
                                log("ERROR: '",self.fruitName,"' fruitEntry.get(",key,") invalid value")
                            end,
                    getAspect = function(self)
                                    local aspect = soilmod.cropAspects[self.fruitName]
                                    if aspect == nil then
                                        aspect = soilmod.cropAspects["defaults"]
                                    end
                                    return aspect
                                end,
                }
                
                -- Needs preparing?
                if fruitDesc.maxPreparingGrowthState >= 0 then
                    -- ...and can be withered?
                    if fruitDesc.minPreparingGrowthState < fruitDesc.maxPreparingGrowthState -- Assumption that if there are multiple stages for preparing, then it can be withered too.
                    and fruitDesc.cutState ~= 1 + fruitDesc.maxPreparingGrowthState -- ... unless cutState is _directly_ after max-preparing, so there is no room for a 'withered' value
                    then
                        entry.witheredValue = entry.maxMatureValue + 1  -- Assumption that 'withering' is just after max-harvesting.
                    end
                else
                    -- Can be withered?
                    if  fruitDesc.cutState > fruitDesc.maxHarvestingGrowthState -- Assumption that if 'cutState' is after max-harvesting, then fruit can be withered.
                    and fruitDesc.cutState ~= 1 + fruitDesc.maxHarvestingGrowthState -- ... unless cutState is _directly_ after max-harvesting, so there is no room for a 'withered' value
                    then
                        entry.witheredValue = entry.maxMatureValue + 1  -- Assumption that 'withering' is just after max-harvesting.
                    end
                end
        
                --
                entry.growing_minValue  = entry.minSeededValue
                entry.growing_maxValue  = Utils.getNoNil(entry.witheredValue, entry.maxMatureValue) - 1
                entry.mature_minValue   = entry.minMatureValue
                entry.mature_maxValue   = entry.maxMatureValue
                
                --entry.manure_healthDiff     = -6
                --entry.lime_healthDiff       = -14
                --entry.herbicide_healthDiff  = -8
                --entry.herbicide_avoidance   = {1,2,3}
                
                entry.groundTypeChange  = (fruitDesc.index == FruitUtil.FRUITTYPE_GRASS and FruitUtil.GROUND_TYPE_GRASS or nil)

                -- Fix for oilseedRadish
                if fruitDesc.index == FruitUtil.FRUITTYPE_OILSEEDRADISH then
                    entry.growing_maxValue = 1
                end
                
                --
                densityFileSubLayers[densityFilename] = Utils.getNoNil(densityFileSubLayers[densityFilename],0) + 1
                
                logInfo("Fruit foliage-layer: '",fruitDesc.name,"'/'",soilmod:i18nText(fruitDesc.name),"'"
                    ,", fruitNum=",      i
                    ,",layerId=",        entry.fruitId,      "/", (entry.fruitId    ~=0 and getTerrainDetailNumChannels(entry.fruitId      ) or -1)
                    ,",preparingId=",    entry.preparingId,  "/", (entry.preparingId~=0 and getTerrainDetailNumChannels(entry.preparingId  ) or -1)
                    ,",minSeeded=",      entry.minSeededValue
                    ,",minMature=",      entry.minMatureValue
                    ,",maxMature=",      entry.maxMatureValue
                    ,",defoliaged=",     entry.defoliagedValue
                    ,",withered=",       entry.witheredValue
                    ,",cutted=",         entry.cuttedValue
                    ,",size=",           getDensityMapSize(entry.fruitId)
                    ,",densityFile=",    densityFilename
                )
        
                table.insert(soilmod.foliageGrowthLayers, entry);
            end
        end
    end
    
    -- Disable growth, as SoilMod takes care of it
    log("Trying to disable vanilla plant-growth, by setting 'fieldCropsAllowGrowing' to false")
    g_currentMission.fieldCropsAllowGrowing = false
    g_currentMission:updateFoliageGrowthStateTime()
end

function soilmod:consoleCommandSoilModQueueEffect(arg1, arg2)
    if not arg1 then
        print("modSoilModQueueEffect <terrainTask-name/part> [<gridType (1-8)>]")
        
        print("  Available terrainTask-names:")
        local txt = ""
        for name,_ in pairs(self.terrainTasks) do
            txt = txt .. name .. ", "
            if #txt > 100 then
                print("    "..txt)
                txt=""
            end
        end
        if txt ~= "" then
            print("    "..txt)
        end

        return
    end
    for taskName,_ in pairs(self.terrainTasks) do
        if nil ~= taskName:lower():find(arg1) then
            self:queueTerrainTask(taskName, tonumber(arg2))
        end
    end
end

function soilmod:updateGrowthControl(dt)
    --if not g_currentMission:getIsServer() then
    --    return
    --end

    if not self.initializedGrowthControl then
        self.initializedGrowthControl = true;

        self.nextUpdateTime = g_currentMission.time + 0
        self.nextSentTime   = g_currentMission.time + 0
        
        --g_currentMission.environment:addDayChangeListener(self);
        --log("soilmod:update() - addDayChangeListener called")
        
        g_currentMission.environment:addHourChangeListener(self);
        log("soilmod:update() - addHourChangeListener called")
    
        g_currentMission.environment:addMinuteChangeListener(self);
        log("soilmod:update() - addMinuteChangeListener called")
    end

    if g_currentMission.missionInfo.plantGrowthRate ~= 1 then
        logInfo("Forcing plant-growth-rate set to 1 (off)")
        g_currentMission:setPlantGrowthRate(1)  -- off!
    end
    if g_currentMission.plantGrowthRateIsLocked ~= true then
        logInfo("Forcing plant-growth-rate to be locked")
        g_currentMission:setPlantGrowthRateLocked(true)
    end

    --
    if self.weedPropagation then
        self.weedPropagation = false
        --
        self.lastWeed = (self.lastWeed + 1) % (self.gridCells * self.gridCells);
        -- Multiply with a prime-number to get some dispersion
        self:updateWeedFoliage((self.lastWeed * 271) % (self.gridCells * self.gridCells))
        
        self:setKeyAttrValue("growthControl", "lastWeed", self.lastWeed)
    end

    --
    self:processQueuedTerrainTask()

    --
    if InputBinding.isPressed(InputBinding.SOILMOD_GROWNOW) then
        if self.actionGrowNowTimeout == nil then
            self.actionGrowNowTimeout = g_currentMission.time + 2000
        elseif self.actionGrowNowTimeout < 0 then
            self.actionGrowNowTimeout = self.actionGrowNowTimeout + dt
        elseif g_currentMission.time > self.actionGrowNowTimeout then
            self.actionGrowNowTimeout = -5000 -- cooldown 5 seconds
            self:queueTerrainTask("soilEffect", nil)
        end
    elseif self.actionGrowNowTimeout ~= nil then
        self.actionGrowNowTimeout = self.actionGrowNowTimeout + dt
        if self.actionGrowNowTimeout >= 0 then
            self.actionGrowNowTimeout = nil
        end
    end
--[[DEBUG
    if InputBinding.hasEvent(InputBinding.SOILMOD_PLACEWEED) then
        self:placeWeedHere()
    end
--DEBUG]]
end;

function soilmod:registerTerrainTask(taskName, taskObj, taskFunc, taskParam, taskFinishFunc, baseGridType)
    if taskName == nil or taskName == ""
    or taskObj == nil
    or taskFunc == nil or type(taskFunc) ~= type(soilmod.registerTerrainTask)
    or (taskFinishFunc ~= nil and type(taskFinishFunc) ~= type(soilmod.registerTerrainTask))
    then
        log("ERROR: Wrong arguments given to registerTerrainTask(), or target-object not correct! TaskName: ",taskName)
        return
    end

    self.terrainTasks = Utils.getNoNil(self.terrainTasks, {})
    self.terrainTasks[taskName] = {
        name    = taskName,         -- string
        obj     = taskObj,          -- table
        func    = taskFunc,         -- function
        finish  = taskFinishFunc,   -- function
        param   = taskParam,        -- <anything>
        gridType= baseGridType,     --
    }
    log("Registered terrain-task: ",taskName)
end

function soilmod:queueTerrainTask(taskName, gridType)
    if self.terrainTasks[taskName] == nil then
        log("ERROR: No terrain-task with name '",taskName,"' have been registered. Unable to queue task!")
        return
    end

    self:appendTerrainTask(taskName, gridType, 0, nil)
end

function soilmod:appendTerrainTask(taskName, gridType, currentGridCell, currentCellStep)
    local terrainTask = self.terrainTasks[taskName]
    if terrainTask == nil then
        log("ERROR: No terrain-task with name '",taskName,"' have been registered. Unable to append task!")
        return
    end
    
    self.queuedTasks = Utils.getNoNil(self.queuedTasks, {})
    table.insert(self.queuedTasks,
        {
            name            = taskName,
            gridType        = Utils.clamp(Utils.getNoNil(gridType, Utils.getNoNil(terrainTask.gridType, 5)), 1, 8),
            currentGridCell = currentGridCell,
            currentCellStep = currentCellStep,
        }
    )
    log("Terrain-task queued: ",taskName)
end

function soilmod:removeTerrainTask(idx)
    table.remove(self.queuedTasks, idx)
end

function soilmod:processQueuedTerrainTask()
    local idx = 1
    local currentTask = self.queuedTasks[idx]
    if currentTask == nil then
        self.pctCompleted = 0
        return
    end
    
    local taskDesc = self.terrainTasks[currentTask.name]
    if taskDesc == nil then
        logInfo("ERROR: Tried to process a queued terrain-task '",currentTask.name,"' which have not been registered!")
        self:removeTerrainTask(idx)
        return
    end

    -- Calculate the terrain-square, corresponding to current-grid-cell and the given grid-type
    local gridCells   = 2 ^ currentTask.gridType -- grid-type 1,2,3,4,5,6,7,8 to grid-cells 1,2,4,8,16,32,64,128
    local terrainSize = math.floor(g_currentMission.terrainSize / gridCells) * gridCells; -- Get a nice power-of-two value
    local cellSize    = math.floor(terrainSize / gridCells); -- Size of a terrain-square

    -- .. take into consideration the different sizes of fruit-density-map vs. terrain-map, so square overlapping should not occur
    local foliageAspectRatio = terrainSize / getDensityMapSize(g_currentMission.fruits[1].id)
    local cellSizeWH_adjust  = math.min(0.75, foliageAspectRatio) + 0.01
    local terrainSizeHalf = math.floor(terrainSize/2)
    
    local col,row = math.floor(currentTask.currentGridCell / gridCells), math.floor(currentTask.currentGridCell % gridCells)
    local x,z     = col * cellSize - terrainSizeHalf, row * cellSize - terrainSizeHalf
    
    -- tpCoords
    local terrainParallelogramCoords = {
        x,z,  
        cellSize - cellSizeWH_adjust,0,     -- adjust width to prevent overlapping
        0,cellSize - cellSizeWH_adjust,     -- adjust height to prevent overlapping
    }
    
    local isFinished
    isFinished, currentTask.currentCellStep = taskDesc.func(taskDesc.obj, terrainParallelogramCoords, currentTask.currentCellStep, taskDesc.param)
    
    --
    if isFinished then
        currentTask.currentGridCell = currentTask.currentGridCell + 1
        local totalGridCells = gridCells*gridCells
        if currentTask.currentGridCell >= totalGridCells then
            log("Terrain-task completed: ",currentTask.name)
            if taskDesc.finish ~= nil then
                taskDesc.finish(taskDesc.obj, taskDesc.param)
            end
            self:removeTerrainTask(idx)
        else
            self.pctCompleted = math.floor(currentTask.currentGridCell * 100 / totalGridCells)
        end
    end
end

--[[
function soilmod:terrainTask_Growth(tpc, cellStep, param)
    -- Is initial step for this terrain-cell?
    if cellStep == nil then
        -- Examine if there even is any field(s) here
        local sumPixels, numPixels, totalPixels = soilmod.getDensity(tpc, soilmod.layerTerrain, soilmod.densityGreater(0))
        if numPixels <= 0 then
            -- Finished, because nothing to do.
            return true, nil
        end
        cellStep = 0
    end
    
    -- More steps required
    return false, cellStep + 1
end
--]]

--
function soilmod:minuteChanged()
    soilmod.weedCounter = Utils.getNoNil(soilmod.weedCounter,0) + 1
    -- Set speed of weed propagation relative to how often 'growth cycle' occurs and a weed-delay.
    if (0 == (soilmod.weedCounter % (soilmod.growthIntervalDelayWeeds + soilmod.growthIntervalIngameDays))) then
        soilmod.weedPropagation = true
    end
end

--
function soilmod:hourChanged()
    log("soilmod:hourChanged() ",g_currentMission.environment.currentDay,"/",g_currentMission.environment.currentHour)

    if soilmod.growthActive or soilmod.weatherActive then
        -- If already active, then do nothing.
        return
    end

    -- Apparently 'currentDay' is NOT incremented _before_ calling the hourChanged() callbacks
    -- This should fix the "midnight problem".
    local currentDay = g_currentMission.environment.currentDay
    if g_currentMission.environment.currentHour == 0 then
        currentDay = currentDay + 1 
    end

    --
    log("Current in-game day/hour: ", currentDay, "/", g_currentMission.environment.currentHour,
        " - Next growth-activation day/hour: ", (soilmod.lastDay + soilmod.growthIntervalIngameDays),"/",soilmod.growthStartIngameHour
    )

    local currentDayHour = currentDay * 24 + g_currentMission.environment.currentHour;
    local nextDayHour    = (soilmod.lastDay + soilmod.growthIntervalIngameDays) * 24 + soilmod.growthStartIngameHour;

    if currentDayHour >= nextDayHour then
        soilmod.canActivate = true
    else
        soilmod:weatherActivation()
        if soilmod.weatherInfo > 0 then
            soilmod.canActivateWeather = true
        end
    end
end

function soilmod:dayChanged()
    log("soilmod:dayChanged() ",g_currentMission.environment.currentDay,"/",g_currentMission.environment.currentHour)
end

function soilmod:weatherActivation()
    if g_currentMission.environment.currentRain ~= nil then
        if g_currentMission.environment.currentRain.rainTypeId == Environment.RAINTYPE_RAIN then
            soilmod.weatherInfo = soilmod.WEATHER_RAIN;
        --elseif g_currentMission.environment.currentRain.rainTypeId == Environment.RAINTYPE_HAIL then
        --    soilmod.weatherInfo = soilmod.WEATHER_HAIL;
        end
    elseif g_currentMission.environment.currentHour == 12 then
        if g_currentMission.environment.weatherTemperaturesDay[1] > 22 then
            soilmod.weatherInfo = soilmod.WEATHER_HOT;
        end
    end
end


--  DEBUG
function soilmod:placeWeedHere()
    local x,y,z
    if g_currentMission.controlPlayer and g_currentMission.player ~= nil then
        x,y,z = getWorldTranslation(g_currentMission.player.rootNode)
    elseif g_currentMission.controlledVehicle ~= nil then
        x,y,z = getWorldTranslation(g_currentMission.controlledVehicle.rootNode)
    end

    if x ~= nil and x==x and z==z then
        local radius = 1 + 3 * math.random()
        local weedType = math.floor(g_currentMission.time) % 2
        log("Placing weed at ",x,"/",z,", r=",radius,", type=",weedType)
        soilmod:createWeedFoliage(x,z,radius,weedType)
    end
end
--DEBUG]]

--
function soilmod:updateWeedFoliage(cellSquareToUpdate)
    local weedPlaced = 0
    local tries = 5
    local x = math.floor(soilmod.gridCellWH * math.floor(cellSquareToUpdate % soilmod.gridCells))
    local z = math.floor(soilmod.gridCellWH * math.floor(cellSquareToUpdate / soilmod.gridCells))
    local sx,sz = (x-(soilmod.terrainSize/2)),(z-(soilmod.terrainSize/2))

    -- Repeat until a spot was found (weed seeded) or maximum-tries reached.
    local weedType = math.floor((math.random()*2) % 2)
    local xOff,zOff
    repeat
        xOff = soilmod.gridCellWH * math.random()
        zOff = soilmod.gridCellWH * math.random()
        local r = 1 + 3 * math.random()
        -- Place 4 "patches" of weed.
        for i=0,3 do
            weedPlaced = weedPlaced + soilmod:createWeedFoliage(math.ceil(sx + xOff), math.ceil(sz + zOff), math.ceil(r), weedType)
            if weedPlaced <= 0 then
                -- If first "patch" failed (i.e. "not in a field"), then do not bother with the rest.
                break
            end
            -- Pick a new spot that is a bit offset from the previous spot.
            local r2 = 1 + 3 * math.random()
            xOff = xOff + (Utils.sign(math.random()-0.5) * (r + r2) * 0.9)
            zOff = zOff + (Utils.sign(math.random()-0.5) * (r + r2) * 0.9)
            r = r2
        end
        tries = tries - 1
    until weedPlaced > 0 or tries <= 0

--  DEBUG  
    if weedPlaced > 0 then
        log("Weed placed in cell #",cellSquareToUpdate,": ",sx,"/",sz,", type=",weedType)
    else
        log("Weed attempted at cell #",cellSquareToUpdate,": ",sx,"/",sz)
    end
--DEBUG]]  
end

--
function soilmod:createWeedFoliage(centerX,centerZ,radius,weedType, noEventSend)
    local function rotXZ(offX,offZ,x,z,angle)
        x = x * math.cos(angle) - z * math.sin(angle)
        z = x * math.sin(angle) + z * math.cos(angle)
        return offX + x, offZ + z
    end

    -- Attempt making a "lesser square" look
    local width,height = radius*2,radius
    local parallelograms = {}
    for _,angle in pairs({0,30,60}) do
        angle = Utils.degToRad(angle + centerX + centerZ) -- Adding 'centerX+centerZ' in attempt to get some "randomization" of the angle.
        local p = {}
        p.sx,p.sz = rotXZ(centerX,centerZ, -radius,-radius, angle)
        p.wx,p.wz = rotXZ(0,0,             width,0,         angle)
        p.hx,p.hz = rotXZ(0,0,             0,height,        angle)
        table.insert(parallelograms, p)
        --log("weed ", angle, ":", p.sx,"/",p.sz, ",", p.wx,"/",p.wz, ",", p.hx,"/",p.hz)
    end

    local value = 4 + 8*(weedType==1 and 1 or 0)
--  DEBUG    
    value = math.random(1,15)
--]]DEBUG    
    local layerId_Weed          = soilmod:getLayerId("weed")
    local layerId_HerbicideTime = soilmod:getLayerId("herbicideTime")

    setDensityCompareParams(layerId_Weed, "equal", 0)
    setDensityMaskParams(layerId_Weed, "between", g_currentMission.cultivatorValue, g_currentMission.grassValue)

    local pixelsMatch = 0
    for _,p in pairs(parallelograms) do
        --log("weed place ", p.sx,"/",p.sz, ",", p.wx,"/",p.wz, ",", p.hx,"/",p.hz)
        local _, pixMatch, _ = setDensityMaskedParallelogram(
            layerId_Weed,
            p.sx,p.sz, p.wx,p.wz, p.hx,p.hz,
            0,4,
            g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel,g_currentMission.terrainDetailTypeNumChannels, -- mask
            value
        )
        -- However if there's germination prevention, then no weed!
        setDensityCompareParams(layerId_Weed, "equals", value)
        setDensityMaskParams(layerId_Weed, "greater", 0)
        setDensityMaskedParallelogram(
            layerId_Weed,
            p.sx,p.sz, p.wx,p.wz, p.hx,p.hz,
            0,4,
            layerId_HerbicideTime, 0,2, -- mask
            0
        )
        --
        pixelsMatch = pixelsMatch + pixMatch
        if pixelsMatch <= 0 then
            break
        end
    end
    --setDensityMaskParams(layerId_Weed, "greater", -1)
    --setDensityCompareParams(layerId_Weed, "greater", -1)

    ----
    --if pixelsMatch > 0 then
    --    CreateWeedEvent.sendEvent(centerX,centerZ,radius,weedType,noEventSend)
    --end

    return pixelsMatch
end

--[[
function soilmod:updateFoliageCell(cellToUpdate, weatherInfo, day, pctCompleted, noEventSend)
    local x = math.floor(soilmod.gridCellWH * math.floor(cellToUpdate % soilmod.gridCells))
    local z = math.floor(soilmod.gridCellWH * math.floor(cellToUpdate / soilmod.gridCells))
    local sx,sz = (x-(soilmod.terrainSize/2)),(z-(soilmod.terrainSize/2))

    soilmod:updateFoliageCellXZWH(sx,sz, soilmod.gridCellWH, weatherInfo, day, pctCompleted, noEventSend)
end

function soilmod:endedFoliageCell(day, noEventSend)
    soilmod:updateFoliageCellXZWH(0,0, 0, 0, day, 0, noEventSend)
end

function soilmod:updateFoliageCellXZWH(x,z, wh, weatherInfo, day, pctCompleted, noEventSend)
    soilmod.pctCompleted = pctCompleted
    GrowthControlEvent.sendEvent(x,z, wh, weatherInfo, day, pctCompleted, noEventSend)

    -- Test for "magic number" indicating finished.
    if wh <= 0 then
        return
    end

    local sx,sz,wx,wz,hx,hz = x,z,  wh - soilmod.gridCellWH_adjust,0,  0,wh - soilmod.gridCellWH_adjust

    --
    if soilmod.debugGrowthCycle>0 then
        logInfo(string.format("%5.2f", pctCompleted*100),"% x/z/wh(",x,":",z,":",wh,") rect(",sx,":",sz," / ",wx,":",wz," / ",hx,":",hz,")")
    end
    --
    
    if weatherInfo <= 0 then
        -- For each fruit foliage-layer
        for _,fruitEntry in pairs(soilmod.foliageGrowthLayers) do
            for _,callFunc in pairs(soilmod.pluginsGrowthCycleFruits) do
                callFunc(sx,sz,wx,wz,hx,hz,day,fruitEntry)
            end
        end
    
        -- For other foliage-layers
        for _,callFunc in pairs(soilmod.pluginsGrowthCycle) do
            callFunc(sx,sz,wx,wz,hx,hz,day)
        end
    else
        for _,callFunc in pairs(soilmod.pluginsWeatherCycle) do
            callFunc(sx,sz,wx,wz,hx,hz,weatherInfo,day)
        end
    end
end
--]]

--
local function renderTextShaded(x,y,fontsize,txt,foreColor,backColor)
    if backColor ~= nil then
        setTextColor(unpack(backColor));
        renderText(x + (fontsize * 0.075), y - (fontsize * 0.075), fontsize, txt)
    end
    if foreColor ~= nil then
        setTextColor(unpack(foreColor));
    end
    renderText(x, y, fontsize, txt)
end

--
function soilmod:drawGrowthControl()
    if g_gui.currentGui == nil  then
        if self.pctCompleted > 0 then
            local txt = (g_i18n:getText("Pct")):format(self.pctCompleted)
            local numTasks = #self.queuedTasks
            if numTasks > 1 then
                txt = txt .. " (+" .. (numTasks-1) .. ")"
            end
            setTextAlignment(RenderText.ALIGN_RIGHT);
            setTextBold(false);
            renderTextShaded(0.999, self.hudPosY, self.hudFontSize, txt, {1,1,1,0.8}, {0,0,0,0.8})
            setTextAlignment(RenderText.ALIGN_LEFT);
            setTextColor(1,1,1,1)
--[[            
        else
            -- Code for showing days countdown to growth cycle.
            -- TODO - Won't work for multiplayer clients
            local daysBeforeGrowthCycle = (soilmod.lastDay + soilmod.growthIntervalIngameDays) - g_currentMission.environment.currentDay
            setTextAlignment(RenderText.ALIGN_RIGHT);
            setTextBold(false);
            renderTextShaded(0.999, soilmod.hudPosY, soilmod.hudFontSize, tostring(daysBeforeGrowthCycle), {1,1,1,0.8}, {0,0,0,0.8})
            setTextAlignment(RenderText.ALIGN_LEFT);
            setTextColor(1,1,1,1)
--]]            
        end
    end
end;

-------
-------
-------

--[[
GrowthControlEvent = {};
GrowthControlEvent_mt = Class(GrowthControlEvent, Event);

InitEventClass(GrowthControlEvent, "GrowthControlEvent");

function GrowthControlEvent:emptyNew()
    local self = Event:new(GrowthControlEvent_mt);
    self.className="GrowthControlEvent";
    return self;
end;

function GrowthControlEvent:new(x,z, wh, weatherInfo, day, pctCompleted)
    local self = GrowthControlEvent:emptyNew()
    self.x = x
    self.z = z
    self.wh = wh
    self.weatherInfo = weatherInfo
    self.day = day
    self.pctCompleted = pctCompleted
    return self;
end;

function GrowthControlEvent:readStream(streamId, connection)
    local pctCompleted  = streamReadUInt8(streamId) / 100
    local weatherInfo   = streamReadUInt8(streamId)
    local x             = streamReadInt16(streamId)
    local z             = streamReadInt16(streamId)
    local wh            = streamReadInt16(streamId)
    local day           = streamReadInt16(streamId)
    soilmod.updateFoliageCellXZWH(soilmod, x,z, wh, weatherInfo, day, pctCompleted, true);
end;

function GrowthControlEvent:writeStream(streamId, connection)
    streamWriteUInt8(streamId, math.floor(self.pctCompleted * 100))
    streamWriteUInt8(streamId, self.weatherInfo)
    streamWriteInt16(streamId, self.x)
    streamWriteInt16(streamId, self.z)
    streamWriteInt16(streamId, self.wh)
    streamWriteInt16(streamId, self.day) -- Might cause a problem at the 32768th day. (signed short)
end;

function GrowthControlEvent.sendEvent(x,z, wh, weatherInfo, day, pctCompleted, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(GrowthControlEvent:new(x,z, wh, weatherInfo, day, pctCompleted), nil, nil, nil);
        end;
    end;
end;

-------
-------
-------

CreateWeedEvent = {};
CreateWeedEvent_mt = Class(CreateWeedEvent, Event);

InitEventClass(CreateWeedEvent, "CreateWeedEvent");

function CreateWeedEvent:emptyNew()
    local self = Event:new(CreateWeedEvent_mt);
    self.className="CreateWeedEvent";
    return self;
end;

function CreateWeedEvent:new(x,z,r,weedType)
    local self = CreateWeedEvent:emptyNew()
    self.centerX = x
    self.centerZ = z
    self.radius  = r
    self.weedType = weedType
    return self;
end;

function CreateWeedEvent:readStream(streamId, connection)
    local centerX  = streamReadIntN(streamId, 16)
    local centerZ  = streamReadIntN(streamId, 16)
    local radius   = streamReadIntN(streamId, 4)
    local weedType = streamReadIntN(streamId, 1)
    soilmod:createWeedFoliage(centerX,centerZ,radius,weedType, true)
end;

function CreateWeedEvent:writeStream(streamId, connection)
    streamWriteIntN(streamId, self.centerX,  16)
    streamWriteIntN(streamId, self.centerZ,  16)
    streamWriteIntN(streamId, self.radius,   4)
    streamWriteIntN(streamId, self.weedType, 1)
end;

function CreateWeedEvent.sendEvent(x,z,r,weedType,noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(CreateWeedEvent:new(x,z,r,weedType), nil, nil, nil);
        end;
    end;
end;
--]]

-------
-------
-------

StatusProperties = {};
StatusProperties_mt = Class(StatusProperties, Event);

InitEventClass(StatusProperties, "StatusProperties");

function StatusProperties:emptyNew()
    local self = Event:new(StatusProperties_mt);
    self.className="StatusProperties";
    return self;
end;

function StatusProperties:new()
    local self = StatusProperties:emptyNew()
    return self;
end;

function StatusProperties:readStream(streamId, connection)
    soilmod.growthIntervalIngameDays = streamReadUInt8( streamId)
    soilmod.growthStartIngameHour    = streamReadUInt8( streamId)
    soilmod.growthIntervalDelayWeeds = streamReadUInt8( streamId)
    soilmod.lastDay                  = streamReadUInt16(streamId)
end;

function StatusProperties:writeStream(streamId, connection)
    streamWriteUInt8( streamId, soilmod.growthIntervalIngameDays)
    streamWriteUInt8( streamId, soilmod.growthStartIngameHour   )
    streamWriteUInt8( streamId, soilmod.growthIntervalDelayWeeds)
    streamWriteUInt16(streamId, soilmod.lastDay                 )
end;

function StatusProperties.sendEvent(noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(StatusProperties:new(), nil, nil, nil);
        end;
    end;
end;
