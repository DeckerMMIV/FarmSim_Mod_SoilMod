--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-03-xx
--

function soilmod:setupGrowthPlugins()
    soilmod:registerTerrainTask("dailyEffect", self, self.terrainDailyEffect, nil, self.terrainDailyEffectFinished)
end

--
--

function soilmod:terrainDailyEffect(tpCoords, cellStep, param)
    -- Is initial step for this terrain-cell?
    if cellStep == nil then
        -- Examine if there even is any field(s) here
        local sumPixels, numPixels, totalPixels = self.getDensity(
            tpCoords, 
            self:getLayer("terrainGround"), self.densityGreater(0)
        )
        if sumPixels <= 0 then
            -- No more steps, because no ground/field to work on
--log("Skipped ",tpCoords[1],",",tpCoords[2])
            return true, nil
        end
        cellStep = 0
    end

    if cellStep == 0 then
--log("Doing   ",tpCoords[1],",",tpCoords[2])
        self:weedEffect1_Withering(tpCoords, nil)
        self:weedEffect2_Growing(tpCoords, nil)
    elseif cellStep == 1 then
        self:manureEffect2_IncreaseMoistureFertilizer(tpCoords, nil)
        self:slurryEffect2_IncreaseFertilizer(tpCoords, nil)
    elseif cellStep == 2 then
        self:waterEffect_AffectMoisture(tpCoords, nil)
        self:wetnessEffect_IncreaseMoisture(tpCoords, nil)
    elseif cellStep == 3 then
        self:limeEffect2_IncreaseSoilpH(tpCoords, nil)
        self:herbicideEffect2_DecreaseSoilpH(tpCoords, nil)
    elseif cellStep == 4 then
        self:fertilizerEffect2_IncreaseN(tpCoords, nil)
        self:fertilizerEffect3_IncreasePK(tpCoords, nil)
    elseif cellStep == 5 then
        self:fertilizerEffect4_PlantKillerAndSoilpH(tpCoords, nil)
        -- No more steps
        return true, nil
    end
    
    -- Still step(s) remaining
    return false, cellStep + 1
end

function soilmod:terrainDailyEffectFinished(param)
    log("terrainDailyEffectFinished")
end

--
--

function soilmod:cropEffect_IncreaseGrowthState(tpCoords, fruitEntry)
    -- Increase growth-state for crop-type
    local layerFruit = fruitEntry:getLayer()
    self.addDensityMasked(
      tpCoords,
      layerFruit, self.densityGreater(0),
      layerFruit, self.densityBetween(fruitEntry:get("growing#minValue"), fruitEntry:get("harvest#maxValue")),
      1 -- increase
    )
end

function soilmod:weedEffect1_Withering(tpCoords, fruitEntry)
    -- Reduce withered weeds
    local layerWeedGrowth = self:getLayer("weedGrowth")
    self.addDensity(
        tpCoords,
        layerWeedGrowth, self.densityBetween(1,3),
        -1
    )
    -- Wither weeds if there is no fertN available
    local layerFertN = self:getLayer("fertN")
    self.setDensityMasked(
        tpCoords,
        layerWeedGrowth, self.densityEqual(7),
        layerFertN,      self.densityEqual(0),
        3
    )
    -- Wither weeds if there is herbicide
    local layerWeedAlive = self:getLayer("weedAlive")
    local layerHerbicide = self:getLayer("herbicide")
    self.setDensityMasked(
        tpCoords,
        layerWeedAlive, self.densityGreater(0),
        layerHerbicide, self.densityGreater(0),
        0
    )
end

