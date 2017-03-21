--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-01-xx
--

sm3SoilModPlugins = {}

-- Register this mod for callback from SoilMod's plugin facility
getfenv(0)["modSoilMod3Plugins"] = getfenv(0)["modSoilMod3Plugins"] or {}
table.insert(getfenv(0)["modSoilMod3Plugins"], sm3SoilModPlugins)

--
-- This function MUST BE named "soilModPluginCallback" and take two arguments!
-- It is the callback method, that SoilMod's plugin facility will call, to let this mod add its own plugins to SoilMod.
-- The argument is a 'table of functions' which must be used to add this mod's plugin-functions into SoilMod.
--
function sm3SoilModPlugins.soilModPluginCallback(soilMod,settings)

    --
    sm3SoilModPlugins.reduceWindrows        = settings.getKeyAttrValue("plugins.sm3SoilModPlugins",  "reduceWindrows",      true)
    sm3SoilModPlugins.removeSprayMoisture   = settings.getKeyAttrValue("plugins.sm3SoilModPlugins",  "removeSprayMoisture", true)

    if (not sm3SoilModPlugins.reduceWindrows)
    or (not sm3SoilModPlugins.removeSprayMoisture)
    then
        logInfo("reduceWindrows=",sm3SoilModPlugins.reduceWindrows,", removeSprayMoisture=",sm3SoilModPlugins.removeSprayMoisture)
    end

    -- Gather the required special foliage-layers for Soil Management & Growth Control.
    local allOK = sm3SoilModPlugins.setupFoliageLayers(soilMod)

    if allOK then
        -- Using SoilMod's plugin facility, we add SoilMod's own effects for each of the particular "Utils." functions
        -- To keep my own sanity, all the plugin-functions for each particular "Utils." function, have their own block:
        sm3SoilModPlugins.pluginsForCutFruitArea(        soilMod)
        sm3SoilModPlugins.pluginsForUpdateCultivatorArea(soilMod)
        sm3SoilModPlugins.pluginsForUpdatePloughArea(    soilMod)
        sm3SoilModPlugins.pluginsForUpdateSowingArea(    soilMod)
        sm3SoilModPlugins.pluginsForUpdateSprayArea(     soilMod)
        sm3SoilModPlugins.pluginsForUpdateWeederArea(   soilMod) -- SoilMod custom tool
        -- And for the 'growth-cycle' plugins:
        sm3SoilModPlugins.pluginsForGrowthCycle(         soilMod)
        --
        sm3SoilModPlugins.pluginsForWeatherCycle(        soilMod)
    end

    return allOK

end

--
local function hasFoliageLayer(foliageId)
    return (foliageId ~= nil and foliageId ~= 0);
end

local function getFoliageLayer(name, isVisible)
    local foliageId = getChild(g_currentMission.terrainRootNode, name)
    if hasFoliageLayer(foliageId) then
        if isVisible then
            foliageId = g_currentMission:loadFoliageLayer(name, -5, -1, true, "alphaBlendStartEnd")
        end
        return foliageId
    end
    return nil
end

--
function sm3SoilModPlugins.setupFoliageLayers(soilMod)
    -- Get foliage-layers that contains visible graphics (i.e. has material that uses shaders)
    g_currentMission.sm3FoliageManure           = getFoliageLayer("sm3_manure"        ,true)
    g_currentMission.sm3FoliageSlurry           = getFoliageLayer("sm3_slurry"        ,true)
    g_currentMission.sm3FoliageWeed             = getFoliageLayer("sm3_weed"          ,true)
    g_currentMission.sm3FoliageLime             = getFoliageLayer("sm3_lime"          ,true)
    g_currentMission.sm3FoliageFertilizer       = getFoliageLayer("sm3_fertilizer"    ,true)
    g_currentMission.sm3FoliageHerbicide        = getFoliageLayer("sm3_herbicide"     ,true)
    g_currentMission.sm3FoliageWater            = getFoliageLayer("sm3_water"         ,true)
    ---- Get foliage-layers that are invisible (i.e. has viewdistance=0 and a material that is "blank")
    g_currentMission.sm3FoliageSoil_pH          = getFoliageLayer("sm3_soil_pH"       ,false)
    g_currentMission.sm3FoliageFertN            = getFoliageLayer("sm3_fertN"         ,false)
    g_currentMission.sm3FoliageFertPK           = getFoliageLayer("sm3_fertPK"        ,false)
    g_currentMission.sm3FoliageMoisture         = getFoliageLayer("sm3_moisture"      ,false)
    g_currentMission.sm3FoliageHerbicideTime    = getFoliageLayer("sm3_herbicideTime" ,false)

    --
    local function verifyFoliage(foliageName, foliageId, reqChannels, grleFileChannels)
        local numChannels
        if hasFoliageLayer(foliageId) then
                  numChannels    = getTerrainDetailNumChannels(foliageId)
            local densityMapSize = getDensityMapSize(foliageId)
            if numChannels == reqChannels then
                local grleFileName = getDensityMapFileName(foliageId)
                grleFileChannels[grleFileName] = Utils.getNoNil(grleFileChannels[grleFileName], 0) + numChannels
                --
                logInfo("Foliage-layer check ok: '",foliageName,"'"
                    ,", id=",        foliageId
                    ,",numChnls=",  numChannels
                    ,",size=",      densityMapSize
                    --,",parent=",    getParent(foliageId)
                    ,",grleFile=",  grleFileName
                )
                return true
            end
        end;
        logInfo("ERROR! Required foliage-layer '",foliageName,"' either does not exist (foliageId=",foliageId,"), or have wrong num-channels (",numChannels,")")
        return false
    end

    local allOK = true
    local grleFileChannels = {}

    allOK = verifyFoliage("sm3_manure"        ,g_currentMission.sm3FoliageManure         ,2 ,grleFileChannels) and allOK;
    allOK = verifyFoliage("sm3_slurry"        ,g_currentMission.sm3FoliageSlurry         ,2 ,grleFileChannels) and allOK;
    allOK = verifyFoliage("sm3_weed"          ,g_currentMission.sm3FoliageWeed           ,4 ,grleFileChannels) and allOK;
    allOK = verifyFoliage("sm3_lime"          ,g_currentMission.sm3FoliageLime           ,1 ,grleFileChannels) and allOK;
    allOK = verifyFoliage("sm3_fertilizer"    ,g_currentMission.sm3FoliageFertilizer     ,3 ,grleFileChannels) and allOK;
    allOK = verifyFoliage("sm3_herbicide"     ,g_currentMission.sm3FoliageHerbicide      ,2 ,grleFileChannels) and allOK;
    allOK = verifyFoliage("sm3_water"         ,g_currentMission.sm3FoliageWater          ,2 ,grleFileChannels) and allOK;
    allOK = verifyFoliage("sm3_soil_pH"       ,g_currentMission.sm3FoliageSoil_pH        ,4 ,grleFileChannels) and allOK;
    allOK = verifyFoliage("sm3_fertN"         ,g_currentMission.sm3FoliageFertN          ,4 ,grleFileChannels) and allOK;
    allOK = verifyFoliage("sm3_fertPK"        ,g_currentMission.sm3FoliageFertPK         ,3 ,grleFileChannels) and allOK;
    allOK = verifyFoliage("sm3_moisture"      ,g_currentMission.sm3FoliageMoisture       ,3 ,grleFileChannels) and allOK;
    allOK = verifyFoliage("sm3_herbicideTime" ,g_currentMission.sm3FoliageHerbicideTime  ,2 ,grleFileChannels) and allOK;

    --
    if allOK then
        -- Attempt to detect the "mis-guided fix" that appeared, due to patch 1.3 beta-1's "Error: TerrainLodTexture can only handle 6 data channels per density map type."
        for grleFile,v in pairs(grleFileChannels) do
            if v > 16 then
                allOK = false
                logInfo("ERROR! Detected invalid foliage-multi-layer for SoilMod. The GRLE '",grleFile,"' apparently uses more than 16 channels(bits) which is impossible.")
                break;
            end
        end
    end

    --
    if allOK then
        -- Verify that SoilMod's two GRLE files, have the same width/height as the fruit_density.GRLE file.
        local mapSize = getDensityMapSize(g_currentMission.fruits[1].id)
        if mapSize ~= getDensityMapSize(g_currentMission.sm3FoliageManure)
        or mapSize ~= getDensityMapSize(g_currentMission.sm3FoliageHerbicideTime) then
            logInfo("")
            logInfo("WARNING! Mismatching width/height for GRLE files. The fruit_density.GRLE and SoilMod's two GRLE files should all have the same width/height, else unexpected growth may appear.")
            logInfo("")
        end
    end

    --
    if allOK then
        -- Add the non-visible foliage-layer to be saved too.
        table.insert(g_currentMission.dynamicFoliageLayers, g_currentMission.sm3FoliageSoil_pH)

        -- Allow weeds to be destroyed too
        soilMod.addDestructibleFoliageId(g_currentMission.sm3FoliageWeed)

        -- Try to "optimize" a for-loop in sm3Updatesm3Foliage()
        sm3SoilModPlugins.sm3FoliageLayersWindrows = {}
        for _,fruit in pairs(g_currentMission.fruits) do
            if fruit.windrowId ~= nil and fruit.windrowId ~= 0 then
                table.insert(sm3SoilModPlugins.sm3FoliageLayersWindrows, fruit)
            end
        end

        -- Try to "optimize" a for-loop in sm3Updatesm3Foliage()
        sm3SoilModPlugins.sm3FoliageLayersCrops = {}
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
                    table.insert(sm3SoilModPlugins.sm3FoliageLayersCrops, props)
                end
            end
        end

    end

    return allOK
