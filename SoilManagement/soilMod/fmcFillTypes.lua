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
function fmcFilltypes.setup(mapBaseDirectory, mapCustomDirectory)
    fmcFilltypes.mapBaseDirectory = mapBaseDirectory

    fmcFilltypes.mapFilltypeOverlaysDirectory = mapCustomDirectory
    if fmcFilltypes.mapFilltypeOverlaysDirectory ~= nil and not Utils.endsWith(fmcFilltypes.mapFilltypeOverlaysDirectory, "/") then
        fmcFilltypes.mapFilltypeOverlaysDirectory = fmcFilltypes.mapFilltypeOverlaysDirectory .. "/"
    end

    fmcFilltypes.setupFillTypes()
end

--
function fmcFilltypes.teardown()
end

--
function fmcFilltypes.getFilltypeIcon(fillname, useSmall)
    local searchPaths = {
        fmcFilltypes.mapFilltypeOverlaysDirectory               -- Map's customized folder, if so instructed.
        ,fmcFilltypes.mapBaseDirectory .. "fruitHuds/"          -- Map's base folder, and same folder as zzz_multiFruit.zip
        ,fmcFilltypes.modDir .. "filltypeOverlays/"             -- Use SoilMod's own HUD overlay icons, as a last resort.
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

--
function fmcFilltypes.setupFillTypes()
    logInfo("Registering new spray-types")

    -- Update the internationalized name for vanilla fill-type fertilizer.
    Fillable.fillTypeIndexToDesc[Fillable.FILLTYPE_FERTILIZER].nameI18N = g_i18n:getText("fertilizer")

    -- Register some new spray types
    -- TODO - Provide some better usage-per-sqm, price-per-liter and mass-per-liter
    local soilModSprayTypes = {
        { fillname="fertilizer2", ppl=0.2, lpsps=10, poe=false, mpl=0.0004 },
        { fillname="fertilizer3", ppl=0.5, lpsps=15, poe=false, mpl=0.0008 },
        { fillname="kalk"       , ppl=0.1, lpsps= 3, poe=false, mpl=0.0010 },
        { fillname="herbicide"  , ppl=0.5, lpsps= 5, poe=false, mpl=0.0004 },
        { fillname="herbicide2" , ppl=0.6, lpsps= 7, poe=false, mpl=0.0006 },
        { fillname="herbicide3" , ppl=0.7, lpsps= 9, poe=false, mpl=0.0008 },
        { fillname="herbicide4" , ppl=1.5, lpsps=19, poe=false, mpl=0.0004 },
        { fillname="herbicide5" , ppl=1.6, lpsps=17, poe=false, mpl=0.0006 },
        { fillname="herbicide6" , ppl=1.7, lpsps=15, poe=false, mpl=0.0008 },
    }
    
    for _,st in pairs(soilModSprayTypes) do
        Sprayer.registerSprayType(
            st.fillname,                                    -- <name>
            g_i18n:hasText(st.fillname) and g_i18n:getText(st.fillname) or st.fillname,     -- <nameI18N>
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
