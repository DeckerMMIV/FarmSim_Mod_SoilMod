--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-01-xx
--

sm3GrowthControl = {}

--
-- DID YOU KNOW? - You should NOT change the values here in the LUA script!
--                 Instead do it in your savegame#/careerSavegame.XML file:
--     <modsSettings>
--         <sm3SoilMod>
--             <growth intervalIngameDays="1" startIngameHour="0" intervalDelayWeeds="0" />
--         </sm3SoilMod>
--     </modsSettings>
--
sm3GrowthControl.growthIntervalIngameDays   = 1
sm3GrowthControl.growthStartIngameHour      = 0
sm3GrowthControl.growthIntervalDelayWeeds   = 0
--
sm3GrowthControl.hudFontSize = 0.015
sm3GrowthControl.hudPosX     = 0.5
sm3GrowthControl.hudPosY     = (1 - sm3GrowthControl.hudFontSize * 1.05)
--
sm3GrowthControl.growthActive   = false
sm3GrowthControl.weatherActive  = false
sm3GrowthControl.canActivate    = false
sm3GrowthControl.pctCompleted   = 0
--
sm3GrowthControl.lastDay        = 1 -- environment.currentDay
sm3GrowthControl.lastGrowth     = 0 -- cell
sm3GrowthControl.lastWeed       = 0 -- cell
sm3GrowthControl.lastWeather    = 0 -- cell
sm3GrowthControl.lastMethod     = 0
sm3GrowthControl.gridPow        = 6 -- 2^6 == 64
sm3GrowthControl.updateDelayMs  = math.ceil(60000 / ((2 ^ sm3GrowthControl.gridPow) ^ 2)); -- Minimum delay before next cell update. Consider network-latency/-updates
--
sm3GrowthControl.debugGrowthCycle = 0


-- These are initialized in sm3SoilMod.LUA:
--sm3GrowthControl.pluginsGrowthCycleFruits   = {}
--sm3GrowthControl.pluginsGrowthCycle         = {}
--sm3GrowthControl.pluginsWeatherCycle        = {}

--
sm3GrowthControl.WEATHER_HOT    = 2^0
sm3GrowthControl.WEATHER_RAIN   = 2^1
sm3GrowthControl.WEATHER_HAIL   = 2^2
sm3GrowthControl.WEATHER_SNOW   = 2^3

sm3GrowthControl.weatherInfo    = 0;

--
function sm3GrowthControl.preSetup()
--[[
    -- Set default values
    sm3Settings.setKeyAttrValue("growthControl",    "lastDay",          sm3GrowthControl.lastDay        )
    sm3Settings.setKeyAttrValue("growthControl",    "lastGrowth",       sm3GrowthControl.lastGrowth     )
    sm3Settings.setKeyAttrValue("growthControl",    "lastWeed",         sm3GrowthControl.lastWeed       )
    sm3Settings.setKeyAttrValue("growthControl",    "lastWeather",      sm3GrowthControl.lastWeather    )
    --sm3Settings.setKeyAttrValue("growthControl",    "lastMethod",       sm3GrowthControl.lastMethod     )
    sm3Settings.setKeyAttrValue("growthControl",    "updateDelayMs",    sm3GrowthControl.updateDelayMs  )
    sm3Settings.setKeyAttrValue("growthControl",    "gridPow",          sm3GrowthControl.gridPow        )

    sm3Settings.setKeyAttrValue("growth",   "intervalIngameDays",   sm3GrowthControl.growthIntervalIngameDays   )
    sm3Settings.setKeyAttrValue("growth",   "startIngameHour",      sm3GrowthControl.growthStartIngameHour      )
    sm3Settings.setKeyAttrValue("growth",   "intervalDelayWeeds",   sm3GrowthControl.growthIntervalDelayWeeds   )
--]]    
end

--
function sm3GrowthControl.setup()
    --sm3GrowthControl.detectFruitSprayFillTypeConflicts()

    sm3GrowthControl.setupFoliageGrowthLayers()
    sm3GrowthControl.initialized = false;
end