end

--
function sm3SoilModPlugins.pluginsForCutFruitArea(soilMod)
    --
    -- Additional effects for the Utils.CutFruitArea()
    --

    --
    soilMod.addPlugin_CutFruitArea_after(
        "Volume affected if partial-growth-state for crop",
        5,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            if fruitDesc.allowsPartialGrowthState then
                dataStore.volume = dataStore.pixelsSum / fruitDesc.maxHarvestingGrowthState
            end
        end
    )

    ---- Special case; if fertN layer is not there, then add the default "double yield from spray layer" effect.
    if not hasFoliageLayer(g_currentMission.sm3FoliageFertN) then
        soilMod.addPlugin_CutFruitArea_before(
            "Remove spray where min/max-harvesting-growth-state is",
            5,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                if dataStore.destroySpray then
                    setDensityMaskParams(g_currentMission.terrainDetailId, "between", dataStore.minHarvestingGrowthState, dataStore.maxHarvestingGrowthState);
                    dataStore.spraySum = setDensityMaskedParallelogram(
                        g_currentMission.terrainDetailId,
                        sx,sz,wx,wz,hx,hz,
                        g_currentMission.sprayChannel, 1,
                        dataStore.fruitFoliageId, 0, g_currentMission.numFruitStateChannels,
                        0 -- value
                    );
                    setDensityMaskParams(g_currentMission.terrainDetailId, "greater", 0);
                end
            end
        )
    end

    --
    soilMod.addPlugin_CutFruitArea_before(
        "Set sowing-channel where min/max-harvesting-growth-state is",
        10,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            if fruitDesc.useSeedingWidth and (dataStore.destroySeedingWidth == nil or dataStore.destroySeedingWidth) then
                setDensityMaskParams(g_currentMission.terrainDetailId, "between", dataStore.minHarvestingGrowthState, dataStore.maxHarvestingGrowthState);
                setDensityMaskedParallelogram(
                    g_currentMission.terrainDetailId,
                    sx,sz,wx,wz,hx,hz,
                    g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels,
                    dataStore.fruitFoliageId, 0, g_currentMission.numFruitStateChannels,
                    2^g_currentMission.sowingChannel  -- value
                );
                setDensityMaskParams(g_currentMission.terrainDetailId, "greater", 0);
            end
        end
    )

    -- Only add effect, when required foliage-layer exist
    if hasFoliageLayer(g_currentMission.sm3FoliageWeed) then
        soilMod.addPlugin_CutFruitArea_before(
            "Get weed density and cut weed",
            20,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Get weeds, but only the lower 2 bits (values 0-3), and then set them to zero.
                -- This way weed gets cut, but alive weed will still grow again.
                setDensityCompareParams(g_currentMission.sm3FoliageWeed, "greater", 0);
                dataStore.weeds = {}
                dataStore.weeds.oldSum, dataStore.weeds.numPixels, dataStore.weeds.newDelta = setDensityParallelogram(
                    g_currentMission.sm3FoliageWeed,
                    sx,sz,wx,wz,hx,hz,
                    0,2,
                    0 -- value
                )
                setDensityCompareParams(g_currentMission.sm3FoliageWeed, "greater", -1);
            end
        )

        soilMod.addPlugin_CutFruitArea_after(
            "Volume is affected by percentage of weeds",
            20,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                if dataStore.weeds.numPixels > 0 and dataStore.numPixels > 0 then
                    dataStore.weeds.weedPct = (dataStore.weeds.oldSum / (3 * dataStore.weeds.numPixels)) * (dataStore.weeds.numPixels / dataStore.numPixels)
                    -- Remove some volume that weeds occupy.
                    dataStore.volume = math.max(0, dataStore.volume - (dataStore.volume * dataStore.weeds.weedPct))
                end
            end
        )
    end

    -- Only add effect, when required foliage-layer exist
    if hasFoliageLayer(g_currentMission.sm3FoliageFertN) then
        -- TODO - Try to add for different fruit-types.
        sm3SoilModPlugins.fertNCurve = AnimCurve:new(linearInterpolator1)
        sm3SoilModPlugins.fertNCurve:addKeyframe({ v=0.00, time= 0 })
        sm3SoilModPlugins.fertNCurve:addKeyframe({ v=0.20, time= 1 })
        sm3SoilModPlugins.fertNCurve:addKeyframe({ v=0.50, time= 2 })
        sm3SoilModPlugins.fertNCurve:addKeyframe({ v=0.70, time= 3 })
        sm3SoilModPlugins.fertNCurve:addKeyframe({ v=0.90, time= 4 })
        sm3SoilModPlugins.fertNCurve:addKeyframe({ v=1.00, time= 5 })
        sm3SoilModPlugins.fertNCurve:addKeyframe({ v=0.50, time=15 })

        soilMod.addPlugin_CutFruitArea_before(
            "Get N density",
            30,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Get N
                dataStore.fertN = {}
                dataStore.fertN.sumPixels, dataStore.fertN.numPixels, dataStore.fertN.totPixels = getDensityParallelogram(
                    g_currentMission.sm3FoliageFertN,
                    sx,sz,wx,wz,hx,hz,
                    0,4
                )
            end
        )

        soilMod.addPlugin_CutFruitArea_after(
            "Volume is affected by N",
            30,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- SoilManagement does not use spray for "yield".
                dataStore.spraySum = 0
                --
                if dataStore.fertN.numPixels > 0 then
                    local nutrientLevel = dataStore.fertN.sumPixels / dataStore.fertN.numPixels
                    dataStore.fertN.factor = sm3SoilModPlugins.fertNCurve:get(nutrientLevel)
--log("FertN: s",dataStore.fertN.sumPixels," n",dataStore.fertN.numPixels," t",dataStore.fertN.totPixels," / l",nutrientLevel," f",factor)
                    dataStore.volume = dataStore.volume + (dataStore.volume * dataStore.fertN.factor)
                end
            end
        )
    end

    -- Only add effect, when required foliage-layer exist
    if hasFoliageLayer(g_currentMission.sm3FoliageFertPK) then
        -- TODO - Try to add for different fruit-types.
        sm3SoilModPlugins.fertPKCurve = AnimCurve:new(linearInterpolator1)
        sm3SoilModPlugins.fertPKCurve:addKeyframe({ v=0.00, time= 0 })
        sm3SoilModPlugins.fertPKCurve:addKeyframe({ v=0.10, time= 1 })
        sm3SoilModPlugins.fertPKCurve:addKeyframe({ v=0.30, time= 2 })
        sm3SoilModPlugins.fertPKCurve:addKeyframe({ v=0.80, time= 3 })
        sm3SoilModPlugins.fertPKCurve:addKeyframe({ v=1.00, time= 4 })
        sm3SoilModPlugins.fertPKCurve:addKeyframe({ v=0.30, time= 7 })

        soilMod.addPlugin_CutFruitArea_before(
            "Get PK density",
            40,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Get PK
                dataStore.fertPK = {}
                dataStore.fertPK.sumPixels, dataStore.fertPK.numPixels, dataStore.fertPK.totPixels = getDensityParallelogram(
                    g_currentMission.sm3FoliageFertPK,
                    sx,sz,wx,wz,hx,hz,
                    0,3
                )
            end
        )

        soilMod.addPlugin_CutFruitArea_after(
            "Volume is slightly boosted by PK",
            40,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                if dataStore.fertPK.numPixels > 0 then
                    local nutrientLevel = dataStore.fertPK.sumPixels / dataStore.fertPK.numPixels
                    dataStore.fertPK.factor = sm3SoilModPlugins.fertPKCurve:get(nutrientLevel)
                    local volumeBoost = (dataStore.numPixels * dataStore.fertPK.factor) / 2
--log("FertPK: s",dataStore.fertPK.sumPixels," n",dataStore.fertPK.numPixels," t",dataStore.fertPK.totPixels," / l",nutrientLevel," b",volumeBoost)
                    dataStore.volume = dataStore.volume + volumeBoost
                end
            end
        )
    end

    -- Only add effect, when required foliage-layer exist
    if hasFoliageLayer(g_currentMission.sm3FoliageSoil_pH) then

        -- TODO - Try to add for different fruit-types.
        sm3SoilModPlugins.pHCurve = AnimCurve:new(linearInterpolator1)
        sm3SoilModPlugins.pHCurve:addKeyframe({ v=0.20, time= 0 })
        sm3SoilModPlugins.pHCurve:addKeyframe({ v=0.70, time= 1 })
        sm3SoilModPlugins.pHCurve:addKeyframe({ v=0.80, time= 2 })
        sm3SoilModPlugins.pHCurve:addKeyframe({ v=0.85, time= 3 })
        sm3SoilModPlugins.pHCurve:addKeyframe({ v=0.90, time= 4 })
        sm3SoilModPlugins.pHCurve:addKeyframe({ v=0.94, time= 5 })
        sm3SoilModPlugins.pHCurve:addKeyframe({ v=0.97, time= 6 })
        sm3SoilModPlugins.pHCurve:addKeyframe({ v=1.00, time= 7 }) -- neutral
        sm3SoilModPlugins.pHCurve:addKeyframe({ v=0.98, time= 8 })
        sm3SoilModPlugins.pHCurve:addKeyframe({ v=0.95, time= 9 })
        sm3SoilModPlugins.pHCurve:addKeyframe({ v=0.91, time=10 })
        sm3SoilModPlugins.pHCurve:addKeyframe({ v=0.87, time=11 })
        sm3SoilModPlugins.pHCurve:addKeyframe({ v=0.84, time=12 })
        sm3SoilModPlugins.pHCurve:addKeyframe({ v=0.80, time=13 })
        sm3SoilModPlugins.pHCurve:addKeyframe({ v=0.76, time=14 })
        sm3SoilModPlugins.pHCurve:addKeyframe({ v=0.50, time=15 })


        soilMod.addPlugin_CutFruitArea_before(
            "Get soil pH density",
            50,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Get soil pH
                dataStore.soilpH = {}
                dataStore.soilpH.sumPixels, dataStore.soilpH.numPixels, dataStore.soilpH.totPixels = getDensityParallelogram(
                    g_currentMission.sm3FoliageSoil_pH,
                    sx,sz,wx,wz,hx,hz,
                    0,4
                )
            end
        )

        soilMod.addPlugin_CutFruitArea_after(
            "Volume is affected by soil pH level",
            50,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                if dataStore.soilpH.totPixels > 0 then
                    local pHFactor = dataStore.soilpH.sumPixels / dataStore.soilpH.totPixels
                    dataStore.soilpH.factor = sm3SoilModPlugins.pHCurve:get(pHFactor)
--log("soil pH: s",dataStore.soilpH.sumPixels," n",dataStore.soilpH.numPixels," t",dataStore.soilpH.totPixels," / f",pHFactor," c",factor)
                    dataStore.volume = dataStore.volume * dataStore.soilpH.factor
                end
            end
        )
    end

    -- Only add effect, when required foliage-layer exist
    if hasFoliageLayer(g_currentMission.sm3FoliageMoisture) then

        -- TODO - Try to add for different fruit-types.
        sm3SoilModPlugins.moistureCurve = AnimCurve:new(linearInterpolator1)
        sm3SoilModPlugins.moistureCurve:addKeyframe({ v=0.50, time=0 })
        sm3SoilModPlugins.moistureCurve:addKeyframe({ v=0.70, time=1 })
        sm3SoilModPlugins.moistureCurve:addKeyframe({ v=0.85, time=2 })
        sm3SoilModPlugins.moistureCurve:addKeyframe({ v=0.98, time=3 })
        sm3SoilModPlugins.moistureCurve:addKeyframe({ v=1.00, time=4 })
        sm3SoilModPlugins.moistureCurve:addKeyframe({ v=0.96, time=5 })
        sm3SoilModPlugins.moistureCurve:addKeyframe({ v=0.93, time=6 })
        sm3SoilModPlugins.moistureCurve:addKeyframe({ v=0.70, time=7 })

        soilMod.addPlugin_CutFruitArea_before(
            "Get water-moisture",
            60,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                dataStore.moisture = {}
                dataStore.moisture.sumPixels, dataStore.moisture.numPixels, dataStore.moisture.totPixels = getDensityParallelogram(
                    g_currentMission.sm3FoliageMoisture,
                    sx,sz,wx,wz,hx,hz,
                    0,3
                )
            end
        )

        soilMod.addPlugin_CutFruitArea_after(
            "Volume is affected by water-moisture",
            60,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                if dataStore.moisture.totPixels > 0 then
                    local moistureFactor = dataStore.moisture.sumPixels / dataStore.moisture.totPixels
                    dataStore.moisture.factor = sm3SoilModPlugins.moistureCurve:get(moistureFactor)
--log("moisture: s",dataStore.moisture.sumPixels," n",dataStore.moisture.numPixels," t",dataStore.moisture.totPixels," / f",moistureFactor," c",factor)
                    dataStore.volume = dataStore.volume * dataStore.moisture.factor
                end
            end
        )
    end

    ---- Issue #26. MoreRealistic's OverrideCutterAreaEvent.LUA will multiply volume with 1.5
    ---- if not sprayed, where the normal game multiply with 1.0. - However both methods will
    ---- multiply with 2.0 in case the spraySum is greater than zero. - So to fix this, this
    ---- plugin for SoilMod will make CutFruitArea return half the volume and have spraySum
    ---- greater than zero.
    --soilMod.addPlugin_CutFruitArea_after(
    --    "Fix for MoreRealistic multiplying volume by 1.5, where SoilMod expects it to be 1.0",
    --    9999, -- This plugin MUST be the last one, before 'CutFruitArea' returns!
    --    function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
    --        dataStore.volume = dataStore.volume / 2
    --        dataStore.spraySum = 1
    --
    --      -- Below didn't work correctly. Causes problem when graintank less than 5% and there's weed plants.
    --      -- -- Fix for multiplayer, to ensure that event will be sent to clients, if there was something to cut.
    --      -- if (dataStore.numPixels > 0) or (dataStore.weeds ~= nil and dataStore.weeds.numPixels > 0) then
    --      --     dataStore.volume = dataStore.volume + 0.0000001
    --      -- end
    --
    --      -- Thinking of a different approach, to send "cut"-event to clients when volume == 0 and (numPixels > 0 or weed > 0),
    --      -- where a "global variable" will be set, and then afterwards elsewhere it is tested to see if an event should be sent,
    --      -- but it requires appending extra functionality to Combine.update() and similar vanilla methods, which may cause even other problems.
    --    end
    --)


