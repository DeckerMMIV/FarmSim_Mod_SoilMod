--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-03-xx
--

--
function soilmod:preSetupFSUtils()
    soilmod.densityMapsFirstFruitId = {}
    soilmod.destructibleFoliageLayers = {}
    
    -- We need a different array of dynamic-foliage-layers, to be used in Utils.updateDestroyCommonArea()
    for _, foliageId in ipairs(g_currentMission.dynamicFoliageLayers) do
        self:addDestructibleFoliageId(foliageId)
    end
end

function soilmod:addDestructibleFoliageId(foliageId)
    if foliageId ~= nil and foliageId ~= 0 and soilmod.destructibleFoliageLayers[foliageId] == nil then
        soilmod.destructibleFoliageLayers[foliageId] = {
            id          = foliageId,
            numChannels = getTerrainDetailNumChannels(foliageId),
        }

        logInfo("Included foliage-layer for \"destruction\" by plough/cultivator/seeder/roller: '",getName(foliageId),"'"
            ,", id=",         foliageId
            ,",numChnls=",    getTerrainDetailNumChannels(foliageId)
            ,",size=",        getDensityMapSize(foliageId)
            ,",densityFile=", getDensityMapFilename(foliageId)
        )
    end
end

--
function soilmod:setupFSUtils()
    -- Overwrite functions with custom...
    soilmod:overwriteFruit()
    soilmod:overwriteWeeder()
    soilmod:overwriteCultivator()
    soilmod:overwritePlough()
    soilmod:overwriteSowing()
    soilmod:overwriteDestroyCommon()
    soilmod:overwriteSpray()
    soilmod:overwriteRoller()    
    soilmod:overwriteHarvestScaleMultiplier()
end

--
function soilmod:overwriteHarvestScaleMultiplier()
    logInfo("Overwriting g_currentMission.getHarvestScaleMultiplier")

    g_currentMission.getHarvestScaleMultiplier = function(sprayFactor, ploughFactor)
        return 1
    end
end

