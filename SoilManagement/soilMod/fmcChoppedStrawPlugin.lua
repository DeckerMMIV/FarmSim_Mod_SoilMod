--
--  The Soil Management and Growth Control Project - version 2 (FS15)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modhoster.com
-- @date    2015-03-xx
--

fmcTempChoppedStrawPlugin = {}

local modItem = ModsUtil.findModItemByModName(g_currentModName);
fmcTempChoppedStrawPlugin.version = (modItem and modItem.version) and modItem.version or "?.?.?";


-- Register this mod for callback from SoilMod's plugin facility
getfenv(0)["modSoilMod2Plugins"] = getfenv(0)["modSoilMod2Plugins"] or {}
table.insert(getfenv(0)["modSoilMod2Plugins"], fmcTempChoppedStrawPlugin)

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
function fmcTempChoppedStrawPlugin.soilModPluginCallback(soilMod,settings)

    -- Include ChoppedStraw's foliage-layers to be destroyed by cultivator/plough/seeder.
    soilMod.addDestructibleFoliageId( getChild(g_currentMission.terrainRootNode, "choppedMaize_haulm") )
    soilMod.addDestructibleFoliageId( getChild(g_currentMission.terrainRootNode, "choppedRape_haulm" ) )
    soilMod.addDestructibleFoliageId( getChild(g_currentMission.terrainRootNode, "choppedStraw_haulm") )

    --
    local foundAsFruitType
        =  FruitUtil.fruitTypes["choppedMaize"] ~= nil 
        or FruitUtil.fruitTypes["choppedRape"]  ~= nil 
        or FruitUtil.fruitTypes["choppedStraw"] ~= nil;
    
    g_currentMission.fmcFoliageHaulmMaize = getFoliageLayer("choppedMaize_haulm", not foundAsFruitType)
    g_currentMission.fmcFoliageHaulmRape  = getFoliageLayer("choppedRape_haulm" , not foundAsFruitType)
    g_currentMission.fmcFoliageHaulmStraw = getFoliageLayer("choppedStraw_haulm", not foundAsFruitType)
    
    -- Add effects.
    fmcTempChoppedStrawPlugin.pluginsForUpdateArea(soilMod)

    return true
end