--DEBUG
    soilMod.addPlugin_CutFruitArea_after(
        "Debug graph",
        99,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            if sm3Display.debugGraph and sm3Display.debugGraphOn then
                sm3Display.debugGraphAddValue(1, (dataStore.numPixels>0 and (dataStore.volume/dataStore.numPixels) or nil), dataStore.pixelsSum, dataStore.numPixels, 0)
                sm3Display.debugGraphAddValue(2, Utils.getNoNil(dataStore.weeds.weedPct  ,0)    ,dataStore.weeds.oldSum         ,dataStore.weeds.numPixels      ,dataStore.weeds.newDelta       )
                sm3Display.debugGraphAddValue(3, Utils.getNoNil(dataStore.fertN.factor   ,0)    ,dataStore.fertN.sumPixels      ,dataStore.fertN.numPixels      ,dataStore.fertN.totPixels      )
                sm3Display.debugGraphAddValue(4, Utils.getNoNil(dataStore.fertPK.factor  ,0)    ,dataStore.fertPK.sumPixels     ,dataStore.fertPK.numPixels     ,dataStore.fertPK.totPixels     )
                sm3Display.debugGraphAddValue(5, Utils.getNoNil(dataStore.soilpH.factor  ,0)    ,dataStore.soilpH.sumPixels     ,dataStore.soilpH.numPixels     ,dataStore.soilpH.totPixels     )
                sm3Display.debugGraphAddValue(6, Utils.getNoNil(dataStore.moisture.factor,0)    ,dataStore.moisture.sumPixels   ,dataStore.moisture.numPixels   ,dataStore.moisture.totPixels   )
            end
        end
    )
