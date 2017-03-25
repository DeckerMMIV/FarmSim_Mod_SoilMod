--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-03-xx
--

function soilmod:registerLayer(layerName, foliageName, isVisible, requiredNumChannels)
    local layer = {}

    layer.layerName     = layerName
    layer.foliageName   = foliageName
    layer.isVisible     = isVisible
    layer.requiredNumChannels = requiredNumChannels
    
    layer.layerId = getChild(g_currentMission.terrainRootNode, foliageName)
    if layer.layerId ~= nil and layer.layerId ~= 0 then
        layer.numChannels = getTerrainDetailNumChannels(layer.layerId)
    end
    
    self.layers = Utils.getNoNil(self.layers, {})
    self.layers[layerName] = layer
end

function soilmod:verifyLayers()
    local allOk = true
    
    local mapSize = getDensityMapSize(g_currentMission.fruits[1].id)
    local mapSizeMismatch = false
    
    local densityFileChannels = {}
    for layerName,layer in pairs(self.layers) do
        if layer.layerId == nil or layer.layerId == 0
        or layer.numChannels ~= layer.requiredNumChannels then
            allOk = false
            logInfo("ERROR! Required foliage-layer '",layer.foliageName,"' either does not exist (layerId=",layer.layerId,"), or have wrong num-channels (",layer.numChannels,")")
        else
            if layer.isVisible then
                g_currentMission:loadFoliageLayer(layer.foliageName, -5, -1, true, "alphaBlendStartEnd")
            end
                
            local densityMapSize    = getDensityMapSize(layer.layerId)
            if densityMapSize ~= mapSize then
                mapSizeMismatch = true
            end
            
            local densityFileName   = getDensityMapFilename(layer.layerId)
            densityFileChannels[densityFileName] = Utils.getNoNil(densityFileChannels[densityFileName], 0) + layer.numChannels
           
            logInfo("Foliage-layer check ok: '",layer.foliageName,"'"
                ,", id=",           layer.layerId
                ,",numChnls=",      layer.numChannels
                ,",size=",          densityMapSize
                ,",densityFile=",   densityFileName
            )
        end
    end

    -- SoilMod's density-map files should have the same width/height as the fruit_density file.
    if mapSizeMismatch then
        logInfo("")
        logInfo("WARNING! Mismatching width/height for density files. The fruit_density and SoilMod's density files should all have the same width/height, else unexpected growth may appear.")
        logInfo("")
    end

    --
    local maxPossibleChannels = 15
    for densityFileName,totalChannels in pairs(densityFileChannels) do
        if totalChannels > maxPossibleChannels then
            allOK = false
            logInfo("ERROR! Detected invalid foliage-multi-layer for SoilMod. The density-file '",densityFileName,"' apparently uses more than ",maxPossibleChannels," channels(bits) which is impossible.")
        end
    end
    
    return allOk
end

function soilmod:getLayer(layerName)
--  DEBUG
    if self.layers[layerName] == nil then
        logInfo("ERROR! getLayer() called with unknown layer-name '",layerName,"'")
        return nil
    end
--]]DEBUG
    return self.layers[layerName]
end
function soilmod:getLayerId(layerName)
--  DEBUG
    if self.layers[layerName] == nil then
        logInfo("ERROR! getLayerId() called with unknown layer-name '",layerName,"'")
        return nil
    end
--]]DEBUG
    return self.layers[layerName].layerId
end

--
--
--   

function soilmod:healthEffect_killCropsWhereHealthIsZero(tpCoords, fruitEntry)
    local layerHealth = self:getLayer("health")
    -- Set to 'cutted' where crop health is zero
    self.setDensityMasked(
        tpCoords,
        fruitEntry:getLayer(), self.densityBetween(fruitEntry:get("growing#minValue"), fruitEntry:get("growing#maxValue")),
        layerHealth, self.densityEqual(0),
        fruitEntry:get("cuttedValue")
    )
    -- Set to 'withered' where crop health is zero
    self.setDensityMasked(
        tpCoords,
        fruitEntry:getLayer(), self.densityBetween(fruitEntry:get("harvest#minValue"), fruitEntry:get("harvest#maxValue")),
        layerHealth, self.densityEqual(0),
        fruitEntry:get("witheredValue")
    )
end