--
function fmcTempChoppedStrawPlugin.pluginsForUpdateArea(soilMod)
    -- Only add effect, when all required foliage-layers exists
    if  hasFoliageLayer(g_currentMission.fmcFoliageHaulmMaize)
    and hasFoliageLayer(g_currentMission.fmcFoliageFertN)
    then
        local numChnls = getTerrainDetailNumChannels(g_currentMission.fmcFoliageHaulmMaize)
        
        soilMod.addPlugin_UpdateCultivatorArea_before(
            "Update foliage-layer for 'choppedMaize_haulm' (+1 N)",
            22,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Increase FertN
                setDensityMaskParams(         g_currentMission.fmcFoliageFertN, "greater", 0)
                addDensityMaskedParallelogram(g_currentMission.fmcFoliageFertN,  sx,sz,wx,wz,hx,hz, 0,4, g_currentMission.fmcFoliageHaulmMaize, 0,numChnls, 1);
            end
        )
    
        if hasFoliageLayer(g_currentMission.fmcFoliageFertPK) then
            soilMod.addPlugin_UpdatePloughArea_before(
                "Update foliage-layer for 'choppedMaize_haulm' (+2 N, +2 PK)",
                22,
                function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                    -- Increase FertN
                    setDensityMaskParams(         g_currentMission.fmcFoliageFertN, "greater", 0)
                    addDensityMaskedParallelogram(g_currentMission.fmcFoliageFertN,  sx,sz,wx,wz,hx,hz, 0,4, g_currentMission.fmcFoliageHaulmMaize, 0,numChnls, 2);

                    -- Increase FertPK
                    setDensityMaskParams(         g_currentMission.fmcFoliageFertPK, "greater", 0)
                    addDensityMaskedParallelogram(g_currentMission.fmcFoliageFertPK,  sx,sz,wx,wz,hx,hz, 0,3, g_currentMission.fmcFoliageHaulmMaize, 0,numChnls, 2);
                end
            )
        end
    end

    -- Only add effect, when all required foliage-layers exists
    if  hasFoliageLayer(g_currentMission.fmcFoliageHaulmRape)
    and hasFoliageLayer(g_currentMission.fmcFoliageFertN)
    then
        local numChnls = getTerrainDetailNumChannels(g_currentMission.fmcFoliageHaulmRape)
        
        soilMod.addPlugin_UpdateCultivatorArea_before(
            "Update foliage-layer for 'choppedRape_haulm' (+1 N)",
            22,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Increase FertN
                setDensityMaskParams(         g_currentMission.fmcFoliageFertN, "greater", 0)
                addDensityMaskedParallelogram(g_currentMission.fmcFoliageFertN,  sx,sz,wx,wz,hx,hz, 0,4, g_currentMission.fmcFoliageHaulmRape, 0,numChnls, 1);
            end
        )
        
        if hasFoliageLayer(g_currentMission.fmcFoliageFertPK) then
            soilMod.addPlugin_UpdatePloughArea_before(
                "Update foliage-layer for 'choppedRape_haulm' (+2 N, +1 PK)",
                22,
                function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                    -- Increase FertN
                    setDensityMaskParams(         g_currentMission.fmcFoliageFertN, "greater", 0)
                    addDensityMaskedParallelogram(g_currentMission.fmcFoliageFertN,  sx,sz,wx,wz,hx,hz, 0,4, g_currentMission.fmcFoliageHaulmRape, 0,numChnls, 2);

                    -- Increase FertPK
                    setDensityMaskParams(         g_currentMission.fmcFoliageFertPK, "greater", 0)
                    addDensityMaskedParallelogram(g_currentMission.fmcFoliageFertPK,  sx,sz,wx,wz,hx,hz, 0,3, g_currentMission.fmcFoliageHaulmRape, 0,numChnls, 1);
                end
            )
        end
    end

    -- Only add effect, when all required foliage-layers exists
    if  hasFoliageLayer(g_currentMission.fmcFoliageHaulmStraw)
    and hasFoliageLayer(g_currentMission.fmcFoliageFertN)
    then
        local numChnls = getTerrainDetailNumChannels(g_currentMission.fmcFoliageHaulmStraw)
        
        soilMod.addPlugin_UpdateCultivatorArea_before(
            "Update foliage-layer for 'choppedStraw_haulm' (+1 N)",
            22,
            function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                -- Increase FertN
                setDensityMaskParams(         g_currentMission.fmcFoliageFertN, "greater", 0)
                addDensityMaskedParallelogram(g_currentMission.fmcFoliageFertN,  sx,sz,wx,wz,hx,hz, 0,4, g_currentMission.fmcFoliageHaulmStraw, 0,numChnls, 1);
            end
        )
        
        if hasFoliageLayer(g_currentMission.fmcFoliageFertPK) then
            soilMod.addPlugin_UpdatePloughArea_before(
                "Update foliage-layer for 'choppedStraw_haulm' (+1 N, +1 PK)",
                22,
                function(sx,sz,wx,wz,hx,hz, dataStore, fruitDesc)
                    -- Increase FertN
                    setDensityMaskParams(         g_currentMission.fmcFoliageFertN, "greater", 0)
                    addDensityMaskedParallelogram(g_currentMission.fmcFoliageFertN,  sx,sz,wx,wz,hx,hz, 0,4, g_currentMission.fmcFoliageHaulmStraw, 0,numChnls, 1);

                    -- Increase FertPK
                    setDensityMaskParams(         g_currentMission.fmcFoliageFertPK, "greater", 0)
                    addDensityMaskedParallelogram(g_currentMission.fmcFoliageFertPK,  sx,sz,wx,wz,hx,hz, 0,3, g_currentMission.fmcFoliageHaulmStraw, 0,numChnls, 1);
                end
            )
        end
    end
end

--
print(string.format("Script loaded: fmcTemporaryChoppedStrawPlugin.lua (v%s)", fmcTempChoppedStrawPlugin.version));