--DEBUG]]
end

--
sm3SoilModPlugins.sm3TYPE_UNKNOWN    = 0
sm3SoilModPlugins.sm3TYPE_PLOUGH     = 2^0
sm3SoilModPlugins.sm3TYPE_CULTIVATOR = 2^1
sm3SoilModPlugins.sm3TYPE_SEEDER     = 2^2

--
function sm3SoilModPlugins.sm3Updatesm3Foliage(sx,sz,wx,wz,hx,hz, isForced, implementType)
    if implementType == sm3SoilModPlugins.sm3TYPE_PLOUGH then
        -- Increase FertN/FertPK where there's crops at specific growth-stages
        for _,props in pairs(sm3SoilModPlugins.sm3FoliageLayersCrops) do
            if props.plough.fertN ~= nil then
                setDensityMaskParams(g_currentMission.sm3FoliageFertN,  "between", props.plough.minGrowthState, props.plough.maxGrowthState)
                addDensityMaskedParallelogram(g_currentMission.sm3FoliageFertN,  sx,sz,wx,wz,hx,hz, 0,4, props.fruit.id, 0,g_currentMission.numFruitStateChannels, props.plough.fertN);
            end
            if props.plough.fertPK ~= nil then
                setDensityMaskParams(g_currentMission.sm3FoliageFertPK, "between", props.plough.minGrowthState, props.plough.maxGrowthState)
                addDensityMaskedParallelogram(g_currentMission.sm3FoliageFertPK, sx,sz,wx,wz,hx,hz, 0,3, props.fruit.id, 0,g_currentMission.numFruitStateChannels, props.plough.fertPK);
            end
        end

        -- Increase FertN +12 where there's solidManure
        setDensityMaskParams(         g_currentMission.sm3FoliageFertN, "greater", 0)
        addDensityMaskedParallelogram(g_currentMission.sm3FoliageFertN,  sx,sz,wx,wz,hx,hz, 0,4, g_currentMission.sm3FoliageManure, 0,2, 12);

        -- Increase FertN +3 where there's windrow
        for _,fruit in pairs(sm3SoilModPlugins.sm3FoliageLayersWindrows) do
            addDensityMaskedParallelogram(g_currentMission.sm3FoliageFertN,  sx,sz,wx,wz,hx,hz, 0, 4, fruit.windrowId, 0,g_currentMission.numWindrowChannels, 3);
        end

        -- Increase FertPK +4 where there's solidManure
        setDensityMaskParams(         g_currentMission.sm3FoliageFertPK, "greater", 0)
        addDensityMaskedParallelogram(g_currentMission.sm3FoliageFertPK,  sx,sz,wx,wz,hx,hz, 0,3, g_currentMission.sm3FoliageManure, 0,2, 4);
    else
        -- Increase FertN/FertPK where there's crops at specific growth-stages
        for _,props in pairs(sm3SoilModPlugins.sm3FoliageLayersCrops) do
            if props.cultivate.fertN ~= nil then
                setDensityMaskParams(g_currentMission.sm3FoliageFertN,  "between", props.cultivate.minGrowthState, props.cultivate.maxGrowthState)
                addDensityMaskedParallelogram(g_currentMission.sm3FoliageFertN,  sx,sz,wx,wz,hx,hz, 0,4, props.fruit.id, 0,g_currentMission.numFruitStateChannels, props.cultivate.fertN);
            end
            if props.cultivate.fertPK ~= nil then
                setDensityMaskParams(g_currentMission.sm3FoliageFertPK, "between", props.cultivate.minGrowthState, props.cultivate.maxGrowthState)
                addDensityMaskedParallelogram(g_currentMission.sm3FoliageFertPK, sx,sz,wx,wz,hx,hz, 0,3, props.fruit.id, 0,g_currentMission.numFruitStateChannels, props.cultivate.fertPK);
            end
        end

        -- Increase FertN +6 where there's solidManure
        setDensityMaskParams(         g_currentMission.sm3FoliageFertN, "greater", 0)
        addDensityMaskedParallelogram(g_currentMission.sm3FoliageFertN,  sx,sz,wx,wz,hx,hz, 0,4, g_currentMission.sm3FoliageManure, 0,2, 6);

        -- Increase FertN +1 where there's windrow
        for _,fruit in pairs(sm3SoilModPlugins.sm3FoliageLayersWindrows) do
            addDensityMaskedParallelogram(g_currentMission.sm3FoliageFertN,  sx,sz,wx,wz,hx,hz, 0, 4, fruit.windrowId, 0,g_currentMission.numWindrowChannels, 1);
        end

        -- Increase FertPK +2 where there's solidManure
        setDensityMaskParams(         g_currentMission.sm3FoliageFertPK, "greater", 0)
        addDensityMaskedParallelogram(g_currentMission.sm3FoliageFertPK,  sx,sz,wx,wz,hx,hz, 0,3, g_currentMission.sm3FoliageManure, 0,2, 2);
    end

    -- Increase soil pH where there's lime
    setDensityMaskParams(         g_currentMission.sm3FoliageSoil_pH, "greater", 0)
    addDensityMaskedParallelogram(g_currentMission.sm3FoliageSoil_pH,  sx,sz,wx,wz,hx,hz, 0, 4, g_currentMission.sm3FoliageLime, 0, 1, 4);

    -- Special case for slurry, due to ZunHammer and instant cultivating.
    setDensityMaskParams(         g_currentMission.sm3FoliageSlurry, "equals", 1);
    setDensityMaskedParallelogram(g_currentMission.sm3FoliageSlurry, sx,sz,wx,wz,hx,hz, 0,2, g_currentMission.sm3FoliageSlurry, 0,1, 2)

    -- Remove the manure/lime we've just cultivated/ploughed into ground.
    setDensityParallelogram(g_currentMission.sm3FoliageManure, sx,sz,wx,wz,hx,hz, 0, 2, 0)
    setDensityParallelogram(g_currentMission.sm3FoliageLime,   sx,sz,wx,wz,hx,hz, 0, 1, 0)
    -- Remove weed plants - where we're cultivating/ploughing.
    setDensityParallelogram(g_currentMission.sm3FoliageWeed,   sx,sz,wx,wz,hx,hz, 0, 4, 0)