--
function sm3GrowthControl.postSetup()
--[[
    -- Get custom values
    sm3GrowthControl.lastDay                    = sm3Settings.getKeyAttrValue("growthControl",  "lastDay",       sm3GrowthControl.lastDay        )
    sm3GrowthControl.lastGrowth                 = sm3Settings.getKeyAttrValue("growthControl",  "lastGrowth",    sm3GrowthControl.lastGrowth     )
    sm3GrowthControl.lastWeed                   = sm3Settings.getKeyAttrValue("growthControl",  "lastWeed",      sm3GrowthControl.lastWeed       )
    sm3GrowthControl.lastWeather                = sm3Settings.getKeyAttrValue("growthControl",  "lastWeather",   sm3GrowthControl.lastWeather    )
    --sm3GrowthControl.lastMethod                 = sm3Settings.getKeyAttrValue("growthControl",  "lastMethod",    sm3GrowthControl.lastMethod     )
    sm3GrowthControl.updateDelayMs              = sm3Settings.getKeyAttrValue("growthControl",  "updateBDelayMs", sm3GrowthControl.updateDelayMs  )
    sm3GrowthControl.gridPow                    = sm3Settings.getKeyAttrValue("growthControl",  "gridBPow",      sm3GrowthControl.gridPow        )
    
    sm3GrowthControl.growthIntervalIngameDays   = sm3Settings.getKeyAttrValue("growth",   "intervalIngameDays",   sm3GrowthControl.growthIntervalIngameDays   )
    sm3GrowthControl.growthStartIngameHour      = sm3Settings.getKeyAttrValue("growth",   "startIngameHour",      sm3GrowthControl.growthStartIngameHour      )
    sm3GrowthControl.growthIntervalDelayWeeds   = sm3Settings.getKeyAttrValue("growth",   "intervalDelayWeeds",   sm3GrowthControl.growthIntervalDelayWeeds   )
--]]
    -- Sanitize the values
    sm3GrowthControl.lastDay                    = math.floor(math.max(0, sm3GrowthControl.lastDay ))
    sm3GrowthControl.lastGrowth                 = math.floor(math.max(0, sm3GrowthControl.lastGrowth))
    sm3GrowthControl.lastWeed                   = math.floor(math.max(0, sm3GrowthControl.lastWeed))
    sm3GrowthControl.lastWeather                = math.floor(math.max(0, sm3GrowthControl.lastWeather))
    sm3GrowthControl.updateDelayMs              = Utils.clamp(math.floor(sm3GrowthControl.updateDelayMs), 10, 60000)
    sm3GrowthControl.gridPow                    = Utils.clamp(math.floor(sm3GrowthControl.gridPow), 4, 8)
    sm3GrowthControl.growthIntervalIngameDays   = Utils.clamp(math.floor(sm3GrowthControl.growthIntervalIngameDays), 1, 99)
    sm3GrowthControl.growthStartIngameHour      = Utils.clamp(math.floor(sm3GrowthControl.growthStartIngameHour), 0, 23)
    sm3GrowthControl.growthIntervalDelayWeeds   = math.floor(sm3GrowthControl.growthIntervalDelayWeeds)
    
    -- Pre-calculate
    sm3GrowthControl.gridCells   = math.pow(2, sm3GrowthControl.gridPow)
    sm3GrowthControl.terrainSize = math.floor(g_currentMission.terrainSize / sm3GrowthControl.gridCells) * sm3GrowthControl.gridCells;
    sm3GrowthControl.gridCellWH  = math.floor(sm3GrowthControl.terrainSize / sm3GrowthControl.gridCells);
    
    --
    local fruitsFoliageLayerSize = getDensityMapSize(g_currentMission.fruits[1].id)
    local foliageAspectRatio = sm3GrowthControl.terrainSize / fruitsFoliageLayerSize
    sm3GrowthControl.gridCellWH_adjust = math.min(0.75, foliageAspectRatio)
    
    --
    sm3GrowthControl.growthActive   = sm3GrowthControl.lastGrowth  > 0
    sm3GrowthControl.weatherActive  = sm3GrowthControl.lastWeather > 0

    if sm3GrowthControl.weatherActive then
        sm3GrowthControl:weatherActivation()
    end
    
    --
    log("fruitsFoliageLayerSize=",fruitsFoliageLayerSize)
    log("g_currentMission.terrainSize=",g_currentMission.terrainSize)
    log("sm3GrowthControl.terrainSize=",sm3GrowthControl.terrainSize)
    log("sm3GrowthControl.gridCellWH_adjust=",sm3GrowthControl.gridCellWH_adjust)
    log("sm3GrowthControl.postSetup()",
        ",growthIntervalIngameDays=" ,sm3GrowthControl.growthIntervalIngameDays,
        ",growthStartIngameHour="    ,sm3GrowthControl.growthStartIngameHour   ,
        ",growthIntervalDelayWeeds=" ,sm3GrowthControl.growthIntervalDelayWeeds,
        ",lastDay="      ,sm3GrowthControl.lastDay      ,
        ",lastGrowth="   ,sm3GrowthControl.lastGrowth   ,
        ",lastWeed="     ,sm3GrowthControl.lastWeed     ,
        ",lastWeather="  ,sm3GrowthControl.lastWeather  ,
        ",lastMethod="   ,sm3GrowthControl.lastMethod   ,
        ",updateDelayMs=",sm3GrowthControl.updateDelayMs,
        ",gridPow="      ,sm3GrowthControl.gridPow      ,
        ",gridCells="    ,sm3GrowthControl.gridCells    ,
        ",gridCellWH="   ,sm3GrowthControl.gridCellWH
    )
