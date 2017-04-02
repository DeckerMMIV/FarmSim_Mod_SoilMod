--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-03-xx
--

-- Register this mod for callback from SoilMod's plugin facility
getfenv(0)["modSoilModPlugins"] = getfenv(0)["modSoilModPlugins"] or {}
table.insert(getfenv(0)["modSoilModPlugins"], soilmod)

--
-- This function MUST BE named "soilModPluginCallback" and take two arguments!
-- It is the callback method, that SoilMod's plugin facility will call, to let this mod add its own plugins to SoilMod.
-- The `registry` argument is a 'table of functions' which must be used to add this mod's plugin-functions into SoilMod.
--
function soilmod.soilModPluginCallback(registry,settings)
    -- Gather the required special foliage-layers for SoilMod
    local allOK = soilmod:setupFoliageLayers(registry)

    if allOK then
        soilmod:additionalMethods()
        
        -- Using SoilMod's plugin facility, we add SoilMod's own effects for each of the particular "Utils." functions
        -- To keep my own sanity, all the plugin-functions for each particular "Utils." function, have their own block:
        soilmod:pluginsForCutFruitArea(        registry)
        soilmod:pluginsForUpdateCultivatorArea(registry)
        soilmod:pluginsForUpdatePloughArea(    registry)
        soilmod:pluginsForUpdateSowingArea(    registry)
        soilmod:pluginsForUpdateWeederArea(    registry)
        soilmod:pluginsForUpdateRollerArea(    registry)
        soilmod:pluginsForUpdateSprayArea(     registry)
    end

    return allOK

end

--
function soilmod:setupFoliageLayers(registry)
    -- Register foliage-layers that contains visible graphics (i.e. has material that uses shaders)
    soilmod:registerLayer("slurry"          ,"sm3_slurry"        ,true  ,2)
    soilmod:registerLayer("weed"            ,"sm3_weed"          ,true  ,4)
    soilmod:registerLayer("lime"            ,"sm3_lime"          ,true  ,1)
    soilmod:registerLayer("fertilizer"      ,"sm3_fertilizer"    ,true  ,3)
    soilmod:registerLayer("herbicide"       ,"sm3_herbicide"     ,true  ,2)
    soilmod:registerLayer("water"           ,"sm3_water"         ,true  ,2)
    -- Register foliage-layers that are invisible (i.e. has viewdistance=0 and a material that is "blank")
    soilmod:registerLayer("soil_pH"         ,"sm3_soil_pH"       ,false ,4)
    soilmod:registerLayer("nutrientN"       ,"sm3_nutrientN"     ,false ,4)
    soilmod:registerLayer("nutrientPK"      ,"sm3_nutrientPK"    ,false ,3)
    soilmod:registerLayer("health"          ,"sm3_health"        ,false ,4)
    
    soilmod:registerLayer("moisture"        ,"sm3_moisture"      ,false ,3)
    soilmod:registerLayer("herbicideTime"   ,"sm3_herbicideTime" ,false ,2)
    soilmod:registerLayer("intermediate"    ,"sm3_intermediate"  ,false ,2)
  --soilmod:registerLayer("quality"         ,"sm3_quality"       ,false ,3)
    soilmod:registerLayer("previous"        ,"sm3_previous"      ,false ,3)

    -- Manure, Wetness
    soilmod:registerSpecialLayers()

    --
    local allOk = soilmod:verifyLayers()

    --
    if allOk then
        -- Add the non-visible foliage-layer to be saved too.
        table.insert(g_currentMission.dynamicFoliageLayers, soilmod:getLayerId("soil_pH"))

        -- Allow weeds to be destroyed too
        soilmod:addDestructibleFoliageId(soilmod:getLayerId("weed"))

        -- Try to "optimize" a for-loop in UpdateFoliage()
        soilmod.foliageLayersCrops = {}
        for _,fruit in pairs(g_currentMission.fruits) do
            if fruit.id ~= nil and fruit.id ~= 0 then
                local foliageName = (getName(fruit.id)):lower()

                -- Default benefits.
                local props = {
                    fruit       = fruit,
                    plough      = { minGrowthState=3, maxGrowthState=8, nutrientN=5, nutrientPK=1   },
                    cultivate   = { minGrowthState=3, maxGrowthState=8, nutrientN=2, nutrientPK=nil },
                }

                if foliageName:find("grass") ~= nil then
                    -- Any grass/dryGrass will not produce any benefits.
                    props = nil
                elseif false
                    -- 'Alfalfa' and in German too
                    or foliageName:find("alfalfa") ~= nil 
                    or foliageName:find("luzerne") ~= nil
                    or foliageName:find("lucerne") ~= nil
                    or foliageName:find("luzern")  ~= nil
                    -- 'Clover' and in German too
                    or foliageName:find("clover")  ~= nil 
                    or foliageName:find("klee")    ~= nil
                    --
                    then
                    -- https://github.com/DeckerMMIV/FarmSim_Mod_SoilMod/issues/66
                    -- Slightly change the benefits of ploughing/cultivating 'alfalfa' or 'clover'.
                    props.plough.minGrowthState = 2 -- Include growth-stage #2, due to WheelLanes mod
                    props.plough.nutrientN  = 4
                    props.plough.nutrientPK = 2
                    props.cultivate.minGrowthState = 2 -- Include growth-stage #2, due to WheelLanes mod
                    props.cultivate.nutrientN  = 1
                    props.cultivate.nutrientPK = nil
                end

                if props ~= nil then
                    table.insert(soilmod.foliageLayersCrops, props)
                end
            end
        end
    end

    return allOk
end