end

--
function sm3SoilModPlugins.pluginsForUpdateWeederArea(soilMod)
    --
    -- Effects for the Utils.updateWeederArea()
    --

    if hasFoliageLayer(g_currentMission.sm3FoliageWeed)
    then
        soilMod.addPlugin_UpdateWeederArea_after(
            "Weeder removes weed-plants",
            20,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Remove weed plants
                setDensityParallelogram(
                    g_currentMission.sm3FoliageWeed, 
                    sx,sz,wx,wz,hx,hz, 
                    0,4, 
                    0
                )
                
                -- Remove crops if they are in growth-state 4-8
                for _,props in pairs(sm3SoilModPlugins.sm3FoliageLayersCrops) do
                    setDensityCompareParams(props.fruit.id, "between", 4, 8);
                    setDensityParallelogram(
                        props.fruit.id, 
                        sx,sz,wx,wz,hx,hz, 
                        0,g_currentMission.numFruitStateChannels, 
                        0
                    )
                    setDensityCompareParams(props.fruit.id, "greater", -1);
                end
            end
        )
    end

    if hasFoliageLayer(g_currentMission.sm3FoliageHerbicideTime)
    then
        soilMod.addPlugin_UpdateWeederArea_after(
            "Weeder gives 2 days weed-prevention",
            30,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                setDensityMaskParams(g_currentMission.sm3FoliageHerbicideTime, "between", 0,1);
                setDensityMaskedParallelogram(
                    g_currentMission.sm3FoliageHerbicideTime, 
                    sx,sz,wx,wz,hx,hz, 
                    0,2, 
                    g_currentMission.sm3FoliageHerbicideTime,0,2,
                    2
                )
            end
        )
    end
    
