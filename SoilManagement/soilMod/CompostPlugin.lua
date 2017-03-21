--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-01-xx
--

sm3CompostPlugin = {}

-- Register this mod for callback from SoilMod's plugin facility
getfenv(0)["modSoilMod3Plugins"] = getfenv(0)["modSoilMod3Plugins"] or {}
table.insert(getfenv(0)["modSoilMod3Plugins"], sm3CompostPlugin)

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
-- This function MUST BE named "soilModPluginCallback" and take two arguments!
-- It is the callback method, that SoilMod's plugin facility will call, to let this mod add its own plugins to SoilMod.
-- The argument is a 'table of functions' which must be used to add this mod's plugin-functions into SoilMod.
--
function sm3CompostPlugin.soilModPluginCallback(soilMod,settings)

    -- Best to use only 'compost' spray-type, with a foliage-layer named 'compost'.
    g_currentMission.sm3FoliageCompost = getFoliageLayer("compost", true)
    
    if not hasFoliageLayer(g_currentMission.sm3FoliageCompost) then
        -- Hmm? Try to look for a foliage-layer named 'compost_soil'
        g_currentMission.sm3FoliageCompost = getFoliageLayer("compost_soil", true)
    end

    if not hasFoliageLayer(g_currentMission.sm3FoliageCompost) then
        -- Now if the mod-/map-author isn't as experienced, they apparently register 'compostSolid' as a fruit-type with windrow,
        -- which then uses yet another fill-type (of the precious few max 64.)
        g_currentMission.sm3FoliageCompost = getFoliageLayer("compostSolid_windrow", true)
    end

    -- Only add effects when the compost foliage-layer was found.
    if hasFoliageLayer(g_currentMission.sm3FoliageCompost) then
        sm3CompostPlugin.sm3NumChnlCompost = getTerrainDetailNumChannels(g_currentMission.sm3FoliageCompost)
        
        -- Add effects when 'compost' is there.
        sm3CompostPlugin.pluginsForUpdateCultivatorArea(soilMod)
        sm3CompostPlugin.pluginsForUpdatePloughArea(    soilMod)
        sm3CompostPlugin.pluginsForUpdateSprayArea(     soilMod)
        sm3CompostPlugin.pluginsForGrowthCycle(         soilMod)
    
        -- Include compost foliage-layer to be destroyed by cultivator/plough/seeder.
        soilMod.addDestructibleFoliageId(g_currentMission.sm3FoliageCompost)
    end

    return true
end

--
function sm3CompostPlugin.pluginsForUpdateCultivatorArea(soilMod)
    -- Only add effect, when all required foliage-layers exists
    if  hasFoliageLayer(g_currentMission.sm3FoliageCompost)
    and hasFoliageLayer(g_currentMission.sm3FoliageFertN)
    and hasFoliageLayer(g_currentMission.sm3FoliageFertPK)
    then
        soilMod.addPlugin_UpdateCultivatorArea_before(
            "Update foliage-layer for 'compost' (+1 N, +1 PK)",
            21,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Increase FertN +1 where there's compost
                setDensityMaskParams(         g_currentMission.sm3FoliageFertN, "greater", 0)
                addDensityMaskedParallelogram(g_currentMission.sm3FoliageFertN,  sx,sz,wx,wz,hx,hz, 0,4, g_currentMission.sm3FoliageCompost, 0,sm3CompostPlugin.sm3NumChnlCompost, 1);

                -- Increase FertPK +1 where there's compost
                setDensityMaskParams(         g_currentMission.sm3FoliageFertPK, "greater", 0)
                addDensityMaskedParallelogram(g_currentMission.sm3FoliageFertPK,  sx,sz,wx,wz,hx,hz, 0,3, g_currentMission.sm3FoliageCompost, 0,sm3CompostPlugin.sm3NumChnlCompost, 1);
            end
        )
    end
end