end

--
--function sm3GrowthControl.detectFruitSprayFillTypeConflicts()
----[[
--    Fill-type can all be transported
--
--    Fruit-type is also a fill-type
--    Spray-type is also a fill-type
--
--    Fruit-type should ONLY be used for crop foliage-layers, that can be seeded and harvested!
--    - Unfortunately some mods register new fruit-types, which basically should ONLY have been a fill-type!
----]]
--
--    -- Issue warnings if a fruit-type has no usable foliage-layer ids
--    for fruitType,fruitDesc in pairs(FruitUtil.fruitIndexToDesc) do
--        local fruitLayer = g_currentMission.fruits[fruitType]
--        if fruitLayer == nil or fruitLayer == 0 then
--            if fruitType == Fillable.FILLTYPE_CHAFF then
--                -- Ignore, as FILLTYPE_CHAFF is one from the base scripts.
--            else
--                logInfo("WARNING. Fruit-type '"..tostring(fruitDesc.name).."' has no usable foliage-layer. If this type is still needed, consider registering '"..tostring(fruitDesc.name).."' only as a Fill-type or Spray-type!")
--            end
--        end
--    end
--end

--
function sm3GrowthControl.setupFoliageGrowthLayers()
    log("sm3GrowthControl.setupFoliageGrowthLayers()")

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
    
    g_currentMission.sm3FoliageGrowthLayers = {}
    local grleFileSubLayers = {}
    for i = 1, FruitUtil.NUM_FRUITTYPES do
        local fruitDesc = FruitUtil.fruitIndexToDesc[i]
        local fruitLayer = g_currentMission.fruits[fruitDesc.index];
        if fruitLayer ~= nil and fruitLayer.id ~= 0 and fruitDesc.minHarvestingGrowthState >= 0 then
            local grleFileName = getDensityMapFileName(fruitLayer.id)
        
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
                    ,",windrowId=",      fruitLayer.windrowId,          "/", (fruitLayer.windrowId          ~=0 and getTerrainDetailNumChannels(fruitLayer.windrowId        ) or -1)
                    ,",preparingId=",    fruitLayer.preparingOutputId,  "/", (fruitLayer.preparingOutputId  ~=0 and getTerrainDetailNumChannels(fruitLayer.preparingOutputId) or -1)
                    ,",size=",           getDensityMapSize(fruitLayer.id)
                    ,",grleFile=",       grleFileName
                )

                logInfo("WARNING! Fruit '",fruitDesc.name,"' seems to be very wrongly set-up. SoilMod will attempt to ignore this fruit!")
                logInfo("WARNING! Fruit '",fruitDesc.name,"' has registerFruitType() problems; ",errMsgs)
            else
                -- Disable growth as this mod will take control of it!
                setEnableGrowth(fruitLayer.id, false);
                --
                local entry = {
                    fruitDescIndex  = fruitDesc.index,
                    fruitId         = fruitLayer.id,
                    windrowId       = fruitLayer.windrowId,
                    preparingId     = fruitLayer.preparingOutputId,
                    minSeededValue  = 1,
                    minMatureValue  = (fruitDesc.minPreparingGrowthState>=0 and fruitDesc.minPreparingGrowthState or fruitDesc.minHarvestingGrowthState) + 1,
                    maxMatureValue  = (fruitDesc.maxPreparingGrowthState>=0 and fruitDesc.maxPreparingGrowthState or fruitDesc.maxHarvestingGrowthState) + 1,
                    cuttedValue     = fruitDesc.cutState + 1,
                    witheredValue   = nil,
                }
        
                -- Needs preparing?
                if fruitDesc.maxPreparingGrowthState >= 0 then
                    -- ...and can be withered?
                    if fruitDesc.minPreparingGrowthState < fruitDesc.maxPreparingGrowthState then -- Assumption that if there are multiple stages for preparing, then it can be withered too.
                        entry.witheredValue = entry.maxMatureValue + 1  -- Assumption that 'withering' is just after max-harvesting.
                    end
                else
                    -- Can be withered?
                    if fruitDesc.cutState > fruitDesc.maxHarvestingGrowthState then -- Assumption that if 'cutState' is after max-harvesting, then fruit can be withered.
                        entry.witheredValue = entry.maxMatureValue + 1  -- Assumption that 'withering' is just after max-harvesting.
                    end
                end
        
                grleFileSubLayers[grleFileName] = Utils.getNoNil(grleFileSubLayers[grleFileName],0) + 1
                
                logInfo("Fruit foliage-layer: '",fruitDesc.name,"'"
                    ,", fruitNum=",      i
                    ,",id=",             entry.fruitId,      "/", (entry.fruitId    ~=0 and getTerrainDetailNumChannels(entry.fruitId      ) or -1)
                    ,",windrowId=",      entry.windrowId,    "/", (entry.windrowId  ~=0 and getTerrainDetailNumChannels(entry.windrowId    ) or -1)
                    ,",preparingId=",    entry.preparingId,  "/", (entry.preparingId~=0 and getTerrainDetailNumChannels(entry.preparingId  ) or -1)
                    ,",minSeededValue=", entry.minSeededValue
                    ,",minMatureValue=", entry.minMatureValue
                    ,",maxMatureValue=", entry.maxMatureValue
                    ,",witheredValue=",  entry.witheredValue
                    ,",cuttedValue=",    entry.cuttedValue
                    ,",size=",           getDensityMapSize(entry.fruitId)
                    --,",parent=",         getParent(entry.fruitId)
                    ,",grleFile=",       grleFileName
                )
        
                table.insert(g_currentMission.sm3FoliageGrowthLayers, entry);
            end
        end
    end