end

--
function sm3SoilModPlugins.pluginsForUpdateCultivatorArea(soilMod)
    --
    -- Additional effects for the Utils.UpdateCultivatorArea()
    --

    -- Only add effect, when all required foliage-layers exists
    if  hasFoliageLayer(g_currentMission.sm3FoliageSoil_pH)
    and hasFoliageLayer(g_currentMission.sm3FoliageManure)
    and hasFoliageLayer(g_currentMission.sm3FoliageSlurry)
    and hasFoliageLayer(g_currentMission.sm3FoliageLime)
    and hasFoliageLayer(g_currentMission.sm3FoliageWeed)
    and hasFoliageLayer(g_currentMission.sm3FoliageFertN)
    then
        soilMod.addPlugin_UpdateCultivatorArea_before(
            "Update foliage-layer for SoilMod",
            20,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                sm3SoilModPlugins.sm3Updatesm3Foliage(sx,sz,wx,wz,hx,hz, dataStore.forced, sm3SoilModPlugins.sm3TYPE_CULTIVATOR)
            end
        )
    end

    soilMod.addPlugin_UpdateCultivatorArea_before(
        "Destroy common area",
        30,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            Utils.sm3UpdateDestroyCommonArea(sx,sz,wx,wz,hx,hz, not dataStore.commonForced, sm3SoilModPlugins.sm3TYPE_CULTIVATOR);
        end
    )

    if hasFoliageLayer(g_currentMission.sm3FoliageFertilizer) then
        soilMod.addPlugin_UpdateCultivatorArea_before(
            "Cultivator changes solid-fertilizer(visible) to liquid-fertilizer(invisible)",
            41,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Where 'greater than 4', then set most-significant-bit to zero
                setDensityMaskParams(         g_currentMission.sm3FoliageFertilizer, "greater", 4)
                setDensityMaskedParallelogram(g_currentMission.sm3FoliageFertilizer,           sx,sz,wx,wz,hx,hz, 2, 1, g_currentMission.sm3FoliageFertilizer, 0, 3, 0);
                setDensityMaskParams(         g_currentMission.sm3FoliageFertilizer, "greater", 0)
            end
        )
    end

end

--
function sm3SoilModPlugins.pluginsForUpdatePloughArea(soilMod)
    --
    -- Additional effects for the Utils.UpdatePloughArea()
    --

    -- Only add effect, when all required foliage-layers exists
    if  hasFoliageLayer(g_currentMission.sm3FoliageSoil_pH)
    and hasFoliageLayer(g_currentMission.sm3FoliageManure)
    and hasFoliageLayer(g_currentMission.sm3FoliageSlurry)
    and hasFoliageLayer(g_currentMission.sm3FoliageLime)
    and hasFoliageLayer(g_currentMission.sm3FoliageWeed)
    and hasFoliageLayer(g_currentMission.sm3FoliageFertN)
    then
        soilMod.addPlugin_UpdatePloughArea_before(
            "Update foliage-layer for SoilMod",
            20,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                sm3SoilModPlugins.sm3Updatesm3Foliage(sx,sz,wx,wz,hx,hz, dataStore.forced, sm3SoilModPlugins.sm3TYPE_PLOUGH)
            end
        )
    end

    soilMod.addPlugin_UpdatePloughArea_before(
        "Destroy common area",
        30,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            Utils.sm3UpdateDestroyCommonArea(sx,sz,wx,wz,hx,hz, not dataStore.commonForced, sm3SoilModPlugins.sm3TYPE_PLOUGH);
        end
    )

    if hasFoliageLayer(g_currentMission.sm3FoliageFertilizer) then
        soilMod.addPlugin_UpdatePloughArea_before(
            "Ploughing changes solid-fertilizer(visible) to liquid-fertilizer(invisible)",
            41,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Where 'greater than 4', then set most-significant-bit to zero
                setDensityMaskParams(         g_currentMission.sm3FoliageFertilizer, "greater", 4)
                setDensityMaskedParallelogram(g_currentMission.sm3FoliageFertilizer,           sx,sz,wx,wz,hx,hz, 2, 1, g_currentMission.sm3FoliageFertilizer, 0, 3, 0);
                setDensityMaskParams(         g_currentMission.sm3FoliageFertilizer, "greater", 0)
            end
        )
    end

    if hasFoliageLayer(g_currentMission.sm3FoliageWater) then
        soilMod.addPlugin_UpdatePloughArea_after(
            "Plouging should reduce water-level",
            40,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                setDensityParallelogram(g_currentMission.sm3FoliageWater, sx,sz,wx,wz,hx,hz, 0,2, 1);
            end
        )
    end

end

--
function sm3SoilModPlugins.pluginsForUpdateSowingArea(soilMod)
    --
    -- Additional effects for the Utils.UpdateSowingArea()
    --

    -- Only add effect, when required foliage-layer exist
    if hasFoliageLayer(g_currentMission.sm3FoliageWeed) then
        soilMod.addPlugin_UpdateSowingArea_before(
            "Destroy weed plants when sowing",
            30,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Remove weed plants - where we're seeding.
                setDensityParallelogram(g_currentMission.sm3FoliageWeed, sx,sz,wx,wz,hx,hz, 0,4, 0)
            end
        )
    end

end

--
function sm3SoilModPlugins.pluginsForUpdateSprayArea(soilMod)
    --
    -- Additional effects for the Utils.UpdateSprayArea()
    --
