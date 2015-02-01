--
--  The Soil Management and Growth Control Project - version 2 (FS15)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modhoster.com
-- @date    2015-01-xx
--

fmcSoilModPlugins = {}

local modItem = ModsUtil.findModItemByModName(g_currentModName);
fmcSoilModPlugins.version = (modItem and modItem.version) and modItem.version or "?.?.?";


-- Register this mod for callback from SoilMod's plugin facility
getfenv(0)["modSoilMod2Plugins"] = getfenv(0)["modSoilMod2Plugins"] or {}
table.insert(getfenv(0)["modSoilMod2Plugins"], fmcSoilModPlugins)

--
-- This function MUST BE named "soilModPluginCallback" and take two arguments!
-- It is the callback method, that SoilMod's plugin facility will call, to let this mod add its own plugins to SoilMod.
-- The argument is a 'table of functions' which must be used to add this mod's plugin-functions into SoilMod.
--
function fmcSoilModPlugins.soilModPluginCallback(soilMod,settings)

    --
    fmcSoilModPlugins.reduceWindrows        = settings.getKeyAttrValue("plugins.fmcSoilModPlugins",  "reduceWindrows",         true)
    fmcSoilModPlugins.removeSprayMoisture   = settings.getKeyAttrValue("plugins.fmcSoilModPlugins",  "removeSprayMoisture",    false)

    --
    settings.setKeyAttrValue("plugins.fmcSoilModPlugins",  "reduceWindrows",         fmcSoilModPlugins.reduceWindrows     )
    settings.setKeyAttrValue("plugins.fmcSoilModPlugins",  "removeSprayMoisture",    fmcSoilModPlugins.removeSprayMoisture)

    log("reduceWindrows=",fmcSoilModPlugins.reduceWindrows,", removeSprayMoisture=",fmcSoilModPlugins.removeSprayMoisture)
    
    -- Gather the required special foliage-layers for Soil Management & Growth Control.
log("fmcSoilModPlugins.setupFoliageLayers()")
    local allOK = fmcSoilModPlugins.setupFoliageLayers()

log("allOK=",allOK)
    if allOK then
        -- Using SoilMod's plugin facility, we add SoilMod's own effects for each of the particular "Utils." functions
        -- To keep my own sanity, all the plugin-functions for each particular "Utils." function, have their own block:
--        fmcSoilModPlugins.pluginsForCutFruitArea(        soilMod)
        fmcSoilModPlugins.pluginsForUpdateCultivatorArea(soilMod)
        fmcSoilModPlugins.pluginsForUpdatePloughArea(    soilMod)
--        fmcSoilModPlugins.pluginsForUpdateSowingArea(    soilMod)
        fmcSoilModPlugins.pluginsForUpdateSprayArea(     soilMod)
        -- And for the 'growth-cycle' plugins:
        fmcSoilModPlugins.pluginsForGrowthCycle(         soilMod)
    end

    return allOK

end

--
local function hasFoliageLayer(foliageId)
    return (foliageId ~= nil and foliageId ~= 0);
end

--
function fmcSoilModPlugins.setupFoliageLayers()
    -- Get foliage-layers that contains visible graphics (i.e. has material that uses shaders)
    g_currentMission.fmcFoliageManure       = g_currentMission:loadFoliageLayer("fmc_manure",     -5, -1, true, "alphaBlendStartEnd")
    g_currentMission.fmcFoliageSlurry       = g_currentMission:loadFoliageLayer("fmc_slurry",     -5, -1, true, "alphaBlendStartEnd")
    g_currentMission.fmcFoliageWeed         = g_currentMission:loadFoliageLayer("fmc_weed",       -5, -1, true, "alphaBlendStartEnd")
    g_currentMission.fmcFoliageLime         = g_currentMission:loadFoliageLayer("fmc_lime",       -5, -1, true, "alphaBlendStartEnd")
    g_currentMission.fmcFoliageFertilizer   = g_currentMission:loadFoliageLayer("fmc_fertilizer", -5, -1, true, "alphaBlendStartEnd")
    g_currentMission.fmcFoliageHerbicide    = g_currentMission:loadFoliageLayer("fmc_herbicide",  -5, -1, true, "alphaBlendStartEnd")

    ---- Get foliage-layers that are invisible (i.e. has viewdistance=0 and a material that is "blank")
    g_currentMission.fmcFoliageSoil_pH              = getChild(g_currentMission.terrainRootNode, "fmc_soil_pH"      )
    g_currentMission.fmcFoliageNitrogen             = getChild(g_currentMission.terrainRootNode, "fmc_nitrogen"     )
    g_currentMission.fmcFoliagePhosphorus           = getChild(g_currentMission.terrainRootNode, "fmc_phosphorus"   )
    g_currentMission.fmcFoliagePotassium            = getChild(g_currentMission.terrainRootNode, "fmc_potassium"    )
    g_currentMission.fmcFoliageHerbicideTime        = getChild(g_currentMission.terrainRootNode, "fmc_herbicideTime")

    --
    local function verifyFoliage(foliageName, foliageId, reqChannels)
        local numChannels
        if hasFoliageLayer(foliageId) then
                  numChannels    = getTerrainDetailNumChannels(foliageId)
            local terrainSize    = getTerrainSize(foliageId)
            local densityMapSize = getDensityMapSize(foliageId)
            if numChannels == reqChannels then
                logInfo("Foliage-layer check ok: '",foliageName,"', id=",foliageId,", numChnls=",numChannels,", size=",terrainSize,"/",densityMapSize)
                return true
            end
        end;
        logInfo("ERROR! Required foliage-layer '",foliageName,"' either does not exist (foliageId=",foliageId,"), or have wrong num-channels (",numChannels,")")
        return false
    end

    local allOK = true
    allOK = verifyFoliage("fmc_manure"              ,g_currentMission.fmcFoliageManure              ,2) and allOK;
    allOK = verifyFoliage("fmc_slurry"              ,g_currentMission.fmcFoliageSlurry              ,2) and allOK;
    allOK = verifyFoliage("fmc_weed"                ,g_currentMission.fmcFoliageWeed                ,4) and allOK;
    allOK = verifyFoliage("fmc_lime"                ,g_currentMission.fmcFoliageLime                ,1) and allOK;
    allOK = verifyFoliage("fmc_fertilizer"          ,g_currentMission.fmcFoliageFertilizer          ,3) and allOK;
    allOK = verifyFoliage("fmc_herbicide"           ,g_currentMission.fmcFoliageHerbicide           ,2) and allOK;
    
    allOK = verifyFoliage("fmc_soil_pH"             ,g_currentMission.fmcFoliageSoil_pH             ,4) and allOK;
    allOK = verifyFoliage("fmc_nitrogen"            ,g_currentMission.fmcFoliageNitrogen            ,4) and allOK;
    allOK = verifyFoliage("fmc_phosphorus"          ,g_currentMission.fmcFoliagePhosphorus          ,3) and allOK;
    allOK = verifyFoliage("fmc_potassium"           ,g_currentMission.fmcFoliagePotassium           ,3) and allOK;
    allOK = verifyFoliage("fmc_herbicideTime"       ,g_currentMission.fmcFoliageHerbicideTime       ,2) and allOK;
    
    return allOK