end

function sm3GrowthControl:update(dt)
    if g_currentMission:getIsServer() then

        if not sm3GrowthControl.initialized then
            sm3GrowthControl.initialized = true;

            sm3GrowthControl.nextUpdateTime = g_currentMission.time + 0
            sm3GrowthControl.nextSentTime   = g_currentMission.time + 0
            
            --g_currentMission.environment:addDayChangeListener(self);
            --log("sm3GrowthControl:update() - addDayChangeListener called")
            
            g_currentMission.environment:addHourChangeListener(self);
            log("sm3GrowthControl:update() - addHourChangeListener called")
        
            if g_currentMission.sm3FoliageWeed ~= nil and sm3GrowthControl.growthIntervalDelayWeeds >= 0 then
                g_currentMission.environment:addMinuteChangeListener(self);
                log("sm3GrowthControl:update() - addMinuteChangeListener called")
            end
        end

        if g_currentMission.missionInfo.plantGrowthRate ~= 1 then
            log("Forcing plant-growth-rate set to 1 (off)")
            g_currentMission.missionInfo.plantGrowthRate = 1
            g_currentMission:setPlantGrowthRate(1)  -- off!
        end

--[[DEBUG
        if InputBinding.hasEvent(InputBinding.SOILMOD_PLACEWEED) then
            sm3GrowthControl.placeWeedHere(self)
        end
--DEBUG]]
        --
        if sm3GrowthControl.weedPropagation and g_currentMission.sm3FoliageWeed ~= nil then
            sm3GrowthControl.weedPropagation = false
            --
            sm3GrowthControl.lastWeed = (sm3GrowthControl.lastWeed + 1) % (sm3GrowthControl.gridCells * sm3GrowthControl.gridCells);
            -- Multiply with a prime-number to get some dispersion
            sm3GrowthControl.updateWeedFoliage(self, (sm3GrowthControl.lastWeed * 271) % (sm3GrowthControl.gridCells * sm3GrowthControl.gridCells))
            
            sm3Settings.setKeyAttrValue("growthControl", "lastWeed", sm3GrowthControl.lastWeed)
        end

        --
        if sm3GrowthControl.growthActive then
            if g_currentMission.time > sm3GrowthControl.nextUpdateTime then
                sm3GrowthControl.nextUpdateTime = g_currentMission.time + sm3GrowthControl.updateDelayMs;
                --
                local totalCells   = (sm3GrowthControl.gridCells * sm3GrowthControl.gridCells)
                local pctCompleted = ((totalCells - sm3GrowthControl.lastGrowth) / totalCells) + 0.01 -- Add 1% to get clients to render "Growth: %"
                local cellToUpdate = sm3GrowthControl.lastGrowth
        
                -- TODO - implement different methods (i.e. patterns) so the cells will not be updated in the same straight pattern every time.
                --if sm3GrowthControl.lastMethod == 0 then
                    -- North-West to South-East
                    cellToUpdate = totalCells - cellToUpdate
                --elseif sm3GrowthControl.lastMethod == 1 then
                --    -- South-East to North-West
                --    cellToUpdate = cellToUpdate - 1
                --end
        
                sm3GrowthControl.updateFoliageCell(self, cellToUpdate, 0, sm3GrowthControl.lastDay, pctCompleted)
                --
                sm3GrowthControl.lastGrowth = sm3GrowthControl.lastGrowth - 1
                if sm3GrowthControl.lastGrowth <= 0 then
                    sm3GrowthControl.growthActive = false;
                    sm3GrowthControl.endedFoliageCell(self, sm3GrowthControl.lastDay)
                    log("sm3GrowthControl - Growth: Finished. For day:",sm3GrowthControl.lastDay)
                end
                --
                sm3Settings.setKeyAttrValue("growthControl", "lastDay",    sm3GrowthControl.lastDay     )
                sm3Settings.setKeyAttrValue("growthControl", "lastGrowth", sm3GrowthControl.lastGrowth  )
                --sm3Settings.setKeyAttrValue("growthControl", "lastMethod", sm3GrowthControl.lastMethod  )
            end
        elseif sm3GrowthControl.weatherActive then
            if g_currentMission.time > sm3GrowthControl.nextUpdateTime then
                sm3GrowthControl.nextUpdateTime = g_currentMission.time + sm3GrowthControl.updateDelayMs;
                --
                local totalCells   = (sm3GrowthControl.gridCells * sm3GrowthControl.gridCells)
                local pctCompleted = ((totalCells - sm3GrowthControl.lastWeather) / totalCells) + 0.01 -- Add 1% to get clients to render "%"
                local cellToUpdate = (sm3GrowthControl.lastWeather * 271) % (sm3GrowthControl.gridCells * sm3GrowthControl.gridCells)
        
                sm3GrowthControl.updateFoliageCell(self, cellToUpdate, sm3GrowthControl.weatherInfo, sm3GrowthControl.lastDay, pctCompleted)
                --
                sm3GrowthControl.lastWeather = sm3GrowthControl.lastWeather - 1
                if sm3GrowthControl.lastWeather <= 0 then
                    sm3GrowthControl.weatherActive = false;
                    sm3GrowthControl.weatherInfo = 0;
                    sm3GrowthControl.endedFoliageCell(self, sm3GrowthControl.lastDay)
                    log("sm3GrowthControl - Weather: Finished.")
                end
                --
                sm3Settings.setKeyAttrValue("growthControl", "lastWeather", sm3GrowthControl.lastWeather  )
            end
        else
            if sm3GrowthControl.actionGrowNow or sm3GrowthControl.canActivate then
                -- For some odd reason, the game's base-scripts are not increasing currentDay the first time after midnight.
                local fixDay = 0
                if sm3GrowthControl.canActivate then
                    if (sm3GrowthControl.lastDay + sm3GrowthControl.growthIntervalIngameDays) > g_currentMission.environment.currentDay then
                        fixDay = 1
                    end
                end
                --
                sm3GrowthControl.actionGrowNow = false
                sm3GrowthControl.actionGrowNowTimeout = nil
                sm3GrowthControl.canActivate = false
                sm3GrowthControl.lastDay  = g_currentMission.environment.currentDay + fixDay;
                sm3GrowthControl.lastGrowth = (sm3GrowthControl.gridCells * sm3GrowthControl.gridCells);
                sm3GrowthControl.nextUpdateTime = g_currentMission.time + 0
                sm3GrowthControl.pctCompleted = 0
                sm3GrowthControl.growthActive = true;
                --
                if ModsSettings ~= nil then
                    sm3GrowthControl.debugGrowthCycle = ModsSettings.getIntLocal("sm3SoilMod", "internals", "debugGrowthCycle", sm3GrowthControl.debugGrowthCycle);
                end
                --
                logInfo("Growth-cycle started. For day/hour:",sm3GrowthControl.lastDay ,"/",g_currentMission.environment.currentHour)
            elseif sm3GrowthControl.canActivateWeather and sm3GrowthControl.weatherInfo > 0 then
                sm3GrowthControl.canActivateWeather = false
                sm3GrowthControl.lastWeather = (sm3GrowthControl.gridCells * sm3GrowthControl.gridCells);
                sm3GrowthControl.nextUpdateTime = g_currentMission.time + 0
                sm3GrowthControl.pctCompleted = 0
                sm3GrowthControl.weatherActive = true;
                logInfo("Weather-effect started. Type=",sm3GrowthControl.weatherInfo,", day/hour:",sm3GrowthControl.lastWeather,"/",g_currentMission.environment.currentHour)
            elseif InputBinding.isPressed(InputBinding.SOILMOD_GROWNOW) then
                if sm3GrowthControl.actionGrowNowTimeout == nil then
                    sm3GrowthControl.actionGrowNowTimeout = g_currentMission.time + 2000
                elseif g_currentMission.time > sm3GrowthControl.actionGrowNowTimeout then
                    sm3GrowthControl.actionGrowNow = true
                    sm3GrowthControl.actionGrowNowTimeout = g_currentMission.time + 24*60*60*1000
                end
            elseif g_currentMission.time > sm3GrowthControl.nextSentTime then
                sm3GrowthControl.nextSentTime = g_currentMission.time + 60*1000 -- once a minute
                --StatusProperties.sendEvent();
            end
        end
    end