function soilmod:weedEffect2_Growing(tpCoords, fruitEntry)
    -- Increase alive weed
    local layerWeedGrowth = self:getLayer("weedGrowth")
    self.addDensity(
        tpCoords,
        layerWeedGrowth, self.densityBetween(4,6),
        1
    )
    -- Decrease fertN where weed is alive
    local layerFertN = self:getLayer("fertN")
    self.addDensityMasked(
        tpCoords,
        layerFertN,      self.densityGreater(0),
        layerWeedGrowth, self.densityGreater(3),
        -1
    )
    -- Decrease moisture where weed is alive
    local layerMoisture = self:getLayer("moisture")
    self.addDensityMasked(
        tpCoords,
        layerMoisture,   self.densityGreater(0),
        layerWeedGrowth, self.densityGreater(3),
        -1
    )
end

function soilmod:manureEffect1_AffectHealth(tpCoords, fruitEntry)
    local manureHealthDiff = fruitEntry:get("manure#healthDiff")
    if manureHealthDiff == 0 then
        return false
    end
    
    local layerTemp = self:resetIntermediateLayer(tpCoords, 0)
    -- Mark crop areas in intermediate layer
    self.setDensityMasked(
        tpCoords, 
        layerTemp,             self.densityGreater(-1), 
        fruitEntry:getLayer(), self.densityBetween(fruitEntry:get("growing#minValue"), fruitEntry:get("harvest#maxValue")),
        1
    )
    -- Remove crop areas from intermediate layer where manure is NOT found
    local layerManure = self:getLayer("manure")
    self.setDensityMasked(
        tpCoords, 
        layerTemp,   self.densityGreater(0), 
        layerManure, self.densityEqual(0),
        0
    )
    -- Decrease health where fruit+manure exists
    local layerHealth = self:getLayer("health")
    self.addDensityMasked(
        tpCoords,
        layerHealth, self.densityGreater(0), 
        layerTemp,   self.densityEqual(0),
        manureHealthDiff
    )
end

function soilmod:manureEffect2_IncreaseMoistureFertilizer(tpCoords, fruitEntry)
    local layerManure = self:getLayer("manure")
    -- Increase moisture where there is manure
    local layerMoisture = self:getLayer("moisture")
    self.addDensityMasked(
        tpCoords,
        layerMoisture, self.densityGreater(-1),
        layerManure,   self.densityGreater(0),
        1
    )
    -- Increase fertN where there is manure
    local layerFertN  = self:getLayer("fertN")
    self.addDensityMasked(
        tpCoords,
        layerFertN,  self.densityGreater(-1),
        layerManure, self.densityGreater(0),
        5
    )
    -- Increase fertPK where there is manure
    local layerFertPK = self:getLayer("fertPK")
    self.addDensityMasked(
        tpCoords,
        layerFertPK, self.densityGreater(-1),
        layerManure, self.densityGreater(0),
        2
    )
    -- Remove manure
    self.setDensity(
        tpCoords,
        layerManure, self.densityGreater(0),
        0
    )
end
    
function soilmod:slurryEffect2_IncreaseFertilizer(tpCoords, fruitEntry)
    local layerSlurry = self:getLayer("slurry")
    -- Increase fertN where there is slurry
    local layerFertN  = self:getLayer("fertN")
    self.addDensityMasked(
        tpCoords,
        layerFertN,  self.densityGreater(-1),
        layerSlurry, self.densityGreater(0),
        4
    )
    -- Increase fertPK where there is slurry
    local layerFertPK = self:getLayer("fertPK")
    self.addDensityMasked(
        tpCoords,
        layerFertPK, self.densityGreater(-1),
        layerSlurry, self.densityGreater(0),
        1
    )
    -- Remove slurry
    self.setDensity(
        tpCoords,
        layerSlurry, self.densityGreater(0),
        0
    )
end
    
