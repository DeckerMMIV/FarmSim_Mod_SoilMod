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
        layer.channelOffset = 0
        layer.numChannels = getTerrainDetailNumChannels(layer.layerId)
    end
    
    self.layers = Utils.getNoNil(self.layers, {})
    self.layers[layerName] = layer
end

function soilmod:registerSpecialLayers()

    local layer = {}
    layer.special               = true
    layer.layerName             = "terrainGround"
    layer.foliageName           = "(terrainGround)"
    layer.layerId               = g_currentMission.terrainDetailId
    layer.channelOffset         = g_currentMission.terrainDetailTypeFirstChannel
    layer.numChannels           = g_currentMission.terrainDetailTypeNumChannels
    layer.requiredNumChannels   = 3
    self.layers[layer.layerName]= layer
    --
    local layer = {}
    layer.special               = true
    layer.layerName             = "wetness"
    layer.foliageName           = "(wetness)"
    layer.layerId               = g_currentMission.terrainDetailId
    layer.channelOffset         = g_currentMission.sprayFirstChannel + 0
    layer.numChannels           = 1
    layer.requiredNumChannels   = 1
    self.layers[layer.layerName]= layer
    --
    local layer = {}
    layer.special               = true
    layer.layerName             = "manure"
    layer.foliageName           = "(manure)"
    layer.layerId               = g_currentMission.terrainDetailId
    layer.channelOffset         = g_currentMission.sprayFirstChannel + 1
    layer.numChannels           = 1
    layer.requiredNumChannels   = 1
    self.layers[layer.layerName]= layer
    -- Repurposing the base-game's spraylevel channels, to be used for 'growth delay when seeding'
    local layer = {}
    layer.special               = true
    layer.layerName             = "growthDelay"
    layer.foliageName           = "(growthDelay)"
    layer.layerId               = g_currentMission.terrainDetailId
    layer.channelOffset         = g_currentMission.sprayLevelFirstChannel
    layer.numChannels           = g_currentMission.sprayLevelNumChannels
    layer.requiredNumChannels   = 2
    self.layers[layer.layerName]= layer
    --
    local layer = {}
    layer.special               = true
    layer.layerName             = "weedGrowth"
    layer.foliageName           = "(weedGrowth)"
    layer.layerId               = self:getLayerId("weed")
    layer.channelOffset         = 0
    layer.numChannels           = 3
    layer.requiredNumChannels   = 3
    self.layers[layer.layerName]= layer
    --
    local layer = {}
    layer.special               = true
    layer.layerName             = "weedAlive"
    layer.foliageName           = "(weedAlive)"
    layer.layerId               = self:getLayerId("weed")
    layer.channelOffset         = 2
    layer.numChannels           = 1
    layer.requiredNumChannels   = 1
    self.layers[layer.layerName]= layer
    --
    local layer = {}
    layer.special               = true
    layer.layerName             = "intermediate1"
    layer.foliageName           = "(intermediate1)"
    layer.layerId               = self:getLayerId("intermediate")
    layer.channelOffset         = 0
    layer.numChannels           = 1
    layer.requiredNumChannels   = 1
    self.layers[layer.layerName]= layer
    --
    local layer = {}
    layer.special               = true
    layer.layerName             = "intermediate2"
    layer.foliageName           = "(intermediate2)"
    layer.layerId               = self:getLayerId("intermediate")
    layer.channelOffset         = 1
    layer.numChannels           = 1
    layer.requiredNumChannels   = 1
    self.layers[layer.layerName]= layer
end

