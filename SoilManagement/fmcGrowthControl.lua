--
--  The Soil Management and Growth Control Project - version 2 (FS15)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modhoster.com
-- @date    2015-01-xx
--

fmcGrowthControl = {}

--
local modItem = ModsUtil.findModItemByModName(g_currentModName);
fmcGrowthControl.version = (modItem and modItem.version) and modItem.version or "?.?.?";
--

fmcGrowthControl.lastDay        = 0
fmcGrowthControl.lastGrowth     = 0 -- cell
fmcGrowthControl.lastWeed       = 0 -- cell
fmcGrowthControl.lastWeather    = 0 -- cell
fmcGrowthControl.lastMethod     = 0
fmcGrowthControl.updateDelayMs  = math.ceil(1000 / 16); -- '16' = Maximum number of cells that may be updated per second. Consider network-latency/-updates
fmcGrowthControl.gridPow        = 5     -- 2^5 == 32
--
fmcGrowthControl.growthIntervalIngameDays   = 1
fmcGrowthControl.growthStartIngameHour      = 0  -- midnight hour
--
fmcGrowthControl.hudFontSize = 0.015
fmcGrowthControl.hudPosX     = 0.5
fmcGrowthControl.hudPosY     = (1 - fmcGrowthControl.hudFontSize * 1.05)
--
fmcGrowthControl.active         = false
fmcGrowthControl.weatherActive  = false
fmcGrowthControl.canActivate    = false
fmcGrowthControl.pctCompleted   = 0

-- These are initialized in fmcSoilMod.LUA:
--fmcGrowthControl.pluginsGrowthCycleFruits   = {}
--fmcGrowthControl.pluginsGrowthCycle         = {}
--fmcGrowthControl.pluginsWeatherCycle        = {}

--
fmcGrowthControl.WEATHER_HOT    = 2^0
fmcGrowthControl.WEATHER_RAIN   = 2^1
fmcGrowthControl.WEATHER_HAIL   = 2^2

fmcGrowthControl.weatherInfo    = 0;

--
function fmcGrowthControl.preSetup()
    -- Set default values
    fmcSettings.setKeyAttrValue("growthControl",    "lastDay",          fmcGrowthControl.lastDay        )
    fmcSettings.setKeyAttrValue("growthControl",    "lastGrowth",       fmcGrowthControl.lastGrowth     )
    fmcSettings.setKeyAttrValue("growthControl",    "lastWeed",         fmcGrowthControl.lastWeed       )
    fmcSettings.setKeyAttrValue("growthControl",    "lastWeather",      fmcGrowthControl.lastWeather    )
    fmcSettings.setKeyAttrValue("growthControl",    "lastMethod",       fmcGrowthControl.lastMethod     )
    fmcSettings.setKeyAttrValue("growthControl",    "updateDelayMs",    fmcGrowthControl.updateDelayMs  )
    fmcSettings.setKeyAttrValue("growthControl",    "gridPow",          fmcGrowthControl.gridPow        )

    fmcSettings.setKeyAttrValue("growth",   "intervalIngameDays",   fmcGrowthControl.growthIntervalIngameDays   )
    fmcSettings.setKeyAttrValue("growth",   "startIngameHour",      fmcGrowthControl.growthStartIngameHour      )
end

--
function fmcGrowthControl.setup()
    --fmcGrowthControl.detectFruitSprayFillTypeConflicts()

    fmcGrowthControl.setupFoliageGrowthLayers()
    fmcGrowthControl.initialized = false;
end

