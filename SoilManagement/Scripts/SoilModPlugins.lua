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
    soilmod.reduceWindrows        = settings:getKeyAttrValue("plugins.SoilModPlugins",  "reduceWindrows",      true)
    soilmod.removeSprayMoisture   = settings:getKeyAttrValue("plugins.SoilModPlugins",  "removeSprayMoisture", true)
    if (not soilmod.reduceWindrows)
    or (not soilmod.removeSprayMoisture)
    then
        logInfo("reduceWindrows=",soilmod.reduceWindrows,", removeSprayMoisture=",soilmod.removeSprayMoisture)
    end

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
        
        ---- And for the 'growth-cycle' plugins:
        --soilmod:pluginsForGrowthCycle(         registry)
        --soilmod:pluginsForWeatherCycle(        registry)
    end

    return allOK

end

--
local function hasFoliageLayer(foliageId)
    return (foliageId ~= nil and foliageId ~= 0);
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
    soilmod:registerLayer("fertN"           ,"sm3_fertN"         ,false ,4)
    soilmod:registerLayer("fertPK"          ,"sm3_fertPK"        ,false ,3)
    soilmod:registerLayer("health"          ,"sm3_health"        ,false ,4)
    soilmod:registerLayer("moisture"        ,"sm3_moisture"      ,false ,3)
    soilmod:registerLayer("herbicideTime"   ,"sm3_herbicideTime" ,false ,2)
    soilmod:registerLayer("intermediate"    ,"sm3_intermediate"  ,false ,1)
  --soilmod:registerLayer("quality"         ,"sm3_quality"       ,false ,3)
  --soilmod:registerLayer("previous"        ,"sm3_previous"      ,false ,3)

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
                    plough      = { minGrowthState=3, maxGrowthState=8, fertN=5, fertPK=1   },
                    cultivate   = { minGrowthState=3, maxGrowthState=8, fertN=2, fertPK=nil },
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
                    props.plough.fertN  = 4
                    props.plough.fertPK = 2
                    props.cultivate.minGrowthState = 2 -- Include growth-stage #2, due to WheelLanes mod
                    props.cultivate.fertN  = 1
                    props.cultivate.fertPK = nil
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

    -- TODO - Try to add for different fruit-types.
    soilmod.fertNCurve = AnimCurve:new(linearInterpolator1)
    soilmod.fertNCurve:addKeyframe({ v=0.00, time= 0 })
    soilmod.fertNCurve:addKeyframe({ v=0.20, time= 1 })
    soilmod.fertNCurve:addKeyframe({ v=0.50, time= 2 })
    soilmod.fertNCurve:addKeyframe({ v=0.70, time= 3 })
    soilmod.fertNCurve:addKeyframe({ v=0.90, time= 4 })
    soilmod.fertNCurve:addKeyframe({ v=1.00, time= 5 })
    soilmod.fertNCurve:addKeyframe({ v=0.50, time=15 })

    local layerId_FertN = soilmod:getLayerId("fertN")
    registry.addPlugin_CutFruitArea_before(
        "Get N density",
        30,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            -- Get N
            setDensityCompareParams(layerId_FertN, "greater", 0)
            local sumPixels, numPixels, totPixels = getDensityParallelogram(layerId_FertN, sx,sz,wx,wz,hx,hz, 0,4)
            dataStore.fertN = {sumPixels=sumPixels, numPixels=numPixels, totPixels=totPixels}
        end
    )
    registry.addPlugin_CutFruitArea_after(
        "Volume is affected by N",
        30,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            -- SoilManagement does not use spray for "yield".
            dataStore.spraySum = 0
            local fertN = dataStore.fertN
            if fertN.numPixels > 0 then
                local nutrientLevel = fertN.sumPixels / fertN.numPixels
                fertN.factor = soilmod.fertNCurve:get(nutrientLevel)
--log("FertN: s",fertN.sumPixels," n",fertN.numPixels," t",fertN.totPixels," / l",nutrientLevel," f",factor)
                dataStore.volume = dataStore.volume + (dataStore.volume * fertN.factor)
            end
        end
    )

    -- TODO - Try to add for different fruit-types.
    soilmod.fertPKCurve = AnimCurve:new(linearInterpolator1)
    soilmod.fertPKCurve:addKeyframe({ v=0.00, time= 0 })
    soilmod.fertPKCurve:addKeyframe({ v=0.10, time= 1 })
    soilmod.fertPKCurve:addKeyframe({ v=0.30, time= 2 })
    soilmod.fertPKCurve:addKeyframe({ v=0.80, time= 3 })
    soilmod.fertPKCurve:addKeyframe({ v=1.00, time= 4 })
    soilmod.fertPKCurve:addKeyframe({ v=0.30, time= 7 })

    local layerId_FertPK = soilmod:getLayerId("fertPK")
    registry.addPlugin_CutFruitArea_before(
        "Get PK density",
        40,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            -- Get PK
            setDensityCompareParams(layerId_FertPK, "greater", 0)
            local sumPixels, numPixels, totPixels = getDensityParallelogram(layerId_FertPK, sx,sz,wx,wz,hx,hz, 0,3)
            dataStore.fertPK = {sumPixels=sumPixels, numPixels=numPixels, totPixels=totPixels}
        end
    )
    registry.addPlugin_CutFruitArea_after(
        "Volume is slightly boosted by PK",
        40,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            local fertPK = dataStore.fertPK
            if fertPK.numPixels > 0 then
                local nutrientLevel = fertPK.sumPixels / fertPK.numPixels
                fertPK.factor = soilmod.fertPKCurve:get(nutrientLevel)
                local volumeBoost = (dataStore.numPixels * fertPK.factor) / 2
--log("FertPK: s",fertPK.sumPixels," n",fertPK.numPixels," t",fertPK.totPixels," / l",nutrientLevel," b",volumeBoost)
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

--DEBUG
    registry.addPlugin_CutFruitArea_after(
        "Debug graph",
        99,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            if soilmod.debugGraph and soilmod.debugGraphOn then
                soilmod.debugGraphAddValue(1, (dataStore.numPixels>0 and (dataStore.volume/dataStore.numPixels) or nil), dataStore.pixelsSum, dataStore.numPixels, 0)
                soilmod.debugGraphAddValue(2, Utils.getNoNil(dataStore.weeds.weedPct  ,0)    ,dataStore.weeds.oldSum         ,dataStore.weeds.numPixels      ,dataStore.weeds.newDelta       )
                soilmod.debugGraphAddValue(3, Utils.getNoNil(dataStore.fertN.factor   ,0)    ,dataStore.fertN.sumPixels      ,dataStore.fertN.numPixels      ,dataStore.fertN.totPixels      )
                soilmod.debugGraphAddValue(4, Utils.getNoNil(dataStore.fertPK.factor  ,0)    ,dataStore.fertPK.sumPixels     ,dataStore.fertPK.numPixels     ,dataStore.fertPK.totPixels     )
                soilmod.debugGraphAddValue(5, Utils.getNoNil(dataStore.soilpH.factor  ,0)    ,dataStore.soilpH.sumPixels     ,dataStore.soilpH.numPixels     ,dataStore.soilpH.totPixels     )
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
    local layerId_FertN   = soilmod:getLayerId("fertN")
    local layerId_FertPK  = soilmod:getLayerId("fertPK")
    local layerId_Soil_pH = soilmod:getLayerId("soil_pH")
    local layerId_Slurry  = soilmod:getLayerId("slurry")
    local layerId_Lime    = soilmod:getLayerId("lime")
    local layerId_Weed    = soilmod:getLayerId("weed")
    
    soilmod.UpdateFoliage = function(sx,sz,wx,wz,hx,hz, isForced, implementType)
        setDensityCompareParams(layerId_FertN,  "greater", 0)
        setDensityCompareParams(layerId_FertPK, "greater", 0)
            
        if implementType == soilmod.TOOLTYPE_PLOUGH then
            -- Increase FertN/FertPK where there's crops at specific growth-stages
            for _,props in pairs(soilmod.foliageLayersCrops) do
                if props.plough.fertN ~= nil then
                    setDensityMaskParams(         layerId_FertN,  "between", props.plough.minGrowthState, props.plough.maxGrowthState)
                    addDensityMaskedParallelogram(layerId_FertN,  sx,sz,wx,wz,hx,hz, 0,4, props.fruit.id, 0,g_currentMission.numFruitStateChannels, props.plough.fertN);
                end
                if props.plough.fertPK ~= nil then
                    setDensityMaskParams(         layerId_FertPK, "between", props.plough.minGrowthState, props.plough.maxGrowthState)
                    addDensityMaskedParallelogram(layerId_FertPK, sx,sz,wx,wz,hx,hz, 0,3, props.fruit.id, 0,g_currentMission.numFruitStateChannels, props.plough.fertPK);
                end
            end
    
            -- Increase FertN +10 where there's solidManure
            setDensityMaskParams(         layerId_FertN, "greater", 1)
            addDensityMaskedParallelogram(layerId_FertN,  sx,sz,wx,wz,hx,hz, 0,4, g_currentMission.terrainDetailId, g_currentMission.sprayFirstChannel,g_currentMission.sprayNumChannels, 10);
    
            ---- Increase FertN +3 where there's windrow
            --for _,fruit in pairs(soilmod.sm3FoliageLayersWindrows) do
            --    addDensityMaskedParallelogram(layerId_FertN,  sx,sz,wx,wz,hx,hz, 0, 4, fruit.windrowId, 0,g_currentMission.numWindrowChannels, 3);
            --end
    
            -- Increase FertPK +4 where there's solidManure
            setDensityMaskParams(         layerId_FertPK, "greater", 1)
            addDensityMaskedParallelogram(layerId_FertPK,  sx,sz,wx,wz,hx,hz, 0,3, g_currentMission.terrainDetailId, g_currentMission.sprayFirstChannel,g_currentMission.sprayNumChannels, 4);
        else
            -- Increase FertN/FertPK where there's crops at specific growth-stages
            for _,props in pairs(soilmod.foliageLayersCrops) do
                if props.cultivate.fertN ~= nil then
                    setDensityMaskParams(         layerId_FertN,  "between", props.cultivate.minGrowthState, props.cultivate.maxGrowthState)
                    addDensityMaskedParallelogram(layerId_FertN,  sx,sz,wx,wz,hx,hz, 0,4, props.fruit.id, 0,g_currentMission.numFruitStateChannels, props.cultivate.fertN);
                end
                if props.cultivate.fertPK ~= nil then
                    setDensityMaskParams(         layerId_FertPK, "between", props.cultivate.minGrowthState, props.cultivate.maxGrowthState)
                    addDensityMaskedParallelogram(layerId_FertPK, sx,sz,wx,wz,hx,hz, 0,3, props.fruit.id, 0,g_currentMission.numFruitStateChannels, props.cultivate.fertPK);
                end
            end
    
            -- Increase FertN +6 where there's solidManure
            setDensityMaskParams(         layerId_FertN, "greater", 1)
            addDensityMaskedParallelogram(layerId_FertN,  sx,sz,wx,wz,hx,hz, 0,4, g_currentMission.terrainDetailId, g_currentMission.sprayFirstChannel,g_currentMission.sprayNumChannels, 6);
    
            ---- Increase FertN +1 where there's windrow
            --for _,fruit in pairs(soilmod.sm3FoliageLayersWindrows) do
            --    addDensityMaskedParallelogram(layerId_FertN,  sx,sz,wx,wz,hx,hz, 0, 4, fruit.windrowId, 0,g_currentMission.numWindrowChannels, 1);
            --end
    
            -- Increase FertPK +2 where there's solidManure
            setDensityMaskParams(         layerId_FertPK, "greater", 1)
            addDensityMaskedParallelogram(layerId_FertPK,  sx,sz,wx,wz,hx,hz, 0,3, g_currentMission.terrainDetailId, g_currentMission.sprayFirstChannel,g_currentMission.sprayNumChannels, 2);
        end
    
        -- Increase soil pH where there's lime
        setDensityCompareParams(      layerId_Soil_pH, "greater", 0)
        setDensityMaskParams(         layerId_Soil_pH, "greater", 0)
        addDensityMaskedParallelogram(layerId_Soil_pH,  sx,sz,wx,wz,hx,hz, 0,4, layerId_Lime, 0,1, 4);
    
        -- Special case for slurry, due to ZunHammer and instant cultivating.
        setDensityCompareParams(      layerId_Slurry, "greater", 0)
        setDensityMaskParams(         layerId_Slurry, "equals", 1);
        setDensityMaskedParallelogram(layerId_Slurry, sx,sz,wx,wz,hx,hz, 0,2, layerId_Slurry, 0,1, 2)
    
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

    local layerId_Fertilizer = soilmod:getLayerId("fertilizer")
    registry.addPlugin_UpdateCultivatorArea_before(
        "Cultivator changes solid-fertilizer(visible) to liquid-fertilizer(invisible)",
        41,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            -- Where masked 'greater than 4', then set most-significant-bit to zero
            setDensityCompareParams(      layerId_Fertilizer, "greater", 0)
            setDensityMaskParams(         layerId_Fertilizer, "greater", 4)
            setDensityMaskedParallelogram(layerId_Fertilizer, sx,sz,wx,wz,hx,hz, 2,1, layerId_Fertilizer, 0,3, 0);
        end
    )

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

    local layerId_Fertilizer = soilmod:getLayerId("fertilizer")
    registry.addPlugin_UpdatePloughArea_before(
        "Ploughing changes solid-fertilizer(visible) to liquid-fertilizer(invisible)",
        41,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            -- Where masked 'greater than 4', then set most-significant-bit to zero
            setDensityCompareParams(      layerId_Fertilizer, "greater", 0)
            setDensityMaskParams(         layerId_Fertilizer, "greater", 4)
            setDensityMaskedParallelogram(layerId_Fertilizer, sx,sz,wx,wz,hx,hz, 2,1, layerId_Fertilizer, 0,3, 0);
        end
    )

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
            setDensityParallelogram(layerId_Fertilizer, sx,sz,wx,wz,hx,hz, 0,3, 1)
            dataStore.moistureValue = 1 -- Place moisture!
        end
    )
    registry.addPlugin_UpdateSprayArea_fillType(
        "Spray liquidFertilizer2(liquid)",
        10,
        FillUtil.FILLTYPE_LIQUIDFERTILIZER2,
        function(sx,sz,wx,wz,hx,hz, dataStore)
            setDensityCompareParams(layerId_Fertilizer, "greater", -1)
            setDensityParallelogram(layerId_Fertilizer, sx,sz,wx,wz,hx,hz, 0,3, 2)
            dataStore.moistureValue = 1 -- Place moisture!
        end
    )
    registry.addPlugin_UpdateSprayArea_fillType(
        "Spray liquidFertilizer3(liquid)",
        10,
        FillUtil.FILLTYPE_LIQUIDFERTILIZER3,
        function(sx,sz,wx,wz,hx,hz, dataStore)
            setDensityCompareParams(layerId_Fertilizer, "greater", -1)
            setDensityParallelogram(layerId_Fertilizer, sx,sz,wx,wz,hx,hz, 0,3, 3)
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

    registry.addPlugin_UpdateSprayArea_fillType(
        "Spray plantKiller(liquid)",
        10,
        FillUtil.FILLTYPE_PLANTKILLER,
        function(sx,sz,wx,wz,hx,hz, dataStore)
            setDensityCompareParams(layerId_Fertilizer, "greater", -1)
            setDensityParallelogram(layerId_Fertilizer, sx,sz,wx,wz,hx,hz, 0,3, 4)
            dataStore.moistureValue = 1 -- Place moisture!
        end
    )
end

--
-- Callback method, to be used in loadMapFinished() in the map's SampleModMap.LUA (or whatever its renamed to)
--
modSoilMod.setFruitTypeHerbicideAvoidance = function(fruitName, herbicideType)
    if fruitName == nil or herbicideType == nil then
        return;
    end

    fruitName = tostring(fruitName):lower()
    herbicideType = tostring(herbicideType):upper()

    log("setFruitTypeHerbicideAvoidance(",fruitName,",",herbicideType,")")

    if     herbicideType == "-" or herbicideType == "0" then
        soilmod.avoidanceRules[fruitName] = 0
    elseif herbicideType == "A" or herbicideType == "1" then
        soilmod.avoidanceRules[fruitName] = 1
    elseif herbicideType == "B" or herbicideType == "2" then
        soilmod.avoidanceRules[fruitName] = 2
    elseif herbicideType == "C" or herbicideType == "3" then
        soilmod.avoidanceRules[fruitName] = 3
    end
end


--
soilmod.avoidanceRules = {
    --
    -- DO NOT CHANGE THESE RULES HERE!
    --
    -- Instead adapt the following code-example and put it into YOUR OWN map's SampleModMap.LUA script's loadMapFinished() method:
    --[[
            -- Check that SoilMod v2.x is available...
            if modSoilMod2 ~= nil then
                -- Add/change fruit-type's dislike regarding herbicide-type...
                modSoilMod2.setFruitTypeHerbicideAvoidance("alfalfa", "B")  -- make 'alfalfa' dislike herbicide-B
                modSoilMod2.setFruitTypeHerbicideAvoidance("clover",  "C")  -- make 'clover' dislike herbicide-C
                modSoilMod2.setFruitTypeHerbicideAvoidance("klee",    "-")  -- change 'klee' to not be affected by any of the herbicide types.
            end
    --]]
    -- If the above code-example confuses you, then please go to http://fs-uk.com, find the support-topic for SoilMod (FS15), and ask for help.
    --

    --
    -- I repeat: DO NOT CHANGE THESE RULES HERE! - Read comment above.
    --
    -- Herbicide-A/AA
    ["wheat"]       = 1,
    ["barley"]      = 1,
    ["rye"]         = 1,
    ["oat"]         = 1,
    ["rice"]        = 1,
    -- Herbicide-B/BB
    ["corn"]        = 2,
    ["maize"]       = 2,
    ["rape"]        = 2,
    ["canola"]      = 2,
    ["osr"]         = 2,
    ["luzerne"]     = 2,
    ["klee"]        = 2,
    -- Herbicide-C/CC
    ["potato"]      = 3,
    ["sugarbeet"]   = 3,
    ["soybean"]     = 3,
    ["sunflower"]   = 3,
}

--
function soilmod:pluginsForGrowthCycle(registry)

    -- Build fruit's herbicide avoidance
    local function getHerbicideAvoidanceTypeForFruit(fruitName)
        fruitName = fruitName:lower()
        if soilmod.avoidanceRules[fruitName] ~= nil then
            return soilmod.avoidanceRules[fruitName]
        end
        return 0; -- Default
    end

    local indexToFillName = {
        [0] = { "n/a", "-" },
        [1] = { FillUtil.fillTypeIntToName[FillUtil.FILLTYPE_HERBICIDE]  ,"A"},
        [2] = { FillUtil.fillTypeIntToName[FillUtil.FILLTYPE_HERBICIDE2] ,"B"},
        [3] = { FillUtil.fillTypeIntToName[FillUtil.FILLTYPE_HERBICIDE3] ,"C"},
    }

    for _,fruitEntry in pairs(soilmod.foliageGrowthLayers) do
        local fruitName = (FruitUtil.fruitIndexToDesc[fruitEntry.fruitDescIndex].name)
        fruitEntry.herbicideAvoidance = getHerbicideAvoidanceTypeForFruit(fruitName)

        logInfo("Herbicide avoidance: '",fruitName,"' dislikes '",indexToFillName[fruitEntry.herbicideAvoidance][1],"' (",indexToFillName[fruitEntry.herbicideAvoidance][2],")")
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

    -- Default growth
    registry.addPlugin_GrowthCycleFruits(
        "Increase crop growth",
        10,
        function(sx,sz,wx,wz,hx,hz,day,fruitEntry)
            setDensityMaskParams(fruitEntry.fruitId, "between", fruitEntry.minSeededValue, fruitEntry.maxMatureValue - ((soilmod.disableWithering or fruitEntry.witheredValue == nil) and 1 or 0))
            addDensityMaskedParallelogram(
              fruitEntry.fruitId,
              sx,sz,wx,wz,hx,hz,
              0, g_currentMission.numFruitStateChannels,
              fruitEntry.fruitId, 0, g_currentMission.numFruitStateChannels, -- mask
              1 -- increase
            )
            setDensityMaskParams(fruitEntry.fruitId, "greater", 0)
        end
    )


    -- Decrease other layers depending on growth-stage
    local fruitLayer = g_currentMission.fruits[1]
    local fruitLayerId = fruitLayer.id
    if hasFoliageLayer(fruitLayerId) then
        if hasFoliageLayer(g_currentMission.sm3FoliageSoil_pH) then
            registry.addPlugin_GrowthCycle(
                "Decrease soil pH when crop at growth-stage 3",
                15,
                function(sx,sz,wx,wz,hx,hz,day)
                    setDensityTypeIndexCompareMode(fruitLayerId, 2) -- COMPARE_NONE
                    setDensityMaskParams(g_currentMission.sm3FoliageSoil_pH, "equals", 3)
                    addDensityMaskedParallelogram(
                        g_currentMission.sm3FoliageSoil_pH,
                        sx,sz,wx,wz,hx,hz,
                        0, 4,
                        fruitLayerId, 0, g_currentMission.numFruitStateChannels, -- mask
                        -1 -- decrease
                    )
                    setDensityTypeIndexCompareMode(fruitLayerId, 0) -- COMPARE_EQUAL
                end
            )
        end

        if hasFoliageLayer(g_currentMission.sm3FoliageFertN) then
            registry.addPlugin_GrowthCycle(
                "Decrease N when crop at growth-stages 1-7",
                16,
                function(sx,sz,wx,wz,hx,hz,day)
                    setDensityTypeIndexCompareMode(fruitLayerId, 2) -- COMPARE_NONE
                    setDensityMaskParams(g_currentMission.sm3FoliageFertN, "between", 1, 7)
                    addDensityMaskedParallelogram(
                        g_currentMission.sm3FoliageFertN,
                        sx,sz,wx,wz,hx,hz,
                        0, 4,
                        fruitLayerId, 0, g_currentMission.numFruitStateChannels, -- mask
                        -1 -- decrease
                    )
                    setDensityTypeIndexCompareMode(fruitLayerId, 0) -- COMPARE_EQUAL
                end
            )
        end

        if hasFoliageLayer(g_currentMission.sm3FoliageFertPK) then
            registry.addPlugin_GrowthCycle(
                "Decrease PK when crop at growth-stages 3,5",
                17,
                function(sx,sz,wx,wz,hx,hz,day)
                    setDensityTypeIndexCompareMode(fruitLayerId, 2) -- COMPARE_NONE
                    setDensityMaskParams(g_currentMission.sm3FoliageFertPK, "equals", 3)
                    addDensityMaskedParallelogram(
                        g_currentMission.sm3FoliageFertPK,
                        sx,sz,wx,wz,hx,hz,
                        0, 3,
                        fruitLayerId, 0, g_currentMission.numFruitStateChannels, -- mask
                        -1 -- decrease
                    )
                    setDensityMaskParams(g_currentMission.sm3FoliageFertPK, "equals", 5)
                    addDensityMaskedParallelogram(
                        g_currentMission.sm3FoliageFertPK,
                        sx,sz,wx,wz,hx,hz,
                        0, 3,
                        fruitLayerId, 0, g_currentMission.numFruitStateChannels, -- mask
                        -1 -- decrease
                    )
                    setDensityTypeIndexCompareMode(fruitLayerId, 0) -- COMPARE_EQUAL
                end
            )
        end

        if hasFoliageLayer(g_currentMission.sm3FoliageMoisture) then
            registry.addPlugin_GrowthCycle(
                "Decrease soil-moisture when crop at growth-stages 2,3,5",
                18,
                function(sx,sz,wx,wz,hx,hz,day)
                    setDensityTypeIndexCompareMode(fruitLayerId, 2) -- COMPARE_NONE
                    setDensityMaskParams(g_currentMission.sm3FoliageMoisture, "equals", 5)
                    addDensityMaskedParallelogram(
                        g_currentMission.sm3FoliageMoisture,
                        sx,sz,wx,wz,hx,hz,
                        0, 3,
                        fruitLayerId, 0, g_currentMission.numFruitStateChannels, -- mask
                        -1 -- decrease
                    )
                    setDensityMaskParams(g_currentMission.sm3FoliageMoisture, "between", 2, 3)
                    addDensityMaskedParallelogram(
                        g_currentMission.sm3FoliageMoisture,
                        sx,sz,wx,wz,hx,hz,
                        0, 3,
                        fruitLayerId, 0, g_currentMission.numFruitStateChannels, -- mask
                        -1 -- decrease
                    )
                    setDensityTypeIndexCompareMode(fruitLayerId, 0) -- COMPARE_EQUAL
                end
            )
        end
    end


    -- Herbicide side-effects
    if hasFoliageLayer(g_currentMission.sm3FoliageHerbicide) then
        registry.addPlugin_GrowthCycleFruits(
            "Herbicide affect crop",
            20,
            function(sx,sz,wx,wz,hx,hz,day,fruitEntry)
                -- Herbicide may affect growth or cause withering...
                if fruitEntry.herbicideAvoidance > 0 then
                    -- Herbicide affected fruit
                    setDensityMaskParams(fruitEntry.fruitId, "equals", fruitEntry.herbicideAvoidance)
                    -- When growing and affected by wrong herbicide, pause one growth-step
                    setDensityCompareParams(fruitEntry.fruitId, "between", fruitEntry.minSeededValue+1, fruitEntry.minMatureValue)
                    addDensityMaskedParallelogram(
                        fruitEntry.fruitId,
                        sx,sz,wx,wz,hx,hz,
                        0, g_currentMission.numFruitStateChannels,
                        g_currentMission.sm3FoliageHerbicide, 0, 2, -- mask
                        -1 -- subtract one
                    )
                    -- When mature and affected by wrong herbicide, change to withered if possible.
                    if fruitEntry.witheredValue ~= nil then
                        --setDensityMaskParams(fruitEntry.fruitId, "equals", fruitEntry.herbicideAvoidance)
                        setDensityCompareParams(fruitEntry.fruitId, "between", fruitEntry.minMatureValue, fruitEntry.maxMatureValue)
                        setDensityMaskedParallelogram(
                            fruitEntry.fruitId,
                            sx,sz,wx,wz,hx,hz,
                            0, g_currentMission.numFruitStateChannels,
                            g_currentMission.sm3FoliageHerbicide, 0, 2, -- mask
                            fruitEntry.witheredValue  -- value
                        )
                    end
                    --
                    setDensityCompareParams(fruitEntry.fruitId, "greater", -1)
                    setDensityMaskParams(fruitEntry.fruitId, "greater", 0)
                end
            end
        )
    end


    -- Remove windrows
    if soilmod.reduceWindrows ~= false then
        registry.addPlugin_GrowthCycleFruits(
            "Reduce crop windrows/swath",
            30,
            function(sx,sz,wx,wz,hx,hz,day,fruitEntry)
                -- Reduce windrow (gone with the wind)
                if fruitEntry.windrowId ~= nil and fruitEntry.windrowId ~= 0 then
                    setDensityMaskParams(fruitEntry.windrowId, "greater", 0)
                    addDensityMaskedParallelogram(
                        fruitEntry.windrowId,
                        sx,sz,wx,wz,hx,hz,
                        0, g_currentMission.numWindrowChannels,
                        fruitEntry.windrowId, 0, g_currentMission.numWindrowChannels,  -- mask
                        -1  -- subtract one
                    );
                    setDensityMaskParams(fruitEntry.windrowId, "greater", -1)
                end
            end
        )
    end


    --Lime/Kalk and soil pH
    if hasFoliageLayer(g_currentMission.sm3FoliageLime) then
        if hasFoliageLayer(g_currentMission.sm3FoliageSoil_pH) then
            registry.addPlugin_GrowthCycle(
                "Increase soil pH where there is lime",
                20 - 1,
                function(sx,sz,wx,wz,hx,hz,day)
                    -- Increase soil-pH, where lime is
                    setDensityMaskParams(g_currentMission.sm3FoliageSoil_pH, "greater", 0); -- lime must be > 0
                    addDensityMaskedParallelogram(
                        g_currentMission.sm3FoliageSoil_pH,
                        sx,sz,wx,wz,hx,hz,
                        0, 4,
                        g_currentMission.sm3FoliageLime, 0, 1,
                        3  -- increase
                    );
                    --setDensityMaskParams(g_currentMission.sm3FoliageSoil_pH, "greater", -1);
                end
            )
        end

        registry.addPlugin_GrowthCycle(
            "Remove lime",
            20,
            function(sx,sz,wx,wz,hx,hz,day)
                -- Remove lime
                setDensityParallelogram(
                    g_currentMission.sm3FoliageLime,
                    sx,sz,wx,wz,hx,hz,
                    0, 1,
                    0  -- value
                );
            end
        )
    end

    -- Manure
    if hasFoliageLayer(g_currentMission.sm3FoliageManure) then
        if hasFoliageLayer(g_currentMission.sm3FoliageMoisture) then
            registry.addPlugin_GrowthCycle(
                "Increase soil-moisture where there is manure",
                30 - 1,
                function(sx,sz,wx,wz,hx,hz,day)
                    setDensityMaskParams(g_currentMission.sm3FoliageMoisture, "greater", 0)
                    addDensityMaskedParallelogram(
                        g_currentMission.sm3FoliageMoisture,
                        sx,sz,wx,wz,hx,hz,
                        0, 3,
                        g_currentMission.sm3FoliageManure, 0, 2, -- mask
                        1  -- increase
                    );
                end
            )
        end

        registry.addPlugin_GrowthCycle(
            "Reduce manure",
            30,
            function(sx,sz,wx,wz,hx,hz,day)
                -- Decrease solid manure
                addDensityParallelogram(
                    g_currentMission.sm3FoliageManure,
                    sx,sz,wx,wz,hx,hz,
                    0, 2,
                    -1  -- subtract one
                );
            end
        )
    end

    -- Slurry (LiquidManure)
    if hasFoliageLayer(g_currentMission.sm3FoliageSlurry) then
        if hasFoliageLayer(g_currentMission.sm3FoliageFertN) then
            registry.addPlugin_GrowthCycle(
                "Increase N where there is slurry",
                40 - 1,
                function(sx,sz,wx,wz,hx,hz,day)
                    -- add to nitrogen
                    setDensityMaskParams(g_currentMission.sm3FoliageFertN, "greater", 0); -- slurry must be > 0
                    addDensityMaskedParallelogram(
                        g_currentMission.sm3FoliageFertN,
                        sx,sz,wx,wz,hx,hz,
                        0, 4,
                        g_currentMission.sm3FoliageSlurry, 0, 2,  -- mask
                        3 -- increase
                    );
                    setDensityMaskParams(g_currentMission.sm3FoliageFertN, "greater", -1);
                end
            )
        end

        registry.addPlugin_GrowthCycle(
            "Remove slurry",
            40,
            function(sx,sz,wx,wz,hx,hz,day)
                -- Remove liquid manure
                setDensityParallelogram(
                    g_currentMission.sm3FoliageSlurry,
                    sx,sz,wx,wz,hx,hz,
                    0, 2,
                    0
                );
            end
        )
    end

    -- Fertilizer
    if hasFoliageLayer(g_currentMission.sm3FoliageFertilizer) then
        if FillUtil.FILLTYPE_PLANTKILLER ~= nil then
            registry.addPlugin_GrowthCycle(
                "Remove plants where there is Herbicide-X",
                45 - 4,
                function(sx,sz,wx,wz,hx,hz,day)
                    -- Remove crops and dynamic-layers
                    Utils.sm3MaskedDestroyCommonArea(
                        sx,sz,wx,wz,hx,hz,
                        g_currentMission.sm3FoliageFertilizer,0,3,
                        "equals",4
                    )
                end
            )
        end

        if hasFoliageLayer(g_currentMission.sm3FoliageSoil_pH) then
            if FillUtil.FILLTYPE_PLANTKILLER ~= nil then
                registry.addPlugin_GrowthCycle(
                    "Reduce soil pH where there is Herbicide-X",
                    45 - 4,
                    function(sx,sz,wx,wz,hx,hz,day)
                        setDensityMaskParams(g_currentMission.sm3FoliageSoil_pH, "equals", 4)
                        addDensityMaskedParallelogram(
                            g_currentMission.sm3FoliageSoil_pH,
                            sx,sz,wx,wz,hx,hz,
                            0, 4,
                            g_currentMission.sm3FoliageFertilizer,0,3,
                            -2  -- decrease
                        );
                    end
                )
            end

            registry.addPlugin_GrowthCycle(
                "Reduce soil pH where there is fertilizer-N",
                45 - 3,
                function(sx,sz,wx,wz,hx,hz,day)
                    setDensityMaskParams(g_currentMission.sm3FoliageSoil_pH, "equals", 3)
                    addDensityMaskedParallelogram(
                        g_currentMission.sm3FoliageSoil_pH,
                        sx,sz,wx,wz,hx,hz,
                        0, 4,
                        g_currentMission.sm3FoliageFertilizer, 0, 2,  -- mask
                        -1  -- decrease
                    );
                    --setDensityMaskParams(g_currentMission.sm3FoliageSoil_pH, "greater", -1)
                end
            )
        end
        if hasFoliageLayer(g_currentMission.sm3FoliageFertN) then
            registry.addPlugin_GrowthCycle(
                "Increase N where there is fertilizer-NPK/N",
                45 - 2,
                function(sx,sz,wx,wz,hx,hz,day)
                    setDensityMaskParams(g_currentMission.sm3FoliageFertN, "equals", 1); -- fertilizer must be == 1
                    addDensityMaskedParallelogram(
                        g_currentMission.sm3FoliageFertN,
                        sx,sz,wx,wz,hx,hz,
                        0, 4,
                        g_currentMission.sm3FoliageFertilizer, 0, 2,  -- mask
                        3 -- increase
                    );
                    setDensityMaskParams(g_currentMission.sm3FoliageFertN, "equals", 3); -- fertilizer must be == 3
                    addDensityMaskedParallelogram(
                        g_currentMission.sm3FoliageFertN,
                        sx,sz,wx,wz,hx,hz,
                        0, 4,
                        g_currentMission.sm3FoliageFertilizer, 0, 2,  -- mask
                        5 -- increase
                    );
                    --setDensityMaskParams(g_currentMission.sm3FoliageFertN, "greater", -1);
                end
            )
        end
        if hasFoliageLayer(g_currentMission.sm3FoliageFertPK) then
            registry.addPlugin_GrowthCycle(
                "Increase PK where there is fertilizer-NPK/PK",
                45 - 1,
                function(sx,sz,wx,wz,hx,hz,day)
                    setDensityMaskParams(g_currentMission.sm3FoliageFertPK, "equals", 1); -- fertilizer must be == 1
                    addDensityMaskedParallelogram(
                        g_currentMission.sm3FoliageFertPK,
                        sx,sz,wx,wz,hx,hz,
                        0, 3,
                        g_currentMission.sm3FoliageFertilizer, 0, 2,  -- mask
                        1 -- increase
                    );
                    setDensityMaskParams(g_currentMission.sm3FoliageFertPK, "equals", 2); -- fertilizer must be == 2
                    addDensityMaskedParallelogram(
                        g_currentMission.sm3FoliageFertPK,
                        sx,sz,wx,wz,hx,hz,
                        0, 3,
                        g_currentMission.sm3FoliageFertilizer, 0, 2,  -- mask
                        3 -- increase
                    );
                    --setDensityMaskParams(g_currentMission.sm3FoliageFertPK, "greater", -1);
                end
            )
        end

        registry.addPlugin_GrowthCycle(
            "Remove fertilizer",
            45,
            function(sx,sz,wx,wz,hx,hz,day)
                -- Remove fertilizer
                setDensityParallelogram(
                    g_currentMission.sm3FoliageFertilizer,
                    sx,sz,wx,wz,hx,hz,
                    0, 3,
                    0
                );
            end
        )
    end


    -- Weed, herbicide and FertN
    if hasFoliageLayer(g_currentMission.sm3FoliageWeed) then

        registry.addPlugin_GrowthCycle(
            "Reduce withered weed",
            50 - 3,
            function(sx,sz,wx,wz,hx,hz,day)
                -- Decrease "dead" weed
                setDensityCompareParams(g_currentMission.sm3FoliageWeed, "between", 1, 3)
                addDensityParallelogram(
                    g_currentMission.sm3FoliageWeed,
                    sx,sz,wx,wz,hx,hz,
                    0, 3,
                    -1  -- subtract
                );
            end
        )

        if hasFoliageLayer(g_currentMission.sm3FoliageFertN) then
            registry.addPlugin_GrowthCycle(
                "Fully grown weed will wither if no nutrition(N) available",
                50 - 2,
                function(sx,sz,wx,wz,hx,hz,day)
                    setDensityCompareParams(g_currentMission.sm3FoliageWeed, "equals", 7)
                    setDensityMaskParams(g_currentMission.sm3FoliageWeed, "equals", 0) -- FertN == 0
                    setDensityMaskedParallelogram(
                        g_currentMission.sm3FoliageWeed,
                        sx,sz,wx,wz,hx,hz,
                        0, 3,
                        g_currentMission.sm3FoliageFertN, 0, 4, -- mask
                        3
                    )
                    setDensityMaskParams(g_currentMission.sm3FoliageWeed, "greater", -1)
                    setDensityCompareParams(g_currentMission.sm3FoliageWeed, "greater", 0)
                end
            )
        end

        if hasFoliageLayer(g_currentMission.sm3FoliageHerbicide) then
            registry.addPlugin_GrowthCycle(
                "Change weed to withered where there is herbicide",
                50 - 1,
                function(sx,sz,wx,wz,hx,hz,day)
                    -- Change to "dead" weed
                    setDensityCompareParams(g_currentMission.sm3FoliageWeed, "greater", 0)
                    setDensityMaskParams(g_currentMission.sm3FoliageWeed, "greater", 0)  -- Herbicide > 0
                    setDensityMaskedParallelogram(
                        g_currentMission.sm3FoliageWeed,
                        sx,sz,wx,wz,hx,hz,
                        2, 1, -- affect only Most-Significant-Bit
                        g_currentMission.sm3FoliageHerbicide, 0, 2, -- mask
                        0 -- reset bit
                    )
                    --setDensityMaskParams(g_currentMission.sm3FoliageWeed, "greater", -1)
                end
            )
        end

        registry.addPlugin_GrowthCycle(
            "Increase weed growth",
            50,
            function(sx,sz,wx,wz,hx,hz,day)
                -- Increase "alive" weed
                setDensityCompareParams(g_currentMission.sm3FoliageWeed, "between", 4, 6)
                addDensityParallelogram(
                    g_currentMission.sm3FoliageWeed,
                    sx,sz,wx,wz,hx,hz,
                    0, 3,
                    1  -- increase
                );
                setDensityCompareParams(g_currentMission.sm3FoliageWeed, "greater", -1)
            end
        )

        if hasFoliageLayer(g_currentMission.sm3FoliageFertN) then
            registry.addPlugin_GrowthCycle(
                "Decrease N where there is weed still alive",
                50 + 1,
                function(sx,sz,wx,wz,hx,hz,day)
                    setDensityMaskParams(g_currentMission.sm3FoliageFertN, "greater", 3)
                    addDensityMaskedParallelogram(
                        g_currentMission.sm3FoliageFertN,
                        sx,sz,wx,wz,hx,hz,
                        0, 4,
                        g_currentMission.sm3FoliageWeed, 0, 3, -- mask
                        -1 -- decrease
                    )
                    setDensityMaskParams(g_currentMission.sm3FoliageFertN, "greater", -1)
                end
            )
        end

        if hasFoliageLayer(g_currentMission.sm3FoliageMoisture) then
            registry.addPlugin_GrowthCycle(
                "Decrease soil-moisture where there is weed still alive",
                50 + 2,
                function(sx,sz,wx,wz,hx,hz,day)
                    setDensityMaskParams(g_currentMission.sm3FoliageMoisture, "greater", 4)
                    addDensityMaskedParallelogram(
                        g_currentMission.sm3FoliageMoisture,
                        sx,sz,wx,wz,hx,hz,
                        0, 3,
                        g_currentMission.sm3FoliageWeed, 0, 3, -- mask
                        -1 -- decrease
                    )
                    setDensityMaskParams(g_currentMission.sm3FoliageMoisture, "greater", -1)
                end
            )
        end
    end

    -- Herbicide and germination prevention
    if  hasFoliageLayer(g_currentMission.sm3FoliageHerbicideTime)
    and hasFoliageLayer(g_currentMission.sm3FoliageHerbicide)
    then
        registry.addPlugin_GrowthCycle(
            "Reduce germination prevention, where there is no herbicide",
            55,
            function(sx,sz,wx,wz,hx,hz,day)
                -- Reduce germination prevention time.
                setDensityMaskParams(g_currentMission.sm3FoliageHerbicideTime, "equals", 0)
                addDensityMaskedParallelogram(
                    g_currentMission.sm3FoliageHerbicideTime,
                    sx,sz,wx,wz,hx,hz,
                    0, 2,
                    g_currentMission.sm3FoliageHerbicide, 0, 2, -- mask
                    -1  -- decrease
                );
            end
        )
    end

    -- Herbicide and soil pH
    if hasFoliageLayer(g_currentMission.sm3FoliageHerbicide) then
        if hasFoliageLayer(g_currentMission.sm3FoliageSoil_pH) then
            registry.addPlugin_GrowthCycle(
                "Reduce soil pH where there is herbicide",
                60 - 1,
                function(sx,sz,wx,wz,hx,hz,day)
                    -- Decrease soil-pH, where herbicide is
                    setDensityMaskParams(g_currentMission.sm3FoliageSoil_pH, "greater", 0)
                    addDensityMaskedParallelogram(
                        g_currentMission.sm3FoliageSoil_pH,
                        sx,sz,wx,wz,hx,hz,
                        0, 4,
                        g_currentMission.sm3FoliageHerbicide, 0, 2, -- mask
                        -1  -- decrease
                    );
                    --setDensityMaskParams(g_currentMission.sm3FoliageSoil_pH, "greater", -1)
                end
            )
        end

        registry.addPlugin_GrowthCycle(
            "Remove herbicide",
            60,
            function(sx,sz,wx,wz,hx,hz,day)
                -- Remove herbicide
                setDensityParallelogram(
                    g_currentMission.sm3FoliageHerbicide,
                    sx,sz,wx,wz,hx,hz,
                    0, 2,
                    0  -- value
                );
            end
        )
    end

    -- Water and Moisture
    if  hasFoliageLayer(g_currentMission.sm3FoliageMoisture)
    and hasFoliageLayer(g_currentMission.sm3FoliageWater)
    then
        registry.addPlugin_GrowthCycle(
            "Increase/decrease soil-moisture depending on water-level",
            70,
            function(sx,sz,wx,wz,hx,hz,day)
                setDensityMaskParams(g_currentMission.sm3FoliageMoisture, "equals", 1)
                addDensityMaskedParallelogram(
                    g_currentMission.sm3FoliageMoisture,
                    sx,sz,wx,wz,hx,hz,
                    0, 3,
                    g_currentMission.sm3FoliageWater, 0, 2, -- mask
                    -1  -- decrease
                );
                setDensityMaskParams(g_currentMission.sm3FoliageMoisture, "equals", 2)
                addDensityMaskedParallelogram(
                    g_currentMission.sm3FoliageMoisture,
                    sx,sz,wx,wz,hx,hz,
                    0, 3,
                    g_currentMission.sm3FoliageWater, 0, 2, -- mask
                    1  -- increase
                );
                setDensityMaskParams(g_currentMission.sm3FoliageMoisture, "equals", 3)
                addDensityMaskedParallelogram(
                    g_currentMission.sm3FoliageMoisture,
                    sx,sz,wx,wz,hx,hz,
                    0, 3,
                    g_currentMission.sm3FoliageWater, 0, 2, -- mask
                    2  -- increase
                );
            end
        )

        registry.addPlugin_GrowthCycle(
            "Remove water-level",
            71,
            function(sx,sz,wx,wz,hx,hz,day)
                setDensityParallelogram(
                    g_currentMission.sm3FoliageWater,
                    sx,sz,wx,wz,hx,hz,
                    0, 2,
                    0  -- value
                );
            end
        )
    end


    -- Spray and Moisture
    if soilmod.removeSprayMoisture ~= false then

        if hasFoliageLayer(g_currentMission.sm3FoliageMoisture) then
            registry.addPlugin_GrowthCycle(
                "Increase soil-moisture where there is sprayed",
                80 - 1,
                function(sx,sz,wx,wz,hx,hz,day)
                    setDensityMaskParams(g_currentMission.sm3FoliageMoisture, "equals", 1)
                    addDensityMaskedParallelogram(
                        g_currentMission.sm3FoliageMoisture,
                        sx,sz,wx,wz,hx,hz,
                        0, 3,
                        g_currentMission.terrainDetailId, g_currentMission.sprayChannel, 1, -- mask
                        1  -- increase
                    );
                end
            )
        end

        registry.addPlugin_GrowthCycle(
            "Remove spray moisture",
            80,
            function(sx,sz,wx,wz,hx,hz,day)
                -- Remove moistness (spray)
                setDensityParallelogram(
                    g_currentMission.terrainDetailId,
                    sx,sz,wx,wz,hx,hz,
                    g_currentMission.sprayChannel, 1,
                    0  -- value
                );
            end
        )
    end

end

--
function soilmod:pluginsForWeatherCycle(registry)

    -- Hot weather reduces soil-moisture
    -- Rain increases soil-moisture
    if hasFoliageLayer(g_currentMission.sm3FoliageMoisture) then
        registry.addPlugin_WeatherCycle(
            "Soil-moisture is affected by weather",
            10,
            function(sx,sz,wx,wz,hx,hz,weatherInfo,day)
                if weatherInfo == soilmod.WEATHER_HOT then
                    addDensityParallelogram(
                        g_currentMission.sm3FoliageMoisture,
                        sx,sz,wx,wz,hx,hz,
                        0, 3,
                        -1  -- decrease
                    );
--
                    setTypeIndexMaskedParallelogram(
                        g_currentMission.fruits[FruitUtil.FRUITTYPE_DRYGRASS].id,   -- dryGrass_windrow
                        sx,sz,wx,wz,hx,hz, 
                        g_currentMission.fruits[FruitUtil.FRUITTYPE_GRASS].id,      -- grass_windrow
                        4,      -- offset for 'windrow'
                        4       -- num-channels for 'window'
                    );
--
                elseif weatherInfo == soilmod.WEATHER_RAIN then
                    addDensityParallelogram(
                        g_currentMission.sm3FoliageMoisture,
                        sx,sz,wx,wz,hx,hz,
                        0, 3,
                        1  -- increase
                    );
                elseif weatherInfo == soilmod.WEATHER_HAIL then
                    --
                end
            end
        )
    end

end