--
function soilmod:pluginsForCutFruitArea(registry)
    --
    -- Additional effects for the Utils.CutFruitArea()
    --

    --
    registry.addPlugin_CutFruitArea_after(
        "Volume affected if partial-growth-state for crop",
        5,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            -- SoilManagement does not use spray for "yield".
            dataStore.spraySum = 0
            if fruitDesc.allowsPartialGrowthState then
                dataStore.volume = dataStore.pixelsSum / fruitDesc.maxHarvestingGrowthState
            end
        end
    )

    ----
    --registry.addPlugin_CutFruitArea_before(
    --    "Set sowing-channel where min/max-harvesting-growth-state is",
    --    10,
    --    function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
    --        if fruitDesc.useSeedingWidth and (dataStore.destroySeedingWidth == nil or dataStore.destroySeedingWidth) then
    --            setDensityMaskParams(g_currentMission.terrainDetailId, "between", dataStore.minHarvestingGrowthState, dataStore.maxHarvestingGrowthState);
    --            setDensityMaskedParallelogram(
    --                g_currentMission.terrainDetailId,
    --                sx,sz,wx,wz,hx,hz,
    --                g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels,
    --                dataStore.fruitFoliageId, 0, g_currentMission.numFruitStateChannels,
    --                2^g_currentMission.sowingChannel  -- value
    --            );
    --            --setDensityMaskParams(g_currentMission.terrainDetailId, "greater", 0);
    --        end
    --    end
    --)

    --
    local layerId_Weed = soilmod:getLayerId("weed")
    registry.addPlugin_CutFruitArea_before(
        "Get weed density and cut weed",
        20,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            -- Get weeds, but only the lower 2 bits (values 0-3), and then set them to zero.
            -- This way weed gets cut, but alive weed will still grow again.
            setDensityCompareParams(layerId_Weed, "greater", 0)
            local oldSum, numPixels, newDelta = setDensityParallelogram(layerId_Weed, sx,sz,wx,wz,hx,hz, 0,2, 0)
            dataStore.weeds = { oldSum=oldSum, numPixels=numPixels, newDelta=newDelta }
        end
    )
    registry.addPlugin_CutFruitArea_after(
        "Volume is affected by percentage of weeds",
        20,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            local weeds = dataStore.weeds
            if weeds.numPixels > 0 and dataStore.numPixels > 0 then
                weeds.weedPct = (weeds.oldSum / (3 * weeds.numPixels)) * (weeds.numPixels / dataStore.numPixels)
                -- Remove some volume that weeds occupy.
                dataStore.volume = math.max(0, dataStore.volume - (dataStore.volume * weeds.weedPct))
            end
        end
    )

    --
    local layerId_Health = soilmod:getLayerId("health")
    registry.addPlugin_CutFruitArea_before(
        "Get crop-health density",
        25,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            -- Get health
            setDensityCompareParams(layerId_Health, "greater", -1)
            local sumPixels, numPixels, totPixels = getDensityParallelogram(layerId_Health, sx,sz,wx,wz,hx,hz, 0,4)
            dataStore.health = {sumPixels=sumPixels, numPixels=numPixels, totPixels=totPixels}
        end
    )
    registry.addPlugin_CutFruitArea_after(
        "Volume is affected by crop-health",
        25,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            local health = dataStore.health
            if health.numPixels > 0 then
                health.factor = health.sumPixels / health.numPixels
                --local nutrientLevel = health.sumPixels / health.numPixels
                --health.factor = soilmod.nutrientNCurve:get(nutrientLevel)
--log("FertN: s",health.sumPixels," n",health.numPixels," t",health.totPixels," / l",nutrientLevel," f",factor)
                dataStore.volume = dataStore.volume + (dataStore.volume * health.factor)
            end
        end
    )