--[[
    -- Broadcast spreader
    if Fillable.FILLTYPE_RAPE ~= nil and FruitUtil.FRUITTYPE_RAPE ~= nil then
        local fruitId     = g_currentMission.fruits[ FruitUtil.FRUITTYPE_RAPE ].id;
        soilMod.addPlugin_UpdateSprayArea_fillType(
            "Broadcast spreader; canola",
            10,
            Fillable.FILLTYPE_RAPE + sm3SoilMod.fillTypeAugmented,
            function(sx,sz,wx,wz,hx,hz)
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
                
                return false -- No moisture!
            end
        )
    end
--]]    
    --
    if hasFoliageLayer(g_currentMission.sm3FoliageManure) then
        local foliageId       = g_currentMission.sm3FoliageManure
        local numChannels     = getTerrainDetailNumChannels(foliageId)
        local value           = 2^numChannels - 1

        if Fillable.FILLTYPE_MANURE ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread manure",
                10,
                Fillable.FILLTYPE_MANURE,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return false -- No moisture!
                end
            )
        end
        if Fillable.FILLTYPE_MANURESOLID ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread manureSolid",
                10,
                Fillable.FILLTYPE_MANURESOLID,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return false -- No moisture!
                end
            )
        end
        if Fillable.FILLTYPE_SOLIDMANURE ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread solidManure",
                10,
                Fillable.FILLTYPE_SOLIDMANURE,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return false -- No moisture!
                end
            )
        end
    end

    if hasFoliageLayer(g_currentMission.sm3FoliageSlurry) then
        local foliageId       = g_currentMission.sm3FoliageSlurry
        local numChannels     = 1 --getTerrainDetailNumChannels(foliageId)
        local value           = 2^numChannels - 1

        if Fillable.FILLTYPE_LIQUIDMANURE ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread slurry (liquidManure)",
                10,
                Fillable.FILLTYPE_LIQUIDMANURE,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return true -- Place moisture!
                end
            )
            -- Fix for Zunhammer Zunidisk, so slurry won't become visible due to "direct cultivating".
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread slurry (liquidManure2)",
                10,
                Fillable.FILLTYPE_LIQUIDMANURE + sm3SoilMod.fillTypeAugmented,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, 2, 2);
                    return true -- Place moisture!
                end
            )
        end
        if Fillable.FILLTYPE_MANURELIQUID ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread slurry (manureLiquid)",
                10,
                Fillable.FILLTYPE_MANURELIQUID,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return true -- Place moisture!
                end
            )
            -- Fix for Zunhammer Zunidisk, so slurry won't become visible due to "direct cultivating".
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread slurry (manureLiquid2)",
                10,
                Fillable.FILLTYPE_MANURELIQUID + sm3SoilMod.fillTypeAugmented,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, 2, 2);
                    return true -- Place moisture!
                end
            )
        end
    end

    if hasFoliageLayer(g_currentMission.sm3FoliageWater) then
        local foliageId       = g_currentMission.sm3FoliageWater
        local numChannels     = getTerrainDetailNumChannels(foliageId)

        if Fillable.FILLTYPE_WATER ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread water",
                10,
                Fillable.FILLTYPE_WATER,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, 2); -- water +1
                    return true -- Place moisture!
                end
            )
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread water(x2)",
                10,
                Fillable.FILLTYPE_WATER + sm3SoilMod.fillTypeAugmented,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, 3); -- water +2
                    return true -- Place moisture!
                end
            )
        end
    end

    if hasFoliageLayer(g_currentMission.sm3FoliageLime) then
        local foliageId       = g_currentMission.sm3FoliageLime
        local numChannels     = getTerrainDetailNumChannels(foliageId)
        local value           = 2^numChannels - 1

        if Fillable.FILLTYPE_LIME ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread lime(solid1)",
                10,
                Fillable.FILLTYPE_LIME,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return false -- No moisture!
                end
            )
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread lime(solid2)",
                10,
                Fillable.FILLTYPE_LIME + sm3SoilMod.fillTypeAugmented,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return false -- No moisture!
                end
            )
        end
        if Fillable.FILLTYPE_KALK ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread kalk(solid1)",
                10,
                Fillable.FILLTYPE_KALK,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return false -- No moisture!
                end
            )
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread kalk(solid2)",
                10,
                Fillable.FILLTYPE_KALK + sm3SoilMod.fillTypeAugmented,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return false -- No moisture!
                end
            )
        end
    end

    if hasFoliageLayer(g_currentMission.sm3FoliageHerbicide) then
        local foliageId       = g_currentMission.sm3FoliageHerbicide
        local numChannels     = getTerrainDetailNumChannels(foliageId)

        if Fillable.FILLTYPE_HERBICIDE ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spray herbicide",
                10,
                Fillable.FILLTYPE_HERBICIDE,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, 1) -- type-A
                    return true -- Place moisture!
                end
            )
        end
        if Fillable.FILLTYPE_HERBICIDE2 ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spray herbicide2",
                10,
                Fillable.FILLTYPE_HERBICIDE2,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, 2) -- type-B
                    return true -- Place moisture!
                end
            )
        end
        if Fillable.FILLTYPE_HERBICIDE3 ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spray herbicide3",
                10,
                Fillable.FILLTYPE_HERBICIDE3,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, 3) -- type-C
                    return true -- Place moisture!
                end
            )
        end

        --
        if hasFoliageLayer(g_currentMission.sm3FoliageHerbicideTime) then
            if Fillable.FILLTYPE_HERBICIDE4 ~= nil then
                soilMod.addPlugin_UpdateSprayArea_fillType(
                    "Spray herbicide4 with germination prevention",
                    10,
                    Fillable.FILLTYPE_HERBICIDE4,
                    function(sx,sz,wx,wz,hx,hz)
                        setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, 1) -- type-A
                        setDensityParallelogram(g_currentMission.sm3FoliageHerbicideTime, sx,sz,wx,wz,hx,hz, 0,2, 3) -- Germination prevention
                        return true -- Place moisture!
                    end
                )
            end
            if Fillable.FILLTYPE_HERBICIDE5 ~= nil then
                soilMod.addPlugin_UpdateSprayArea_fillType(
                    "Spray herbicide5 with germination prevention",
                    10,
                    Fillable.FILLTYPE_HERBICIDE5,
                    function(sx,sz,wx,wz,hx,hz)
                        setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, 2) -- type-B
                        setDensityParallelogram(g_currentMission.sm3FoliageHerbicideTime, sx,sz,wx,wz,hx,hz, 0,2, 3) -- Germination prevention
                        return true -- Place moisture!
                    end
                )
            end
            if Fillable.FILLTYPE_HERBICIDE6 ~= nil then
                soilMod.addPlugin_UpdateSprayArea_fillType(
                    "Spray herbicide6 with germination prevention",
                    10,
                    Fillable.FILLTYPE_HERBICIDE6,
                    function(sx,sz,wx,wz,hx,hz)
                        setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, 3) -- type-C
                        setDensityParallelogram(g_currentMission.sm3FoliageHerbicideTime, sx,sz,wx,wz,hx,hz, 0,2, 3) -- Germination prevention
                        return true -- Place moisture!
                    end
                )
            end
        end
    end

    if hasFoliageLayer(g_currentMission.sm3FoliageFertilizer) then
        local foliageId    = g_currentMission.sm3FoliageFertilizer
        local numChannels  = getTerrainDetailNumChannels(foliageId)

        if Fillable.FILLTYPE_FERTILIZER ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spray fertilizer(liquid)",
                10,
                Fillable.FILLTYPE_FERTILIZER,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0,numChannels, 1) -- type-A(liquid)
                    return true -- Place moisture!
                end
            )
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spray fertilizer(solid)",
                10,
                Fillable.FILLTYPE_FERTILIZER + sm3SoilMod.fillTypeAugmented,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0,numChannels, 1+4) -- type-A(solid)
                    return false -- No moisture!
                end
            )
        end
        if Fillable.FILLTYPE_FERTILIZER2 ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spray fertilizer2(liquid)",
                10,
                Fillable.FILLTYPE_FERTILIZER2,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0,numChannels, 2) -- type-B(liquid)
                    return true -- Place moisture!
                end
            )
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spray fertilizer2(solid)",
                10,
                Fillable.FILLTYPE_FERTILIZER2 + sm3SoilMod.fillTypeAugmented,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0,numChannels, 2+4) -- type-B(solid)
                    return false -- No moisture!
                end
            )
        end
        if Fillable.FILLTYPE_FERTILIZER3 ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spray fertilizer3(liquid)",
                10,
                Fillable.FILLTYPE_FERTILIZER3,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0,numChannels, 3) -- type-C(liquid)
                    return true -- Place moisture!
                end
            )
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spray fertilizer3(solid)",
                10,
                Fillable.FILLTYPE_FERTILIZER3 + sm3SoilMod.fillTypeAugmented,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0,numChannels, 3+4) -- type-C(solid)
                    return false -- No moisture!
                end
            )
        end

        --
        if Fillable.FILLTYPE_PLANTKILLER ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spray plantKiller(liquid)",
                10,
                Fillable.FILLTYPE_PLANTKILLER,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(
                        foliageId,
                        sx,sz,wx,wz,hx,hz,
                        0,numChannels,
                        4               -- type-X
                    )
                    return true -- Place moisture!
                end
            )
        end
    end
