--
--  The Soil Management and Growth Control Project - version 2 (FS15)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modhoster.com
-- @date    2015-02-xx
--

fmcFilltypes = {}
--
local modItem = ModsUtil.findModItemByModName(g_currentModName);
fmcFilltypes.version = (modItem and modItem.version) and modItem.version or "?.?.?";
--
fmcFilltypes.modDir = g_currentModDirectory;

--
function fmcFilltypes.setup(mapFilltypeOverlaysDirectory)
    if mapFilltypeOverlaysDirectory == nil then
        mapFilltypeOverlaysDirectory = fmcFilltypes.modDir .. "filltypeOverlays/"; -- Use SoilMod's own HUD overlay icons.
    end
    if not Utils.endsWith(mapFilltypeOverlaysDirectory, "/") then
        mapFilltypeOverlaysDirectory = mapFilltypeOverlaysDirectory .. "/"
    end
    fmcFilltypes.mapFilltypeOverlaysDirectory = mapFilltypeOverlaysDirectory

    fmcFilltypes.setupFillTypes(mapFilltypeOverlaysDirectory)
end

--
function fmcFilltypes.teardown()
end

--
function fmcFilltypes.setupFillTypes()
    logInfo("Registering new spray-types")

    -- Update the internationalized name for vanilla fill-type fertilizer.
    Fillable.fillTypeIndexToDesc[Fillable.FILLTYPE_FERTILIZER].nameI18N = g_i18n:getText("fertilizer")

    -- Register some new spray types
    -- TODO - Provide some better usage-per-sqm, price-per-liter and mass-per-liter
--[[
registerSprayType(
	<name>
	<nameI18N>
	<pricePerLiter>
	<litersPerSqmPerSecond>
	<partOfEconomy>
	<hudOverlayFilename>
	<hudOverlayFilenameSmall>
	<massPerLiter>
)
--]]    
    Sprayer.registerSprayType("fertilizer2", g_i18n:getText("fertilizer2"),  0.2, 10, true, Utils.getFilename("fertilizer2.dds", fmcFilltypes.mapFilltypeOverlaysDirectory), Utils.getFilename("fertilizer2.dds", fmcFilltypes.mapFilltypeOverlaysDirectory), 0.0007);
    Sprayer.registerSprayType("fertilizer3", g_i18n:getText("fertilizer3"),  0.5, 15, true, Utils.getFilename("fertilizer3.dds", fmcFilltypes.mapFilltypeOverlaysDirectory), Utils.getFilename("fertilizer3.dds", fmcFilltypes.mapFilltypeOverlaysDirectory), 0.0009);
    
    Sprayer.registerSprayType("kalk",        g_i18n:getText("kalk"),         0.1,  3, true, Utils.getFilename("kalk.dds",        fmcFilltypes.mapFilltypeOverlaysDirectory), Utils.getFilename("kalk.dds",        fmcFilltypes.mapFilltypeOverlaysDirectory), 0.0010);
    
    Sprayer.registerSprayType("herbicide",   g_i18n:getText("herbicide"),    0.5,  5, true, Utils.getFilename("herbicide1.dds",  fmcFilltypes.mapFilltypeOverlaysDirectory), Utils.getFilename("herbicide1.dds",  fmcFilltypes.mapFilltypeOverlaysDirectory), 0.0004);
    Sprayer.registerSprayType("herbicide2",  g_i18n:getText("herbicide2"),   0.6, 10, true, Utils.getFilename("herbicide2.dds",  fmcFilltypes.mapFilltypeOverlaysDirectory), Utils.getFilename("herbicide2.dds",  fmcFilltypes.mapFilltypeOverlaysDirectory), 0.0006);
    Sprayer.registerSprayType("herbicide3",  g_i18n:getText("herbicide3"),   0.7, 15, true, Utils.getFilename("herbicide3.dds",  fmcFilltypes.mapFilltypeOverlaysDirectory), Utils.getFilename("herbicide3.dds",  fmcFilltypes.mapFilltypeOverlaysDirectory), 0.0008);
    
    Sprayer.registerSprayType("herbicide4",  g_i18n:getText("herbicide4"),   1.5,  5, true, Utils.getFilename("herbicide4.dds",  fmcFilltypes.mapFilltypeOverlaysDirectory), Utils.getFilename("herbicide4.dds",  fmcFilltypes.mapFilltypeOverlaysDirectory), 0.0004);
    Sprayer.registerSprayType("herbicide5",  g_i18n:getText("herbicide5"),   1.6, 10, true, Utils.getFilename("herbicide5.dds",  fmcFilltypes.mapFilltypeOverlaysDirectory), Utils.getFilename("herbicide5.dds",  fmcFilltypes.mapFilltypeOverlaysDirectory), 0.0006);
    Sprayer.registerSprayType("herbicide6",  g_i18n:getText("herbicide6"),   1.7, 15, true, Utils.getFilename("herbicide6.dds",  fmcFilltypes.mapFilltypeOverlaysDirectory), Utils.getFilename("herbicide6.dds",  fmcFilltypes.mapFilltypeOverlaysDirectory), 0.0008);