--[[    
    -- TODO - Try to add for different fruit-types.
    soilmod.nutrientNCurve = AnimCurve:new(linearInterpolator1)
    soilmod.nutrientNCurve:addKeyframe({ v=0.00, time= 0 })
    soilmod.nutrientNCurve:addKeyframe({ v=0.20, time= 1 })
    soilmod.nutrientNCurve:addKeyframe({ v=0.50, time= 2 })
    soilmod.nutrientNCurve:addKeyframe({ v=0.70, time= 3 })
    soilmod.nutrientNCurve:addKeyframe({ v=0.90, time= 4 })
    soilmod.nutrientNCurve:addKeyframe({ v=1.00, time= 5 })
    soilmod.nutrientNCurve:addKeyframe({ v=0.50, time=15 })

    local layerId_FertN = soilmod:getLayerId("nutrientN")
    registry.addPlugin_CutFruitArea_before(
        "Get nutrient-N density",
        30,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            -- Get N
            setDensityCompareParams(layerId_FertN, "greater", 0)
            local sumPixels, numPixels, totPixels = getDensityParallelogram(layerId_FertN, sx,sz,wx,wz,hx,hz, 0,4)
            dataStore.nutrientN = {sumPixels=sumPixels, numPixels=numPixels, totPixels=totPixels}
        end
    )
    registry.addPlugin_CutFruitArea_after(
        "Volume is affected by nutrient-N",
        30,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            local nutrientN = dataStore.nutrientN
            if nutrientN.numPixels > 0 then
                local nutrientLevel = nutrientN.sumPixels / nutrientN.numPixels
                nutrientN.factor = soilmod.nutrientNCurve:get(nutrientLevel)
--log("FertN: s",nutrientN.sumPixels," n",nutrientN.numPixels," t",nutrientN.totPixels," / l",nutrientLevel," f",factor)
                dataStore.volume = dataStore.volume + (dataStore.volume * nutrientN.factor)
            end
        end
    )

    -- TODO - Try to add for different fruit-types.
    soilmod.nutrientPKCurve = AnimCurve:new(linearInterpolator1)
    soilmod.nutrientPKCurve:addKeyframe({ v=0.00, time= 0 })
    soilmod.nutrientPKCurve:addKeyframe({ v=0.10, time= 1 })
    soilmod.nutrientPKCurve:addKeyframe({ v=0.30, time= 2 })
    soilmod.nutrientPKCurve:addKeyframe({ v=0.80, time= 3 })
    soilmod.nutrientPKCurve:addKeyframe({ v=1.00, time= 4 })
    soilmod.nutrientPKCurve:addKeyframe({ v=0.30, time= 7 })

    local layerId_NutrientPK = soilmod:getLayerId("nutrientPK")
    registry.addPlugin_CutFruitArea_before(
        "Get nutrient-PK density",
        40,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            -- Get PK
            setDensityCompareParams(layerId_NutrientPK, "greater", 0)
            local sumPixels, numPixels, totPixels = getDensityParallelogram(layerId_NutrientPK, sx,sz,wx,wz,hx,hz, 0,3)
            dataStore.nutrientPK = {sumPixels=sumPixels, numPixels=numPixels, totPixels=totPixels}
        end
    )
    registry.addPlugin_CutFruitArea_after(
        "Volume is slightly boosted by nutrient-PK",
        40,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            local nutrientPK = dataStore.nutrientPK
            if nutrientPK.numPixels > 0 then
                local nutrientLevel = nutrientPK.sumPixels / nutrientPK.numPixels
                nutrientPK.factor = soilmod.nutrientPKCurve:get(nutrientLevel)
                local volumeBoost = (dataStore.numPixels * nutrientPK.factor) / 2
--log("NutrientPK: s",nutrientPK.sumPixels," n",nutrientPK.numPixels," t",nutrientPK.totPixels," / l",nutrientLevel," b",volumeBoost)
                dataStore.volume = dataStore.volume + volumeBoost
            end
        end
    )

    -- TODO - Try to add for different fruit-types.
    soilmod.pHCurve = AnimCurve:new(linearInterpolator1)
    soilmod.pHCurve:addKeyframe({ v=0.20, time= 0 })
    soilmod.pHCurve:addKeyframe({ v=0.70, time= 1 })
    soilmod.pHCurve:addKeyframe({ v=0.80, time= 2 })
    soilmod.pHCurve:addKeyframe({ v=0.85, time= 3 })
    soilmod.pHCurve:addKeyframe({ v=0.90, time= 4 })
    soilmod.pHCurve:addKeyframe({ v=0.94, time= 5 })
    soilmod.pHCurve:addKeyframe({ v=0.97, time= 6 })
    soilmod.pHCurve:addKeyframe({ v=1.00, time= 7 }) -- neutral
    soilmod.pHCurve:addKeyframe({ v=0.98, time= 8 })
    soilmod.pHCurve:addKeyframe({ v=0.95, time= 9 })
    soilmod.pHCurve:addKeyframe({ v=0.91, time=10 })
    soilmod.pHCurve:addKeyframe({ v=0.87, time=11 })
    soilmod.pHCurve:addKeyframe({ v=0.84, time=12 })
    soilmod.pHCurve:addKeyframe({ v=0.80, time=13 })
    soilmod.pHCurve:addKeyframe({ v=0.76, time=14 })
    soilmod.pHCurve:addKeyframe({ v=0.50, time=15 })

    local layerId_SoilpH = soilmod:getLayerId("soil_pH")
    registry.addPlugin_CutFruitArea_before(
        "Get soil pH density",
        50,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            -- Get soil pH
            setDensityCompareParams(layerId_SoilpH, "greater", 0)
            local sumPixels, numPixels, totPixels = getDensityParallelogram(layerId_SoilpH, sx,sz,wx,wz,hx,hz, 0,4)
            dataStore.soilpH = {sumPixels=sumPixels, numPixels=numPixels, totPixels=totPixels}
        end
    )
    registry.addPlugin_CutFruitArea_after(
        "Volume is affected by soil pH level",
        50,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            local soilpH = dataStore.soilpH
            if soilpH.totPixels > 0 then
                local pHFactor = soilpH.sumPixels / soilpH.totPixels
                soilpH.factor = soilmod.pHCurve:get(pHFactor)
--log("soil pH: s",soilpH.sumPixels," n",soilpH.numPixels," t",soilpH.totPixels," / f",pHFactor," c",factor)
                dataStore.volume = dataStore.volume * soilpH.factor
            end
        end
    )
--]]
    -- TODO - Try to add for different fruit-types.
    soilmod.moistureCurve = AnimCurve:new(linearInterpolator1)
    soilmod.moistureCurve:addKeyframe({ v=0.50, time=0 })
    soilmod.moistureCurve:addKeyframe({ v=0.70, time=1 })
    soilmod.moistureCurve:addKeyframe({ v=0.85, time=2 })
    soilmod.moistureCurve:addKeyframe({ v=0.98, time=3 })
    soilmod.moistureCurve:addKeyframe({ v=1.00, time=4 })
    soilmod.moistureCurve:addKeyframe({ v=0.96, time=5 })
    soilmod.moistureCurve:addKeyframe({ v=0.93, time=6 })
    soilmod.moistureCurve:addKeyframe({ v=0.70, time=7 })

    local layerId_Moisture = soilmod:getLayerId("moisture")
    registry.addPlugin_CutFruitArea_before(
        "Get water-moisture",
        60,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            setDensityCompareParams(layerId_Moisture, "greater", 0)
            local sumPixels, numPixels, totPixels = getDensityParallelogram(layerId_Moisture, sx,sz,wx,wz,hx,hz, 0,3)
            dataStore.moisture = {sumPixels=sumPixels, numPixels=numPixels, totPixels=totPixels}
        end
    )
    registry.addPlugin_CutFruitArea_after(
        "Volume is affected by water-moisture",
        60,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            local moisture = dataStore.moisture
            if moisture.totPixels > 0 then
                local moistureFactor = moisture.sumPixels / moisture.totPixels
                moisture.factor = soilmod.moistureCurve:get(moistureFactor)
--log("moisture: s",moisture.sumPixels," n",moisture.numPixels," t",moisture.totPixels," / f",moistureFactor," c",factor)
                dataStore.volume = dataStore.volume * moisture.factor
            end
        end
    )