--
function sm3CompostPlugin.pluginsForUpdatePloughArea(soilMod)
    -- Only add effect, when all required foliage-layers exists
    if  hasFoliageLayer(g_currentMission.sm3FoliageCompost)
    and hasFoliageLayer(g_currentMission.sm3FoliageFertN)
    and hasFoliageLayer(g_currentMission.sm3FoliageFertPK)
    and hasFoliageLayer(g_currentMission.sm3FoliageSoil_pH)
    then
        soilMod.addPlugin_UpdatePloughArea_before(
            "Update foliage-layer for 'compost' (+3 N, +2 PK, +1 pH)",
            21,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Increase FertN +3 where there's compost
                setDensityMaskParams(         g_currentMission.sm3FoliageFertN, "greater", 0)
                addDensityMaskedParallelogram(g_currentMission.sm3FoliageFertN,  sx,sz,wx,wz,hx,hz, 0,4, g_currentMission.sm3FoliageCompost, 0,sm3CompostPlugin.sm3NumChnlCompost, 3);

                -- Increase FertPK +2 where there's compost
                setDensityMaskParams(         g_currentMission.sm3FoliageFertPK, "greater", 0)
                addDensityMaskedParallelogram(g_currentMission.sm3FoliageFertPK,  sx,sz,wx,wz,hx,hz, 0,3, g_currentMission.sm3FoliageCompost, 0,sm3CompostPlugin.sm3NumChnlCompost, 2);
                
                -- Increase pH +1 where there's compost
                setDensityMaskParams(         g_currentMission.sm3FoliageSoil_pH, "greater", 0)
                addDensityMaskedParallelogram(g_currentMission.sm3FoliageSoil_pH, sx,sz,wx,wz,hx,hz, 0,4, g_currentMission.sm3FoliageCompost, 0,sm3CompostPlugin.sm3NumChnlCompost, 1);
            end
        )
    end
end

--
function sm3CompostPlugin.pluginsForUpdateSprayArea(soilMod)
    --
    if hasFoliageLayer(g_currentMission.sm3FoliageCompost) then
        local foliageId       = g_currentMission.sm3FoliageCompost
        --local numChannels     = getTerrainDetailNumChannels(foliageId)
        local numChannels     = sm3CompostPlugin.sm3NumChnlCompost
        local value           = 2^numChannels - 1
        
        if Fillable.FILLTYPE_COMPOST ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread compost",
                10,
                Fillable.FILLTYPE_COMPOST,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return false -- No moisture!
                end
            )
        end
        if Fillable.FILLTYPE_COMPOST_SOIL ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread compost_soil",
                10,
                Fillable.FILLTYPE_COMPOST_SOIL,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return false -- No moisture!
                end
            )
        end
        if Fillable.FILLTYPE_COMPOSTSOLID ~= nil then
            soilMod.addPlugin_UpdateSprayArea_fillType(
                "Spread compostSolid",
                10,
                Fillable.FILLTYPE_COMPOSTSOLID,
                function(sx,sz,wx,wz,hx,hz)
                    setDensityParallelogram(foliageId, sx,sz,wx,wz,hx,hz, 0, numChannels, value);
                    return false -- No moisture!
                end
            )
        end
    end
end

--
function sm3CompostPlugin.pluginsForGrowthCycle(soilMod)
    -- Compost
    if hasFoliageLayer(g_currentMission.sm3FoliageCompost) then
    
        if hasFoliageLayer(g_currentMission.sm3FoliageMoisture) then
            soilMod.addPlugin_GrowthCycle(
                "Increase moisture where there is compost",
                45, 
                function(sx,sz,wx,wz,hx,hz,day)
                    setDensityMaskParams(g_currentMission.sm3FoliageMoisture, "greater", 0);
                    addDensityMaskedParallelogram(
                        g_currentMission.sm3FoliageMoisture,
                        sx,sz,wx,wz,hx,hz,
                        0, 3,
                        g_currentMission.sm3FoliageCompost, 0, sm3CompostPlugin.sm3NumChnlCompost,  -- mask
                        1 -- increase
                    );
                    setDensityMaskParams(g_currentMission.sm3FoliageMoisture, "greater", -1);
                end
            )
        end

        soilMod.addPlugin_GrowthCycle(
            "Remove compost",
            45 + 1, 
            function(sx,sz,wx,wz,hx,hz,day)
                -- Remove compost
                setDensityParallelogram(
                    g_currentMission.sm3FoliageCompost,
                    sx,sz,wx,wz,hx,hz,
                    0, sm3CompostPlugin.sm3NumChnlCompost,
                    0
                );
            end
        )
    end
end