end;

--
function sm3GrowthControl:minuteChanged()
    sm3GrowthControl.weedCounter = Utils.getNoNil(sm3GrowthControl.weedCounter,0) + 1
    -- Set speed of weed propagation relative to how often 'growth cycle' occurs and a weed-delay.
    if (0 == (sm3GrowthControl.weedCounter % (sm3GrowthControl.growthIntervalDelayWeeds + sm3GrowthControl.growthIntervalIngameDays))) then
        sm3GrowthControl.weedPropagation = true
    end
end

--
function sm3GrowthControl:hourChanged()
    --log("sm3GrowthControl:hourChanged() ",g_currentMission.environment.currentDay,"/",g_currentMission.environment.currentHour)

    if sm3GrowthControl.growthActive or sm3GrowthControl.weatherActive then
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
        " - Next growth-activation day/hour: ", (sm3GrowthControl.lastDay + sm3GrowthControl.growthIntervalIngameDays),"/",sm3GrowthControl.growthStartIngameHour
    )

    local currentDayHour = currentDay * 24 + g_currentMission.environment.currentHour;
    local nextDayHour    = (sm3GrowthControl.lastDay + sm3GrowthControl.growthIntervalIngameDays) * 24 + sm3GrowthControl.growthStartIngameHour;

    if currentDayHour >= nextDayHour then
        sm3GrowthControl.canActivate = true
    else
        sm3GrowthControl:weatherActivation()
        if sm3GrowthControl.weatherInfo > 0 then
            sm3GrowthControl.canActivateWeather = true
        end
    end