--[[
    --
    PREVIOUSTYPE_GENERIC = 0
    PREVIOUSTYPE_GRAIN   = 1
    PREVIOUSTYPE_ROOT    = 2
    PREVIOUSTYPE_STALK   = 3
    
    soilmod.fruitToPrevious = {}

    soilmod.fruitToPrevious[FruitUtil.FRUITTYPE_WHEAT]    = PREVIOUSTYPE_GRAIN
    soilmod.fruitToPrevious[FruitUtil.FRUITTYPE_BARLEY]   = PREVIOUSTYPE_GRAIN
    soilmod.fruitToPrevious[FruitUtil.FRUITTYPE_RAPE]     = PREVIOUSTYPE_GRAIN
    soilmod.fruitToPrevious[FruitUtil.FRUITTYPE_SOYBEAN]  = PREVIOUSTYPE_GRAIN

    soilmod.fruitToPrevious[FruitUtil.FRUITTYPE_POTATO]   = PREVIOUSTYPE_ROOT
    soilmod.fruitToPrevious[FruitUtil.FRUITTYPE_SUGARBEET]= PREVIOUSTYPE_ROOT
    
    soilmod.fruitToPrevious[FruitUtil.FRUITTYPE_MAIZE]    = PREVIOUSTYPE_STALK
    soilmod.fruitToPrevious[FruitUtil.FRUITTYPE_SUNFLOWER]= PREVIOUSTYPE_STALK
    soilmod.fruitToPrevious[FruitUtil.FRUITTYPE_POPLAR]   = PREVIOUSTYPE_STALK

    local layerId_Previous = soilmod:getLayerId("previous")
    registry.addPlugin_CutFruitArea_before(
        "Set as previous crop",
        70,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            local previousType = Utils.getNoNil(soilmod.fruitToPrevious[fruitDesc.index], 0)
            setDensityCompareParams(layerId_Previous, "greater", -1)
            setDensityMaskParams(layerId_Previous, "between", 5,7)
            setDensityMaskedParallelogram(
                layerId_Previous, 
                sx,sz,wx,wz,hx,hz, 
                0,2,
                dataStore.fruitFoliageId, 0,4,
                previousType
            )
        end
    )
--]]
    
--DEBUG
    registry.addPlugin_CutFruitArea_after(
        "Debug graph",
        99,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            if soilmod.debugGraph and soilmod.debugGraphOn then
                soilmod.debugGraphAddValue(1, (dataStore.numPixels>0 and (dataStore.volume/dataStore.numPixels) or nil), dataStore.pixelsSum, dataStore.numPixels, 0)
                soilmod.debugGraphAddValue(2, Utils.getNoNil(dataStore.weeds.weedPct  ,0)    ,dataStore.weeds.oldSum         ,dataStore.weeds.numPixels      ,dataStore.weeds.newDelta       )
                soilmod.debugGraphAddValue(3, Utils.getNoNil(dataStore.health.factor  ,0)    ,dataStore.nutrientN.sumPixels      ,dataStore.health.numPixels     ,dataStore.health.totPixels     )
              --soilmod.debugGraphAddValue(3, Utils.getNoNil(dataStore.nutrientN.factor   ,0)    ,dataStore.nutrientN.sumPixels      ,dataStore.nutrientN.numPixels      ,dataStore.nutrientN.totPixels      )
              --soilmod.debugGraphAddValue(4, Utils.getNoNil(dataStore.nutrientPK.factor  ,0)    ,dataStore.nutrientPK.sumPixels     ,dataStore.nutrientPK.numPixels     ,dataStore.nutrientPK.totPixels     )
              --soilmod.debugGraphAddValue(5, Utils.getNoNil(dataStore.soilpH.factor  ,0)    ,dataStore.soilpH.sumPixels     ,dataStore.soilpH.numPixels     ,dataStore.soilpH.totPixels     )
                soilmod.debugGraphAddValue(6, Utils.getNoNil(dataStore.moisture.factor,0)    ,dataStore.moisture.sumPixels   ,dataStore.moisture.numPixels   ,dataStore.moisture.totPixels   )
            end
        end
    )
--DEBUG]]
end

