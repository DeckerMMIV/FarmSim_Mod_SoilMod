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
        if nil ~= fruitEntry.fruitName:lower():find("drygrass") then
            --log("Has no growth; ",fruitEntry.fruitName)
        else
            soilmod:registerTerrainTask(fruitEntry.fruitName .. "Growth" ,self ,self.terrainCropGrowth ,fruitEntry ,self.terrainCropGrowthFinished ,5)
        end
    end
    soilmod:registerTerrainTask("weedGrowth" ,self ,self.terrainWeedGrowth ,nil ,self.terrainWeedGrowthFinished ,4)

    soilmod:registerTerrainTask("rainWeather" ,self ,self.terrainRainEffect ,nil ,self.terrainRainEffectFinished ,4)
    soilmod:registerTerrainTask("hailWeather" ,self ,self.terrainHailEffect ,nil ,self.terrainHailEffectFinished ,4)
    soilmod:registerTerrainTask("hotWeather"  ,self ,self.terrainHotEffect  ,nil ,self.terrainHotEffectFinished  ,4)

    soilmod:registerTerrainTask("reduceDelay" ,self ,self.terrainGrowthDelay ,nil ,self.terrainGrowthDelayFinished ,4)
end

--[[
Growth states

   Density value (from channels/bits)
   |  RegisterFruit value (for RegisterFruit)
   |  |
   0  -  nothing
   1  0  growth-1 (just seeded)
   2  1  growth-2
   3  2  growth-3
   4  3  growth-4
   5  4  harvest-1 / prepare-1
   6  5  harvest-2 / prepare-2
   7  6  harvest-3 / prepare-3
   8  7  withered
   9  8  cutted
  10  9  harvest (defoliaged)
  11 10  <unused>
  12 11  <unused>
  13 12  <unused>
  14 13  <unused>
  15 14  <unused>
--]]

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

    for _,fruitEntry in pairs(foliageGrowthLayers) do
        if nil ~= fruitEntry.fruitName:lower():find("grass") 
        or nil ~= fruitEntry.fruitName:lower():find("oilseedradish") then
            --log("Not affected by herbicide; ",fruitEntry.fruitName)
        else
            table.insert(sequence, function(self, tpCoords)
                self:herbicideEffect1_AffectHealth(tpCoords, fruitEntry)
            end)
        end
    end
    
    table.insert(sequence, function(self, tpCoords)
        self:herbicideEffect2_DecreaseSoilpH(tpCoords, nil)
        self:slurryEffect1_PlantKiller(tpCoords, nil)
        self:slurryEffect2_IncreaseFertilizer(tpCoords, nil)
    end)
    
    table.insert(sequence, function(self, tpCoords)
        self:fertilizerEffect2_IncreaseN(tpCoords, nil)
        self:fertilizerEffect3_IncreasePK(tpCoords, nil)
    end)
    
    table.insert(sequence, function(self, tpCoords)
        self:fertilizerEffect4_AffectSoilpH(tpCoords, nil)
        self:growthDelayEffect_Decrease(tpCoords, nil)
    end)
    
    for _,fruitEntry in pairs(foliageGrowthLayers) do
        if nil ~= fruitEntry.fruitName:lower():find("grass") 
        or nil ~= fruitEntry.fruitName:lower():find("oilseedradish") then
            --log("Not affected by zero health; ",fruitEntry.fruitName)
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

function soilmod:terrainGrowthDelay(tpCoords, cellStep, fruitEntry)
    self:growthDelayEffect_Decrease(tpCoords, fruitEntry)
    -- No more steps
    return true, nil
end

function soilmod:terrainGrowthDelayFinished(param)
    --log("terrainGrowthDelayFinished")
end

--
--

function soilmod:terrainWeedGrowth(tpCoords, cellStep, fruitEntry)
    self:weedEffect1_Withering(tpCoords, nil)
    self:weedEffect2_Growing(tpCoords, nil)
    -- No more steps
    return true, nil
end

function soilmod:terrainWeedGrowthFinished(param)
    --log("terrainWeedGrowthFinished")
end
    
--
--

