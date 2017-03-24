--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-03-xx
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
    --
    local layerHealth = soilmod.getLayer("health")
    local layerLime = soilmod.getLayer("lime")
    local layerTemp = soilmod.setIntermediateLayer(worldCoords, 0)
    -- Mark crop areas in intermediate layer
    soilmod.setDensityMasked(
        worldCoords, 
        layerTemp, soilmod.densityGreater(-1), 
        fruitEntry:getLayer(), soilmod.densityBetween(fruitEntry:get("growing#minValue"), fruitEntry:get("harvest#maxValue")),
        1
    )
    -- Remove crop areas from intermediate layer where lime is NOT found
    soilmod.setDensityMasked(
        worldCoords, 
        layerTemp, soilmod.densityGreater(0), 
        layerLime, soilmod.densityEqual(0),
        0
    )
    -- Decrease health where fruit+lime exists
    soilmod.addDensityMasked(
        worldCoords,
        layerHealth, soilmod.densityGreater(-1), 
        layerTemp, soilmod.densityEqual(0),
        Utils.getNoNil(fruitEntry.limeEffectValue, -10)
    )
end

function soilmod.limeEffect2_IncreaseSoilpH(worldCoords, fruitEntry)
    local layerSoilpH = soilmod.getLayer("soil_pH")
    local layerLime = soilmod.getLayer("lime")
    -- Increase soil pH where there's lime
    soilmod.addDensityMasked(
        worldCoords,
        layerSoilpH, soilmod.densityGreater(-1),
        layerLime, soilmod.densityEqual(1),
        2
    )
    -- Remove lime
    soilmod.setDensity(
        worldCoords,
        layerLime, soilmod.densityGreater(-1),
        0
    )
end

--
--
--

function soilmod.setIntermediateLayer(worldCoords, value)
    local layer = soilmod.getLayer("intermediate")
    setDensityParallelogram(
        layer.layerId,
        worldCoords[1],worldCoords[2], worldCoords[3],worldCoords[4], worldCoords[5],worldCoords[6],
        0,layer.numChannels,
        Utils.getNoNil(value, 0)
    )
    return layer
end

-- Methods for creating 'compare' and 'mask' parameters
function soilmod.densityEqual(value)
    return {"equal", value}
end
function soilmod.densityBetween(low,high)
    return {"between", low, high}
end
function soilmod.densityGreater(value)
    return {"greater", value}
end

-- Wrapper methods
function soilmod.getDensity(worldCoords, layer, compareParams)
    setDensityCompareParams(layer.layerId, unpack(compareParams))
    return getDensityParallelogram(
        layer.layerId,
        worldCoords[1],worldCoords[2], worldCoords[3],worldCoords[4], worldCoords[5],worldCoords[6],
        0,layer.numChannels
    )
end

function soilmod.setDensity(worldCoords, layerName, compareParams, newValue)
    local layer = soilmod.getLayer(layerName)
    setDensityCompareParams(layer.layerId, unpack(compareParams))
    setDensityParallelogram(
        layer.layerId,
        worldCoords[1],worldCoords[2], worldCoords[3],worldCoords[4], worldCoords[5],worldCoords[6],
        0,layer.numChannels,
        newValue
    )
end

function soilmod.setDensityMasked(worldCoords, layerName, compareParams, maskLayerName, maskParams, newValue)
    local layer = soilmod.getLayer(layerName)
    local maskLayer = soilmod.getLayer(maskLayerName)
    setDensityMaskParams(layer.layerId, unpack(maskParams))
    setDensityCompareParams(layer.layerId, unpack(compareParams))
    setDensityMaskedParallelogram(
        layer.layerId,
        worldCoords[1],worldCoords[2], worldCoords[3],worldCoords[4], worldCoords[5],worldCoords[6],
        0,layer.numChannels,
        maskLayer.layerId, 0,maskLayer.numChannels,
        newValue
    )
end

function soilmod.addDensityMasked(worldCoords, layerName, compareParams, maskLayerName, maskParams, addValue)
    local layer = soilmod.getLayer(layerName)
    local maskLayer = soilmod.getLayer(maskLayerName)
    setDensityMaskParams(layer.layerId, unpack(maskParams))
    setDensityCompareParams(layer.layerId, unpack(compareParams))
    addDensityMaskedParallelogram(
        layer.layerId,
        worldCoords[1],worldCoords[2], worldCoords[3],worldCoords[4], worldCoords[5],worldCoords[6],
        0,layer.numChannels,
        maskLayer.layerId, 0,maskLayer.numChannels,
        addValue
    )
end