end

--
-- Callback method, to be used in loadMapFinished() in the map's SampleModMap.LUA (or whatever its renamed to)
--
modSoilMod2.setFruitTypeHerbicideAvoidance = function(fruitName, herbicideType)
    if fruitName == nil or herbicideType == nil then
        return;
    end

    fruitName = tostring(fruitName):lower()
    herbicideType = tostring(herbicideType):upper()

    log("setFruitTypeHerbicideAvoidance(",fruitName,",",herbicideType,")")

    if     herbicideType == "-" or herbicideType == "0" then
        sm3SoilModPlugins.avoidanceRules[fruitName] = 0
    elseif herbicideType == "A" or herbicideType == "1" then
        sm3SoilModPlugins.avoidanceRules[fruitName] = 1
    elseif herbicideType == "B" or herbicideType == "2" then
        sm3SoilModPlugins.avoidanceRules[fruitName] = 2
    elseif herbicideType == "C" or herbicideType == "3" then
        sm3SoilModPlugins.avoidanceRules[fruitName] = 3
    end
end


--
sm3SoilModPlugins.avoidanceRules = {
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
function sm3SoilModPlugins.pluginsForGrowthCycle(soilMod)

    -- Build fruit's herbicide avoidance
    local function getHerbicideAvoidanceTypeForFruit(fruitName)
        fruitName = fruitName:lower()
        if sm3SoilModPlugins.avoidanceRules[fruitName] ~= nil then
            return sm3SoilModPlugins.avoidanceRules[fruitName]
        end
        return 0; -- Default
    end

    local indexToFillName = {
        [0] = { "n/a", "-" },
        [1] = { Fillable.fillTypeIntToName[Fillable.FILLTYPE_HERBICIDE]  ,"A"},
        [2] = { Fillable.fillTypeIntToName[Fillable.FILLTYPE_HERBICIDE2] ,"B"},
        [3] = { Fillable.fillTypeIntToName[Fillable.FILLTYPE_HERBICIDE3] ,"C"},
    }

    for _,fruitEntry in pairs(g_currentMission.sm3FoliageGrowthLayers) do
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
    soilMod.addPlugin_GrowthCycleFruits(
        "Increase crop growth",
        10,
        function(sx,sz,wx,wz,hx,hz,day,fruitEntry)
            setDensityMaskParams(fruitEntry.fruitId, "between", fruitEntry.minSeededValue, fruitEntry.maxMatureValue - ((sm3GrowthControl.disableWithering or fruitEntry.witheredValue == nil) and 1 or 0))
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
            soilMod.addPlugin_GrowthCycle(
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
            soilMod.addPlugin_GrowthCycle(
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
            soilMod.addPlugin_GrowthCycle(
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
            soilMod.addPlugin_GrowthCycle(
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
        soilMod.addPlugin_GrowthCycleFruits(
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
    if sm3SoilModPlugins.reduceWindrows ~= false then
        soilMod.addPlugin_GrowthCycleFruits(
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
            soilMod.addPlugin_GrowthCycle(
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

        soilMod.addPlugin_GrowthCycle(
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
            soilMod.addPlugin_GrowthCycle(
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

        soilMod.addPlugin_GrowthCycle(
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
            soilMod.addPlugin_GrowthCycle(
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

        soilMod.addPlugin_GrowthCycle(
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
        if Fillable.FILLTYPE_PLANTKILLER ~= nil then
            soilMod.addPlugin_GrowthCycle(
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
            if Fillable.FILLTYPE_PLANTKILLER ~= nil then
                soilMod.addPlugin_GrowthCycle(
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

            soilMod.addPlugin_GrowthCycle(
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
            soilMod.addPlugin_GrowthCycle(
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
            soilMod.addPlugin_GrowthCycle(
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

        soilMod.addPlugin_GrowthCycle(
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

        soilMod.addPlugin_GrowthCycle(
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
            soilMod.addPlugin_GrowthCycle(
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
            soilMod.addPlugin_GrowthCycle(
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

        soilMod.addPlugin_GrowthCycle(
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
            soilMod.addPlugin_GrowthCycle(
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
            soilMod.addPlugin_GrowthCycle(
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
        soilMod.addPlugin_GrowthCycle(
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
            soilMod.addPlugin_GrowthCycle(
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

        soilMod.addPlugin_GrowthCycle(
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
        soilMod.addPlugin_GrowthCycle(
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

        soilMod.addPlugin_GrowthCycle(
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
    if sm3SoilModPlugins.removeSprayMoisture ~= false then

        if hasFoliageLayer(g_currentMission.sm3FoliageMoisture) then
            soilMod.addPlugin_GrowthCycle(
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

        soilMod.addPlugin_GrowthCycle(
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
function sm3SoilModPlugins.pluginsForWeatherCycle(soilMod)

    -- Hot weather reduces soil-moisture
    -- Rain increases soil-moisture
    if hasFoliageLayer(g_currentMission.sm3FoliageMoisture) then
        soilMod.addPlugin_WeatherCycle(
            "Soil-moisture is affected by weather",
            10,
            function(sx,sz,wx,wz,hx,hz,weatherInfo,day)
                if weatherInfo == sm3GrowthControl.WEATHER_HOT then
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
                elseif weatherInfo == sm3GrowthControl.WEATHER_RAIN then
                    addDensityParallelogram(
                        g_currentMission.sm3FoliageMoisture,
                        sx,sz,wx,wz,hx,hz,
                        0, 3,
                        1  -- increase
                    );
                elseif weatherInfo == sm3GrowthControl.WEATHER_HAIL then
                    --
                end
            end
        )
    end

end