function soilmod:healthEffect_KillCropsWhereHealthIsZero(tpCoords, fruitEntry)
    local layerHealth = self:getLayer("health")
    -- Set to 'cutted' where crop health is zero
    self.setDensityMasked(
        tpCoords,
        fruitEntry:getLayer(), self.densityBetween(fruitEntry:get("growing#minValue"), fruitEntry:get("growing#maxValue")),
        layerHealth,           self.densityEqual(0),
        fruitEntry:get("cuttedValue")
    )
    -- Set to 'withered' where crop health is zero
    self.setDensityMasked(
        tpCoords,
        fruitEntry:getLayer(), self.densityBetween(fruitEntry:get("harvest#minValue"), fruitEntry:get("harvest#maxValue")),
        layerHealth,           self.densityEqual(0),
        fruitEntry:get("witheredValue")
    )
end

function soilmod:limeEffect1_UnhealthyForCrops(tpCoords, fruitEntry)
    local limeHealthDiff = fruitEntry:get("lime#healthDiff")
    if limeHealthDiff == 0 then
        return false
    end
    
    local layerTemp = self:resetIntermediateLayer(tpCoords, 0)
    -- Mark crop areas in intermediate layer
    self.setDensityMasked(
        tpCoords, 
        layerTemp,             self.densityGreater(-1), 
        fruitEntry:getLayer(), self.densityBetween(fruitEntry:get("growing#minValue"), fruitEntry:get("harvest#maxValue")),
        1
    )
    -- Remove crop areas from intermediate layer where lime is NOT found
    local layerLime = self:getLayer("lime")
    self.setDensityMasked(
        tpCoords, 
        layerTemp, self.densityGreater(0), 
        layerLime, self.densityEqual(0),
        0
    )
    -- Decrease health where fruit+lime exists
    local layerHealth = self:getLayer("health")
    self.addDensityMasked(
        tpCoords,
        layerHealth, self.densityGreater(0), 
        layerTemp,   self.densityEqual(0),
        limeHealthDiff
    )
end

function soilmod:limeEffect2_IncreaseSoilpH(tpCoords, fruitEntry)
    local layerSoilpH = self:getLayer("soil_pH")
    local layerLime = self:getLayer("lime")
    -- Increase soil pH where there's lime
    self.addDensityMasked(
        tpCoords,
        layerSoilpH, self.densityGreater(-1),
        layerLime,   self.densityGreater(0),
        2
    )
    -- Remove lime
    self.setDensity(
        tpCoords,
        layerLime, self.densityGreater(0),
        0
    )
end

function soilmod:waterEffect_AffectMoisture(tpCoords, fruitEntry)
    local layerWater = self:getLayer("water")
    local layerMoisture = self:getLayer("moisture")
    -- Increase moisture where there are water(+2)
    self.addDensityMasked(
        tpCoords,
        layerMoisture, self.densityGreater(-1),
        layerWater,    self.densityEqual(3),
        2
    )
    -- Increase moisture where there are water(+1)
    self.addDensityMasked(
        tpCoords,
        layerMoisture, self.densityGreater(-1),
        layerWater,    self.densityEqual(2),
        1
    )
    -- Decrease moisture where there are water(-2)
    self.addDensityMasked(
        tpCoords,
        layerMoisture, self.densityGreater(-1),
        layerWater,    self.densityEqual(1),
        -1
    )
    -- Remove water
    self.setDensity(
        tpCoords,
        layerWater, self.densityGreater(0),
        0
    )
end

function soilmod:wetnessEffect_IncreaseMoisture(tpCoords, fruitEntry)
    local layerWetness = self:getLayer("wetness")
    -- Increase moisture where there have been sprayed (wetness)
    local layerMoisture = self:getLayer("moisture")
    self.addDensityMasked(
        tpCoords,
        layerMoisture, self.densityGreater(-1),
        layerWetness,  self.densityGreater(0),
        1
    )
    -- Remove spray (wetness)
    self.setDensity(
        tpCoords,
        layerWetness, self.densityGreater(0),
        0
    )
end