end

function sm3GrowthControl:dayChanged()
    --log("sm3GrowthControl:dayChanged() ",g_currentMission.environment.currentDay,"/",g_currentMission.environment.currentHour)
end

function sm3GrowthControl:weatherActivation()
    if g_currentMission.environment.currentRain ~= nil then
        if g_currentMission.environment.currentRain.rainTypeId == Environment.RAINTYPE_RAIN then
            sm3GrowthControl.weatherInfo = sm3GrowthControl.WEATHER_RAIN;
        --elseif g_currentMission.environment.currentRain.rainTypeId == Environment.RAINTYPE_HAIL then
        --    sm3GrowthControl.weatherInfo = sm3GrowthControl.WEATHER_HAIL;
        end
    elseif g_currentMission.environment.currentHour == 12 then
        if g_currentMission.environment.weatherTemperaturesDay[1] > 22 then
            sm3GrowthControl.weatherInfo = sm3GrowthControl.WEATHER_HOT;
        end
    end
end


--  DEBUG
function sm3GrowthControl:placeWeedHere()
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
        sm3GrowthControl.createWeedFoliage(self, x,z,radius,weedType)
    end
end
--DEBUG]]

--
function sm3GrowthControl:updateWeedFoliage(cellSquareToUpdate)
  local weedPlaced = 0
  local tries = 5
  local x = math.floor(sm3GrowthControl.gridCellWH * math.floor(cellSquareToUpdate % sm3GrowthControl.gridCells))
  local z = math.floor(sm3GrowthControl.gridCellWH * math.floor(cellSquareToUpdate / sm3GrowthControl.gridCells))
  local sx,sz = (x-(sm3GrowthControl.terrainSize/2)),(z-(sm3GrowthControl.terrainSize/2))

  -- Repeat until a spot was found (weed seeded) or maximum-tries reached.
  local weedType = math.floor((math.random()*2) % 2)
  local xOff,zOff
  repeat
    xOff = sm3GrowthControl.gridCellWH * math.random()
    zOff = sm3GrowthControl.gridCellWH * math.random()
    local r = 1 + 3 * math.random()
    -- Place 4 "patches" of weed.
    for i=0,3 do
        weedPlaced = weedPlaced + sm3GrowthControl.createWeedFoliage(self, math.ceil(sx + xOff), math.ceil(sz + zOff), math.ceil(r), weedType)
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

--[[DEBUG  
  if weedPlaced > 0 then
    log("Weed placed: ",sx,"/",sz,", type=",weedType)
  else
    log("Weed attempted at: ",sx,"/",sz)
  end
--DEBUG]]  
end