end

-- Version 1.2.x of ZZZ_ChoppedStraw now uses SoilMod's plugin facility
-- -- TODO: Let the ZZZ_ChoppedStraw mod do this itself, once/if it is changed to support SoilMod's plugin facility
-- function fmcSoilModPlugins.extra_SupportForChoppedStrawMod(soilMod)
--     --
--     local function addFruitToDestructiveList(fruitId, layerAttribute)
--         local fruitDesc = g_currentMission.fruits[fruitId]
--         if fruitDesc ~= nil then
--             soilMod.addDestructibleFoliageId(fruitDesc[layerAttribute])
--         end
--     end
-- 
--     -- Support for "zzz_ChoppedStraw v1.1.02" by Webalizer
--     -- Add the foliage-layer-id's to SoilMod's list of "destructible-foliage-layers by cultivator/plough"
--     addFruitToDestructiveList(FruitUtil.FRUITTYPE_CHOPPEDSTRAW, "preparingOutputId")
--     addFruitToDestructiveList(FruitUtil.FRUITTYPE_CHOPPEDMAIZE, "preparingOutputId")
--     addFruitToDestructiveList(FruitUtil.FRUITTYPE_CHOPPEDRAPE,  "preparingOutputId")
-- 
--     -- HACK: For having sowing-machines also destroy foliage-layers, in a quick attempt at supporting ZZZ_ChoppedStraw.
--     soilMod.addPlugin_UpdateSowingArea_before(
--         "Destroy dynamic foliage-layers",
--         40,
--         function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
--             Utils.fmcUpdateDestroyDynamicFoliageLayers(sx,sz,wx,wz,hx,hz, true, fmcSoilModPlugins.fmcTYPE_SEEDER)
--         end
--     )
-- end

