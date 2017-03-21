--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-01-xx
--

sm3TempChoppedStrawPlugin = {}

-- Register this mod for callback from SoilMod's plugin facility
getfenv(0)["modSoilMod3Plugins"] = getfenv(0)["modSoilMod3Plugins"] or {}
table.insert(getfenv(0)["modSoilMod3Plugins"], sm3TempChoppedStrawPlugin)

--
local function hasFoliageLayer(foliageId)
    return (foliageId ~= nil and foliageId ~= 0);
end

local function getFoliageLayer(name, notRegisteredAsFruitType)
    local foliageId = getChild(g_currentMission.terrainRootNode, name)
    if hasFoliageLayer(foliageId) then
        if notRegisteredAsFruitType then
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
function sm3TempChoppedStrawPlugin.soilModPluginCallback(soilMod,settings)

    -- Include ChoppedStraw's foliage-layers to be destroyed by cultivator/plough/seeder.
    soilMod.addDestructibleFoliageId( getChild(g_currentMission.terrainRootNode, "choppedMaize_haulm") )
    soilMod.addDestructibleFoliageId( getChild(g_currentMission.terrainRootNode, "choppedRape_haulm" ) )
    soilMod.addDestructibleFoliageId( getChild(g_currentMission.terrainRootNode, "choppedStraw_haulm") )

    --
    local foundAsFruitType
        =  FruitUtil.fruitTypes["choppedMaize"] ~= nil 
        or FruitUtil.fruitTypes["choppedRape"]  ~= nil 
        or FruitUtil.fruitTypes["choppedStraw"] ~= nil;
    
    g_currentMission.sm3FoliageHaulmMaize = getFoliageLayer("choppedMaize_haulm", not foundAsFruitType)
    g_currentMission.sm3FoliageHaulmRape  = getFoliageLayer("choppedRape_haulm" , not foundAsFruitType)
    g_currentMission.sm3FoliageHaulmStraw = getFoliageLayer("choppedStraw_haulm", not foundAsFruitType)
    
    -- Add effects.
    sm3TempChoppedStrawPlugin.pluginsForUpdateArea(soilMod)
    sm3TempChoppedStrawPlugin.pluginsForSowingArea(soilMod)

    return true
end

--
function sm3TempChoppedStrawPlugin.pluginsForUpdateArea(soilMod)
    -- Only add effect, when all required foliage-layers exists
    if  hasFoliageLayer(g_currentMission.sm3FoliageHaulmMaize)
    and hasFoliageLayer(g_currentMission.sm3FoliageFertN)
    then
        local numChnls = getTerrainDetailNumChannels(g_currentMission.sm3FoliageHaulmMaize)
        
        soilMod.addPlugin_UpdateCultivatorArea_before(
            "Update foliage-layer for 'choppedMaize_haulm' (+1 N)",
            22,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Increase FertN
                setDensityMaskParams(         g_currentMission.sm3FoliageFertN, "greater", 0)
                addDensityMaskedParallelogram(g_currentMission.sm3FoliageFertN,  sx,sz,wx,wz,hx,hz, 0,4, g_currentMission.sm3FoliageHaulmMaize, 0,numChnls, 1);
            end
        )
    
        if hasFoliageLayer(g_currentMission.sm3FoliageFertPK) then
            soilMod.addPlugin_UpdatePloughArea_before(
                "Update foliage-layer for 'choppedMaize_haulm' (+2 N, +2 PK)",
                22,
                function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                    -- Increase FertN
                    setDensityMaskParams(         g_currentMission.sm3FoliageFertN, "greater", 0)
                    addDensityMaskedParallelogram(g_currentMission.sm3FoliageFertN,  sx,sz,wx,wz,hx,hz, 0,4, g_currentMission.sm3FoliageHaulmMaize, 0,numChnls, 2);

                    -- Increase FertPK
                    setDensityMaskParams(         g_currentMission.sm3FoliageFertPK, "greater", 0)
                    addDensityMaskedParallelogram(g_currentMission.sm3FoliageFertPK,  sx,sz,wx,wz,hx,hz, 0,3, g_currentMission.sm3FoliageHaulmMaize, 0,numChnls, 2);
                end
            )
        end
    end

    -- Only add effect, when all required foliage-layers exists
    if  hasFoliageLayer(g_currentMission.sm3FoliageHaulmRape)
    and hasFoliageLayer(g_currentMission.sm3FoliageFertN)
    then
        local numChnls = getTerrainDetailNumChannels(g_currentMission.sm3FoliageHaulmRape)
        
        soilMod.addPlugin_UpdateCultivatorArea_before(
            "Update foliage-layer for 'choppedRape_haulm' (+1 N)",
            22,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Increase FertN
                setDensityMaskParams(         g_currentMission.sm3FoliageFertN, "greater", 0)
                addDensityMaskedParallelogram(g_currentMission.sm3FoliageFertN,  sx,sz,wx,wz,hx,hz, 0,4, g_currentMission.sm3FoliageHaulmRape, 0,numChnls, 1);
            end
        )
        
        if hasFoliageLayer(g_currentMission.sm3FoliageFertPK) then
            soilMod.addPlugin_UpdatePloughArea_before(
                "Update foliage-layer for 'choppedRape_haulm' (+2 N, +1 PK)",
                22,
                function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                    -- Increase FertN
                    setDensityMaskParams(         g_currentMission.sm3FoliageFertN, "greater", 0)
                    addDensityMaskedParallelogram(g_currentMission.sm3FoliageFertN,  sx,sz,wx,wz,hx,hz, 0,4, g_currentMission.sm3FoliageHaulmRape, 0,numChnls, 2);

                    -- Increase FertPK
                    setDensityMaskParams(         g_currentMission.sm3FoliageFertPK, "greater", 0)
                    addDensityMaskedParallelogram(g_currentMission.sm3FoliageFertPK,  sx,sz,wx,wz,hx,hz, 0,3, g_currentMission.sm3FoliageHaulmRape, 0,numChnls, 1);
                end
            )
        end
    end

    -- Only add effect, when all required foliage-layers exists
    if  hasFoliageLayer(g_currentMission.sm3FoliageHaulmStraw)
    and hasFoliageLayer(g_currentMission.sm3FoliageFertN)
    then
        local numChnls = getTerrainDetailNumChannels(g_currentMission.sm3FoliageHaulmStraw)
        
        soilMod.addPlugin_UpdateCultivatorArea_before(
            "Update foliage-layer for 'choppedStraw_haulm' (+1 N)",
            22,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Increase FertN
                setDensityMaskParams(         g_currentMission.sm3FoliageFertN, "greater", 0)
                addDensityMaskedParallelogram(g_currentMission.sm3FoliageFertN,  sx,sz,wx,wz,hx,hz, 0,4, g_currentMission.sm3FoliageHaulmStraw, 0,numChnls, 1);
            end
        )
        
        if hasFoliageLayer(g_currentMission.sm3FoliageFertPK) then
            soilMod.addPlugin_UpdatePloughArea_before(
                "Update foliage-layer for 'choppedStraw_haulm' (+1 N, +1 PK)",
                22,
                function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                    -- Increase FertN
                    setDensityMaskParams(         g_currentMission.sm3FoliageFertN, "greater", 0)
                    addDensityMaskedParallelogram(g_currentMission.sm3FoliageFertN,  sx,sz,wx,wz,hx,hz, 0,4, g_currentMission.sm3FoliageHaulmStraw, 0,numChnls, 1);

                    -- Increase FertPK
                    setDensityMaskParams(         g_currentMission.sm3FoliageFertPK, "greater", 0)
                    addDensityMaskedParallelogram(g_currentMission.sm3FoliageFertPK,  sx,sz,wx,wz,hx,hz, 0,3, g_currentMission.sm3FoliageHaulmStraw, 0,numChnls, 1);
                end
            )
        end
    end