--
function fmcGrowthControl.postSetup()
    -- Get custom values
    fmcGrowthControl.lastDay                    = fmcSettings.getKeyAttrValue("growthControl",  "lastDay",       fmcGrowthControl.lastDay        )
    fmcGrowthControl.lastGrowth                 = fmcSettings.getKeyAttrValue("growthControl",  "lastGrowth",    fmcGrowthControl.lastGrowth     )
    fmcGrowthControl.lastWeed                   = fmcSettings.getKeyAttrValue("growthControl",  "lastWeed",      fmcGrowthControl.lastWeed       )
    fmcGrowthControl.lastWeather                = fmcSettings.getKeyAttrValue("growthControl",  "lastWeather",   fmcGrowthControl.lastWeather    )
    fmcGrowthControl.lastMethod                 = fmcSettings.getKeyAttrValue("growthControl",  "lastMethod",    fmcGrowthControl.lastMethod     )
    fmcGrowthControl.updateDelayMs              = fmcSettings.getKeyAttrValue("growthControl",  "updateDelayMs", fmcGrowthControl.updateDelayMs  )
    fmcGrowthControl.gridPow                    = fmcSettings.getKeyAttrValue("growthControl",  "gridPow",       fmcGrowthControl.gridPow        )
    
    fmcGrowthControl.growthIntervalIngameDays   = fmcSettings.getKeyAttrValue("growth",   "intervalIngameDays",   fmcGrowthControl.growthIntervalIngameDays   )
    fmcGrowthControl.growthStartIngameHour      = fmcSettings.getKeyAttrValue("growth",   "startIngameHour",      fmcGrowthControl.growthStartIngameHour      )

    -- Sanitize the values
    fmcGrowthControl.lastDay                    = math.floor(math.max(0, fmcGrowthControl.lastDay ))
    fmcGrowthControl.lastGrowth                 = math.floor(math.max(0, fmcGrowthControl.lastGrowth))
    fmcGrowthControl.lastWeed                   = math.floor(math.max(0, fmcGrowthControl.lastWeed))
    fmcGrowthControl.lastWeather                = math.floor(math.max(0, fmcGrowthControl.lastWeather))
    fmcGrowthControl.updateDelayMs              = Utils.clamp(math.floor(fmcGrowthControl.updateDelayMs), 10, 60000)
    fmcGrowthControl.gridPow                    = Utils.clamp(math.floor(fmcGrowthControl.gridPow), 1, 8)
    fmcGrowthControl.growthIntervalIngameDays   = Utils.clamp(math.floor(fmcGrowthControl.growthIntervalIngameDays), 1, 99)
    fmcGrowthControl.growthStartIngameHour      = Utils.clamp(math.floor(fmcGrowthControl.growthStartIngameHour), 0, 23)
    
    -- Pre-calculate
    fmcGrowthControl.gridCells  = math.pow(2, fmcGrowthControl.gridPow)
    fmcGrowthControl.gridCellWH = math.floor(g_currentMission.terrainSize / fmcGrowthControl.gridCells);
    
    --
    fmcGrowthControl.active         = fmcGrowthControl.lastGrowth  > 0
    fmcGrowthControl.weatherActive  = fmcGrowthControl.lastWeather > 0

    if fmcGrowthControl.weatherActive then
        fmcGrowthControl:weatherActivation()
    end
    
    --
    log("g_currentMission.terrainSize=",g_currentMission.terrainSize)
    log("fmcGrowthControl.postSetup()",
        ",growthIntervalIngameDays=" ,fmcGrowthControl.growthIntervalIngameDays,
        ",growthStartIngameHour="    ,fmcGrowthControl.growthStartIngameHour   ,
        ",lastDay="      ,fmcGrowthControl.lastDay      ,
        ",lastGrowth="   ,fmcGrowthControl.lastGrowth   ,
        ",lastWeed="     ,fmcGrowthControl.lastWeed     ,
        ",lastMethod="   ,fmcGrowthControl.lastMethod   ,
        ",updateDelayMs" ,fmcGrowthControl.updateDelayMs,
        ",gridPow="      ,fmcGrowthControl.gridPow      ,
        ",gridCells="    ,fmcGrowthControl.gridCells    ,
        ",gridCellWH="   ,fmcGrowthControl.gridCellWH
    )
end

