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
-- This function MUST BE named "soilModPluginCallback" and take two arguments!
-- It is the callback method, that SoilMod's plugin facility will call, to let this mod add its own plugins to SoilMod.
-- The argument is a 'table of functions' which must be used to add this mod's plugin-functions into SoilMod.
--
function fmcTempChoppedStrawPlugin.soilModPluginCallback(soilMod,settings)

    -- Include ChoppedStraw's foliage-layers to be destroyed by cultivator/plough/seeder.
    soilMod.addDestructibleFoliageId( getChild(g_currentMission.terrainRootNode, "choppedMaize_haulm") )
    soilMod.addDestructibleFoliageId( getChild(g_currentMission.terrainRootNode, "choppedRape_haulm" ) )
    soilMod.addDestructibleFoliageId( getChild(g_currentMission.terrainRootNode, "choppedStraw_haulm") )

    return true
end

--
print(string.format("Script loaded: fmcTemporaryChoppedStrawPlugin.lua (v%s)", fmcTempChoppedStrawPlugin.version));