function soilmod:verifyLayers()
    local allOk = true
    
    local mapSize = getDensityMapSize(g_currentMission.fruits[1].id)
    local mapSizeMismatch = false
    
    local densityFileChannels = {}
    for layerName,layer in pairs(self.layers) do
        if layer.special == true then
            -- do nothing
        elseif layer.layerId == nil or layer.layerId == 0
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
function soilmod:resetIntermediateLayer(tpCoords, value)
    local layer = self:getLayer("intermediate")
    setDensityCompareParams(layer.layerId, "greater", 0)
    setDensityParallelogram(
        layer.layerId,
        tpCoords[1],tpCoords[2], tpCoords[3],tpCoords[4], tpCoords[5],tpCoords[6],
        layer.channelOffset,layer.numChannels,
        Utils.getNoNil(value, 0)
    )
    return layer
end

--
--

-- Methods for creating 'compare' and 'mask' parameters
function soilmod.densityEqual(value)
    return { "equal", value }
end
function soilmod.densityEquals(value) -- Due to making the same typo-error several times.
    return { "equal", value }
end
function soilmod.densityBetween(low,high)
    return { "between", low, high }
end
function soilmod.densityGreater(value)
    return { "greater", value }
end

--
--

-- Wrapper methods
function soilmod.getDensity(tpCoords, layer, compareParams)
    setDensityCompareParams(layer.layerId, unpack(compareParams))
    return getDensityParallelogram(
        layer.layerId,
        tpCoords[1],tpCoords[2], tpCoords[3],tpCoords[4], tpCoords[5],tpCoords[6],
        layer.channelOffset,layer.numChannels
    )
end

function soilmod.setDensity(tpCoords, layer, compareParams, newValue)
    setDensityCompareParams(layer.layerId, unpack(compareParams))
    return setDensityParallelogram(
        layer.layerId,
        tpCoords[1],tpCoords[2], tpCoords[3],tpCoords[4], tpCoords[5],tpCoords[6],
        layer.channelOffset,layer.numChannels,
        newValue
    )
end

function soilmod.addDensity(tpCoords, layer, compareParams, addValue)
    setDensityCompareParams(layer.layerId, unpack(compareParams))
    return addDensityParallelogram(
        layer.layerId,
        tpCoords[1],tpCoords[2], tpCoords[3],tpCoords[4], tpCoords[5],tpCoords[6],
        layer.channelOffset,layer.numChannels,
        addValue
    )
end

function soilmod.getDensityMasked(tpCoords, layer, compareParams, maskLayer, maskParams)
    setDensityCompareParams(layer.layerId, unpack(compareParams))
    setDensityMaskParams(layer.layerId, unpack(maskParams))
    return getDensityMaskedParallelogram(
        layer.layerId,
        tpCoords[1],tpCoords[2], tpCoords[3],tpCoords[4], tpCoords[5],tpCoords[6],
        layer.channelOffset,layer.numChannels,
        maskLayer.layerId,
        maskLayer.channelOffset,maskLayer.numChannels
    )
end

function soilmod.setDensityMasked(tpCoords, layer, compareParams, maskLayer, maskParams, newValue)
    setDensityCompareParams(layer.layerId, unpack(compareParams))
    setDensityMaskParams(layer.layerId, unpack(maskParams))
    return setDensityMaskedParallelogram(
        layer.layerId,
        tpCoords[1],tpCoords[2], tpCoords[3],tpCoords[4], tpCoords[5],tpCoords[6],
        layer.channelOffset,layer.numChannels,
        maskLayer.layerId,
        maskLayer.channelOffset,maskLayer.numChannels,
        newValue
    )
end

function soilmod.addDensityMasked(tpCoords, layer, compareParams, maskLayer, maskParams, addValue)
    setDensityCompareParams(layer.layerId, unpack(compareParams))
    setDensityMaskParams(layer.layerId, unpack(maskParams))
    return addDensityMaskedParallelogram(
        layer.layerId,
        tpCoords[1],tpCoords[2], tpCoords[3],tpCoords[4], tpCoords[5],tpCoords[6],
        layer.channelOffset,layer.numChannels,
        maskLayer.layerId,
        maskLayer.channelOffset,maskLayer.numChannels,
        addValue
    )
end