--
--function fmcGrowthControl.detectFruitSprayFillTypeConflicts()
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
function fmcGrowthControl.setupFoliageGrowthLayers()
    log("fmcGrowthControl.setupFoliageGrowthLayers()")

    g_currentMission.fmcFoliageGrowthLayers = {}
    for i = 1, FruitUtil.NUM_FRUITTYPES do
      local fruitDesc = FruitUtil.fruitIndexToDesc[i]
      local fruitLayer = g_currentMission.fruits[fruitDesc.index];
      if fruitLayer ~= nil and fruitLayer.id ~= 0 and fruitDesc.minHarvestingGrowthState >= 0 then
        -- Disable growth as this mod will take control of it!
        setEnableGrowth(fruitLayer.id, false);
        --
        local entry = {
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

        logInfo("Fruit foliage-layer: '",fruitDesc.name,"'",
            ",fruitNum=",       i,
            ",id=",             entry.fruitId,
            ",windrowId=",      entry.windrowId,
            ",preparingId=",    entry.preparingId,
            ",minSeededValue=", entry.minSeededValue,
            ",minMatureValue=", entry.minMatureValue,
            ",maxMatureValue=", entry.maxMatureValue,
            ",witheredValue=",  entry.witheredValue,
            ",cuttedValue=",    entry.cuttedValue,
            ",numChnls=",       getTerrainDetailNumChannels(entry.fruitId),
            ",size=",           getTerrainSize(entry.fruitId),"/",getDensityMapSize(entry.fruitId),
            ",parent=",         getParent(entry.fruitId)
        )

        table.insert(g_currentMission.fmcFoliageGrowthLayers, entry);
      end
    end
end

function fmcGrowthControl:update(dt)
    if g_currentMission:getIsServer() then

        if not fmcGrowthControl.initialized then
            fmcGrowthControl.initialized = true;

            fmcGrowthControl.nextUpdateTime = g_currentMission.time + 0
            g_currentMission.environment:addHourChangeListener(self);
            log("fmcGrowthControl:update() - addHourChangeListener called")
        
            if g_currentMission.fmcFoliageWeed ~= nil then
                g_currentMission.environment:addMinuteChangeListener(self);
            end
        end

        if g_currentMission.missionInfo.plantGrowthRate ~= 1 then
            log("Forcing plant-growth-rate set to 1 (off)")
            g_currentMission.missionInfo.plantGrowthRate = 1
            g_currentMission:setPlantGrowthRate(1)  -- off!
        end

--  DEBUG
        if InputBinding.hasEvent(InputBinding.SOILMOD_PLACEWEED) then
            fmcGrowthControl.placeWeedHere(self)
        end
--DEBUG]]
        --
        if fmcGrowthControl.weedPropagation and g_currentMission.fmcFoliageWeed ~= nil then
            fmcGrowthControl.weedPropagation = false
            --
            fmcGrowthControl.lastWeed = (fmcGrowthControl.lastWeed + 1) % (fmcGrowthControl.gridCells * fmcGrowthControl.gridCells);
            -- Multiply with a prime-number to get some dispersion
            fmcGrowthControl.updateWeedFoliage(self, (fmcGrowthControl.lastWeed * 271) % (fmcGrowthControl.gridCells * fmcGrowthControl.gridCells))
            
            fmcSettings.setKeyAttrValue("growthControl", "lastWeed", fmcGrowthControl.lastWeed)
        end

        --
        if fmcGrowthControl.active then
            if g_currentMission.time > fmcGrowthControl.nextUpdateTime then
                fmcGrowthControl.nextUpdateTime = g_currentMission.time + fmcGrowthControl.updateDelayMs;
                --
                local totalCells   = (fmcGrowthControl.gridCells * fmcGrowthControl.gridCells)
                local pctCompleted = ((totalCells - fmcGrowthControl.lastGrowth) / totalCells) + 0.01 -- Add 1% to get clients to render "Growth: %"
                local cellToUpdate = fmcGrowthControl.lastGrowth
        
                -- TODO - implement different methods (i.e. patterns) so the cells will not be updated in the same straight pattern every time.
                --if fmcGrowthControl.lastMethod == 0 then
                    -- North-West to South-East
                    cellToUpdate = totalCells - cellToUpdate
                --elseif fmcGrowthControl.lastMethod == 1 then
                --    -- South-East to North-West
                --    cellToUpdate = cellToUpdate - 1
                --end
        
                fmcGrowthControl.updateFoliageCell(self, cellToUpdate, fmcGrowthControl.lastDay, pctCompleted)
                --
                fmcGrowthControl.lastGrowth = fmcGrowthControl.lastGrowth - 1
                if fmcGrowthControl.lastGrowth <= 0 then
                    fmcGrowthControl.active = false;
                    fmcGrowthControl.endedFoliageCell(self, fmcGrowthControl.lastDay)
                    log("fmcGrowthControl - Growth: Finished. For day:",fmcGrowthControl.lastDay)
                end
                --
                fmcSettings.setKeyAttrValue("growthControl", "lastDay",    fmcGrowthControl.lastDay     )
                fmcSettings.setKeyAttrValue("growthControl", "lastGrowth", fmcGrowthControl.lastGrowth  )
                fmcSettings.setKeyAttrValue("growthControl", "lastMethod", fmcGrowthControl.lastMethod  )
            end
        elseif fmcGrowthControl.weatherActive then
            if g_currentMission.time > fmcGrowthControl.nextUpdateTime then
                fmcGrowthControl.nextUpdateTime = g_currentMission.time + fmcGrowthControl.updateDelayMs;
                --
                local totalCells   = (fmcGrowthControl.gridCells * fmcGrowthControl.gridCells)
                local pctCompleted = ((totalCells - fmcGrowthControl.lastWeather) / totalCells) + 0.01 -- Add 1% to get clients to render "%"
                local cellToUpdate = (fmcGrowthControl.lastWeather * 271) % (fmcGrowthControl.gridCells * fmcGrowthControl.gridCells)
        
                fmcGrowthControl.updateFoliageWeatherCell(self, cellToUpdate, fmcGrowthControl.weatherInfo, fmcGrowthControl.lastDay, pctCompleted)
                --
                fmcGrowthControl.lastWeather = fmcGrowthControl.lastWeather - 1
                if fmcGrowthControl.lastWeather <= 0 then
                    fmcGrowthControl.weatherActive = false;
                    fmcGrowthControl.weatherInfo = 0;
                    fmcGrowthControl.endedFoliageCell(self, fmcGrowthControl.lastDay)
                    log("fmcGrowthControl - Weather: Finished.")
                end
                --
                fmcSettings.setKeyAttrValue("growthControl", "lastWeather", fmcGrowthControl.lastWeather  )
            end
        elseif InputBinding.hasEvent(InputBinding.SOILMOD_GROWNOW) or fmcGrowthControl.canActivate then
            fmcGrowthControl.canActivate = false
            fmcGrowthControl.lastDay  = g_currentMission.environment.currentDay;
            fmcGrowthControl.lastGrowth = (fmcGrowthControl.gridCells * fmcGrowthControl.gridCells);
            fmcGrowthControl.nextUpdateTime = g_currentMission.time + 0
            fmcGrowthControl.pctCompleted = 0
            fmcGrowthControl.active = true;
            log("fmcGrowthControl - Growth: Started. For day/hour:",fmcGrowthControl.lastDay ,"/",g_currentMission.environment.currentHour)
        elseif fmcGrowthControl.canActivateWeather and fmcGrowthControl.weatherInfo > 0 then
            fmcGrowthControl.canActivateWeather = false
            fmcGrowthControl.lastWeather = (fmcGrowthControl.gridCells * fmcGrowthControl.gridCells);
            fmcGrowthControl.nextUpdateTime = g_currentMission.time + 0
            fmcGrowthControl.pctCompleted = 0
            fmcGrowthControl.weatherActive = true;
            log("fmcGrowthControl - Weather: Started. Type=",fmcGrowthControl.weatherInfo)
        end
    end