--
function fmcSoilModPlugins.pluginsForCutFruitArea(soilMod)
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
    
    -- Special case; if fertilizerOrganic layer is not there, then add the default "double yield from spray layer" effect.
    if not hasFoliageLayer(g_currentMission.fmcFoliageFertilizerOrganic) then
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
    if hasFoliageLayer(g_currentMission.fmcFoliageWeed) then
        soilMod.addPlugin_CutFruitArea_before(
            "Get weed density and cut weed",
            20,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Get weeds, but only the lower 2 bits (values 0-3), and then set them to zero.
                -- This way weed gets cut, but alive weed will still grow again.
                setDensityCompareParams(g_currentMission.fmcFoliageWeed, "greater", 0);
                dataStore.weeds = {}
                dataStore.weeds.oldSum, dataStore.weeds.numPixels, dataStore.weeds.newDelta = setDensityParallelogram(
                    g_currentMission.fmcFoliageWeed,
                    sx,sz,wx,wz,hx,hz,
                    0,2,
                    0 -- value
                )
                setDensityCompareParams(g_currentMission.fmcFoliageWeed, "greater", -1);
            end
        )
        
        soilMod.addPlugin_CutFruitArea_after(
            "Volume is affected by percentage of weeds",
            20,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                if dataStore.weeds.numPixels > 0 then
                    local weedPct = (dataStore.weeds.oldSum / (3 * dataStore.weeds.numPixels)) * (dataStore.weeds.numPixels / dataStore.numPixels)
                    -- Remove some volume that weeds occupy.
                    dataStore.volume = math.max(0, dataStore.volume - (dataStore.volume * weedPct))
                end
            end
        )
    end
    
    -- Only add effect, when required foliage-layer exist
    if hasFoliageLayer(g_currentMission.fmcFoliageFertilizerOrganic) then
        soilMod.addPlugin_CutFruitArea_before(
            "Get fertilizer(organic) density and reduce",
            20,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Get fertilizer(organic), and reduce it by one
                setDensityMaskParams(g_currentMission.fmcFoliageFertilizerOrganic, "between", dataStore.minHarvestingGrowthState, dataStore.maxHarvestingGrowthState);
                dataStore.fertilizerOrganic = {}
                dataStore.fertilizerOrganic.oldSum, dataStore.fertilizerOrganic.numPixels, dataStore.fertilizerOrganic.newDelta = addDensityMaskedParallelogram(
                    g_currentMission.fmcFoliageFertilizerOrganic, 
                    sx,sz,wx,wz,hx,hz,
                    0,2,
                    dataStore.fruitFoliageId,0,g_currentMission.numFruitStateChannels,
                    -1 -- subtract
                )
                setDensityMaskParams(g_currentMission.fmcFoliageFertilizerOrganic, "greater", -1);
            end
        )
    
        soilMod.addPlugin_CutFruitArea_after(
            "Volume is affected by fertilizer(organic)",
            30,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- SoilManagement does not use spray for "yield".
                dataStore.spraySum = 0
                --
                if dataStore.fertilizerOrganic.numPixels > 0 then
                    local nutrientLevel = dataStore.fertilizerOrganic.oldSum / dataStore.fertilizerOrganic.numPixels
                    -- If nutrition available, then increase volume by 50%-100%
                    if nutrientLevel > 0 then
                        dataStore.volume = dataStore.volume * math.min(2, nutrientLevel+1.5)
                    end
                end
            end
        )
    end
    
    -- Only add effect, when required foliage-layer exist
    if hasFoliageLayer(g_currentMission.fmcFoliageFertilizerSynthetic) then
        soilMod.addPlugin_CutFruitArea_before(
            "Get fertilizer(synthetic) density and remove",
            20,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Get fertilizer(synthetic)-A and -B types, and reduce them to zero.
                setDensityMaskParams(g_currentMission.fmcFoliageFertilizerSynthetic, "between", dataStore.minHarvestingGrowthState, dataStore.maxHarvestingGrowthState);
                dataStore.fertilizerSynthetic1 = {}
                dataStore.fertilizerSynthetic1.oldSum, dataStore.fertilizerSynthetic1.numPixels, dataStore.fertilizerSynthetic1.newDelta = setDensityMaskedParallelogram(
                    g_currentMission.fmcFoliageFertilizerSynthetic, 
                    sx,sz,wx,wz,hx,hz,
                    0,1,
                    dataStore.fruitFoliageId,0,g_currentMission.numFruitStateChannels,
                    0 -- value
                )
                dataStore.fertilizerSynthetic2 = {}
                dataStore.fertilizerSynthetic2.oldSum, dataStore.fertilizerSynthetic2.numPixels, dataStore.fertilizerSynthetic2.newDelta = setDensityMaskedParallelogram(
                    g_currentMission.fmcFoliageFertilizerSynthetic, 
                    sx,sz,wx,wz,hx,hz,
                    1,1,
                    dataStore.fruitFoliageId,0,g_currentMission.numFruitStateChannels,
                    0 -- value
                )
                setDensityMaskParams(g_currentMission.fmcFoliageFertilizerSynthetic, "greater", -1);
            end
        )
    
        soilMod.addPlugin_CutFruitArea_after(
            "Volume is slightly boosted if correct fertilizer(synthetic)",
            40,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                local fertApct = (dataStore.fertilizerSynthetic1.numPixels > 0) and (dataStore.fertilizerSynthetic1.oldSum / dataStore.fertilizerSynthetic1.numPixels) or 0
                local fertBpct = (dataStore.fertilizerSynthetic2.numPixels > 0) and (dataStore.fertilizerSynthetic2.oldSum / dataStore.fertilizerSynthetic2.numPixels) or 0
    
                if fmcSoilModPlugins.simplisticMode then
                    -- Simplistic mode: Fruits get a boost if (any) fertilizer is applied
                    local volumeBoost = 0
                    if fertApct>0 and fertBpct>0 then
                        volumeBoost = (dataStore.numPixels * ((fertApct + fertBpct) / 2)) 
                    elseif fertApct>0 then
                        volumeBoost = (dataStore.numPixels * fertApct)
                    elseif fertBpct>0 then
                        volumeBoost = (dataStore.numPixels * fertBpct)
                    end
                    dataStore.volume = dataStore.volume + volumeBoost
                else
                    -- Advanced mode: Fruits only get a boost from a particular fertilizer
                    local volumeBoost = 0
                    if fertApct>0 and fertBpct>0 then
                        if fruitDesc.fmcBoostFertilizer == Fillable.FILLTYPE_FERTILIZER3 then
                            volumeBoost = (dataStore.numPixels * ((fertApct + fertBpct) / 2)) 
                        end
                    elseif fertApct>0 then
                        if fruitDesc.fmcBoostFertilizer == Fillable.FILLTYPE_FERTILIZER then
                            volumeBoost = (dataStore.numPixels * fertApct)
                        end
                    elseif fertBpct>0 then
                        if fruitDesc.fmcBoostFertilizer == Fillable.FILLTYPE_FERTILIZER2 then
                            volumeBoost = (dataStore.numPixels * fertBpct)
                        end
                    end
                    dataStore.volume = dataStore.volume + volumeBoost
                end
            end
        )
    end

    -- Only add effect, when required foliage-layer exist
    if hasFoliageLayer(g_currentMission.fmcFoliageSoil_pH) then
        -- Array of 9 elements... must be sorted! (high, factor)
        fmcSoilModPlugins.fmcSoilpHfactors = {
            {h= 5.1, f=0.05},
            {h= 5.6, f=0.50},
            {h= 6.1, f=0.75},
            {h= 6.6, f=0.95},
            {h= 7.3, f=1.00},   -- neutral
            {h= 7.9, f=0.95},
            {h= 8.5, f=0.90},
            {h= 9.0, f=0.80},
            {h=99.0, f=0.70},
        }
    
        soilMod.addPlugin_CutFruitArea_before(
            "Get soil pH density and reduce",
            20,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Get soil pH, and reduce by one
                setDensityMaskParams(g_currentMission.fmcFoliageSoil_pH, "between", dataStore.minHarvestingGrowthState, dataStore.maxHarvestingGrowthState);
                dataStore.soilpH = {}
                dataStore.soilpH.oldSum, dataStore.soilpH.numPixels, dataStore.soilpH.newDelta = addDensityMaskedParallelogram(
                    g_currentMission.fmcFoliageSoil_pH, 
                    sx,sz,wx,wz,hx,hz,
                    0,3,
                    dataStore.fruitFoliageId,0,g_currentMission.numFruitStateChannels,
                    -1 -- subtract
                )
                setDensityMaskParams(g_currentMission.fmcFoliageSoil_pH, "greater", -1);
            end
        )
    
        soilMod.addPlugin_CutFruitArea_after(
            "Volume is affected by soil pH level",
            50,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                local phValue = 7; -- Default pH value, if setDensity failed to match any pixels or calculation function does not exist.
                if (fmcSoilMod and fmcSoilMod.density_to_pH) then
                    phValue = fmcSoilMod.density_to_pH(dataStore.soilpH.oldSum, dataStore.soilpH.numPixels, 3)
                end
                if fmcSoilModPlugins.simplisticMode then
                    -- Simplistic mode: Soil pH value affects yields, but only when highly acidid.
                    if phValue <= fmcSoilModPlugins.fmcSoilpHfactors[1].h then
                        dataStore.volume = dataStore.volume * fmcSoilModPlugins.fmcSoilpHfactors[1].f
                    elseif phValue <= fmcSoilModPlugins.fmcSoilpHfactors[2].h then
                        dataStore.volume = dataStore.volume * fmcSoilModPlugins.fmcSoilpHfactors[2].f
                    end
                else
                    -- Advanced mode: Soil pH value affects yields
                    -- TODO - Binary search? Or is that too much for an array of 9 elements?
                    if     phValue <= fmcSoilModPlugins.fmcSoilpHfactors[3].h then
                        if     phValue < fmcSoilModPlugins.fmcSoilpHfactors[1].h then
                            dataStore.volume = dataStore.volume * fmcSoilModPlugins.fmcSoilpHfactors[1].f
                        elseif phValue < fmcSoilModPlugins.fmcSoilpHfactors[2].h then
                            dataStore.volume = dataStore.volume * fmcSoilModPlugins.fmcSoilpHfactors[2].f
                        else
                            dataStore.volume = dataStore.volume * fmcSoilModPlugins.fmcSoilpHfactors[3].f
                        end
                    elseif phValue <= fmcSoilModPlugins.fmcSoilpHfactors[6].h then
                        if     phValue < fmcSoilModPlugins.fmcSoilpHfactors[4].h then
                            dataStore.volume = dataStore.volume * fmcSoilModPlugins.fmcSoilpHfactors[4].f
                        elseif phValue < fmcSoilModPlugins.fmcSoilpHfactors[5].h then
                            dataStore.volume = dataStore.volume * fmcSoilModPlugins.fmcSoilpHfactors[5].f
                        else
                            dataStore.volume = dataStore.volume * fmcSoilModPlugins.fmcSoilpHfactors[6].f
                        end
                    else
                        if     phValue < fmcSoilModPlugins.fmcSoilpHfactors[7].h then
                            dataStore.volume = dataStore.volume * fmcSoilModPlugins.fmcSoilpHfactors[7].f
                        elseif phValue < fmcSoilModPlugins.fmcSoilpHfactors[8].h then
                            dataStore.volume = dataStore.volume * fmcSoilModPlugins.fmcSoilpHfactors[8].f
                        else
                            dataStore.volume = dataStore.volume * fmcSoilModPlugins.fmcSoilpHfactors[9].f
                        end
                    end
                end
            end
        )
    end
    
    -- Issue #26. MoreRealistic's OverrideCutterAreaEvent.LUA will multiply volume with 1.5
    -- if not sprayed, where the normal game multiply with 1.0. - However both methods will 
    -- multiply with 2.0 in case the spraySum is greater than zero. - So to fix this, this 
    -- plugin for SoilMod will make CutFruitArea return half the volume and have spraySum 
    -- greater than zero.
    soilMod.addPlugin_CutFruitArea_after(
        "Fix for MoreRealistic multiplying volume by 1.5, where SoilMod expects it to be 1.0",
        9999, -- This plugin MUST be the last one, before 'CutFruitArea' returns!
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)    
            dataStore.volume = dataStore.volume / 2
            dataStore.spraySum = 1
            
          -- Below didn't work correctly. Causes problem when graintank less than 5% and there's weed plants.
          -- -- Fix for multiplayer, to ensure that event will be sent to clients, if there was something to cut.
          -- if (dataStore.numPixels > 0) or (dataStore.weeds ~= nil and dataStore.weeds.numPixels > 0) then
          --     dataStore.volume = dataStore.volume + 0.0000001
          -- end
          
          -- Thinking of a different approach, to send "cut"-event to clients when volume == 0 and (numPixels > 0 or weed > 0),
          -- where a "global variable" will be set, and then afterwards elsewhere it is tested to see if an event should be sent,
          -- but it requires appending extra functionality to Combine.update() and similar vanilla methods, which may cause even other problems.
        end
    )