--
function soilmod:overwriteFruit()
    logInfo("Overwriting Utils.cutFruitArea")

    Utils.cutFruitArea = function(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, destroySpray, destroySeedingWidth, useMinForageState)
        -- fruitDesc and the world-location are CONSTANTS! Do NOT modify, not even in the plugins!
        local fruitDesc = FruitUtil.fruitIndexToDesc[fruitId];
        local sx,sz,wx,wz,hx,hz = Utils.getXZWidthAndHeight(nil, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ);
        
        -- dataStore is a 'dictionary'. Plugins can add additional elements (using very unique names) or modify the given ones if needed.
        local dataStore = {}
        dataStore.fruitFoliageId            = g_currentMission.fruits[fruitId].id
        if useMinForageState then
            dataStore.minHarvestingGrowthState  = fruitDesc.minForageGrowthState+1 -- add 1 since growth state 0 has density value 1
        else
            dataStore.minHarvestingGrowthState  = fruitDesc.minHarvestingGrowthState+1 -- add 1 since growth state 0 has density value 1
        end
        dataStore.maxHarvestingGrowthState  = fruitDesc.maxHarvestingGrowthState+1 -- add 1 since growth state 0 has density value 1
        dataStore.cutState                  = fruitDesc.cutState+1                 -- add 1 since growth state 0 has density value 1
        dataStore.destroySeedingWidth       = destroySeedingWidth
        dataStore.destroySpray              = destroySpray
        dataStore.sprayFactor               = 0
        dataStore.ploughFactor              = 0
        dataStore.growthState               = dataStore.minHarvestingGrowthState
        dataStore.growthStateMaxArea        = 0
    
        -- Setup phase - If any plugin needs to modify anything in dataStore
        for _,callFunc in pairs(Utils.sm3Plugins_CutFruitArea_Setup) do
            callFunc(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
        end
        
        -- Before phase - Give plugins the possibility to affect foliage-layer(s) and dataStore, before the default effect occurs.
        for _,callFunc in pairs(Utils.sm3Plugins_CutFruitArea_PreFuncs) do
            callFunc(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
        end

        -- 
        setDensityCompareParams(dataStore.fruitFoliageId, "between", dataStore.minHarvestingGrowthState, dataStore.maxHarvestingGrowthState);
        
        local sumPixels, numPixels, _ = getDensityParallelogram(dataStore.fruitFoliageId, sx,sz,wx,wz,hx,hz, 0, g_currentMission.numFruitStateChannels);
        if numPixels > 0 then
            -- Try to estimate the growth state
            local approxGrowthState = sumPixels / numPixels
            dataStore.growthState = Utils.clamp(approxGrowthState, dataStore.minHarvestingGrowthState, dataStore.maxHarvestingGrowthState)
            dataStore.growthStateMaxArea = numPixels
        end
        
        setDensityReturnValueShift(dataStore.fruitFoliageId, -1); -- if no fruit is there, the value is 0 or 1, thus we need to shift by -1, to get values from 0-4, where 0 is no and 4 is full
        dataStore.sumPixels, dataStore.numPixels, dataStore.totalPixels = setDensityParallelogram(dataStore.fruitFoliageId, sx,sz,wx,wz,hx,hz, 0, g_currentMission.numFruitStateChannels, dataStore.cutState);
        setDensityReturnValueShift(dataStore.fruitFoliageId, 0);
        setDensityCompareParams(dataStore.fruitFoliageId, "greater", -1);
    
        dataStore.volume = dataStore.numPixels
        
        -- After phase - Give plugins the possibility to affect foliage-layer(s) and dataStore, after the default effect have been done.
        for _,callFunc in pairs(Utils.sm3Plugins_CutFruitArea_PostFuncs) do
            callFunc(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
        end
    
        --
        return  dataStore.volume, 
                dataStore.numPixels, 
                dataStore.sprayFactor, 
                dataStore.ploughFactor, 
                dataStore.growthState, 
                dataStore.growthStateMaxArea
    end

end  

--
function soilmod:overwriteWeeder()
    logInfo("Overwriting Utils.updateWeederArea")

    Utils.updateWeederArea = function(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
        local sx,sz,wx,wz,hx,hz = Utils.getXZWidthAndHeight(nil, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ);
    
        -- dataStore is a 'dictionary'. Plugins can add additional elements (using very unique names) or modify the given ones if needed.
        local dataStore = {}
        dataStore.numPixels = 0;
        
        -- Setup phase - If any plugin needs to modify anything in dataStore
        for _,callFunc in pairs(Utils.sm3Plugins_WeederArea_Setup) do
            callFunc(sx,sz,wx,wz,hx,hz, dataStore, nil)
        end
        
        -- Before phase - Give plugins the possibility to affect foliage-layer(s) and dataStore.
        for _,callFunc in pairs(Utils.sm3Plugins_WeederArea_PreFuncs) do
            callFunc(sx,sz,wx,wz,hx,hz, dataStore, nil)
        end

        -- Weeder destroys crops at higher growth states
        for fruitId, fruitFoliageId in pairs(g_currentMission.fruits) do
            if  fruitId ~= FruitUtil.FRUITTYPE_GRASS
            and fruitId ~= FruitUtil.FRUITTYPE_DRYGRASS
            then
                local fruitDesc = FruitUtil.fruitIndexToDesc[fruitId]
                --setDensityMaskParams(fruitFoliageId, "greater", 0)
                setDensityCompareParams(fruitFoliageId, "between", 3, fruitDesc.cutState);
                setDensityMaskedParallelogram(
                    fruitFoliageId, 
                    sx,sz,wx,wz,hx,hz,
                    0, g_currentMission.numFruitStateChannels, 
                    g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, 
                    fruitDesc.cutState+1
                )
                --setDensityCompareParams(fruitFoliageId, "greater", -1);
            end
        end

        setDensityCompareParams(g_currentMission.terrainDetailId, "greater", 0)
        dataStore.sumPixels, dataStore.numPixels, dataStore.totalPixels = getDensityParallelogram(
            g_currentMission.terrainDetailId, 
            sx,sz,wx,wz,hx,hz,
            g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels
        )
        --setDensityCompareParams(g_currentMission.terrainDetailId, "greater", -1)

        -- After phase - Give plugins the possibility to affect foliage-layer(s) and dataStore.
        for _,callFunc in pairs(Utils.sm3Plugins_WeederArea_PostFuncs) do
            callFunc(sx,sz,wx,wz,hx,hz, dataStore, nil)
        end

        return dataStore.numPixels;
    end
end

--
function soilmod:overwriteCultivator()
    logInfo("Overwriting Utils.updateCultivatorArea")

    Utils.updateCultivatorArea = function(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, forced, commonForced, angle)
        local sx,sz,wx,wz,hx,hz = Utils.getXZWidthAndHeight(nil, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ);
    
        -- dataStore is a 'dictionary'. Plugins can add additional elements (using very unique names) or modify the given ones if needed.
        local dataStore = {}
        dataStore.forced            = Utils.getNoNil(forced, true)
        dataStore.commonForced      = Utils.getNoNil(commonForced, true)
        dataStore.angle             = angle
        
        -- Setup phase - If any plugin needs to modify anything in dataStore
        for _,callFunc in pairs(Utils.sm3Plugins_CultivatorArea_Setup) do
            callFunc(sx,sz,wx,wz,hx,hz, dataStore, nil)
        end

        --
        setDensityCompareParams(g_currentMission.terrainDetailId, "equal", g_currentMission.cultivatorValue);
        _, dataStore.areaBefore, _ = getDensityParallelogram(
            g_currentMission.terrainDetailId, 
            sx,sz,wx,wz,hx,hz, 
            g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels
        );
        --setDensityCompareParams(g_currentMission.terrainDetailId, "greater", -1);
        
        -- Before phase - Give plugins the possibility to affect foliage-layer(s) and dataStore, before the default effect occurs.
        for _,callFunc in pairs(Utils.sm3Plugins_CultivatorArea_PreFuncs) do
            callFunc(sx,sz,wx,wz,hx,hz, dataStore, nil)
        end
    
        -- Default "cultivating"
        if dataStore.forced then
            setDensityCompareParams(g_currentMission.terrainDetailId, "greater", -1);
            dataStore.sumPixels, dataStore.numPixels, dataStore.totalPixels = setDensityParallelogram(
                g_currentMission.terrainDetailId, 
                sx,sz,wx,wz,hx,hz, 
                g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, 
                g_currentMission.cultivatorValue
            );
            if dataStore.angle ~= nil then
                setDensityParallelogram(
                    g_currentMission.terrainDetailId, 
                    sx,sz,wx,wz,hx,hz, 
                    g_currentMission.terrainDetailAngleFirstChannel, g_currentMission.terrainDetailAngleNumChannels, 
                    dataStore.angle
                );
            end
        else
            setDensityMaskParams(g_currentMission.terrainDetailId, "greater", 0);
            setDensityCompareParams(g_currentMission.terrainDetailId, "greater", 0);
            dataStore.sumPixels, dataStore.numPixels, dataStore.totalPixels = setDensityMaskedParallelogram(
                g_currentMission.terrainDetailId, 
                sx,sz,wx,wz,hx,hz, 
                g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, 
                g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, 
                g_currentMission.cultivatorValue
            );
            if dataStore.angle ~= nil then
                setDensityCompareParams(g_currentMission.terrainDetailId, "greater", -1);
                setDensityMaskedParallelogram(
                    g_currentMission.terrainDetailId, 
                    sx,sz,wx,wz,hx,hz, 
                    g_currentMission.terrainDetailAngleFirstChannel, g_currentMission.terrainDetailAngleNumChannels, 
                    g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, 
                    dataStore.angle
                );
            end
        end

        --
        setDensityCompareParams(g_currentMission.terrainDetailId, "equal", g_currentMission.cultivatorValue);
        _, dataStore.areaAfter, _ = getDensityParallelogram(
            g_currentMission.terrainDetailId, 
            sx,sz,wx,wz,hx,hz, 
            g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels
        );
        --setDensityCompareParams(g_currentMission.terrainDetailId, "greater", -1);
        
        --
        TipUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
        
        -- After phase - Give plugins the possibility to affect foliage-layer(s) and dataStore, after the default effect have been done.
        for _,callFunc in pairs(Utils.sm3Plugins_CultivatorArea_PostFuncs) do
            callFunc(sx,sz,wx,wz,hx,hz, dataStore, nil)
        end
        
        return (dataStore.areaAfter - dataStore.areaBefore), dataStore.sumPixels;
    end

end

--
function soilmod:overwritePlough()
    logInfo("Overwriting Utils.updatePloughArea")

    Utils.updatePloughArea = function(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, forced, commonForced, angle)
        local sx,sz,wx,wz,hx,hz = Utils.getXZWidthAndHeight(nil, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ);
    
        -- dataStore is a 'dictionary'. Plugins can add additional elements (using very unique names) or modify the given ones if needed.
        local dataStore = {}
        dataStore.forced        = Utils.getNoNil(forced, true)
        dataStore.commonForced  = Utils.getNoNil(commonForced, true)
        dataStore.angle         = angle
        
        -- Setup phase - If any plugin needs to modify anything in dataStore
        for _,callFunc in pairs(Utils.sm3Plugins_PloughArea_Setup) do
            callFunc(sx,sz,wx,wz,hx,hz, dataStore, nil)
        end
        
        --
        setDensityCompareParams(g_currentMission.terrainDetailId, "equal", g_currentMission.ploughValue);
        _, dataStore.areaBefore, _ = getDensityParallelogram(
            g_currentMission.terrainDetailId, 
            sx,sz,wx,wz,hx,hz, 
            g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels
        );
        --setDensityCompareParams(g_currentMission.terrainDetailId, "greater", -1);
        
        -- Before phase - Give plugins the possibility to affect foliage-layer(s) and dataStore, before the default effect occurs.
        for _,callFunc in pairs(Utils.sm3Plugins_PloughArea_PreFuncs) do
            callFunc(sx,sz,wx,wz,hx,hz, dataStore, nil)
        end

        -- Default "ploughing"
        if dataStore.forced then
            setDensityCompareParams(g_currentMission.terrainDetailId, "greater", -1);
            dataStore.sumPixels, dataStore.numPixels, dataStore.totalPixels = setDensityParallelogram(
                g_currentMission.terrainDetailId, 
                sx,sz,wx,wz,hx,hz, 
                g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, 
                g_currentMission.ploughValue
            );
            if dataStore.angle ~= nil then
                setDensityParallelogram(
                    g_currentMission.terrainDetailId, 
                    sx,sz,wx,wz,hx,hz, 
                    g_currentMission.terrainDetailAngleFirstChannel, g_currentMission.terrainDetailAngleNumChannels, 
                    dataStore.angle
                );
            end
        else
            setDensityMaskParams(g_currentMission.terrainDetailId, "greater", 0);
            setDensityCompareParams(g_currentMission.terrainDetailId, "greater", 0);
            dataStore.sumPixels, dataStore.numPixels, dataStore.totalPixels = setDensityMaskedParallelogram(
                g_currentMission.terrainDetailId, 
                sx,sz,wx,wz,hx,hz, 
                g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, 
                g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, 
                g_currentMission.ploughValue
            );
            if dataStore.angle ~= nil then
                setDensityCompareParams(g_currentMission.terrainDetailId, "greater", -1);
                setDensityMaskedParallelogram(
                    g_currentMission.terrainDetailId, 
                    sx,sz,wx,wz,hx,hz, 
                    g_currentMission.terrainDetailAngleFirstChannel, g_currentMission.terrainDetailAngleNumChannels, 
                    g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, 
                    dataStore.angle
                );
            end
        end
    
        --
        setDensityCompareParams(g_currentMission.terrainDetailId, "equal", g_currentMission.ploughValue);
        _, dataStore.areaAfter, _ = getDensityParallelogram(
            g_currentMission.terrainDetailId, 
            sx,sz,wx,wz,hx,hz, 
            g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels
        );
        --setDensityCompareParams(g_currentMission.terrainDetailId, "greater", -1);
        
        --
        TipUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
        
        -- After phase - Give plugins the possibility to affect foliage-layer(s) and dataStore, after the default effect have been done.
        for _,callFunc in pairs(Utils.sm3Plugins_PloughArea_PostFuncs) do
            callFunc(sx,sz,wx,wz,hx,hz, dataStore, nil)
        end
        
        return (dataStore.areaAfter - dataStore.areaBefore), dataStore.sumPixels;
    end
    
end

--
function soilmod:overwriteSowing()
    logInfo("Overwriting Utils.updateSowingArea")
    
    Utils.updateSowingArea = function(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, angle, useDirectPlanting, plantValue)
        -- fruitDesc and the world-location are CONSTANTS! Do NOT modify, not even in the plugins!
        local fruitDesc = FruitUtil.fruitIndexToDesc[fruitId];
        local sx,sz,wx,wz,hx,hz = Utils.getXZWidthAndHeight(nil, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ);
    
        -- dataStore is a 'dictionary'. Plugins can add additional elements (using very unique names) or modify the given ones if needed.
        local dataStore = {}
        dataStore.fruitFoliageId    = g_currentMission.fruits[fruitId].id
        dataStore.angle             = Utils.getNoNil(angle, 0);
        dataStore.useDirectPlanting = Utils.getNoNil(useDirectPlanting, false);
        dataStore.plantValue        = Utils.getNoNil(plantValue, 1)
        if fruitDesc.useSeedingWidth then
            dataStore.sowingValue = g_currentMission.sowingWidthValue
        else
            dataStore.sowingValue = g_currentMission.sowingValue
        end
    
        -- Setup phase - If any plugin needs to modify anything in dataStore
        for _,callFunc in pairs(Utils.sm3Plugins_SowingArea_Setup) do
            callFunc(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
        end
        
        -- Before phase - Give plugins the possibility to affect foliage-layer(s) and dataStore, before the default effect occurs.
        for _,callFunc in pairs(Utils.sm3Plugins_SowingArea_PreFuncs) do
            callFunc(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
        end
    
        -- Default "seeding"
        if dataStore.useDirectPlanting then
            setDensityMaskParams(dataStore.fruitFoliageId, "greater", 0);
        else
            setDensityMaskParams(dataStore.fruitFoliageId, "between", g_currentMission.firstSowableValue, g_currentMission.lastSowableValue);
        end

        -- change fruit twice, once with values greater than the plant value and once with values smaller than the plant value (==0)
        -- do not change (and count) the already planted areas
        setDensityCompareParams(dataStore.fruitFoliageId, "greater", dataStore.plantValue);
        dataStore.sumDensity1, dataStore.numPixels1, dataStore.totalPixels1 = setDensityMaskedParallelogram(
            dataStore.fruitFoliageId, 
            sx,sz,wx,wz,hx,hz, 
            0, g_currentMission.numFruitDensityMapChannels, 
            g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, 
            dataStore.plantValue
        );
        
        setDensityCompareParams(dataStore.fruitFoliageId, "equals", 0);
        dataStore.sumDensity2, dataStore.numPixels2, dataStore.totalPixels2 = setDensityMaskedParallelogram(
            dataStore.fruitFoliageId, 
            sx,sz,wx,wz,hx,hz, 
            0, g_currentMission.numFruitDensityMapChannels, 
            g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, 
            dataStore.plantValue
        );
        
        --setDensityCompareParams(dataStore.fruitFoliageId, "greater", -1);
        --setDensityMaskParams(dataStore.fruitFoliageId, "greater", 0);
        
        dataStore.numPixels = dataStore.numPixels1 + dataStore.numPixels2;

        -- Set field angle and sowing texture
        if dataStore.useDirectPlanting then
            TipUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
            setDensityMaskParams(g_currentMission.terrainDetailId, "greater", 0);
        else
            setDensityMaskParams(g_currentMission.terrainDetailId, "between", g_currentMission.firstSowableValue, g_currentMission.lastSowableValue);
        end
        setDensityCompareParams(g_currentMission.terrainDetailId, "greater", -1);
        setDensityMaskedParallelogram(
            g_currentMission.terrainDetailId,
            sx,sz,wx,wz,hx,hz, 
            g_currentMission.terrainDetailAngleFirstChannel, g_currentMission.terrainDetailAngleNumChannels, 
            g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels,
            dataStore.angle
        );
        setDensityCompareParams(g_currentMission.terrainDetailId, "greater", 0);
        dataStore.sumDetailDensity, dataStore.numDetailPixels, dataStore.totalDetailPixels = setDensityMaskedParallelogram(
            g_currentMission.terrainDetailId, 
            sx,sz,wx,wz,hx,hz, 
            g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, 
            g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, 
            dataStore.sowingValue
        );
        --setDensityMaskParams(g_currentMission.terrainDetailId, "greater", 0);
    
        -- After phase - Give plugins the possibility to affect foliage-layer(s) and dataStore, after the default effect have been done.
        for _,callFunc in pairs(Utils.sm3Plugins_SowingArea_PostFuncs) do
            callFunc(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
        end

        return dataStore.numPixels, dataStore.numDetailPixels;
    end

    --
    logInfo("Overwriting Utils.updateDirectSowingArea")
    
    Utils.updateDirectSowingArea = function(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, angle, plantValue)
        return Utils.updateSowingArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, angle, true, plantValue)
    end
    
end

--
function soilmod:overwriteRoller()
    logInfo("Overwriting Utils.updateRollerArea")

    -- Added extra argument; destroyGrass
    Utils.updateRollerArea = function(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, destroyGrass)
        local sx,sz,wx,wz,hx,hz = Utils.getXZWidthAndHeight(nil, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ);

        -- dataStore is a 'dictionary'. Plugins can add additional elements (using very unique names) or modify the given ones if needed.
        local dataStore = {}
        dataStore.destroyGrass    = Utils.getNoNil(destroyGrass, false)
        
        -- Setup phase - If any plugin needs to modify anything in dataStore
        for _,callFunc in pairs(Utils.sm3Plugins_RollerArea_Setup) do
            callFunc(sx,sz,wx,wz,hx,hz, dataStore, nil)
        end
        
        -- Before phase - Give plugins the possibility to affect foliage-layer(s) and dataStore, before the default effect occurs.
        for _,callFunc in pairs(Utils.sm3Plugins_RollerArea_PreFuncs) do
            callFunc(sx,sz,wx,wz,hx,hz, dataStore, nil)
        end
    
        --
        if dataStore.destroyGrass == true then
            Utils.sm3DestroyCommonArea(sx,sz,wx,wz,hx,hz, false)
        else
            -- TODO: Isn't there a better way, instead of iterating through all the crop-types?
            for fruitIndex,fruit in pairs(g_currentMission.fruits) do
                if fruitIndex ~= FruitUtil.FRUITTYPE_GRASS then
                    setDensityCompareParams(fruit.id, "greater", 0)
                    setDensityParallelogram(
                        fruit.id,
                        sx,sz,wx,wz,hx,hz,
                        0, g_currentMission.numFruitStateChannels,
                        0
                    )
                    if fruit.preparingOutputId ~= 0 then
                        setDensityCompareParams(fruit.preparingOutputId, "greater", 0)
                        setDensityParallelogram(
                            fruit.preparingOutputId,
                            sx,sz,wx,wz,hx,hz,
                            0, 1,
                            0
                        )
                    end
                end
            end

            Utils.sm3DestroyDynamicFoliageLayers(sx,sz,wx,wz,hx,hz, false)
        end

        --
        TipUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
        
        setDensityCompareParams(g_currentMission.terrainDetailId, "greater", 0)
        _, dataStore.numPixels, _ = setDensityParallelogram(
            g_currentMission.terrainDetailId, 
            sx,sz,wx,wz,hx,hz,
            g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, 
            0
        );

        -- After phase - Give plugins the possibility to affect foliage-layer(s) and dataStore, after the default effect have been done.
        for _,callFunc in pairs(Utils.sm3Plugins_RollerArea_PostFuncs) do
            callFunc(sx,sz,wx,wz,hx,hz, dataStore, nil)
        end
        
        return dataStore.numPixels
    end
end

--
function soilmod:buildDensityMaps()
    soilmod.densityMapsFirstFruitId = {}
    local densityMapFiles = {}
    for _,entry in pairs(g_currentMission.fruits) do
        if entry.id ~= nil and entry.id ~= 0 then
            local densityMapFile = getDensityMapFilename(entry.id)
            if not densityMapFiles[densityMapFile] then
                densityMapFiles[densityMapFile] = true
                table.insert(soilmod.densityMapsFirstFruitId, entry.id)
            --    log("buildDensityMaps: id:",entry.id," file:",densityMapFile," - used in densityMapsFirstFruitId")
            --else
            --    log("buildDensityMaps: id:",entry.id," file:",densityMapFile)
            end
        end
    end
end

--
function soilmod:overwriteDestroyCommon()
    logInfo("Overwriting Utils.updateDestroyCommonArea")
    
    Utils.updateDestroyCommonArea = function(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, limitToField)
        local sx,sz,wx,wz,hx,hz = Utils.getXZWidthAndHeight(nil, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ);
        Utils.sm3DestroyCommonArea(sx,sz,wx,wz,hx,hz, limitToField)
        
        TipUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    end

    --
    logInfo("Adding Utils.sm3DestroyCommonArea")
    
    -- A slightly optimized DestroyCommonArea method, though this function requires different coordinate parameters!
    Utils.sm3DestroyCommonArea = function(sx,sz,wx,wz,hx,hz, limitToField, implementType)
        -- destroy all fruits
        if limitToField == true then
            for _,id in ipairs(soilmod.densityMapsFirstFruitId) do
                setDensityNewTypeIndexMode(    id, 2) --SET_INDEX_TO_ZERO);
                setDensityTypeIndexCompareMode(id, 2) --TYPE_COMPARE_NONE);

                setDensityMaskedParallelogram(
                    id, 
                    sx,sz,wx,wz,hx,hz, 
                    0, g_currentMission.numFruitDensityMapChannels, 
                    g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, 
                    0
                );

                setDensityNewTypeIndexMode(    id, 0) --UPDATE_INDEX);
                setDensityTypeIndexCompareMode(id, 0) --TYPE_COMPARE_EQUAL);
            end
        else
            for _,id in ipairs(soilmod.densityMapsFirstFruitId) do
                setDensityNewTypeIndexMode(    id, 2) --SET_INDEX_TO_ZERO);
                setDensityTypeIndexCompareMode(id, 2) --TYPE_COMPARE_NONE);

                setDensityParallelogram(      
                    id, 
                    sx,sz,wx,wz,hx,hz, 
                    0, g_currentMission.numFruitDensityMapChannels, 
                    0
                );

                setDensityNewTypeIndexMode(    id, 0) --UPDATE_INDEX);
                setDensityTypeIndexCompareMode(id, 0) --TYPE_COMPARE_EQUAL);
            end
        end

        Utils.sm3DestroyDynamicFoliageLayers(sx,sz,wx,wz,hx,hz, limitToField, implementType)
    end

    --
    logInfo("Adding Utils.sm3DestroyDynamicFoliageLayers")
    
    Utils.sm3DestroyDynamicFoliageLayers = function(sx,sz,wx,wz,hx,hz, limitToField, implementType)
        if limitToField == true then
            for _,layer in ipairs(soilmod.destructibleFoliageLayers) do
                setDensityCompareParams(layer.id, "greater", -1)
                setDensityMaskParams(layer.id, "greater", 0);
                setDensityMaskedParallelogram(
                    layer.id, 
                    sx,sz,wx,wz,hx,hz, 
                    0, layer.numChannels,
                    g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, 
                    0
                );
            end
        else
            for _,layer in ipairs(soilmod.destructibleFoliageLayers) do
                setDensityCompareParams(layer.id, "greater", -1)
                setDensityParallelogram( 
                    layer.id, 
                    sx,sz,wx,wz,hx,hz, 
                    0, layer.numChannels, 
                    0
                );
            end
        end
    end