end;

--
function fmcGrowthControl:minuteChanged()
    fmcGrowthControl.weedCounter = Utils.getNoNil(fmcGrowthControl.weedCounter,0) + 1
    -- Set speed of weed propagation relative to how often 'growth cycle' occurs.
    if (0 == (fmcGrowthControl.weedCounter % fmcGrowthControl.growthIntervalIngameDays)) then
        fmcGrowthControl.weedPropagation = true
    end
end

--
function fmcGrowthControl:hourChanged()
    if fmcGrowthControl.active or fmcGrowthControl.weatherActive then
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
        " - Growth-activation day/hour: ", (fmcGrowthControl.lastDay + fmcGrowthControl.growthIntervalIngameDays),"/",fmcGrowthControl.growthStartIngameHour
    )

    local currentDayHour = currentDay * 24 + g_currentMission.environment.currentHour;
    local nextDayHour    = (fmcGrowthControl.lastDay + fmcGrowthControl.growthIntervalIngameDays) * 24 + fmcGrowthControl.growthStartIngameHour;

    if currentDayHour >= nextDayHour then
        fmcGrowthControl.canActivate = true
    else
        fmcGrowthControl:weatherActivation()
        if fmcGrowthControl.weatherInfo > 0 then
            fmcGrowthControl.canActivateWeather = true
        end
    end