--
function sm3GrowthControl:createWeedFoliage(centerX,centerZ,radius,weedType, noEventSend)
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
 
    local includeMask   = 2^g_currentMission.sowingChannel
                        + 2^g_currentMission.sowingWidthChannel
                        + 2^g_currentMission.cultivatorChannel
                        + 2^g_currentMission.ploughChannel;
    local value = 4 + 8*(weedType==1 and 1 or 0)

    setDensityCompareParams(g_currentMission.sm3FoliageWeed, "equal", 0)
    setDensityMaskParams(g_currentMission.sm3FoliageWeed, "greater", -1,-1, includeMask, 0)
    local pixelsMatch = 0
    for _,p in pairs(parallelograms) do
        --log("weed place ", p.sx,"/",p.sz, ",", p.wx,"/",p.wz, ",", p.hx,"/",p.hz)
        local _, pixMatch, _ = setDensityMaskedParallelogram(
            g_currentMission.sm3FoliageWeed,
            p.sx,p.sz, p.wx,p.wz, p.hx,p.hz,
            0, 4,
            g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, -- mask
            value
        )
        -- However if there's germination prevention, then no weed!
        setDensityMaskParams(g_currentMission.sm3FoliageWeed, "greater", 0)
        setDensityCompareParams(g_currentMission.sm3FoliageWeed, "equals", value)
        setDensityMaskedParallelogram(
            g_currentMission.sm3FoliageWeed,
            p.sx,p.sz, p.wx,p.wz, p.hx,p.hz,
            0, 4,
            g_currentMission.sm3FoliageHerbicideTime, 0, 2, -- mask
            0
        )
        --
        pixelsMatch = pixelsMatch + pixMatch
        if pixelsMatch <= 0 then
            break
        end
    end
    setDensityMaskParams(g_currentMission.sm3FoliageWeed, "greater", -1)
    setDensityCompareParams(g_currentMission.sm3FoliageWeed, "greater", -1)

    --
    if pixelsMatch > 0 then
        CreateWeedEvent.sendEvent(centerX,centerZ,radius,weedType,noEventSend)
    end

    return pixelsMatch
end

--
function sm3GrowthControl:updateFoliageCell(cellToUpdate, weatherInfo, day, pctCompleted, noEventSend)
    local x = math.floor(sm3GrowthControl.gridCellWH * math.floor(cellToUpdate % sm3GrowthControl.gridCells))
    local z = math.floor(sm3GrowthControl.gridCellWH * math.floor(cellToUpdate / sm3GrowthControl.gridCells))
    local sx,sz = (x-(sm3GrowthControl.terrainSize/2)),(z-(sm3GrowthControl.terrainSize/2))

    sm3GrowthControl:updateFoliageCellXZWH(sx,sz, sm3GrowthControl.gridCellWH, weatherInfo, day, pctCompleted, noEventSend)
end

function sm3GrowthControl:endedFoliageCell(day, noEventSend)
    sm3GrowthControl:updateFoliageCellXZWH(0,0, 0, 0, day, 0, noEventSend)
end

function sm3GrowthControl:updateFoliageCellXZWH(x,z, wh, weatherInfo, day, pctCompleted, noEventSend)
    sm3GrowthControl.pctCompleted = pctCompleted
    sm3GrowthControlEvent.sendEvent(x,z, wh, weatherInfo, day, pctCompleted, noEventSend)

    -- Test for "magic number" indicating finished.
    if wh <= 0 then
        return
    end

    local sx,sz,wx,wz,hx,hz = x,z,  wh - sm3GrowthControl.gridCellWH_adjust,0,  0,wh - sm3GrowthControl.gridCellWH_adjust

    --
    if sm3GrowthControl.debugGrowthCycle>0 then
        logInfo(string.format("%5.2f", pctCompleted*100),"% x/z/wh(",x,":",z,":",wh,") rect(",sx,":",sz," / ",wx,":",wz," / ",hx,":",hz,")")
    end
    --
    
    if weatherInfo <= 0 then
        -- For each fruit foliage-layer
        for _,fruitEntry in pairs(g_currentMission.sm3FoliageGrowthLayers) do
            for _,callFunc in pairs(sm3GrowthControl.pluginsGrowthCycleFruits) do
                callFunc(sx,sz,wx,wz,hx,hz,day,fruitEntry)
            end
        end
    
        -- For other foliage-layers
        for _,callFunc in pairs(sm3GrowthControl.pluginsGrowthCycle) do
            callFunc(sx,sz,wx,wz,hx,hz,day)
        end
    else
        for _,callFunc in pairs(sm3GrowthControl.pluginsWeatherCycle) do
            callFunc(sx,sz,wx,wz,hx,hz,weatherInfo,day)
        end
    end