--
function soilmod:additionalMethods()
    soilmod.TOOLTYPE_UNKNOWN    = 2^0
    soilmod.TOOLTYPE_PLOUGH     = 2^1
    soilmod.TOOLTYPE_CULTIVATOR = 2^2
    soilmod.TOOLTYPE_SEEDER     = 2^3
    soilmod.TOOLTYPE_WEEDER     = 2^4
    soilmod.TOOLTYPE_ROLLER     = 2^5

    --
    local layerId_NutrientN     = soilmod:getLayerId("nutrientN")
    local layerId_NutrientPK    = soilmod:getLayerId("nutrientPK")
    local layerId_Soil_pH       = soilmod:getLayerId("soil_pH")
    local layerId_Slurry        = soilmod:getLayerId("slurry")
    local layerId_Lime          = soilmod:getLayerId("lime")
    local layerId_Weed          = soilmod:getLayerId("weed")
    
    soilmod.UpdateFoliage = function(sx,sz,wx,wz,hx,hz, isForced, implementType)
        setDensityCompareParams(layerId_NutrientN,  "greater", 0)
        setDensityCompareParams(layerId_NutrientPK, "greater", 0)
            
        if implementType == soilmod.TOOLTYPE_PLOUGH then
            -- Increase NutrientN/NutrientPK where there's crops at specific growth-stages
            for _,props in pairs(soilmod.foliageLayersCrops) do
                if props.plough.nutrientN ~= nil then
                    setDensityMaskParams(         layerId_NutrientN,  "between", props.plough.minGrowthState, props.plough.maxGrowthState)
                    addDensityMaskedParallelogram(layerId_NutrientN,  sx,sz,wx,wz,hx,hz, 0,4, props.fruit.id, 0,g_currentMission.numFruitStateChannels, props.plough.nutrientN);
                end
                if props.plough.nutrientPK ~= nil then
                    setDensityMaskParams(         layerId_NutrientPK, "between", props.plough.minGrowthState, props.plough.maxGrowthState)
                    addDensityMaskedParallelogram(layerId_NutrientPK, sx,sz,wx,wz,hx,hz, 0,3, props.fruit.id, 0,g_currentMission.numFruitStateChannels, props.plough.nutrientPK);
                end
            end
    
            -- Increase NutrientN +10 where there's solidManure
            setDensityMaskParams(         layerId_NutrientN, "greater", 1)
            addDensityMaskedParallelogram(layerId_NutrientN,  sx,sz,wx,wz,hx,hz, 0,4, g_currentMission.terrainDetailId, g_currentMission.sprayFirstChannel,g_currentMission.sprayNumChannels, 10);
    
            ---- Increase NutrientN +3 where there's windrow
            --for _,fruit in pairs(soilmod.sm3FoliageLayersWindrows) do
            --    addDensityMaskedParallelogram(layerId_NutrientN,  sx,sz,wx,wz,hx,hz, 0, 4, fruit.windrowId, 0,g_currentMission.numWindrowChannels, 3);
            --end
    
            -- Increase NutrientPK +4 where there's solidManure
            setDensityMaskParams(         layerId_NutrientPK, "greater", 1)
            addDensityMaskedParallelogram(layerId_NutrientPK,  sx,sz,wx,wz,hx,hz, 0,3, g_currentMission.terrainDetailId, g_currentMission.sprayFirstChannel,g_currentMission.sprayNumChannels, 4);
        else
            -- Increase NutrientN/NutrientPK where there's crops at specific growth-stages
            for _,props in pairs(soilmod.foliageLayersCrops) do
                if props.cultivate.nutrientN ~= nil then
                    setDensityMaskParams(         layerId_NutrientN,  "between", props.cultivate.minGrowthState, props.cultivate.maxGrowthState)
                    addDensityMaskedParallelogram(layerId_NutrientN,  sx,sz,wx,wz,hx,hz, 0,4, props.fruit.id, 0,g_currentMission.numFruitStateChannels, props.cultivate.nutrientN);
                end
                if props.cultivate.nutrientPK ~= nil then
                    setDensityMaskParams(         layerId_NutrientPK, "between", props.cultivate.minGrowthState, props.cultivate.maxGrowthState)
                    addDensityMaskedParallelogram(layerId_NutrientPK, sx,sz,wx,wz,hx,hz, 0,3, props.fruit.id, 0,g_currentMission.numFruitStateChannels, props.cultivate.nutrientPK);
                end
            end
    
            -- Increase NutrientN +6 where there's solidManure
            setDensityMaskParams(         layerId_NutrientN, "greater", 1)
            addDensityMaskedParallelogram(layerId_NutrientN,  sx,sz,wx,wz,hx,hz, 0,4, g_currentMission.terrainDetailId, g_currentMission.sprayFirstChannel,g_currentMission.sprayNumChannels, 6);
    
            ---- Increase NutrientN +1 where there's windrow
            --for _,fruit in pairs(soilmod.sm3FoliageLayersWindrows) do
            --    addDensityMaskedParallelogram(layerId_NutrientN,  sx,sz,wx,wz,hx,hz, 0, 4, fruit.windrowId, 0,g_currentMission.numWindrowChannels, 1);
            --end
    
            -- Increase NutrientPK +2 where there's solidManure
            setDensityMaskParams(         layerId_NutrientPK, "greater", 1)
            addDensityMaskedParallelogram(layerId_NutrientPK,  sx,sz,wx,wz,hx,hz, 0,3, g_currentMission.terrainDetailId, g_currentMission.sprayFirstChannel,g_currentMission.sprayNumChannels, 2);
        end
    
        -- Increase soil pH where there's lime
        setDensityCompareParams(      layerId_Soil_pH, "greater", 0)
        setDensityMaskParams(         layerId_Soil_pH, "greater", 0)
        addDensityMaskedParallelogram(layerId_Soil_pH,  sx,sz,wx,wz,hx,hz, 0,4, layerId_Lime, 0,1, 4);
    
        -- Special case for slurry, due to ZunHammer and instant cultivating.
        setDensityCompareParams(      layerId_Slurry, "greater", 1) -- ignore 1=plantkiller
        setDensityMaskParams(         layerId_Slurry, "equal", 3); -- 3=visible slurry
        setDensityMaskedParallelogram(layerId_Slurry, sx,sz,wx,wz,hx,hz, 0,2, layerId_Slurry, 0,2, 2) -- 2=invisible slurry
    
        -- Remove the manure (but keep the spray/wetness) we've just cultivated/ploughed into ground.
        setDensityCompareParams(g_currentMission.terrainDetailId, "greater", 0)
        setDensityParallelogram(g_currentMission.terrainDetailId, sx,sz,wx,wz,hx,hz, g_currentMission.sprayFirstChannel+1,1, 0)
        
        -- Remove the lime we've just cultivated/ploughed into ground.
        setDensityCompareParams(layerId_Lime, "greater", 0)
        setDensityParallelogram(layerId_Lime, sx,sz,wx,wz,hx,hz, 0,1, 0)
    
        -- Remove weed plants - where we're cultivating/ploughing.
        setDensityCompareParams(layerId_Weed, "greater", 0)
        setDensityParallelogram(layerId_Weed, sx,sz,wx,wz,hx,hz, 0,4, 0)
    end
end

--
function soilmod:pluginsForUpdateCultivatorArea(registry)
    --
    -- Additional effects for the Utils.UpdateCultivatorArea()
    --

    registry.addPlugin_UpdateCultivatorArea_before(
        "Update foliage-layer for SoilMod",
        20,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            soilmod.UpdateFoliage(sx,sz,wx,wz,hx,hz, dataStore.forced, soilmod.TOOLTYPE_CULTIVATOR)
        end
    )

    registry.addPlugin_UpdateCultivatorArea_before(
        "Destroy common area",
        30,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            Utils.sm3DestroyCommonArea(sx,sz,wx,wz,hx,hz, not dataStore.commonForced, soilmod.TOOLTYPE_CULTIVATOR);
        end
    )

    --local layerId_Fertilizer = soilmod:getLayerId("fertilizer")
    --registry.addPlugin_UpdateCultivatorArea_before(
    --    "Cultivator changes solid-fertilizer(visible) to liquid-fertilizer(invisible)",
    --    41,
    --    function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
    --        -- Where masked 'greater than 4', then set most-significant-bit to zero
    --        setDensityCompareParams(      layerId_Fertilizer, "greater", 0)
    --        setDensityMaskParams(         layerId_Fertilizer, "greater", 4)
    --        setDensityMaskedParallelogram(layerId_Fertilizer, sx,sz,wx,wz,hx,hz, 2,1, layerId_Fertilizer, 0,3, 0);
    --    end
    --)

end

