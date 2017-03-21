--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-01-xx
--

local sm3Layers = {}

function registerSoilModLayer(name)
    local layer = {}
    layer.layerId     = getTerrainDetailByName(g_currentMission.terrainNode, "sm3_"..name)
    layer.numChannels = getTerrainNumChannels(layer.layerId)
    
    sm3Layers[name] = layer
end

--
--
--   

function healthEffect_killCropsWhereHealthIsZero(worldCoords, fruitEntry)
    -- Set to 'cutted' where crop health is zero
    sm3SetDensityMasked(
        worldCoords,
        fruitEntry, whereBetween(fruitEntry.growing.minValue, fruitEntry.growing.maxValue),
        sm3Layers.cropHealth, whereEqual(0),
        fruitEntry.cuttedValue
    )
    -- Set to 'withered' where crop health is zero
    sm3SetDensityMasked(
        worldCoords,
        fruitEntry, whereBetween(fruitEntry.harvest.minValue, fruitEntry.harvest.maxValue),
        sm3Layers.cropHealth, whereEqual(0),
        fruitEntry.witheredValue
    )
end

function limeEffect1_UnhealthyForCrops(worldCoords, fruitEntry)
    -- Reset intermediate layer
    setIntermediateLayer(worldCoords, 0)
    -- Mark crop areas in intermediate layer
    sm3SetDensityMasked(
        worldCoords, 
        sm3Layers.intermediate, whereGreater(-1), 
        fruitEntry, whereBetween(fruitEntry.growing.minValue, fruitEntry.harvest.maxValue),
        1
    )
    -- Remove crop areas from intermediate layer where lime is NOT found
    sm3SetDensityMasked(
        worldCoords, 
        sm3Layers.intermediate, whereGreater(0), 
        sm3Layers.lime, whereEqual(0),
        0
    )
    -- Decrease health where fruit+lime exists
    sm3AddDensityMasked(
        worldCoords,
        sm3Layers.health, whereGreater(-1), 
        sm3Layers.intermediate, whereEqual(0),
        Utils.getNoNil(fruitEntry.limeEffectValue, -10)
    )
end

function limeEffect2_IncreaseSoilpH(worldCoords, fruitEntry)
    -- Increase soil pH where there's lime
    sm3AddDensityMasked(
        worldCoords,
        sm3Layers.soilpH, whereGreater(-1),
        sm3Layers.lime, whereEqual(1),
        2
    )
    -- Remove lime
    sm3SetDensity(
        worldCoords,
        sm3Layers.lime, whereGreater(-1),
        0
    )
end

--
--
--

function setIntermediateLayer(worldCoords, value)
    setDensityParallelogram(
        sm3Layers.intermediate.layerId,
        unpack(worldCoords),
        0,sm3Layers.intermediate.numChannels,
        Utils.getNoNil(value, 0)
    )
end

-- Methods for creating 'compare' and 'mask' parameters
function whereEqual(value)
    return {"equal", value}
end
function whereBetween(low,high)
    return {"between", low, high}
end
function whereGreater(value)
    return {"greater", value}
end

-- Wrapper methods
function sm3SetDensity(worldCoords, layerEntry, compareParams, newValue)
    setDensityCompareParams(layerEntry.layerId, unpack(compareParams))
    setDensityMaskedParallelogram(
        layerEntry.layerId,
        unpack(worldCoords),
        0,layerEntry.numChannels,
        newValue
    )
end
function sm3SetDensityMasked(worldCoords, layerEntry, compareParams, maskLayer, maskParams, newValue)
    setDensityMaskParams(layerEntry.layerId, unpack(maskParams))
    setDensityCompareParams(layerEntry.layerId, unpack(compareParams))
    setDensityMaskedParallelogram(
        layerEntry.layerId,
        unpack(worldCoords),
        0,layerEntry.numChannels,
        maskLayer.layerId, 0,maskLayer.numChannels,
        newValue
    )
end
function sm3AddDensityMasked(worldCoords, layerEntry, compareParams, maskLayer, maskParams, addValue)
    setDensityMaskParams(layerEntry.layerId, unpack(maskParams))
    setDensityCompareParams(layerEntry.layerId, unpack(compareParams))
    addDensityMaskedParallelogram(
        layerEntry.layerId,
        unpack(worldCoords),
        0,layerEntry.numChannels,
        maskLayer.layerId, 0,maskLayer.numChannels,
        addValue
    )
end
