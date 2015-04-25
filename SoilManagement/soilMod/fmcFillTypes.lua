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
function fmcFilltypes.setup(mapSelf)

    --fmcFilltypes.i18n = (mapSelf.missionInfo.customEnvironment ~= nil) and _G[mapSelf.missionInfo.customEnvironment].g_i18n or nil;
    fmcFilltypes.mapBaseDirectory = mapSelf.baseDirectory

    --fmcFilltypes.mapFilltypeOverlaysDirectory = mapCustomDirectory
    --if fmcFilltypes.mapFilltypeOverlaysDirectory ~= nil and not Utils.endsWith(fmcFilltypes.mapFilltypeOverlaysDirectory, "/") then
    --    fmcFilltypes.mapFilltypeOverlaysDirectory = fmcFilltypes.mapFilltypeOverlaysDirectory .. "/"
    --end

    fmcFilltypes.setupFillTypes()
end

--
function fmcFilltypes.teardown()
end

--
function fmcFilltypes.getFilltypeIcon(fillname, useSmall)
    local searchPaths = {
        --fmcFilltypes.mapFilltypeOverlaysDirectory,               -- Map's customized folder, if so instructed.
        fmcFilltypes.mapBaseDirectory .. "fruitHuds/",          -- Map's base folder, and same folder as zzz_multiFruit.zip
        fmcFilltypes.modDir .. "filltypeOverlays/",             -- Use SoilMod's own HUD overlay icons, as a last resort.
    }
    local filenames = {}
    if useSmall then
        table.insert(filenames, "hud_fruit_"..fillname.."_small.dds")
        table.insert(filenames, "hud_spray_"..fillname.."_small.dds")
        table.insert(filenames, "hud_fill_" ..fillname.."_small.dds")
        table.insert(filenames,               fillname.."_small.dds")
    end
    table.insert(filenames, "hud_fruit_"..fillname..".dds")
    table.insert(filenames, "hud_spray_"..fillname..".dds")
    table.insert(filenames, "hud_fill_" ..fillname..".dds")
    table.insert(filenames,               fillname..".dds")

    for _,searchPath in pairs(searchPaths) do
        if searchPath ~= nil then
            for _,filename in pairs(filenames) do
                if filename ~= nil then
                    local pathAndFilename = Utils.getFilename(filename, searchPath)
                    if fileExists(pathAndFilename) then
                        log("Found icon-file; ",pathAndFilename)
                        return pathAndFilename
                    end
                end
            end
        end
    end
    
    logInfo("Failed to find icon-file for; ",fillname)
    return nil
end

--function fmcFilltypes.i18nText(textName)
--    if fmcFilltypes.i18n ~= nil and fmcFilltypes.i18n:hasText(textName) then
--        log("gI18N: generic-name: '",textName,"', custom-I18N: '",fmcFilltypes.i18n:getText(textName),"'")
--        return fmcFilltypes.i18n:getText(textName)
--    elseif g_i18n:hasText(textName) then
--        return g_i18n:getText(textName)
--    end
--    return textName
--end

--
function fmcFilltypes.setupFillTypes()
    logInfo("Registering new spray-types")

    -- Update the internationalized name for vanilla fill-type fertilizer.
    Fillable.fillTypeIndexToDesc[Fillable.FILLTYPE_FERTILIZER].nameI18N = fmcSoilMod.i18nText("fertilizer")

    -- Register some new spray types
    -- price-per-liter (ppl), liters-per-sqm-per-second (lpsps), part-of-economy (poe), mass-per-liter (mpl)
    local soilModSprayTypes = {
        { fillname="fertilizer2", ppl=0.3, lpsps=0.90, poe=false, mpl=0.0004 },
        { fillname="fertilizer3", ppl=0.5, lpsps=1.10, poe=false, mpl=0.0007 },
        { fillname="kalk"       , ppl=0.1, lpsps=1.10, poe=false, mpl=0.0008 },
        { fillname="herbicide"  , ppl=0.5, lpsps=0.95, poe=false, mpl=0.0004 },
        { fillname="herbicide2" , ppl=0.6, lpsps=1.00, poe=false, mpl=0.0005 },
        { fillname="herbicide3" , ppl=0.7, lpsps=1.05, poe=false, mpl=0.0006 },
        { fillname="herbicide4" , ppl=3.5, lpsps=1.55, poe=false, mpl=0.0005 },
        { fillname="herbicide5" , ppl=3.6, lpsps=1.50, poe=false, mpl=0.0006 },
        { fillname="herbicide6" , ppl=3.7, lpsps=1.45, poe=false, mpl=0.0007 },
        { fillname="plantKiller", ppl=7.0, lpsps=1.50, poe=false, mpl=0.0006 },
    }

    for _,st in pairs(soilModSprayTypes) do
        Sprayer.registerSprayType(
            st.fillname,                                    -- <name>
            fmcSoilMod.i18nText(st.fillname),               -- <nameI18N>
            st.ppl,                                         -- <pricePerLiter>
            st.lpsps,                                       -- <litersPerSqmPerSecond>
            st.poe,                                         -- <partOfEconomy>
            fmcFilltypes.getFilltypeIcon(st.fillname),      -- <hudOverlayFilename>
            fmcFilltypes.getFilltypeIcon(st.fillname,true), -- <hudOverlayFilenameSmall>
            st.mpl                                          -- <massPerLiter>
        )
    end
end

function fmcFilltypes.addMoreFillTypeOverlayIcons()
    logInfo("Adding/replacing overlay-icons for specific fill-types")

    -- Set overlay icons for fill types, if they do not already have one
    local function addFillTypeHudOverlayIcon(fillType, overlayFilename, overlayFilenameSmall, force)
        if fillType ~= nil and Fillable.fillTypeIndexToDesc[fillType] ~= nil then
            if force or Fillable.fillTypeIndexToDesc[fillType].hudOverlayFilename == nil then
                Fillable.fillTypeIndexToDesc[fillType].hudOverlayFilename       = overlayFilename;
                Fillable.fillTypeIndexToDesc[fillType].hudOverlayFilenameSmall  = overlayFilenameSmall;
            end
            if force and g_currentMission.fillTypeOverlays[fillType] ~= nil then
                -- Remove filltype overlay icon, so it can be correctly updated later.
                g_currentMission.fillTypeOverlays[fillType]:delete();
                g_currentMission.fillTypeOverlays[fillType] = nil;
            end
        end
    end

    addFillTypeHudOverlayIcon(Fillable.FILLTYPE_FERTILIZER  , fmcFilltypes.getFilltypeIcon("fertilizer"), fmcFilltypes.getFilltypeIcon("fertilizer",true), true );
    addFillTypeHudOverlayIcon(Fillable.FILLTYPE_KALK        , fmcFilltypes.getFilltypeIcon("kalk"      ), fmcFilltypes.getFilltypeIcon("kalk"      ,true), false);
end

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