end

function fmcGrowthControl:weatherActivation()
    if g_currentMission.environment.currentRain ~= nil then
        if g_currentMission.environment.currentRain.rainTypeId == Environment.RAINTYPE_RAIN then
            fmcGrowthControl.weatherInfo = fmcGrowthControl.WEATHER_RAIN;
        elseif g_currentMission.environment.currentRain.rainTypeId == Environment.RAINTYPE_HAIL then
            fmcGrowthControl.weatherInfo = fmcGrowthControl.WEATHER_HAIL;
        end
    elseif g_currentMission.environment.currentHour == 12 then
        if g_currentMission.environment.weatherTemperaturesDay[1] > 22 then
            fmcGrowthControl.weatherInfo = fmcGrowthControl.WEATHER_HOT;
        end
    end
end


--  DEBUG
function fmcGrowthControl:placeWeedHere()
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
        fmcGrowthControl.createWeedFoliage(self, x,z,radius,weedType)
    end
end
--DEBUG]]

--
function fmcGrowthControl:updateWeedFoliage(cellSquareToUpdate)
  local weedPlaced = 0
  local tries = 5
  local x = math.floor(fmcGrowthControl.gridCellWH * math.floor(cellSquareToUpdate % fmcGrowthControl.gridCells))
  local z = math.floor(fmcGrowthControl.gridCellWH * math.floor(cellSquareToUpdate / fmcGrowthControl.gridCells))
  local sx,sz = (x-(g_currentMission.terrainSize/2)),(z-(g_currentMission.terrainSize/2))

  -- Repeat until a spot was found (weed seeded) or maximum-tries reached.
  local weedType = math.floor((math.random()*2) % 2)
  local xOff,zOff
  repeat
    xOff = fmcGrowthControl.gridCellWH * math.random()
    zOff = fmcGrowthControl.gridCellWH * math.random()
    local r = 1 + 3 * math.random()
    -- Place 4 "patches" of weed.
    for i=0,3 do
        weedPlaced = weedPlaced + fmcGrowthControl.createWeedFoliage(self, math.ceil(sx + xOff), math.ceil(sz + zOff), math.ceil(r), weedType)
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
function fmcGrowthControl:createWeedFoliage(centerX,centerZ,radius,weedType, noEventSend)
    local function rotXZ(offX,offZ,x,z,angle)
        x = x * math.cos(angle) - z * math.sin(angle)
        z = x * math.sin(angle) + z * math.cos(angle)
        return offX + x, offZ + z
    end

    -- Attempt making a more "round" look
    local width,height = radius*2,radius
    local parallelograms = {}
    for _,angle in pairs({0,30,60}) do
        angle = Utils.degToRad(angle) + radius
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

    setDensityCompareParams(g_currentMission.fmcFoliageWeed, "equal", 0)
    setDensityMaskParams(g_currentMission.fmcFoliageWeed, "greater", -1,-1, includeMask, 0)
    local pixelsMatch = 0
    for _,p in pairs(parallelograms) do
        --log("weed place ", p.sx,"/",p.sz, ",", p.wx,"/",p.wz, ",", p.hx,"/",p.hz)
        local _, pixMatch, _ = setDensityMaskedParallelogram(
            g_currentMission.fmcFoliageWeed,
            p.sx,p.sz, p.wx,p.wz, p.hx,p.hz,
            0, 4,
            g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, -- mask
            value
        )
        -- However if there's germination prevention, then no weed!
        setDensityMaskParams(g_currentMission.fmcFoliageWeed, "greater", 0)
        setDensityCompareParams(g_currentMission.fmcFoliageWeed, "equals", value)
        setDensityMaskedParallelogram(
            g_currentMission.fmcFoliageWeed,
            p.sx,p.sz, p.wx,p.wz, p.hx,p.hz,
            0, 4,
            g_currentMission.fmcFoliageHerbicideTime, 0, 2, -- mask
            0
        )
        --
        pixelsMatch = pixelsMatch + pixMatch
        if pixelsMatch <= 0 then
            break
        end
    end
    setDensityMaskParams(g_currentMission.fmcFoliageWeed, "greater", -1)
    setDensityCompareParams(g_currentMission.fmcFoliageWeed, "greater", -1)

    --
    if pixelsMatch > 0 then
        CreateWeedEvent.sendEvent(centerX,centerZ,radius,weedType,noEventSend)
    end

    return pixelsMatch