end

function fmcFilltypes.addMoreFillTypeOverlayIcons()
    logInfo("Adding overlay-icons for specific fill-types that has none")

    -- Set overlay icons for fill types, if they do not already have one
    local function addFillTypeHudOverlayIcon(fillType, overlayFilename, force)
        if fillType ~= nil and Fillable.fillTypeIndexToDesc[fillType] ~= nil then
            if force or Fillable.fillTypeIndexToDesc[fillType].hudOverlayFilename == nil then
                Fillable.fillTypeIndexToDesc[fillType].hudOverlayFilename = overlayFilename;
                Fillable.fillTypeIndexToDesc[fillType].hudOverlayFilenameSmall = overlayFilename; -- TODO
            end
            if force and g_currentMission.fillTypeOverlays[fillType] ~= nil then
                -- Remove filltype overlay icon, so it can be correctly updated later.
                g_currentMission.fillTypeOverlays[fillType]:delete();
                g_currentMission.fillTypeOverlays[fillType] = nil;
            end
        end
    end

    addFillTypeHudOverlayIcon(Fillable.FILLTYPE_FERTILIZER  , Utils.getFilename("fertilizer1.dds",   fmcFilltypes.mapFilltypeOverlaysDirectory), false);
  --addFillTypeHudOverlayIcon(Fillable.FILLTYPE_MANURE      , Utils.getFilename("manure.dds",        fmcFilltypes.mapFilltypeOverlaysDirectory), false);
  --addFillTypeHudOverlayIcon(Fillable.FILLTYPE_LIQUIDMANURE, Utils.getFilename("liquidManure.dds",  fmcFilltypes.mapFilltypeOverlaysDirectory), false);
    --
    addFillTypeHudOverlayIcon(Fillable.FILLTYPE_KALK        , Utils.getFilename("kalk.dds",          fmcFilltypes.mapFilltypeOverlaysDirectory), false);
end

--
--function fmcFilltypes.setupFruitFertilizerBoostHerbicideAffected()
--    if (not fmcFilltypes.simplisticMode) then
--        -- Set which fertilizer-fill-type that boosts what fruit-type
--        -- Set which herbicide-fill-type that will affect what fruit-type
--        fmcSoilMod.setFruit_FertilizerBoost_HerbicideAffected("wheat"      ,"fertilizer"   ,"herbicide" )
--        fmcSoilMod.setFruit_FertilizerBoost_HerbicideAffected("barley"     ,"fertilizer"   ,"herbicide2")
--        fmcSoilMod.setFruit_FertilizerBoost_HerbicideAffected("rape"       ,"fertilizer3"  ,"herbicide3")
--        fmcSoilMod.setFruit_FertilizerBoost_HerbicideAffected("maize"      ,"fertilizer3"  ,"herbicide" )
--        fmcSoilMod.setFruit_FertilizerBoost_HerbicideAffected("sugarBeet"  ,"fertilizer2"  ,"herbicide2")
--        fmcSoilMod.setFruit_FertilizerBoost_HerbicideAffected("potato"     ,"fertilizer2"  ,"herbicide3")
--        fmcSoilMod.setFruit_FertilizerBoost_HerbicideAffected("grass"      ,"fertilizer"   ,nil         )
--    end
--end

--
function fmcFilltypes.updateFillTypeOverlays()
    logInfo("Updating fill-types HUD overlay-icons")
    for _,fillTypeDesc in pairs(Fillable.fillTypeIndexToDesc) do
        if g_currentMission.fillTypeOverlays[fillTypeDesc.index] == nil and fillTypeDesc.hudOverlayFilename ~= nil and fillTypeDesc.hudOverlayFilename ~= "" then
            g_currentMission:addFillTypeOverlay(fillTypeDesc.index, fillTypeDesc.hudOverlayFilename)
        end
    end
end

print(string.format("Script loaded: fmcFilltypes.lua (v%s)", fmcFilltypes.version));