end

--
fmcSoilModPlugins.fmcTYPE_UNKNOWN    = 0
fmcSoilModPlugins.fmcTYPE_PLOUGH     = 2^0
fmcSoilModPlugins.fmcTYPE_CULTIVATOR = 2^1
fmcSoilModPlugins.fmcTYPE_SEEDER     = 2^2

--
function fmcSoilModPlugins.fmcUpdateFmcFoliage(sx,sz,wx,wz,hx,hz, isForced, implementType)
    ---- Increase fertilizer(organic)...
    --setDensityMaskParams(         g_currentMission.fmcFoliageFertilizerOrganic, "greater", 0);
    ---- ..where there's manure, by 1(cultivator) or 3(plough)
    --addDensityMaskedParallelogram(g_currentMission.fmcFoliageFertilizerOrganic, sx,sz,wx,wz,hx,hz, 0, 2, g_currentMission.fmcFoliageManure, 0, 2, (implementType==fmcSoilModPlugins.fmcTYPE_PLOUGH and 3 or 1));
    ---- ..where there's slurry, by 1.
    --addDensityMaskedParallelogram(g_currentMission.fmcFoliageFertilizerOrganic, sx,sz,wx,wz,hx,hz, 0, 2, g_currentMission.fmcFoliageSlurry, 0, 1, 1);
    --
    ---- Set "moisture" where there's manure - we're cultivating/plouging it into ground.
    --setDensityMaskedParallelogram(g_currentMission.terrainDetailId,             sx,sz,wx,wz,hx,hz, g_currentMission.sprayChannel, 1, g_currentMission.fmcFoliageManure, 0, 2, 1);
    ---- Set "moisture" where there's slurry - we're cultivating/plouging it into ground.
    --setDensityMaskedParallelogram(g_currentMission.terrainDetailId,             sx,sz,wx,wz,hx,hz, g_currentMission.sprayChannel, 1, g_currentMission.fmcFoliageSlurry, 0, 1, 1);
    
    -- Increase soil pH where there's lime, by 4 - we're cultivating/plouging it into ground.
    setDensityMaskParams(         g_currentMission.fmcFoliageSoil_pH, "greater", 0)
    addDensityMaskedParallelogram(g_currentMission.fmcFoliageSoil_pH,           sx,sz,wx,wz,hx,hz, 0, 4, g_currentMission.fmcFoliageLime, 0, 1, 4);

    -- Remove the manure/slurry/lime we've just cultivated/ploughed into ground.
    setDensityParallelogram(g_currentMission.fmcFoliageManure, sx,sz,wx,wz,hx,hz, 0, 2, 0)
    setDensityParallelogram(g_currentMission.fmcFoliageSlurry, sx,sz,wx,wz,hx,hz, 0, 2, 0)
    setDensityParallelogram(g_currentMission.fmcFoliageLime,   sx,sz,wx,wz,hx,hz, 0, 1, 0)
    -- Remove weed plants - where we're cultivating/ploughing.
    setDensityParallelogram(g_currentMission.fmcFoliageWeed,   sx,sz,wx,wz,hx,hz, 0, 4, 0)
