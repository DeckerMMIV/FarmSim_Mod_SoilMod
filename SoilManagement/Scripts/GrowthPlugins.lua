--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-03-xx
--

function soilmod:setupGrowthPlugins()
    if self.foliageGrowthLayers == nil or #self.foliageGrowthLayers <= 0 then
        log("ERROR: 'foliageGrowthLayers' array not set!")
        return
    end

    self:buildSequenceForSoilEffect(self.foliageGrowthLayers)
    
    soilmod:registerTerrainTask("soilEffect" ,self ,self.terrainSoilEffect ,nil ,self.terrainSoilEffectFinished ,4)
    
    for _,fruitEntry in pairs(self.foliageGrowthLayers) do
        soilmod:registerTerrainTask(fruitEntry.fruitName .. "Growth" ,self ,self.terrainCropGrowth ,fruitEntry ,self.terrainCropGrowthFinished ,4)
    end

    soilmod:registerTerrainTask("rainWeather" ,self ,self.terrainRainEffect ,nil ,self.terrainRainEffectFinished ,4)
    soilmod:registerTerrainTask("hailWeather" ,self ,self.terrainHailEffect ,nil ,self.terrainHailEffectFinished ,4)
    soilmod:registerTerrainTask("hotWeather"  ,self ,self.terrainHotEffect  ,nil ,self.terrainHotEffectFinished  ,4)
end

--
--

function soilmod:buildSequenceForSoilEffect(foliageGrowthLayers)
    local sequence = {}

    for _,fruitEntry in pairs(foliageGrowthLayers) do
        table.insert(sequence, function(self, tpCoords)
            self:manureEffect1_AffectHealth(tpCoords, fruitEntry)
            self:limeEffect1_AffectHealth(tpCoords, fruitEntry)
        end)
    end

    table.insert(sequence, function(self, tpCoords)
        self:manureEffect2_IncreaseMoistureFertilizer(tpCoords, nil)
        self:limeEffect2_IncreaseSoilpH(tpCoords, nil)
    end)
    
    table.insert(sequence, function(self, tpCoords)
        self:waterEffect_AffectMoisture(tpCoords, nil)
        self:wetnessEffect_IncreaseMoisture(tpCoords, nil)
    end)
    
    table.insert(sequence, function(self, tpCoords)
        self:slurryEffect2_IncreaseFertilizer(tpCoords, nil)
        self:herbicideEffect2_DecreaseSoilpH(tpCoords, nil)
    end)
    
    table.insert(sequence, function(self, tpCoords)
        self:fertilizerEffect2_IncreaseN(tpCoords, nil)
        self:fertilizerEffect3_IncreasePK(tpCoords, nil)
    end)
    
    table.insert(sequence, function(self, tpCoords)
        self:fertilizerEffect4_AffectSoilpH(tpCoords, nil)
    end)
    
    table.insert(sequence, function(self, tpCoords)
        self:weedEffect1_Withering(tpCoords, nil)
        self:weedEffect2_Growing(tpCoords, nil)
    end)
    
    for _,fruitEntry in pairs(foliageGrowthLayers) do
        if nil ~= fruitEntry.fruitName:lower():find("grass") 
        or nil ~= fruitEntry.fruitName:lower():find("oilseedradish") then
            log("dailyEffect. Will not be affected by zero health; ",fruitEntry.fruitName)
        else
            table.insert(sequence, function(self, tpCoords)
                self:healthEffect_KillCropsWhereHealthIsZero(tpCoords, fruitEntry)
            end)
        end
    end
    
    self.sequenceSoilEffect = sequence
end

function soilmod:terrainSoilEffect(tpCoords, cellStep, param)
    -- Is initial step for this terrain-cell?
    if cellStep == nil then
        -- Examine if there even is any field(s) here
        local sumPixels, numPixels, totalPixels = self.getDensity(
            tpCoords, 
            self:getLayer("terrainGround"), self.densityGreater(0)
        )
        if sumPixels <= 0 then
            -- No more steps, because no ground/field to work on
            return true, nil
        end
        cellStep = 0
    end

    cellStep = cellStep + 1
    self.sequenceSoilEffect[cellStep](self, tpCoords)
    
    if cellStep < #self.sequenceSoilEffect then
        -- Still some step(s) remaining
        return false, cellStep
    end
    
    -- No more steps
    return true, nil
end

function soilmod:terrainSoilEffectFinished(param)
    --log("terrainSoilEffectFinished")
end