end

--
function sm3TempChoppedStrawPlugin.pluginsForSowingArea(soilMod)
    --
    if  ZZZ_ChoppedStraw ~= nil 
    and ZZZ_ChoppedStraw.ChoppedStraw_Register ~= nil
    then
        -- Test for if ZZZ_ChoppedStraw mod did add something to Utils.updateSowingArea()
        if ZZZ_ChoppedStraw.ChoppedStraw_Register.old_updateSowingArea ~= nil then
            return;
        end
    end

    -- If all 3 foliage-layers are there, then only add one plugin-function
    if  hasFoliageLayer(g_currentMission.sm3FoliageHaulmStraw)
    and hasFoliageLayer(g_currentMission.sm3FoliageHaulmMaize)
    and hasFoliageLayer(g_currentMission.sm3FoliageHaulmRape )
    then
        local numChnls = getTerrainDetailNumChannels(g_currentMission.sm3FoliageHaulmStraw) -- Assuming same number of channels.
        soilMod.addPlugin_UpdateSowingArea_after(
            "Removes foliage-layers for 'chopped*_haulm'",
            50,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                setDensityParallelogram(g_currentMission.sm3FoliageHaulmStraw, sx,sz,wx,wz,hx,hz, 0,numChnls, 0);
                setDensityParallelogram(g_currentMission.sm3FoliageHaulmMaize, sx,sz,wx,wz,hx,hz, 0,numChnls, 0);
                setDensityParallelogram(g_currentMission.sm3FoliageHaulmRape , sx,sz,wx,wz,hx,hz, 0,numChnls, 0);
            end
        )
    else
        -- One or more of the foliage-layers are not present.
        --
        if hasFoliageLayer(g_currentMission.sm3FoliageHaulmStraw) then
            local numChnls = getTerrainDetailNumChannels(g_currentMission.sm3FoliageHaulmStraw)
            soilMod.addPlugin_UpdateSowingArea_after(
                "Removes foliage-layer for 'choppedStraw_haulm'",
                50,
                function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                    setDensityParallelogram(g_currentMission.sm3FoliageHaulmStraw, sx,sz,wx,wz,hx,hz, 0,numChnls, 0);
                end
            )
        end
        --
        if hasFoliageLayer(g_currentMission.sm3FoliageHaulmMaize) then
            local numChnls = getTerrainDetailNumChannels(g_currentMission.sm3FoliageHaulmMaize)
            soilMod.addPlugin_UpdateSowingArea_after(
                "Removes foliage-layer for 'choppedMaize_haulm'",
                50,
                function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                    setDensityParallelogram(g_currentMission.sm3FoliageHaulmMaize, sx,sz,wx,wz,hx,hz, 0,numChnls, 0);
                end
            )
        end
        --
        if hasFoliageLayer(g_currentMission.sm3FoliageHaulmRape ) then
            local numChnls = getTerrainDetailNumChannels(g_currentMission.sm3FoliageHaulmRape)
            soilMod.addPlugin_UpdateSowingArea_after(
                "Removes foliage-layer for 'choppedRape_haulm'",
                50,
                function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                    setDensityParallelogram(g_currentMission.sm3FoliageHaulmRape , sx,sz,wx,wz,hx,hz, 0,numChnls, 0);
                end
            )
        end
    end
end