end

--
function fmcSoilModPlugins.pluginsForUpdateCultivatorArea(soilMod)
    --
    -- Additional effects for the Utils.UpdateCultivatorArea()
    --

    soilMod.addPlugin_UpdateCultivatorArea_before(
        "Destroy common area",
        30,
        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            Utils.fmcUpdateDestroyCommonArea(sx,sz,wx,wz,hx,hz, not dataStore.commonForced, fmcSoilModPlugins.fmcTYPE_CULTIVATOR);
        end
    )

    -- Only add effect, when all required foliage-layers exists
    if  --hasFoliageLayer(g_currentMission.fmcFoliageFertilizerOrganic)
        hasFoliageLayer(g_currentMission.fmcFoliageSoil_pH)
    and hasFoliageLayer(g_currentMission.fmcFoliageManure)
    and hasFoliageLayer(g_currentMission.fmcFoliageSlurry)
    and hasFoliageLayer(g_currentMission.fmcFoliageLime)
    and hasFoliageLayer(g_currentMission.fmcFoliageWeed)
    then
        soilMod.addPlugin_UpdateCultivatorArea_before(
            "Update foliage-layer for SoilMod",
            40,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                fmcSoilModPlugins.fmcUpdateFmcFoliage(sx,sz,wx,wz,hx,hz, dataStore.forced, fmcSoilModPlugins.fmcTYPE_CULTIVATOR)
            end
        )
    end

end

--
function fmcSoilModPlugins.pluginsForUpdatePloughArea(soilMod)
    --
    -- Additional effects for the Utils.UpdatePloughArea()
    --

    soilMod.addPlugin_UpdatePloughArea_before(
        "Destroy common area",
        30,function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
            Utils.fmcUpdateDestroyCommonArea(sx,sz,wx,wz,hx,hz, not dataStore.commonForced, fmcSoilModPlugins.fmcTYPE_PLOUGH);
        end
    )

    -- Only add effect, when all required foliage-layers exists
    if  --hasFoliageLayer(g_currentMission.fmcFoliageFertilizerOrganic)
        hasFoliageLayer(g_currentMission.fmcFoliageSoil_pH)
    and hasFoliageLayer(g_currentMission.fmcFoliageManure)
    and hasFoliageLayer(g_currentMission.fmcFoliageSlurry)
    and hasFoliageLayer(g_currentMission.fmcFoliageLime)
    then
        soilMod.addPlugin_UpdatePloughArea_before(
            "Update foliage-layer for SoilMod",
            40,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                fmcSoilModPlugins.fmcUpdateFmcFoliage(sx,sz,wx,wz,hx,hz, dataStore.forced, fmcSoilModPlugins.fmcTYPE_PLOUGH)
            end
        )
    end

    -- Attempt at adding stones randomly appearing when ploughing.
    -- Unfortunately it won't work, for two reasons:
    -- - Using "math.random" client-side, will produce different results compared to server,
    --   so it will not be the same areas that gets affected.
    -- - Even when the equipment/tool is not moving, it will still continuously call
    --   Utils.updatePloughArea(), thereby causing "flickering" of the terrain.
    --local stoneFoliageLayerId = getChild(g_currentMission.terrainRootNode, "stones")
    --if stoneFoliageLayerId ~= nil and stoneFoliageLayerId ~= 0 then
    --    local numChannels     = getTerrainDetailNumChannels(stoneFoliageLayerId)
    --    local value           = 2^numChannels - 1
    --
    --    soilMod.addPlugin_UpdatePloughArea_before(
    --        "Ploughing causes stones to randomly appear",
    --        50,
    --        function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
    --            if math.random(0,100) < 2 then
    --                setDensityParallelogram(stoneFoliageLayerId, sx,sz,wx,wz,hx,hz, 0, numChannels, value)
    --            end
    --        end
    --    )
    --end
    
end

--
function fmcSoilModPlugins.pluginsForUpdateSowingArea(soilMod)
    --
    -- Additional effects for the Utils.UpdateSowingArea()
    --

    -- Only add effect, when required foliage-layer exist
    if hasFoliageLayer(g_currentMission.fmcFoliageWeed) then
        soilMod.addPlugin_UpdateSowingArea_before(
            "Destroy weed plants when sowing",
            30,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Remove weed plants - where we're seeding.
                setDensityParallelogram(g_currentMission.fmcFoliageWeed, sx,sz,wx,wz,hx,hz, 0, 3, 0)
            end
        )
    end
    
end