function soilmod:limeEffect1_UnhealthyForCrops(tpCoords, fruitEntry)
    local layerTemp = self:resetIntermediateLayer(tpCoords, 0)
    -- Mark crop areas in intermediate layer
    self.setDensityMasked(
        tpCoords, 
        layerTemp, soilmod.densityGreater(-1), 
        fruitEntry:getLayer(), soilmod.densityBetween(fruitEntry:get("growing#minValue"), fruitEntry:get("harvest#maxValue")),
        1
    )
    -- Remove crop areas from intermediate layer where lime is NOT found
    local layerLime = self:getLayer("lime")
    self.setDensityMasked(
        tpCoords, 
        layerTemp, soilmod.densityGreater(0), 
        layerLime, soilmod.densityEqual(0),
        0
    )
    -- Decrease health where fruit+lime exists
    local layerHealth = self:getLayer("health")
    self.addDensityMasked(
        tpCoords,
        layerHealth, soilmod.densityGreater(0), 
        layerTemp, soilmod.densityEqual(0),
        Utils.getNoNil(fruitEntry:get("limeEffectValue"), -10)
    )
end

function soilmod:limeEffect2_IncreaseSoilpH(tpCoords, fruitEntry)
    local layerSoilpH = self:getLayer("soil_pH")
    local layerLime = self:getLayer("lime")
    -- Increase soil pH where there's lime
    soilmod.addDensityMasked(
        tpCoords,
        layerSoilpH, soilmod.densityGreater(-1),
        layerLime, soilmod.densityEqual(1),
        2
    )
    -- Remove lime
    soilmod.setDensity(
        tpCoords,
        layerLime, soilmod.densityGreater(0),
        0
    )
end

--
--
--

--
function soilmod:resetIntermediateLayer(tpCoords, value)
    local layer = self:getLayer("intermediate")
    setDensityCompareParams(layer.layerId, "greater", 0)
    setDensityParallelogram(
        layer.layerId,
        tpCoords[1],tpCoords[2], tpCoords[3],tpCoords[4], tpCoords[5],tpCoords[6],
        0,layer.numChannels,
        Utils.getNoNil(value, 0)
    )
    return layer
end

-- Methods for creating 'compare' and 'mask' parameters
function soilmod.densityEqual(value)
    return { "equal", value }
end
function soilmod.densityBetween(low,high)
    return { "between", low, high }
end
function soilmod.densityGreater(value)
    return { "greater", value }
end

-- Wrapper methods
function soilmod.getDensity(tpCoords, layer, compareParams)
    setDensityCompareParams(layer.layerId, unpack(compareParams))
    return getDensityParallelogram(
        layer.layerId,
        tpCoords[1],tpCoords[2], tpCoords[3],tpCoords[4], tpCoords[5],tpCoords[6],
        0,layer.numChannels
    )
end

function soilmod.setDensity(tpCoords, layer, compareParams, newValue)
    setDensityCompareParams(layer.layerId, unpack(compareParams))
    return setDensityParallelogram(
        layer.layerId,
        tpCoords[1],tpCoords[2], tpCoords[3],tpCoords[4], tpCoords[5],tpCoords[6],
        0,layer.numChannels,
        newValue
    )
end

function soilmod.setDensityMasked(tpCoords, layer, compareParams, maskLayer, maskParams, newValue)
    setDensityCompareParams(layer.layerId, unpack(compareParams))
    setDensityMaskParams(layer.layerId, unpack(maskParams))
    return setDensityMaskedParallelogram(
        layer.layerId,
        tpCoords[1],tpCoords[2], tpCoords[3],tpCoords[4], tpCoords[5],tpCoords[6],
        0,layer.numChannels,
        maskLayer.layerId, 0,maskLayer.numChannels,
        newValue
    )
end

function soilmod.addDensityMasked(tpCoords, layer, compareParams, maskLayer, maskParams, addValue)
    setDensityCompareParams(layer.layerId, unpack(compareParams))
    setDensityMaskParams(layer.layerId, unpack(maskParams))
    return addDensityMaskedParallelogram(
        layer.layerId,
        tpCoords[1],tpCoords[2], tpCoords[3],tpCoords[4], tpCoords[5],tpCoords[6],
        0,layer.numChannels,
        maskLayer.layerId, 0,maskLayer.numChannels,
        addValue
    )
end