--
function soilmod:pluginsForUpdatePloughArea(registry)
    --
    -- Additional effects for the Utils.UpdatePloughArea()
    --

    registry.addPlugin_UpdatePloughArea_before(
        "Update foliage-layer for SoilMod",
        20,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            soilmod.UpdateFoliage(sx,sz,wx,wz,hx,hz, dataStore.forced, soilmod.TOOLTYPE_PLOUGH)
        end
    )

    registry.addPlugin_UpdatePloughArea_before(
        "Destroy common area",
        30,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            Utils.sm3DestroyCommonArea(sx,sz,wx,wz,hx,hz, not dataStore.commonForced, soilmod.TOOLTYPE_PLOUGH);
        end
    )

    --local layerId_Fertilizer = soilmod:getLayerId("fertilizer")
    --registry.addPlugin_UpdatePloughArea_before(
    --    "Ploughing changes solid-fertilizer(visible) to liquid-fertilizer(invisible)",
    --    41,
    --    function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
    --        -- Where masked 'greater than 4', then set most-significant-bit to zero
    --        setDensityCompareParams(      layerId_Fertilizer, "greater", 0)
    --        setDensityMaskParams(         layerId_Fertilizer, "greater", 4)
    --        setDensityMaskedParallelogram(layerId_Fertilizer, sx,sz,wx,wz,hx,hz, 2,1, layerId_Fertilizer, 0,3, 0);
    --    end
    --)

    local layerId_Water = soilmod:getLayerId("water")
    registry.addPlugin_UpdatePloughArea_after(
        "Plouging should reduce water-level",
        40,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            setDensityParallelogram(layerId_Water, sx,sz,wx,wz,hx,hz, 0,2, 1);
        end
    )

end

--
function soilmod:pluginsForUpdateSowingArea(registry)
    --
    -- Additional effects for the Utils.UpdateSowingArea()
    --

    local layerId_Weed = soilmod:getLayerId("weed")
    registry.addPlugin_UpdateSowingArea_before(
        "Destroy weed plants when sowing",
        30,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            -- Remove weed plants - where we're seeding.
            setDensityCompareParams(layerId_Weed, "greater", 0)
            setDensityParallelogram(layerId_Weed, sx,sz,wx,wz,hx,hz, 0,4, 0)
        end
    )

    local layerId_Health = soilmod:getLayerId("health")
    registry.addPlugin_UpdateSowingArea_after(
        "Give seeded crops a bit of starting health",
        30,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            -- Set start health for seeded crops
            setDensityCompareParams(layerId_Health, "greater", -1)
            setDensityParallelogram(layerId_Health, sx,sz,wx,wz,hx,hz, 0,4, 2)
        end
    )
    
    local layerId_GrowthDelay = soilmod:getLayerId("growthDelay")
    registry.addPlugin_UpdateSowingArea_after(
        "Seeding sets 'initial growth-delay'",
        31,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            setDensityCompareParams(      layerId_GrowthDelay, "greater", -1)
            setDensityMaskParams(         layerId_GrowthDelay, "equal", dataStore.plantValue);
            setDensityMaskedParallelogram(layerId_GrowthDelay, sx,sz,wx,wz,hx,hz, 0,2, dataStore.fruitFoliageId, 0,4, 3)
        end
    )
    
end

--
function soilmod:pluginsForUpdateWeederArea(registry)
    --
    -- Effects for the Utils.updateWeederArea()
    --

    local layerId_Weed = soilmod:getLayerId("weed")
    registry.addPlugin_UpdateWeederArea_after(
        "Weeder removes weed-plants",
        20,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            -- Remove weed plants
            setDensityCompareParams(layerId_Weed, "greater", 0)
            setDensityParallelogram(layerId_Weed, sx,sz,wx,wz,hx,hz, 0,4, 0)
            
            -- Remove crops if they are in growth-state 4-8
            for _,props in pairs(soilmod.foliageLayersCrops) do
                setDensityCompareParams(props.fruit.id, "between", 4, 8);
                setDensityParallelogram(props.fruit.id, sx,sz,wx,wz,hx,hz, 0,g_currentMission.numFruitStateChannels, 0)
                --setDensityCompareParams(props.fruit.id, "greater", -1);
            end
        end
    )

    local layerId_HerbicideTime = soilmod:getLayerId("herbicideTime")
    registry.addPlugin_UpdateWeederArea_after(
        "Weeder gives 2 days weed-prevention",
        30,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            setDensityCompareParams(layerId_HerbicideTime, "greater", -1)
            setDensityMaskParams(   layerId_HerbicideTime, "between", 0,1);
            setDensityMaskedParallelogram(layerId_HerbicideTime, sx,sz,wx,wz,hx,hz, 0,2, layerId_HerbicideTime, 0,2, 2)
        end
    )
    
end

--
function soilmod:pluginsForUpdateRollerArea(registry)
    --
    -- Effects for the Utils.updateRollerArea()
    --

    registry.addPlugin_UpdateRollerArea_before(
        "Roller removes manure",
        20,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            -- Remove manure (but not wetness)
            setDensityCompareParams(g_currentMission.terrainDetailId, "greater", 0)
            setDensityParallelogram(g_currentMission.terrainDetailId, sx,sz,wx,wz,hx,hz, g_currentMission.sprayFirstChannel+1,1, 0)
        end
    )

    local layerId_Slurry = soilmod:getLayerId("slurry")
    registry.addPlugin_UpdateRollerArea_before(
        "Roller removes visible slurry",
        21,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            -- Remove visible slurry
            setDensityCompareParams(layerId_Slurry, "greater", 0)
            setDensityMaskParams(   layerId_Slurry, "greater", 0);
            setDensityMaskedParallelogram(layerId_Slurry, sx,sz,wx,wz,hx,hz, 0,1, layerId_Slurry, 0,1, 0)
        end
    )

    local layerId_Lime = soilmod:getLayerId("lime")
    registry.addPlugin_UpdateRollerArea_before(
        "Roller removes lime",
        22,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            -- Remove the lime
            setDensityCompareParams(layerId_Lime, "greater", 0)
            setDensityParallelogram(layerId_Lime, sx,sz,wx,wz,hx,hz, 0,1, 0)
        end
    )

    local layerId_Weed = soilmod:getLayerId("weed")
    registry.addPlugin_UpdateRollerArea_before(
        "Roller removes weed-plants",
        23,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            -- Remove weed plants
            setDensityCompareParams(layerId_Weed, "greater", 0)
            setDensityParallelogram(layerId_Weed, sx,sz,wx,wz,hx,hz, 0,4, 0)
        end
    )

    local layerId_Fertilizer = soilmod:getLayerId("fertilizer")
    registry.addPlugin_UpdateRollerArea_before(
        "Roller removes fertilizer",
        24,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            -- Remove fertilizer
            setDensityCompareParams(layerId_Fertilizer, "greater", 0)
            setDensityParallelogram(layerId_Fertilizer, sx,sz,wx,wz,hx,hz, 0,3, 0)
        end
    )