function soilmod:growthDelayEffect_Decrease(tpCoords, fruitEntry)
    -- Reduce growth-delay value
    local layerGrowthDelay = self:getLayer("growthDelay")
    self.addDensity(
        tpCoords,
        layerGrowthDelay, self.densityGreater(0),
        -1
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
    -- Wither weeds if there is no nutrientN available
    local layerNutrientN = self:getLayer("nutrientN")
    self.setDensityMasked(
        tpCoords,
        layerWeedGrowth, self.densityEqual(7),
        layerNutrientN,      self.densityEqual(0),
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
    -- Decrease nutrientN where weed is alive
    local layerNutrientN = self:getLayer("nutrientN")
    self.addDensityMasked(
        tpCoords,
        layerNutrientN,      self.densityGreater(0),
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
    -- Increase nutrientN where there is manure
    local layerNutrientN  = self:getLayer("nutrientN")
    self.addDensityMasked(
        tpCoords,
        layerNutrientN,  self.densityGreater(-1),
        layerManure, self.densityGreater(0),
        5
    )
    -- Increase nutrientPK where there is manure
    local layerNutrientPK = self:getLayer("nutrientPK")
    self.addDensityMasked(
        tpCoords,
        layerNutrientPK, self.densityGreater(-1),
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

function soilmod:slurryEffect1_PlantKiller(tpCoords, fruitEntry)
    local layerSlurry = self:getLayer("slurry")
    -- Remove crops/fruits where there is plant-killer
    for _,id in ipairs(self.densityMapsFirstFruitId) do
        setDensityNewTypeIndexMode(    id, 2) --SET_INDEX_TO_ZERO);
        setDensityTypeIndexCompareMode(id, 2) --TYPE_COMPARE_NONE);

        setDensityMaskParams(id, "equal", 1) -- 1=plantkiller
        setDensityMaskedParallelogram(
            id, 
            tpCoords[1],tpCoords[2], tpCoords[3],tpCoords[4], tpCoords[5],tpCoords[6],
            0,g_currentMission.numFruitDensityMapChannels, 
            layerSlurry.layerId, layerSlurry.channelOffset,layerSlurry.numChannels,
            0
        );

        setDensityNewTypeIndexMode(    id, 0) --UPDATE_INDEX);
        setDensityTypeIndexCompareMode(id, 0) --TYPE_COMPARE_EQUAL);
    end
    -- Reduce soil pH where there is PlantKiller
    local layerSoilpH = self:getLayer("soil_pH")
    self.addDensityMasked(
        tpCoords,
        layerSoilpH, self.densityGreater(0),
        layerSlurry, self.densityEqual(1),
        -1
    )
end
    
function soilmod:slurryEffect2_IncreaseFertilizer(tpCoords, fruitEntry)
    local layerSlurry = self:getLayer("slurry")
    -- Increase nutrientN where there is slurry
    local layerNutrientN  = self:getLayer("nutrientN")
    self.addDensityMasked(
        tpCoords,
        layerNutrientN, self.densityGreater(-1),
        layerSlurry, self.densityGreater(1),
        4
    )
    -- Increase nutrientPK where there is slurry
    local layerNutrientPK = self:getLayer("nutrientPK")
    self.addDensityMasked(
        tpCoords,
        layerNutrientPK, self.densityGreater(-1),
        layerSlurry, self.densityGreater(1),
        1
    )
    -- Remove slurry/plantkiller
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