--
function fmcSoilModPlugins.pluginsForUpdateSprayArea(soilMod)
    --
    -- Additional effects for the Utils.UpdateSprayArea()
    --

    if hasFoliageLayer(g_currentMission.fmcFoliageManure) then
        local foliageId       = g_currentMission.fmcFoliageManure
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

    if hasFoliageLayer(g_currentMission.fmcFoliageSlurry) then
        local foliageId       = g_currentMission.fmcFoliageSlurry
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
        end
    end

    if hasFoliageLayer(g_currentMission.fmcFoliageLime) then
        local foliageId       = g_currentMission.fmcFoliageLime
        local numChannels     = getTerrainDetailNumChannels(foliageId)
        local value           = 2^numChannels - 1
        
        if Fillable.FILLTYPE_LIME ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread lime",
                10,
                Fillable.FILLTYPE_LIME,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return false -- No moisture!
                end
            )
        end
        if Fillable.FILLTYPE_KALK ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread kalk",
                10,
                Fillable.FILLTYPE_KALK,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return false -- No moisture!
                end
            )
        end
    end

    if hasFoliageLayer(g_currentMission.fmcFoliageHerbicide) then
        local foliageId       = g_currentMission.fmcFoliageHerbicide
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
    end

    if hasFoliageLayer(g_currentMission.fmcFoliageFertilizer) then
        local fruitLayer = g_currentMission.fruits[1]
        -- TODO - add support for multiple FMLs
        if fruitLayer ~= nil and hasFoliageLayer(fruitLayer.id) then
            local fruitLayerId = fruitLayer.id
            local foliageId    = g_currentMission.fmcFoliageFertilizer
            local numChannels  = getTerrainDetailNumChannels(foliageId)
        
            if Fillable.FILLTYPE_FERTILIZER ~= nil then
                soilMod.addPlugin_UpdateSprayArea_fillType(
                    "Spray fertilizer",
                    10,
                    Fillable.FILLTYPE_FERTILIZER,
                    function(sx,sz,wx,wz,hx,hz)
                        -- TODO - add support for multiple FMLs
                        --setDensityTypeIndexCompareMode(fruitLayerId, 2) -- COMPARE_NONE
                        --setDensityMaskParams(foliageId, "between", fmcModifyFSUtils.fertilizerSynthetic_spray_firstGrowthState, fmcModifyFSUtils.fertilizerSynthetic_spray_lastGrowthState)
                        --setDensityMaskedParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0,numChannels, fruitLayerId,0,g_currentMission.numFruitStateChannels, 1) -- type-A
                        --setDensityTypeIndexCompareMode(fruitLayerId, 0) -- COMPARE_EQUAL
                        --setDensityMaskParams(foliageId, "greater", -1)

                        setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0,numChannels, 1) -- type-A
                        
                        return true -- Place moisture!
                    end
                )
                ---- Support for URF-seeders, using a special "augmented fill-type" value (i.e. "<fillType> + 128").
                --soilMod.addPlugin_UpdateSprayArea_fillType(
                --    "Spray fertilizer(augmented)",
                --    10,
                --    Fillable.FILLTYPE_FERTILIZER + 128,
                --    function(sx,sz,wx,wz,hx,hz)
                --        -- TODO - add support for multiple FMLs
                --        setDensityTypeIndexCompareMode(fruitLayerId, 2) -- COMPARE_NONE
                --        setDensityMaskParams(foliageId, "between", 0, fmcModifyFSUtils.fertilizerSynthetic_spray_lastGrowthState)
                --        setDensityMaskedParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0,numChannels, fruitLayerId,0,g_currentMission.numFruitStateChannels, 1) -- type-A
                --        setDensityTypeIndexCompareMode(fruitLayerId, 0) -- COMPARE_EQUAL
                --        setDensityMaskParams(foliageId, "greater", -1)
                --        return true -- Place moisture!
                --    end
                --)
            end
            if Fillable.FILLTYPE_FERTILIZER2 ~= nil then
                soilMod.addPlugin_UpdateSprayArea_fillType(
                    "Spray fertilizer2",
                    10,
                    Fillable.FILLTYPE_FERTILIZER2,
                    function(sx,sz,wx,wz,hx,hz)
                        -- TODO - add support for multiple FMLs
                        --setDensityTypeIndexCompareMode(fruitLayerId, 2) -- COMPARE_NONE
                        --setDensityMaskParams(foliageId, "between", fmcModifyFSUtils.fertilizerSynthetic_spray_firstGrowthState, fmcModifyFSUtils.fertilizerSynthetic_spray_lastGrowthState)
                        --setDensityMaskedParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0,numChannels, fruitLayerId,0,g_currentMission.numFruitStateChannels, 2) -- type-B
                        --setDensityTypeIndexCompareMode(fruitLayerId, 0) -- COMPARE_EQUAL
                        --setDensityMaskParams(foliageId, "greater", -1)
                        
                        setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0,numChannels, 2) -- type-B
                        
                        return true -- Place moisture!
                    end
                )
                ---- Support for URF-seeders, using a special "augmented fill-type" value (i.e. "<fillType> + 128").
                --soilMod.addPlugin_UpdateSprayArea_fillType(
                --    "Spray fertilizer2(augmented)",
                --    10,
                --    Fillable.FILLTYPE_FERTILIZER2 + 128,
                --    function(sx,sz,wx,wz,hx,hz)
                --        -- TODO - add support for multiple FMLs
                --        setDensityTypeIndexCompareMode(fruitLayerId, 2) -- COMPARE_NONE
                --        setDensityMaskParams(foliageId, "between", 0, fmcModifyFSUtils.fertilizerSynthetic_spray_lastGrowthState)
                --        setDensityMaskedParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0,numChannels, fruitLayerId,0,g_currentMission.numFruitStateChannels, 2) -- type-B
                --        setDensityTypeIndexCompareMode(fruitLayerId, 0) -- COMPARE_EQUAL
                --        setDensityMaskParams(foliageId, "greater", -1)
                --        return true -- Place moisture!
                --    end
                --)
            end
            if Fillable.FILLTYPE_FERTILIZER3 ~= nil then
                soilMod.addPlugin_UpdateSprayArea_fillType(
                    "Spray fertilizer3",
                    10,
                    Fillable.FILLTYPE_FERTILIZER3,
                    function(sx,sz,wx,wz,hx,hz)
                        -- TODO - add support for multiple FMLs
                        --setDensityTypeIndexCompareMode(fruitLayerId, 2) -- COMPARE_NONE
                        --setDensityMaskParams(foliageId, "between", fmcModifyFSUtils.fertilizerSynthetic_spray_firstGrowthState, fmcModifyFSUtils.fertilizerSynthetic_spray_lastGrowthState)
                        setDensityMaskedParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0,numChannels, fruitLayerId,0,g_currentMission.numFruitStateChannels, 3) -- type-C
                        --setDensityTypeIndexCompareMode(fruitLayerId, 0) -- COMPARE_EQUAL
                        --setDensityMaskParams(foliageId, "greater", -1)

                        setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0,numChannels, 3) -- type-C
                        
                        return true -- Place moisture!
                    end
                )
                ---- Support for URF-seeders, using a special "augmented fill-type" value (i.e. "<fillType> + 128").
                --soilMod.addPlugin_UpdateSprayArea_fillType(
                --    "Spray fertilizer3(augmented)",
                --    10,
                --    Fillable.FILLTYPE_FERTILIZER3 + 128,
                --    function(sx,sz,wx,wz,hx,hz)
                --        -- TODO - add support for multiple FMLs
                --        setDensityTypeIndexCompareMode(fruitLayerId, 2) -- COMPARE_NONE
                --        setDensityMaskParams(foliageId, "between", 0, fmcModifyFSUtils.fertilizerSynthetic_spray_lastGrowthState)
                --        setDensityMaskedParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0,numChannels, fruitLayerId,0,g_currentMission.numFruitStateChannels, 3) -- type-C
                --        setDensityTypeIndexCompareMode(fruitLayerId, 0) -- COMPARE_EQUAL
                --        setDensityMaskParams(foliageId, "greater", -1)
                --        return true -- Place moisture!
                --    end                
                --)
            end
        end
    end