end

--
function soilmod:pluginsForUpdateSprayArea(registry)
    --
    -- Additional effects for the Utils.UpdateSprayArea()
    --
--[[
    -- Broadcast spreader
    if FillUtil.FILLTYPE_RAPE ~= nil and FruitUtil.FRUITTYPE_RAPE ~= nil then
        local fruitId     = g_currentMission.fruits[ FruitUtil.FRUITTYPE_RAPE ].id;
        registry.addPlugin_UpdateSprayArea_fillType(
            "Broadcast spreader; canola",
            10,
            FillUtil.FILLTYPE_RAPE,
            function(sx,sz,wx,wz,hx,hz, dataStore)
                local excludeMask = nil -- 2^g_currentMission.sowingChannel + 2^g_currentMission.sowingWidthChannel;
                local includeMask = 2^g_currentMission.ploughChannel + 2^g_currentMission.cultivatorChannel;
                setDensityMaskParams(fruitId, "greater", 0, 0, includeMask, excludeMask);
                setDensityCompareParams(fruitId, "equals", 0);
                setDensityMaskedParallelogram(
                    fruitId, 
                    sx,sz,wx,wz,hx,hz, 
                    0, g_currentMission.numFruitDensityMapChannels, 
                    g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, 
                    1
                );
    
                --setDensityParallelogram(
                --    g_currentMission.terrainDetailId, 
                --    sx,sz,wx,wz,hx,hz, 
                --    g_currentMission.terrainDetailAngleFirstChannel, g_currentMission.terrainDetailAngleNumChannels, 
                --    dataStore.angle
                --);
                
                dataStore.moistureValue = 0 -- No moisture!
            end
        )
    end
--]]    
    --
    registry.addPlugin_UpdateSprayArea_fillType(
        "Spread manure(solid)",
        10,
        FillUtil.FILLTYPE_MANURE,
        function(sx,sz,wx,wz,hx,hz, dataStore)
            dataStore.moistureValue = 2 -- Place manure
        end
    )

    --
    local layerId_Slurry = soilmod:getLayerId("slurry")
    registry.addPlugin_UpdateSprayArea_fillType(
        "Spray plantKiller(liquid)",
        10,
        FillUtil.FILLTYPE_PLANTKILLER,
        function(sx,sz,wx,wz,hx,hz, dataStore)
            setDensityCompareParams(layerId_Slurry, "greater", -1)
            setDensityParallelogram(layerId_Slurry, sx,sz,wx,wz,hx,hz, 0,2, 1)  -- invisible
            dataStore.moistureValue = 1 -- Place moisture!
        end
    )
    registry.addPlugin_UpdateSprayArea_fillType(
        "Spread liquidManure(liquid)",
        10,
        FillUtil.FILLTYPE_LIQUIDMANURE,
        function(sx,sz,wx,wz,hx,hz, dataStore)
            setDensityCompareParams(layerId_Slurry, "greater", -1)
            setDensityParallelogram(layerId_Slurry, sx,sz,wx,wz,hx,hz, 0,2, 3); -- slurry visible, and invisible
            dataStore.moistureValue = 1 -- Place moisture!
        end
    )
    registry.addPlugin_UpdateSprayArea_fillType(
        "Spread digestate(liquid)",
        10,
        FillUtil.FILLTYPE_DIGESTATE,
        function(sx,sz,wx,wz,hx,hz, dataStore)
            setDensityCompareParams(layerId_Slurry, "greater", -1)
            setDensityParallelogram(layerId_Slurry, sx,sz,wx,wz,hx,hz, 0,2, 3); -- slurry visible, and invisible
            dataStore.moistureValue = 1 -- Place moisture!
        end
    )

    --
    local layerId_Water = soilmod:getLayerId("water")
    registry.addPlugin_UpdateSprayArea_fillType(
        "Spray water(liquid)",
        10,
        FillUtil.FILLTYPE_WATER,
        function(sx,sz,wx,wz,hx,hz, dataStore)
            setDensityCompareParams(layerId_Water, "greater", -1)
            setDensityParallelogram(layerId_Water, sx,sz,wx,wz,hx,hz, 0,2, 2); -- water +1
            dataStore.moistureValue = 1 -- Place moisture!
        end
    )
    registry.addPlugin_UpdateSprayArea_fillType(
        "Spray water2(liquid)",
        10,
        FillUtil.FILLTYPE_WATER2,
        function(sx,sz,wx,wz,hx,hz, dataStore)
            setDensityCompareParams(layerId_Water, "greater", -1)
            setDensityParallelogram(layerId_Water, sx,sz,wx,wz,hx,hz, 0,2, 3); -- water +2
            dataStore.moistureValue = 1 -- Place moisture!
        end
    )

    --
    local layerId_Lime = soilmod:getLayerId("lime")
    registry.addPlugin_UpdateSprayArea_fillType(
        "Spread lime/kalk(solid)",
        10,
        FillUtil.FILLTYPE_LIME,
        function(sx,sz,wx,wz,hx,hz, dataStore)
            setDensityCompareParams(layerId_Lime, "greater", -1)
            setDensityParallelogram(layerId_Lime, sx,sz,wx,wz,hx,hz, 0,1, 1);
            dataStore.moistureValue = 0 -- No moisture!
        end
    )
    registry.addPlugin_UpdateSprayArea_fillType(
        "Spread kalk/lime(solid)",
        10,
        FillUtil.FILLTYPE_KALK,
        function(sx,sz,wx,wz,hx,hz, dataStore)
            setDensityCompareParams(layerId_Lime, "greater", -1)
            setDensityParallelogram(layerId_Lime, sx,sz,wx,wz,hx,hz, 0,1, 1);
            dataStore.moistureValue = 0 -- No moisture!
        end
    )

    --
    local layerId_Herbicide     = soilmod:getLayerId("herbicide")
    local layerId_HerbicideTime = soilmod:getLayerId("herbicideTime")
    registry.addPlugin_UpdateSprayArea_fillType(
        "Spray herbicide(liquid)",
        10,
        FillUtil.FILLTYPE_HERBICIDE,
        function(sx,sz,wx,wz,hx,hz, dataStore)
            setDensityCompareParams(layerId_Herbicide, "greater", -1)
            setDensityParallelogram(layerId_Herbicide,     sx,sz,wx,wz,hx,hz, 0,2, 1) -- type-A
            setDensityCompareParams(layerId_HerbicideTime, "greater", -1)
            setDensityParallelogram(layerId_HerbicideTime, sx,sz,wx,wz,hx,hz, 0,2, 3) -- Germination prevention
            dataStore.moistureValue = 1 -- Place moisture!
        end
    )
    registry.addPlugin_UpdateSprayArea_fillType(
        "Spray herbicide2(liquid)",
        10,
        FillUtil.FILLTYPE_HERBICIDE2,
        function(sx,sz,wx,wz,hx,hz, dataStore)
            setDensityCompareParams(layerId_Herbicide, "greater", -1)
            setDensityParallelogram(layerId_Herbicide,     sx,sz,wx,wz,hx,hz, 0,2, 2) -- type-B
            setDensityCompareParams(layerId_HerbicideTime, "greater", -1)
            setDensityParallelogram(layerId_HerbicideTime, sx,sz,wx,wz,hx,hz, 0,2, 3) -- Germination prevention
            dataStore.moistureValue = 1 -- Place moisture!
        end
    )
    registry.addPlugin_UpdateSprayArea_fillType(
        "Spray herbicide3(liquid)",
        10,
        FillUtil.FILLTYPE_HERBICIDE3,
        function(sx,sz,wx,wz,hx,hz, dataStore)
            setDensityCompareParams(layerId_Herbicide, "greater", -1)
            setDensityParallelogram(layerId_Herbicide,     sx,sz,wx,wz,hx,hz, 0,2, 3) -- type-C
            setDensityCompareParams(layerId_HerbicideTime, "greater", -1)
            setDensityParallelogram(layerId_HerbicideTime, sx,sz,wx,wz,hx,hz, 0,2, 3) -- Germination prevention
            dataStore.moistureValue = 1 -- Place moisture!
        end
    )

    --    
    local layerId_Fertilizer = soilmod:getLayerId("fertilizer")
    registry.addPlugin_UpdateSprayArea_fillType(
        "Spray liquidFertilizer(liquid)",
        10,
        FillUtil.FILLTYPE_LIQUIDFERTILIZER,
        function(sx,sz,wx,wz,hx,hz, dataStore)
            setDensityCompareParams(layerId_Fertilizer, "greater", -1)
            setDensityParallelogram(layerId_Fertilizer, sx,sz,wx,wz,hx,hz, 0,3, 3)
            dataStore.moistureValue = 1 -- Place moisture!
        end
    )
    registry.addPlugin_UpdateSprayArea_fillType(
        "Spray liquidFertilizer2(liquid)",
        10,
        FillUtil.FILLTYPE_LIQUIDFERTILIZER2,
        function(sx,sz,wx,wz,hx,hz, dataStore)
            setDensityCompareParams(layerId_Fertilizer, "greater", -1)
            setDensityParallelogram(layerId_Fertilizer, sx,sz,wx,wz,hx,hz, 0,3, 1)
            dataStore.moistureValue = 1 -- Place moisture!
        end
    )
    registry.addPlugin_UpdateSprayArea_fillType(
        "Spray liquidFertilizer3(liquid)",
        10,
        FillUtil.FILLTYPE_LIQUIDFERTILIZER3,
        function(sx,sz,wx,wz,hx,hz, dataStore)
            setDensityCompareParams(layerId_Fertilizer, "greater", -1)
            setDensityParallelogram(layerId_Fertilizer, sx,sz,wx,wz,hx,hz, 0,3, 2)
            dataStore.moistureValue = 1 -- Place moisture!
        end
    )

    registry.addPlugin_UpdateSprayArea_fillType(
        "Spread fertilizer(solid)",
        10,
        FillUtil.FILLTYPE_FERTILIZER,
        function(sx,sz,wx,wz,hx,hz, dataStore)
            setDensityCompareParams(layerId_Fertilizer, "greater", -1)
            setDensityParallelogram(layerId_Fertilizer, sx,sz,wx,wz,hx,hz, 0,3, 5)
            dataStore.moistureValue = 0 -- No moisture!
        end
    )
    registry.addPlugin_UpdateSprayArea_fillType(
        "Spread fertilizer2(solid)",
        10,
        FillUtil.FILLTYPE_FERTILIZER2,
        function(sx,sz,wx,wz,hx,hz, dataStore)
            setDensityCompareParams(layerId_Fertilizer, "greater", -1)
            setDensityParallelogram(layerId_Fertilizer, sx,sz,wx,wz,hx,hz, 0,3, 6)
            dataStore.moistureValue = 0 -- No moisture!
        end
    )
    registry.addPlugin_UpdateSprayArea_fillType(
        "Spread fertilizer3(solid)",
        10,
        FillUtil.FILLTYPE_FERTILIZER3,
        function(sx,sz,wx,wz,hx,hz, dataStore)
            setDensityCompareParams(layerId_Fertilizer, "greater", -1)
            setDensityParallelogram(layerId_Fertilizer, sx,sz,wx,wz,hx,hz, 0,3, 7)
            dataStore.moistureValue = 0 -- No moisture!
        end
    )
end