function soilmod:herbicideEffect2_DecreaseSoilpH(tpCoords, fruitEntry)
    local layerHerbicide = self:getLayer("herbicide")
    -- Reduce germination prevention time, where there is no herbicide
    local layerHerbicideTime = self:getLayer("herbicideTime")
    self.addDensityMasked(
        tpCoords,
        layerHerbicideTime, self.densityGreater(0),
        layerHerbicide,     self.densityEqual(0),
        -1
    )
    -- Decrease soil pH where there's herbicide
    local layerSoilpH = self:getLayer("soil_pH")
    self.addDensityMasked(
        tpCoords,
        layerSoilpH,    self.densityGreater(-1),
        layerHerbicide, self.densityGreater(0),
        -1
    )
    -- Remove herbicide
    self.setDensity(
        tpCoords,
        layerHerbicide, self.densityGreater(0),
        0
    )
end

function soilmod:fertilizerEffect2_IncreaseN(tpCoords, fruitEntry)
    local layerFertilizer = self:getLayer("fertilizer")
    -- Increase N(+4) where there is fertilizer 4.0.0
    local layerFertN = self:getLayer("fertN")
    self.addDensityMasked(
        tpCoords,
        layerFertN,      self.densityGreater(-1),
        layerFertilizer, self.densityEqual(5),
        4
    )
    -- Increase N(+3) where there is fertilizer 3.1.1
    self.addDensityMasked(
        tpCoords,
        layerFertN,      self.densityGreater(-1),
        layerFertilizer, self.densityEqual(6),
        3
    )
    -- Increase N(+1) where there is fertilizer 1.3.3
    self.addDensityMasked(
        tpCoords,
        layerFertN,      self.densityGreater(-1),
        layerFertilizer, self.densityEqual(7),
        1
    )
    -- Increase N(+1) where there is fertilizer 1.0.0
    self.addDensityMasked(
        tpCoords,
        layerFertN,      self.densityGreater(-1),
        layerFertilizer, self.densityEqual(1),
        1
    )
end

function soilmod:fertilizerEffect3_IncreasePK(tpCoords, fruitEntry)
    local layerFertilizer = self:getLayer("fertilizer")
    -- Increase PK(+3) where there is fertilizer 1.3.3
    local layerFertPK = self:getLayer("fertPK")
    self.addDensityMasked(
        tpCoords,
        layerFertPK,     self.densityGreater(-1),
        layerFertilizer, self.densityEqual(7),
        3
    )
    -- Increase PK(+2) where there is fertilizer 0.2.2
    self.addDensityMasked(
        tpCoords,
        layerFertPK,     self.densityGreater(-1),
        layerFertilizer, self.densityEqual(3),
        2
    )
    -- Increase PK(+1) where there is fertilizer 3.1.1
    self.addDensityMasked(
        tpCoords,
        layerFertPK,     self.densityGreater(-1),
        layerFertilizer, self.densityEqual(6),
        1
    )
    -- Increase PK(+1) where there is fertilizer 0.1.1
    self.addDensityMasked(
        tpCoords,
        layerFertPK,     self.densityGreater(-1),
        layerFertilizer, self.densityEqual(2),
        1
    )
end

function soilmod:fertilizerEffect4_PlantKillerAndSoilpH(tpCoords, fruitEntry)
    local layerFertilizer = self:getLayer("fertilizer")
    -- Remove plants where there is PlantKiller
    
    -- TODO
    
    -- Reduce soil pH where there is PlantKiller
    local layerSoilpH = self:getLayer("soil_pH")
    self.addDensityMasked(
        tpCoords,
        layerSoilpH,     self.densityGreater(-1),
        layerFertilizer, self.densityEqual(4),
        -2
    )
    -- Reduce soil pH where there is fertilizer 4.0.0
    self.addDensityMasked(
        tpCoords,
        layerSoilpH,     self.densityGreater(-1),
        layerFertilizer, self.densityEqual(5),
        -1
    )
    -- Remove fertilizer
    self.setDensity(
        tpCoords,
        layerFertilizer, self.densityGreater(0),
        0
    )
end