end

--
function sm3GrowthControl:renderTextShaded(x,y,fontsize,txt,foreColor,backColor)
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
function sm3GrowthControl:draw()
    if g_gui.currentGui == nil  then
        if sm3GrowthControl.pctCompleted > 0.00 then
            local txt = (g_i18n:getText("Pct")):format(sm3GrowthControl.pctCompleted * 100)
            setTextAlignment(RenderText.ALIGN_RIGHT);
            setTextBold(false);
            self:renderTextShaded(0.999, sm3GrowthControl.hudPosY, sm3GrowthControl.hudFontSize, txt, {1,1,1,0.8}, {0,0,0,0.8})
            setTextAlignment(RenderText.ALIGN_LEFT);
            setTextColor(1,1,1,1)
        else
            -- Code for showing days countdown to growth cycle.
            -- TODO - Won't work for multiplayer clients
            local daysBeforeGrowthCycle = (sm3GrowthControl.lastDay + sm3GrowthControl.growthIntervalIngameDays) - g_currentMission.environment.currentDay
            setTextAlignment(RenderText.ALIGN_RIGHT);
            setTextBold(false);
            self:renderTextShaded(0.999, sm3GrowthControl.hudPosY, sm3GrowthControl.hudFontSize, tostring(daysBeforeGrowthCycle), {1,1,1,0.8}, {0,0,0,0.8})
            setTextAlignment(RenderText.ALIGN_LEFT);
            setTextColor(1,1,1,1)
        end
    end
end;

-------
-------
-------

sm3GrowthControlEvent = {};
sm3GrowthControlEvent_mt = Class(sm3GrowthControlEvent, Event);

InitEventClass(sm3GrowthControlEvent, "GrowthControlEvent");

function sm3GrowthControlEvent:emptyNew()
    local self = Event:new(sm3GrowthControlEvent_mt);
    self.className="sm3GrowthControlEvent";
    return self;
end;

function sm3GrowthControlEvent:new(x,z, wh, weatherInfo, day, pctCompleted)
    local self = sm3GrowthControlEvent:emptyNew()
    self.x = x
    self.z = z
    self.wh = wh
    self.weatherInfo = weatherInfo
    self.day = day
    self.pctCompleted = pctCompleted
    return self;
end;

function sm3GrowthControlEvent:readStream(streamId, connection)
    local pctCompleted  = streamReadUInt8(streamId) / 100
    local weatherInfo   = streamReadUInt8(streamId)
    local x             = streamReadInt16(streamId)
    local z             = streamReadInt16(streamId)
    local wh            = streamReadInt16(streamId)
    local day           = streamReadInt16(streamId)
    sm3GrowthControl.updateFoliageCellXZWH(sm3GrowthControl, x,z, wh, weatherInfo, day, pctCompleted, true);
end;

function sm3GrowthControlEvent:writeStream(streamId, connection)
    streamWriteUInt8(streamId, math.floor(self.pctCompleted * 100))
    streamWriteUInt8(streamId, self.weatherInfo)
    streamWriteInt16(streamId, self.x)
    streamWriteInt16(streamId, self.z)
    streamWriteInt16(streamId, self.wh)
    streamWriteInt16(streamId, self.day) -- Might cause a problem at the 32768th day. (signed short)
end;

function sm3GrowthControlEvent.sendEvent(x,z, wh, weatherInfo, day, pctCompleted, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(sm3GrowthControlEvent:new(x,z, wh, weatherInfo, day, pctCompleted), nil, nil, nil);
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
    sm3GrowthControl:createWeedFoliage(centerX,centerZ,radius,weedType, true)
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
    sm3GrowthControl.growthIntervalIngameDays = streamReadUInt8( streamId)
    sm3GrowthControl.growthStartIngameHour    = streamReadUInt8( streamId)
    sm3GrowthControl.growthIntervalDelayWeeds = streamReadUInt8( streamId)
    sm3GrowthControl.lastDay                  = streamReadUInt16(streamId)
end;

function StatusProperties:writeStream(streamId, connection)
    streamWriteUInt8( streamId, sm3GrowthControl.growthIntervalIngameDays)
    streamWriteUInt8( streamId, sm3GrowthControl.growthStartIngameHour   )
    streamWriteUInt8( streamId, sm3GrowthControl.growthIntervalDelayWeeds)
    streamWriteUInt16(streamId, sm3GrowthControl.lastDay                 )
end;

function StatusProperties.sendEvent(noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(StatusProperties:new(), nil, nil, nil);
        end;
    end;
end;