end

--
function soilmod:overwriteSpray()
    logInfo("Overwriting Utils.updateSprayArea")
    
    -- Modified to take extra argument: 'fillType'
    Utils.updateSprayArea = function(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, terrainValue, sprayType, fillType)
        local sx,sz,wx,wz,hx,hz = Utils.getXZWidthAndHeight(nil, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ);
        
        local dataStore = {}
        dataStore.terrainValue  = terrainValue
        dataStore.sprayType     = sprayType   
        dataStore.moistureValue = sprayType -- 0=none, 1=wet, 2=manure, 3=wet+manure
    
--log("Utils.updateSprayArea; ",fillType,", plugins: ",Utils.sm3Plugins_SprayArea_FillTypeFuncs[fillType])
        
        -- If fillType has custom update-spray-area plugin(s), then call them
        if fillType ~= nil and Utils.sm3Plugins_SprayArea_FillTypeFuncs[fillType] ~= nil then
--log("Utils.updateSprayArea; ",fillType,", num-of-plugins: ",#Utils.sm3Plugins_SprayArea_FillTypeFuncs[fillType])
            for _,callFunc in pairs(Utils.sm3Plugins_SprayArea_FillTypeFuncs[fillType]) do
                callFunc(sx,sz,wx,wz,hx,hz, dataStore)
            end
        end
    
        local numPixels, totalPixels
        if dataStore.moistureValue > 0 then
            setDensityCompareParams(g_currentMission.terrainDetailId, "greater", -1)
            --setDensityMaskParams(g_currentMission.terrainDetailId, "greater", -1);
            if dataStore.moistureValue ~= 2 then
                -- "Wet" texture
                _, numPixels, totalPixels = setDensityParallelogram(
                    g_currentMission.terrainDetailId, 
                    sx,sz,wx,wz,hx,hz, 
                    g_currentMission.sprayFirstChannel+0, 1, 
                    --g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels,
                    1
                )
            end
            if dataStore.moistureValue ~= 1 then
                -- "Manure" texture
                _, numPixels, totalPixels = setDensityParallelogram(
                    g_currentMission.terrainDetailId, 
                    sx,sz,wx,wz,hx,hz, 
                    g_currentMission.sprayFirstChannel+1, 1, 
                    --g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels,
                    1
                )
            end
            setDensityCompareParams(g_currentMission.terrainDetailId, "greater", 0)
            --setDensityMaskParams(g_currentMission.terrainDetailId, "greater", 0);
        else
            _, numPixels, totalPixels = getDensityParallelogram(
                g_currentMission.terrainDetailId, 
                sx,sz,wx,wz,hx,hz, 
                g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels
            )
        end
    
        return numPixels, totalPixels
    end

    --
    logInfo("Overwriting Utils.resetSprayArea")
    
    Utils.resetSprayArea = function(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, force)
        -- SoilMod does it differently...
    end
end