end

--
function fmcSoilModPlugins.pluginsForGrowthCycle(soilMod)
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
    
    soilMod.addPlugin_GrowthCycleFruits(
        "Increase crop growth",
        10, 
        function(sx,sz,wx,wz,hx,hz,fruitEntry,day)
            -- Increase growth by 1
            setDensityMaskParams(fruitEntry.fruitId, "between", fruitEntry.minSeededValue, fruitEntry.maxMatureValue - ((fmcGrowthControl.disableWithering or fruitEntry.witheredValue == nil) and 1 or 0))
            addDensityMaskedParallelogram(
              fruitEntry.fruitId,
              sx,sz,wx,wz,hx,hz,
              0, g_currentMission.numFruitStateChannels,
              fruitEntry.fruitId, 0, g_currentMission.numFruitStateChannels, -- mask
              1 -- add one
            )
            setDensityMaskParams(fruitEntry.fruitId, "greater", 0)
        end
    )

    ---- Only add effect, when required foliage-layer exist
    --if hasFoliageLayer(g_currentMission.fmcFoliageHerbicide) then
    --    soilMod.addPlugin_GrowthCycleFruits(
    --        "Herbicide affect crop",
    --        20, 
    --        function(sx,sz,wx,wz,hx,hz,fruitEntry,day)
    --            -- Herbicide may affect growth or cause withering...
    --            if fruitEntry.herbicideAvoidance ~= nil and fruitEntry.herbicideAvoidance >= 1 and fruitEntry.herbicideAvoidance <= 3 then
    --              -- Herbicide affected fruit
    --              setDensityMaskParams(fruitEntry.fruitId, "equals", fruitEntry.herbicideAvoidance)
    --              -- When growing and affected by wrong herbicide, pause one growth-step
    --              setDensityCompareParams(fruitEntry.fruitId, "between", fruitEntry.minSeededValue+1, fruitEntry.minMatureValue)
    --              addDensityMaskedParallelogram(
    --                fruitEntry.fruitId,
    --                sx,sz,wx,wz,hx,hz,
    --                0, g_currentMission.numFruitStateChannels,
    --                g_currentMission.fmcFoliageHerbicide, 0, 2, -- mask
    --                -1 -- subtract one
    --              )
    --              -- When mature and affected by wrong herbicide, change to withered if possible.
    --              if fruitEntry.witheredValue ~= nil then
    --                setDensityMaskParams(fruitEntry.fruitId, "equals", fruitEntry.herbicideAvoidance)
    --                setDensityCompareParams(fruitEntry.fruitId, "between", fruitEntry.minMatureValue, fruitEntry.maxMatureValue)
    --                setDensityMaskedParallelogram(
    --                    fruitEntry.fruitId,
    --                    sx,sz,wx,wz,hx,hz,
    --                    0, g_currentMission.numFruitStateChannels,
    --                    g_currentMission.fmcFoliageHerbicide, 0, 2, -- mask
    --                    fruitEntry.witheredValue  -- value
    --                )
    --              end
    --              --
    --              setDensityCompareParams(fruitEntry.fruitId, "greater", -1)
    --              setDensityMaskParams(fruitEntry.fruitId, "greater", 0)
    --            end
    --        end
    --    )
    --end
    
    if fmcSoilModPlugins.reduceWindrows ~= false then
        soilMod.addPlugin_GrowthCycleFruits(
            "Reduce crop windrows/swath",
            30, 
            function(sx,sz,wx,wz,hx,hz,fruitEntry,day)
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
    
    
    -- Spray moisture
    if fmcGrowthControl.removeSprayMoisture then
        soilMod.addPlugin_GrowthCycle(
            "Remove spray moisture",
            10, 
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
    
    --Lime/Kalk and soil pH
    -- Only add effect, when required foliage-layer exist
    if hasFoliageLayer(g_currentMission.fmcFoliageLime) then
        if hasFoliageLayer(g_currentMission.fmcFoliageSoil_pH) then
            soilMod.addPlugin_GrowthCycle(
                "Increase soil pH where there is lime",
                20 - 1, 
                function(sx,sz,wx,wz,hx,hz,day)
                    -- Increase soil-pH, where lime is
                    setDensityMaskParams(g_currentMission.fmcFoliageSoil_pH, "greater", 0); -- lime must be > 0
                    addDensityMaskedParallelogram(
                        g_currentMission.fmcFoliageSoil_pH,
                        sx,sz,wx,wz,hx,hz,
                        0, 4,
                        g_currentMission.fmcFoliageLime, 0, 1,
                        3  -- increase
                    );
                    setDensityMaskParams(g_currentMission.fmcFoliageSoil_pH, "greater", -1);
                end
            )
        end
    
        soilMod.addPlugin_GrowthCycle(
            "Remove lime",
            20, 
            function(sx,sz,wx,wz,hx,hz,day)
                -- Remove lime
                setDensityParallelogram(
                    g_currentMission.fmcFoliageLime,
                    sx,sz,wx,wz,hx,hz,
                    0, 1,
                    0  -- value
                );
            end
        )
    end
    
    -- Manure
    -- Only add effect, when required foliage-layer exist
    if hasFoliageLayer(g_currentMission.fmcFoliageManure) then
        soilMod.addPlugin_GrowthCycle(
            "Reduce manure",
            30, 
            function(sx,sz,wx,wz,hx,hz,day)
                -- Decrease solid manure
                addDensityParallelogram(
                    g_currentMission.fmcFoliageManure,
                    sx,sz,wx,wz,hx,hz,
                    0, 2,
                    -1  -- subtract one
                );
            end
        )
    end
    
    -- Slurry/LiquidManure
    -- Only add effect, when required foliage-layer exist
    if hasFoliageLayer(g_currentMission.fmcFoliageSlurry) then
        if hasFoliageLayer(g_currentMission.fmcFoliageNitrogen) then
            soilMod.addPlugin_GrowthCycle(
                "Add +1 nitrate(N) where there is slurry",
                40 - 1, 
                function(sx,sz,wx,wz,hx,hz,day)
                    -- add to nitrogen
                    setDensityMaskParams(g_currentMission.fmcFoliageNitrogen, "greater", 0); -- slurry must be > 0
                    addDensityMaskedParallelogram(
                        g_currentMission.fmcFoliageNitrogen,
                        sx,sz,wx,wz,hx,hz,
                        0, 4,
                        g_currentMission.fmcFoliageSlurry, 0, 1,  -- mask
                        1 -- increase
                    );
                    setDensityMaskParams(g_currentMission.fmcFoliageNitrogen, "greater", -1);
                end
            )
        end
        
        soilMod.addPlugin_GrowthCycle(
            "Remove slurry",
            40, 
            function(sx,sz,wx,wz,hx,hz,day)
                -- Remove liquid manure
                setDensityParallelogram(
                    g_currentMission.fmcFoliageSlurry,
                    sx,sz,wx,wz,hx,hz,
                    0, 1,
                    0
                );
            end
        )
    end
    
    ---- Weed and herbicide
    ---- Only add effect, when required foliage-layer exist
    --if hasFoliageLayer(g_currentMission.fmcFoliageWeed) then
    --    soilMod.addPlugin_GrowthCycle(
    --        "Reduce withered weed",
    --        50 - 2, 
    --        function(sx,sz,wx,wz,hx,hz,day)
    --            -- Decrease "dead" weed
    --            setDensityCompareParams(g_currentMission.fmcFoliageWeed, "between", 1, 3)
    --            addDensityParallelogram(
    --                g_currentMission.fmcFoliageWeed,
    --                sx,sz,wx,wz,hx,hz,
    --                0, 3,
    --                -1  -- subtract
    --            );
    --        end
    --    )
    --
    --    --
    --    if hasFoliageLayer(g_currentMission.fmcFoliageHerbicide) then
    --        soilMod.addPlugin_GrowthCycle(
    --            "Change weed to withered where there is herbicide",
    --            50 - 1, 
    --            function(sx,sz,wx,wz,hx,hz,day)
    --                -- Change to "dead" weed
    --                setDensityCompareParams(g_currentMission.fmcFoliageWeed, "greater", 0)
    --                setDensityMaskParams(g_currentMission.fmcFoliageWeed, "greater", 0)
    --                setDensityMaskedParallelogram(
    --                    g_currentMission.fmcFoliageWeed,
    --                    sx,sz,wx,wz,hx,hz,
    --                    2, 1, -- affect only Most-Significant-Bit
    --                    g_currentMission.fmcFoliageHerbicide, 0, 2, -- mask
    --                    0 -- reset bit
    --                )
    --                setDensityMaskParams(g_currentMission.fmcFoliageWeed, "greater", -1)
    --            end
    --        )
    --    end
    --
    --    soilMod.addPlugin_GrowthCycle(
    --        "Increase weed growth",
    --        50, 
    --        function(sx,sz,wx,wz,hx,hz,day)
    --            -- Increase "alive" weed
    --            setDensityCompareParams(g_currentMission.fmcFoliageWeed, "between", 4, 6)
    --            addDensityParallelogram(
    --                g_currentMission.fmcFoliageWeed,
    --                sx,sz,wx,wz,hx,hz,
    --                0, 3,
    --                1  -- increase
    --            );
    --            setDensityCompareParams(g_currentMission.fmcFoliageWeed, "greater", -1)
    --        end
    --    )
    --end
    --
    ---- Herbicide and soil pH
    ---- Only add effect, when required foliage-layer exist
    --if hasFoliageLayer(g_currentMission.fmcFoliageHerbicide) then
    --    if hasFoliageLayer(g_currentMission.fmcFoliageSoil_pH) then
    --        soilMod.addPlugin_GrowthCycle(
    --            "Reduce soil pH where there is herbicide",
    --            60 - 1, 
    --            function(sx,sz,wx,wz,hx,hz,day)
    --                -- Decrease soil-pH, where herbicide is
    --                setDensityMaskParams(g_currentMission.fmcFoliageSoil_pH, "greater", 0)
    --                addDensityMaskedParallelogram(
    --                    g_currentMission.fmcFoliageSoil_pH,
    --                    sx,sz,wx,wz,hx,hz,
    --                    0, 3,
    --                    g_currentMission.fmcFoliageHerbicide, 0, 2, -- mask
    --                    -1  -- decrease
    --                );
    --                setDensityMaskParams(g_currentMission.fmcFoliageSoil_pH, "greater", -1)
    --            end
    --        )
    --    end
    --
    --    soilMod.addPlugin_GrowthCycle(
    --        "Remove herbicide",
    --        60, 
    --        function(sx,sz,wx,wz,hx,hz,day)
    --            -- Remove herbicide
    --            setDensityParallelogram(
    --                g_currentMission.fmcFoliageHerbicide,
    --                sx,sz,wx,wz,hx,hz,
    --                0, 2,
    --                0  -- value
    --            );
    --        end
    --    )
    --end

end

--
print(string.format("Script loaded: fmcSoilModPlugins.lua (v%s)", fmcSoilModPlugins.version));