function soilmod:herbicideEffect1_AffectHealth(tpCoords, fruitEntry)
    local herbicideAvoidance  = fruitEntry:get("herbicide_avoidance", {3})
    local herbicideHealthDiff = fruitEntry:get("herbicide_healthDiff", -8)

    local layerHerbicide = self:getLayer("herbicide")
    local layerTemp = self:resetIntermediateLayer(tpCoords, 0)
    -- Set intermediate layer, for wrong herbicides
    for _,herbicideType in pairs(herbicideAvoidance) do
        self.setDensityMasked(
            tpCoords, 
            layerTemp,      self.densityGreater(-1), 
            layerHerbicide, self.densityEqual(herbicideType),
            1
        )
    end
    -- Remove from intermediate layer, where crops are NOT
    self.setDensityMasked(
        tpCoords, 
        layerTemp,             self.densityGreater(0), 
        fruitEntry:getLayer(), self.densityEqual(0),
        0
    )
    -- Decrease health where wrong herbicide used for crop
    local layerHealth = self:getLayer("health")
    self.addDensityMasked(
        tpCoords,
        layerHealth, self.densityGreater(0),
        layerTemp,   self.densityGreater(0),
        herbicideHealthDiff
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
        layerSoilpH,    self.densityGreater(0),
        layerHerbicide, self.densityGreater(0),
        -1
    )
    -- Decrease health where there's herbicide - to provide a reason for using weeder
    local layerHealth = self:getLayer("health")
    self.addDensityMasked(
        tpCoords,
        layerHealth,    self.densityGreater(0),
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
    local layerNutrientN = self:getLayer("nutrientN")
    self.addDensityMasked(
        tpCoords,
        layerNutrientN,  self.densityGreater(-1),
        layerFertilizer, self.densityEqual(5),
        4
    )
    -- Increase N(+3) where there is fertilizer 3.1.1
    self.addDensityMasked(
        tpCoords,
        layerNutrientN,  self.densityGreater(-1),
        layerFertilizer, self.densityEqual(6),
        3
    )
    -- Increase N(+1) where there is fertilizer 1.3.3
    self.addDensityMasked(
        tpCoords,
        layerNutrientN,  self.densityGreater(-1),
        layerFertilizer, self.densityEqual(7),
        1
    )
    -- Increase N(+1) where there is fertilizer 1.0.0
    self.addDensityMasked(
        tpCoords,
        layerNutrientN,  self.densityGreater(-1),
        layerFertilizer, self.densityEqual(3),
        1
    )
end

function soilmod:fertilizerEffect3_IncreasePK(tpCoords, fruitEntry)
    local layerFertilizer = self:getLayer("fertilizer")
    -- Increase PK(+3) where there is fertilizer 1.3.3
    local layerNutrientPK = self:getLayer("nutrientPK")
    self.addDensityMasked(
        tpCoords,
        layerNutrientPK, self.densityGreater(-1),
        layerFertilizer, self.densityEqual(7),
        3
    )
    -- Increase PK(+2) where there is fertilizer 0.2.2
    self.addDensityMasked(
        tpCoords,
        layerNutrientPK, self.densityGreater(-1),
        layerFertilizer, self.densityEqual(2),
        2
    )
    -- Increase PK(+1) where there is fertilizer 3.1.1
    self.addDensityMasked(
        tpCoords,
        layerNutrientPK, self.densityGreater(-1),
        layerFertilizer, self.densityEqual(6),
        1
    )
    -- Increase PK(+1) where there is fertilizer 0.1.1
    self.addDensityMasked(
        tpCoords,
        layerNutrientPK, self.densityGreater(-1),
        layerFertilizer, self.densityEqual(1),
        1
    )
end

function soilmod:fertilizerEffect4_AffectSoilpH(tpCoords, fruitEntry)
    local layerFertilizer = self:getLayer("fertilizer")
    -- Reduce soil pH where there is fertilizer N
    local layerSoilpH = self:getLayer("soil_pH")
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

--[[

GrowthState     1   2   3   4   5   6   7   8   9   10
Seeded          x
Growing         .   x   x   x   .   .   .
Harvestable                     x   x   x
Defoliaged                                          x
Withered                                    x
Cutted                                          x

StartHealth     2
N(good)          +1  +1  +1      +1  +1            +1
PK(good)                 +1  +1
Moisture(good)   +1  +1      +1  +1                +1
pH(good)             +1  +1                
EndHealth       2   4   7   10  12  14  15


N(bad)           -1  -1  -1      -1  -1            -1
PK(bad)                  -1  -1
Moisture(bad)    -1  -1      -1  -1                -1
pH(bad)              -1  -1

--]]
    
    
    if cellStep == 0 then
        self:cropEffect_ConsumeNutrientN(tpCoords, fruitEntry)
    elseif cellStep == 1 then
        self:cropEffect_ConsumeNutrientPK(tpCoords, fruitEntry)
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

function soilmod:cropEffect_ConsumeNutrientN(tpCoords, fruitEntry)
    -- Increase health(+1) where NutrientN and fruit
    local growthStatesConsumeNutrientN = fruitEntry:get("growthStates_consumeNutrientN", {1,2,3,5,6})
    
    local layerFruit = fruitEntry:getLayer()
    local layerTemp = self:resetIntermediateLayer(tpCoords, 0)
    -- Mark crop areas in intermediate layer
    for _,growthState in pairs(growthStatesConsumeNutrientN) do
        self.setDensityMasked(
            tpCoords, 
            layerTemp,  self.densityGreater(-1), 
            layerFruit, self.densityEqual(growthState),
            1
        )
    end
    -- Remove crop areas from intermediate layer where NutrientN is NOT found
    local layerNutrientN = self:getLayer("nutrientN")
    self.setDensityMasked(
        tpCoords, 
        layerTemp,  self.densityEqual(1), 
        layerNutrientN, self.densityEqual(0),
        0
    )
    -- Increase health where fruit+NutrientN exists
    local layerHealth = self:getLayer("health")
    self.addDensityMasked(
        tpCoords,
        layerHealth, self.densityGreater(-1), 
        layerTemp,   self.densityEqual(1),
        1
    )
    -- Reduce NutrientN
    self.addDensityMasked(
        tpCoords,
        layerNutrientN, self.densityGreater(0), 
        layerTemp,  self.densityEqual(1),
        -1
    )
end

function soilmod:cropEffect_ConsumeNutrientPK(tpCoords, fruitEntry)
    -- Increase health(+1) where NutrientPK and fruit
    local growthStatesConsumeNutrientPK = fruitEntry:get("growthStates_consumeNutrientPK", {3,4})
    
    local layerFruit = fruitEntry:getLayer()
    local layerTemp = self:resetIntermediateLayer(tpCoords, 0)
    -- Mark crop areas in intermediate layer
    for _,growthState in pairs(growthStatesConsumeNutrientPK) do
        self.setDensityMasked(
            tpCoords, 
            layerTemp,  self.densityGreater(-1), 
            layerFruit, self.densityEqual(growthState),
            1
        )
    end
    -- Remove crop areas from intermediate layer where NutrientPK is NOT found
    local layerNutrientPK = self:getLayer("nutrientPK")
    self.setDensityMasked(
        tpCoords, 
        layerTemp,  self.densityEqual(1), 
        layerNutrientPK, self.densityEqual(0),
        0
    )
    -- Increase health where fruit+NutrientN exists
    local layerHealth = self:getLayer("health")
    self.addDensityMasked(
        tpCoords,
        layerHealth, self.densityGreater(-1), 
        layerTemp,   self.densityEqual(1),
        1
    )
    -- Reduce NutrientPK
    self.addDensityMasked(
        tpCoords,
        layerNutrientPK, self.densityGreater(0), 
        layerTemp,   self.densityEqual(1),
        -1
    )
end

function soilmod:cropEffect_ConsumeMoisture(tpCoords, fruitEntry)
    -- Increase health(+1) where good Moisture and fruit
    local growthStatesConsumeMoisture = fruitEntry:get("growthStates_consumeMoisture", {1,2,4,5})
    
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
        layerTemp1,    self.densityGreater(0), 
        layerMoisture, self.densityEqual(0),
        0
    )
    -- Remove crop areas from intermediate-1 layer where Moisture is high
    self.setDensityMasked(
        tpCoords, 
        layerTemp1,    self.densityGreater(0), 
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
    -- Decrease health(-1) where bad soil pH and fruit
    local growthStatesReduceSoilpH = fruitEntry:get("growthStates_reduceSoilpH", {2,3})
    
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
        -1
    )
    -- Reduce Soil pH
    self.addDensityMasked(
        tpCoords,
        layerSoilpH, self.densityGreater(0), 
        layerTemp,   self.densityGreater(0),
        -1
    )
end

function soilmod:cropEffect_IncreaseGrowthState(tpCoords, fruitEntry)
    -- Increase growth-state for crop-type, where growth-delay is zero
    local layerFruit = fruitEntry:getLayer()
    local layerGrowthDelay = self:getLayer("growthDelay")
    
    self.addDensityMasked(
        tpCoords,
        layerFruit,       self.densityBetween(fruitEntry:get("growing_minValue"), fruitEntry:get("growing_maxValue")),
        layerGrowthDelay, self.densityEqual(0),
        1 -- increase
    )
    -- Change ground-type if needed
    if fruitEntry.groundTypeChange ~= nil then
        local layerGround = self:getLayer("terrainGround")
        self.setDensityMasked(
            tpCoords,
            layerGround, self.densityGreater(0),
            layerFruit,  self.densityEqual(2),
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
        -2
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