end

--
function fmcGrowthControl:updateFoliageCell(cellToUpdate, day, pctCompleted, noEventSend)
    local x = math.floor(fmcGrowthControl.gridCellWH * math.floor(cellToUpdate % fmcGrowthControl.gridCells))
    local z = math.floor(fmcGrowthControl.gridCellWH * math.floor(cellToUpdate / fmcGrowthControl.gridCells))
    local sx,sz = (x-(g_currentMission.terrainSize/2)),(z-(g_currentMission.terrainSize/2))

    fmcGrowthControl:updateFoliageCellXZWH(sx,sz, fmcGrowthControl.gridCellWH, 0, day, pctCompleted, noEventSend)
end

function fmcGrowthControl:updateFoliageWeatherCell(cellToUpdate, weatherInfo, day, pctCompleted, noEventSend)
    local x = math.floor(fmcGrowthControl.gridCellWH * math.floor(cellToUpdate % fmcGrowthControl.gridCells))
    local z = math.floor(fmcGrowthControl.gridCellWH * math.floor(cellToUpdate / fmcGrowthControl.gridCells))
    local sx,sz = (x-(g_currentMission.terrainSize/2)),(z-(g_currentMission.terrainSize/2))

    fmcGrowthControl:updateFoliageCellXZWH(sx,sz, fmcGrowthControl.gridCellWH, weatherInfo, day, pctCompleted, noEventSend)
end

function fmcGrowthControl:endedFoliageCell(day, noEventSend)
    fmcGrowthControl:updateFoliageCellXZWH(0,0, 0, 0, day, 0, noEventSend)
end

function fmcGrowthControl:updateFoliageCellXZWH(x,z, wh, weatherInfo, day, pctCompleted, noEventSend)
    fmcGrowthControl.pctCompleted = pctCompleted
    fmcGrowthControlEvent.sendEvent(x,z, wh, weatherInfo, day, pctCompleted, noEventSend)

    -- Test for "magic number" indicating finished.
    if wh <= 0 then
        return
    end

    local sx,sz,wx,wz,hx,hz = x,z,  wh-0.5,0,  0,wh-0.5

    if weatherInfo <= 0 then
        -- For each fruit foliage-layer
        for _,fruitEntry in pairs(g_currentMission.fmcFoliageGrowthLayers) do
            for _,callFunc in pairs(fmcGrowthControl.pluginsGrowthCycleFruits) do
                callFunc(sx,sz,wx,wz,hx,hz,day,fruitEntry)
            end
        end
    
        -- For other foliage-layers
        for _,callFunc in pairs(fmcGrowthControl.pluginsGrowthCycle) do
            callFunc(sx,sz,wx,wz,hx,hz,day)
        end
    else
        for _,callFunc in pairs(fmcGrowthControl.pluginsWeatherCycle) do
            callFunc(sx,sz,wx,wz,hx,hz,weatherInfo,day)
        end
    end