--
--

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
    local manureHealthDiff = fruitEntry:get("manure_healthDiff", 0)
    if manureHealthDiff == 0 then
        return false
    end
    
    local layerTemp = self:resetIntermediateLayer(tpCoords, 0)
    -- Mark crop areas in intermediate layer
    self.setDensityMasked(
        tpCoords, 
        layerTemp,             self.densityGreater(-1), 
        fruitEntry:getLayer(), self.densityBetween(fruitEntry:get("growing_minValue"), fruitEntry:get("growing_maxValue")),
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
        layerTemp,   self.densityEqual(1),
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
    local layerFruit = fruitEntry:getLayer()
    local layerHealth = self:getLayer("health")
    local witheredValue = fruitEntry:get("witheredValue", -1)
    if witheredValue <= 0 then
        -- Set to 'cutted' where crop health is zero
        self.setDensityMasked(
            tpCoords,
            layerFruit,  self.densityBetween(fruitEntry:get("growing_minValue"), fruitEntry:get("growing_maxValue")),
            layerHealth, self.densityEqual(0),
            fruitEntry:get("cuttedValue")
        )
    else
        -- Set to 'cutted' where crop health is zero
        self.setDensityMasked(
            tpCoords,
            layerFruit,  self.densityBetween(fruitEntry:get("growing_minValue"), fruitEntry:get("mature_minValue") - 1),
            layerHealth, self.densityEqual(0),
            fruitEntry:get("cuttedValue")
        )
        -- Set to 'withered' where crop health is zero
        self.setDensityMasked(
            tpCoords,
            layerFruit,  self.densityBetween(fruitEntry:get("mature_minValue"), fruitEntry:get("mature_maxValue")),
            layerHealth, self.densityEqual(0),
            witheredValue
        )
    end
end

function soilmod:limeEffect1_AffectHealth(tpCoords, fruitEntry)
    local limeHealthDiff = fruitEntry:get("lime_healthDiff", -14)
    if limeHealthDiff == 0 then
        return false
    end
    
    local layerTemp = self:resetIntermediateLayer(tpCoords, 0)
    -- Mark crop areas in intermediate layer
    self.setDensityMasked(
        tpCoords, 
        layerTemp,             self.densityGreater(-1), 
        fruitEntry:getLayer(), self.densityBetween(fruitEntry:get("growing_minValue"), fruitEntry:get("growing_maxValue")),
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
        layerTemp,   self.densityEqual(1),
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
        layerFertilizer, self.densityEqual(3),
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
        layerFertilizer, self.densityEqual(2),
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
        layerFertilizer, self.densityEqual(1),
        1
    )
end

function soilmod:fertilizerEffect4_AffectSoilpH(tpCoords, fruitEntry)
    local layerFertilizer = self:getLayer("fertilizer")
    -- Reduce soil pH where there is PlantKiller
    local layerSoilpH = self:getLayer("soil_pH")
    self.addDensityMasked(
        tpCoords,
        layerSoilpH,     self.densityGreater(0),
        layerFertilizer, self.densityEqual(4),
        -1
    )
    -- Reduce soil pH where there is fertilizer N
    self.addDensityMasked(
        tpCoords,
        layerSoilpH,     self.densityGreater(0),
        layerFertilizer, self.densityBetween(3,7),
        -1
    )
    -- Remove fertilizer
    self.setDensity(
        tpCoords,
        layerFertilizer, self.densityGreater(0),
        0
    )
end

--
--

function soilmod:terrainCropGrowth(tpCoords, cellStep, fruitEntry)
    -- Is initial step for this terrain-cell?
    if cellStep == nil then
        -- Examine if there even is any of the crop here
        local sumPixels, numPixels, totalPixels = self.getDensity(
            tpCoords,
            fruitEntry:getLayer(), self.densityBetween(fruitEntry:get("growing_minValue"), fruitEntry:get("growing_maxValue"))
        )
        --log(fruitEntry.fruitName,"; x/z; ",tpCoords[1],"/",tpCoords[2], " - sum/num/tot; ",sumPixels,"/",numPixels,"/",totalPixels)
        if sumPixels <= 0 then
            -- No more steps, because no crop to work on
            return true, nil
        end
        cellStep = 0
    end

    if cellStep == 0 then
        self:cropEffect_ConsumeFertN(tpCoords, fruitEntry)
    elseif cellStep == 1 then
        self:cropEffect_ConsumeFertPK(tpCoords, fruitEntry)
    elseif cellStep == 2 then
        self:cropEffect_ConsumeMoisture(tpCoords, fruitEntry)
    elseif cellStep == 3 then
        self:cropEffect_ReduceSoilpH(tpCoords, fruitEntry)    
    elseif cellStep == 4 then
        self:cropEffect_IncreaseGrowthState(tpCoords, fruitEntry)
        -- No more steps
        return true, nil
    end
    
    -- Still some step(s) remaining
    return false, cellStep + 1
end


function soilmod:terrainCropGrowthFinished(fruitEntry)
    --log("terrainCropGrowthFinished; ",fruitEntry.fruitName)
end

--
--

function soilmod:cropEffect_IncreaseGrowthState(tpCoords, fruitEntry)
    -- Increase growth-state for crop-type
    local layerFruit = fruitEntry:getLayer()
    self.addDensityMasked(
        tpCoords,
        layerFruit, self.densityGreater(0),
        layerFruit, self.densityBetween(fruitEntry:get("growing_minValue"), fruitEntry:get("growing_maxValue")),
        1 -- increase
    )
    -- Change ground-type if needed
    if fruitEntry.groundTypeChange ~= nil then
        local layerGround = self:getLayer("terrainGround")
        self.setDensityMasked(
            tpCoords,
            layerGround, self.densityGreater(0),
            layerFruit,  self.densityGreater(0),
            fruitEntry.groundTypeChange
        )
    end
    -- Change health to zero where crops have withered
    if fruitEntry.witheredValue ~= nil then
        local layerHealth = self:getLayer("health")
        self.setDensityMasked(
            tpCoords,
            layerHealth, self.densityGreater(0),
            layerFruit,  self.densityEqual(fruitEntry.witheredValue),
            0
        )
    end
end

function soilmod:cropEffect_ConsumeFertN(tpCoords, fruitEntry)
    -- Increase health(+2) where FertN and fruit
    local growthStatesConsumeFertN = fruitEntry:get("growthStates_consumeFertN", {1,3,5,6})
    
    local layerFruit = fruitEntry:getLayer()
    local layerTemp = self:resetIntermediateLayer(tpCoords, 0)
    -- Mark crop areas in intermediate layer
    for _,growthState in pairs(growthStatesConsumeFertN) do
        self.setDensityMasked(
            tpCoords, 
            layerTemp,  self.densityGreater(-1), 
            layerFruit, self.densityEqual(growthState),
            1
        )
    end
    -- Remove crop areas from intermediate layer where FertN is NOT found
    local layerFertN = self:getLayer("fertN")
    self.setDensityMasked(
        tpCoords, 
        layerTemp,  self.densityEqual(1), 
        layerFertN, self.densityEqual(0),
        0
    )
    -- Increase health where fruit+FertN exists
    local layerHealth = self:getLayer("health")
    self.addDensityMasked(
        tpCoords,
        layerHealth, self.densityGreater(-1), 
        layerTemp,   self.densityEqual(1),
        2
    )
    -- Reduce FertN
    self.addDensityMasked(
        tpCoords,
        layerFertN, self.densityGreater(0), 
        layerTemp,  self.densityEqual(1),
        -1
    )
end

function soilmod:cropEffect_ConsumeFertPK(tpCoords, fruitEntry)
    -- Increase health(+1) where FertPK and fruit
    local growthStatesConsumeFertPK = fruitEntry:get("growthStates_consumeFertPK", {2,4})
    
    local layerFruit = fruitEntry:getLayer()
    local layerTemp = self:resetIntermediateLayer(tpCoords, 0)
    -- Mark crop areas in intermediate layer
    for _,growthState in pairs(growthStatesConsumeFertPK) do
        self.setDensityMasked(
            tpCoords, 
            layerTemp,  self.densityGreater(-1), 
            layerFruit, self.densityEqual(growthState),
            1
        )
    end
    -- Remove crop areas from intermediate layer where FertPK is NOT found
    local layerFertPK = self:getLayer("fertPK")
    self.setDensityMasked(
        tpCoords, 
        layerTemp,  self.densityEqual(1), 
        layerFertPK, self.densityEqual(0),
        0
    )
    -- Increase health where fruit+FertN exists
    local layerHealth = self:getLayer("health")
    self.addDensityMasked(
        tpCoords,
        layerHealth, self.densityGreater(-1), 
        layerTemp,   self.densityEqual(1),
        1
    )
    -- Reduce FertPK
    self.addDensityMasked(
        tpCoords,
        layerFertPK, self.densityGreater(0), 
        layerTemp,   self.densityEqual(1),
        -1
    )
end

function soilmod:cropEffect_ConsumeMoisture(tpCoords, fruitEntry)
    -- Increase health(+1) where good Moisture and fruit
    local growthStatesConsumeMoisture = fruitEntry:get("growthStates_consumeMoisture", {1,2,4,6})
    
    local layerFruit = fruitEntry:getLayer()
    local layerTemp  = self:resetIntermediateLayer(tpCoords, 0)
    -- Mark crop areas in intermediate layer
    for _,growthState in pairs(growthStatesConsumeMoisture) do
        self.setDensityMasked(
            tpCoords, 
            layerTemp,  self.densityGreater(-1), 
            layerFruit, self.densityEqual(growthState),
            3
        )
    end
    -- Remove crop areas from intermediate-1 layer where Moisture is very-low
    local layerMoisture = self:getLayer("moisture")
    local layerTemp1 = self:getLayer("intermediate1")
    self.setDensityMasked(
        tpCoords, 
        layerTemp1,    self.densityEqual(1), 
        layerMoisture, self.densityEqual(0),
        0
    )
    -- Remove crop areas from intermediate-1 layer where Moisture is high
    self.setDensityMasked(
        tpCoords, 
        layerTemp1,    self.densityEqual(1), 
        layerMoisture, self.densityGreater(6),
        0
    )
    -- Increase health where fruit+moisture exists
    local layerHealth = self:getLayer("health")
    self.addDensityMasked(
        tpCoords,
        layerHealth, self.densityGreater(-1), 
        layerTemp1,  self.densityEqual(1),
        1
    )
    -- Reduce Moisture
    self.addDensityMasked(
        tpCoords,
        layerMoisture, self.densityGreater(0), 
        layerTemp,     self.densityGreater(0),
        -1
    )
end

function soilmod:cropEffect_ReduceSoilpH(tpCoords, fruitEntry)
    -- Decrease health(-2) where bad soil pH and fruit
    local growthStatesReduceSoilpH = fruitEntry:get("growthStates_reduceSoilpH", {3})
    
    local layerFruit = fruitEntry:getLayer()
    local layerTemp = self:resetIntermediateLayer(tpCoords, 0)
    -- Mark crop areas in intermediate layer
    for _,growthState in pairs(growthStatesReduceSoilpH) do
        self.setDensityMasked(
            tpCoords, 
            layerTemp,  self.densityGreater(-1), 
            layerFruit, self.densityEqual(growthState),
            3
        )
    end
    -- Remove crop areas from intermediate-1 layer where soil pH is good
    local layerSoilpH = self:getLayer("soil_pH")
    local layerTemp1 = self:getLayer("intermediate1")
    self.setDensityMasked(
        tpCoords, 
        layerTemp1,  self.densityEqual(1), 
        layerSoilpH, self.densityBetween(3,13),
        0
    )
    -- Decrease health where fruit and bad Soil pH exists
    local layerHealth = self:getLayer("health")
    self.addDensityMasked(
        tpCoords,
        layerHealth, self.densityGreater(-1), 
        layerTemp1,  self.densityEqual(1),
        -2
    )
    -- Reduce Soil pH
    self.addDensityMasked(
        tpCoords,
        layerSoilpH, self.densityGreater(0), 
        layerTemp,   self.densityGreater(0),
        -1
    )
end

--
--

function soilmod:terrainRainEffect(tpCoords, cellStep, param)
    -- Increase moisture
    local layerMoisture = self:getLayer("moisture")
    local layerField    = self:getLayer("terrainGround")
    self.addDensityMasked(
        tpCoords,
        layerMoisture, self.densityGreater(-1), 
        layerField,    self.densityGreater(0),
        1
    )
    -- Wetness
    local layerWetness = self:getLayer("wetness")
    self.setDensityMasked(
        tpCoords,
        layerWetness,  self.densityGreater(-1), 
        layerField,    self.densityGreater(0),
        1
    )
    -- No more steps
    return true, nil
end
function soilmod:terrainRainEffectFinished(param)
    --log("terrainRainEffectFinished")
end

--
--

function soilmod:terrainHailEffect(tpCoords, cellStep, param)
    -- Decrease health
    local layerHealth = self:getLayer("health")
    local layerField  = self:getLayer("terrainGround")
    self.addDensityMasked(
        tpCoords,
        layerHealth, self.densityGreater(0), 
        layerField,  self.densityGreater(0),
        -1
    )
    ---- Wetness
    --local layerWetness = self:getLayer("wetness")
    --self.setDensityMasked(
    --    tpCoords,
    --    layerWetness,  self.densityGreater(-1), 
    --    layerField,    self.densityGreater(0),
    --    1
    --)
    -- No more steps
    return true, nil
end
function soilmod:terrainHailEffectFinished(param)
    --log("terrainHailEffectFinished")
end

--
--

function soilmod:terrainHotEffect(tpCoords, cellStep, param)
    -- Decrease moisture
    local layerMoisture = self:getLayer("moisture")
    self.addDensity(
        tpCoords,
        layerMoisture, self.densityGreater(0), 
        -1
    )
    -- Remove Wetness
    local layerWetness = self:getLayer("wetness")
    self.setDensity(
        tpCoords,
        layerWetness,  self.densityGreater(0), 
        0
    )
    -- No more steps
    return true, nil
end
function soilmod:terrainHotEffectFinished(param)
    --log("terrainHotEffectFinished")
end