end

--
function fmcGrowthControl:renderTextShaded(x,y,fontsize,txt,foreColor,backColor)
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
function fmcGrowthControl:draw()
    if g_gui.currentGui == nil  then
        if fmcGrowthControl.pctCompleted > 0.00 then
            local txt = (g_i18n:getText("Pct")):format(fmcGrowthControl.pctCompleted * 100)
            setTextAlignment(RenderText.ALIGN_RIGHT);
            setTextBold(false);
            self:renderTextShaded(0.999, fmcGrowthControl.hudPosY, fmcGrowthControl.hudFontSize, txt, {1,1,1,0.8}, {0,0,0,0.8})
            setTextAlignment(RenderText.ALIGN_LEFT);
            setTextColor(1,1,1,1)
        else
            -- Code for showing days countdown to growth cycle.
            -- TODO - Won't work for multiplayer clients
            local daysBeforeGrowthCycle = (fmcGrowthControl.lastDay + fmcGrowthControl.growthIntervalIngameDays) - g_currentMission.environment.currentDay
            setTextAlignment(RenderText.ALIGN_RIGHT);
            setTextBold(false);
            self:renderTextShaded(0.999, fmcGrowthControl.hudPosY, fmcGrowthControl.hudFontSize, tostring(daysBeforeGrowthCycle), {1,1,1,0.8}, {0,0,0,0.8})
            setTextAlignment(RenderText.ALIGN_LEFT);
            setTextColor(1,1,1,1)
        end
    end
end;

-------
-------
-------

fmcGrowthControlEvent = {};
fmcGrowthControlEvent_mt = Class(fmcGrowthControlEvent, Event);

InitEventClass(fmcGrowthControlEvent, "GrowthControlEvent");

function fmcGrowthControlEvent:emptyNew()
    local self = Event:new(fmcGrowthControlEvent_mt);
    self.className="fmcGrowthControlEvent";
    return self;
end;

function fmcGrowthControlEvent:new(x,z, wh, weatherInfo, day, pctCompleted)
    local self = fmcGrowthControlEvent:emptyNew()
    self.x = x
    self.z = z
    self.wh = wh
    self.weatherInfo = weatherInfo
    self.day = day
    self.pctCompleted = pctCompleted
    return self;
end;

function fmcGrowthControlEvent:readStream(streamId, connection)
    local pctCompleted  = streamReadUInt8(streamId) / 100
    local weatherInfo   = streamReadUInt8(streamId)
    local x             = streamReadInt16(streamId)
    local z             = streamReadInt16(streamId)
    local wh            = streamReadInt16(streamId)
    local day           = streamReadInt16(streamId)
    fmcGrowthControl.updateFoliageCellXZWH(fmcGrowthControl, x,z, wh, weatherInfo, day, pctCompleted, true);
end;

function fmcGrowthControlEvent:writeStream(streamId, connection)
    streamWriteUInt8(streamId, math.floor(self.pctCompleted * 100))
    streamWriteUInt8(streamId, self.weatherInfo)
    streamWriteInt16(streamId, self.x)
    streamWriteInt16(streamId, self.z)
    streamWriteInt16(streamId, self.wh)
    streamWriteInt16(streamId, self.day) -- Might cause a problem at the 32768th day. (signed short)
end;

function fmcGrowthControlEvent.sendEvent(x,z, wh, weatherInfo, day, pctCompleted, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(fmcGrowthControlEvent:new(x,z, wh, weatherInfo, day, pctCompleted), nil, nil, nil);
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
    fmcGrowthControl:createWeedFoliage(centerX,centerZ,radius,weedType, true)
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


print(string.format("Script loaded: fmcGrowthControl.lua (v%s)", fmcGrowthControl.version));
