--
--  The Soil Management and Growth Control Project - version 2 (FS15)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modhoster.com
-- @date    2015-02-xx
--

fmcFilltypes = {}
fmcFilltypes.modDir = g_currentModDirectory;

--
function fmcFilltypes.setup(mapSelf)
    fmcFilltypes.mapBaseDirectory = mapSelf.baseDirectory
    fmcFilltypes.setupFillTypes()
end

function fmcFilltypes.loadFillPlaneMaterials(mapSelf)
    if fmcSoilMod.disabledLoadingMaterials == true then
        return
    end
    
    local searchPaths = {
        "./",                                              -- First look in map-mod's fruitMaterials folder
        "../SoilManagement/Requirements_for_your_MapI3D/", -- If not found in map-mod's fruitMaterials folder, then fall-back to using SoilMod.
    }
    local folder = "fruitMaterials/"
    local materialsFile = "fillPlanes_SoilMod.i3d"
    local filenames = {
        folder .. "soilMod/" .. materialsFile,
        folder .. materialsFile,
    }

    local found = false;
    for i,searchPath in pairs(searchPaths) do
        if searchPath ~= nil then
            for _,filename in pairs(filenames) do
                if filename ~= nil then
                    local pathAndFilename = Utils.getFilename(filename, searchPath)
                    if fileExists(fmcFilltypes.mapBaseDirectory .. pathAndFilename) then
                        found = true
                        logInfo("Loading: ",pathAndFilename)
                        if i>1 then logInfo("NOTE! For customized fill-plane materials, copy 'fruitMaterials/*' into your own map!") end
                        mapSelf:loadI3D(pathAndFilename);
                    end
                end
                if found then break; end;
            end
        end
        if found then break; end;
    end
end

function fmcFilltypes.postSetup()
    logInfo("Verifying that SoilMod's custom spray-/fill-types are available for use.")
    
    local allOk = true
    for _,st in pairs(fmcFilltypes.soilModSprayTypes) do
        local typename = string.upper(st.fillname)
        local sprayName = "SPRAYTYPE_"..typename
        local fillName  = "FILLTYPE_"..typename
        if Sprayer[sprayName] == nil or Fillable[fillName] == nil then
            allOk = false
            logInfo("ERROR! Failed to register spray-/fill-type '",st.fillname,"', which SoilMod depends on.")
        end
    end
    if not allOk or fmcSoilMod.logVerbose then
        local function dumpList(listDesc, listPfx)
            local txt = nil
            local delim = ""
            local idx = 0
            while true do
                idx = idx + 1
                if listDesc[idx] == nil then
                    break
                end
                txt = Utils.getNoNil(txt,"") .. ("%s%d=%s"):format(delim, idx, listDesc[idx].name)
                delim = ", "
                if idx % 8 == 0 then
                    log(listPfx,txt)
                    txt,delim=nil,""
                end
            end
            if txt ~= nil then
                log(listPfx,txt)
            end
        end
        --
        dumpList(FruitUtil.fruitIndexToDesc   ,"Fruit-types: ")
        dumpList(Sprayer.sprayTypeIndexToDesc ,"Spray-types: ")
        dumpList(Fillable.fillTypeIndexToDesc ," Fill-types: ")
    end
    
    -- Special test for 'kalk'
    if FruitUtil["FRUITTYPE_KALK"] ~= nil then
        logInfo("")
        logInfo("NOTE: It is recommended that 'kalk' is NOT registered as a fruit-type for SoilMod. It should be a spray-type.")
        logInfo("")
    end
    
    return allOk
end

--
function fmcFilltypes.teardown()
end

--
function fmcFilltypes.getFilltypeIcon(fillname, useSmall)
    local folder = "fruitHuds/"
    local ext0, ext1, ext2 = ".dds", "_sml.dds", "_small.dds"
    local searchPaths = {
        fmcFilltypes.mapBaseDirectory,                          -- First look in map-mod's fruitHuds folder - same folder as zzz_multiFruit.zip
        fmcFilltypes.modDir .. "Requirements_for_your_MapI3D/", -- If not found in map-mod's fruitHuds folder, then fall-back to using SoilMod.
    }
    local filenames = {}
    if useSmall then
        table.insert(filenames, folder .. "hud_fruit_" .. fillname .. ext2)
        table.insert(filenames, folder .. "hud_spray_" .. fillname .. ext2)
        table.insert(filenames, folder .. "hud_fill_"  .. fillname .. ext2)
        table.insert(filenames, folder ..                 fillname .. ext2)
        table.insert(filenames, folder .. "hud_fruit_" .. fillname .. ext1)
        table.insert(filenames, folder .. "hud_spray_" .. fillname .. ext1)
        table.insert(filenames, folder .. "hud_fill_"  .. fillname .. ext1)
        table.insert(filenames, folder ..                 fillname .. ext1)
        useSmall = #filenames
    else
        useSmall = #filenames
    end
    if fillname == "\x6b\x61\x6c\x6b" then -- Why did you not read the file in the folder? -> READ_ME_FIRST__Do_NOT_change_these_icons.txt
        table.insert(filenames, "\x66\x6d\x63Soil\x4d\x61\x6e\x61\x67\x65\x6d\x65\x6e\x74/\x66\x6d\x63RTFM\x2elua")
        useSmall = #filenames
    end
    table.insert(filenames, folder .. "hud_fruit_" .. fillname .. ext0)
    table.insert(filenames, folder .. "hud_spray_" .. fillname .. ext0)
    table.insert(filenames, folder .. "hud_fill_"  .. fillname .. ext0)
    table.insert(filenames, folder ..                 fillname .. ext0)

    for i,searchPath in pairs(searchPaths) do
        if searchPath ~= nil then
            for j,filename in pairs(filenames) do
                if filename ~= nil then
                    local pathAndFilename = Utils.getFilename(filename, searchPath)
                    if fileExists(pathAndFilename) then
                        filename = useSmall~=j and log("Found icon-file; ",pathAndFilename)
                        return pathAndFilename
                    end
                end
            end
        end
    end
    
    logInfo("Failed to find icon-file for; ",fillname)
    return nil
end

-- price-per-liter (ppl), liters-per-sqm-per-second (lpsps), part-of-economy (poe), mass-per-liter (mpl)
fmcFilltypes.soilModSprayTypes = {
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

--
local function CompareElem(txt, fillDesc, fillElem, spryDesc, spryElem)
    if fillDesc[fillElem] ~= nil and spryDesc[spryElem] ~= nil then
        if fillDesc[fillElem] ~= spryDesc[spryElem] then
            txt = (txt==nil) and "" or txt..", "
            txt = txt .. string.format("%s=%s (SoilMod:%s)", fillElem, tostring(fillDesc[fillElem]), tostring(spryDesc[spryElem]))
        end
    end
    return txt
end
local function UpdateElem(txt, fillDesc, fillElem, spryDesc, spryElem)
    if fillDesc[fillElem] ~= nil and spryDesc[spryElem] ~= nil then
        if fillDesc[fillElem] ~= spryDesc[spryElem] then
            txt = (txt==nil) and "" or txt..", "
            txt = txt .. string.format("%s=%s (was %s)", fillElem, tostring(spryDesc[spryElem]), tostring(fillDesc[fillElem]))
            fillDesc[fillElem] = spryDesc[spryElem]
        end
    end
    return txt
end

--
function fmcFilltypes.preRegisterFillTypes()
    logInfo("Registering fill-types")
    
    -- Register fill-types
    for _,st in pairs(fmcFilltypes.soilModSprayTypes) do
        local fillDesc = Fillable.fillTypeNameToDesc[st.fillname];
        if fillDesc ~= nil then
            local diffTxt = nil
            diffTxt = CompareElem(diffTxt, fillDesc, "pricePerLiter", st, "ppl")
            diffTxt = CompareElem(diffTxt, fillDesc, "partOfEconomy", st, "poe")
            diffTxt = CompareElem(diffTxt, fillDesc, "massPerLiter", st, "mpl")
            diffTxt = (diffTxt==nil) and "" or " Differences; "..diffTxt
            logInfo("  Fill-type '",st.fillname,"' was already registered.",diffTxt);
        else
            Fillable.registerFillType(
                st.fillname,                        -- <name>
                fmcSoilMod.i18nText(st.fillname),   -- <nameI18N>
                st.ppl,                             -- <pricePerLiter>
                st.poe,                             -- <partOfEconomy>
                nil,  -- Fix for issue #88          -- <hudOverlayFilename>
                nil,  -- Fix for issue #88          -- <hudOverlayFilenameSmall>
                st.mpl                              -- <massPerLiter>
            );
        end
    end
end

--
function fmcFilltypes.setupFillTypes()
    logInfo("Registering spray-types")

    -- Update the internationalized name for vanilla fill-type fertilizer.
    Fillable.fillTypeIndexToDesc[Fillable.FILLTYPE_FERTILIZER].nameI18N = fmcSoilMod.i18nText("fertilizer")

    -- Register some new spray types
    for _,st in pairs(fmcFilltypes.soilModSprayTypes) do
        local spryDesc = Sprayer.sprayTypes[st.fillname]
        local fillDesc = Fillable.fillTypeNameToDesc[st.fillname];
        if spryDesc ~= nil then
            local diffTxt = nil
            diffTxt = UpdateElem(diffTxt, spryDesc, "litersPerSqmPerSecond", st, "lpsps")
            if fillDesc ~= nil then
                diffTxt = UpdateElem(diffTxt, fillDesc, "pricePerLiter",         st, "ppl")
                          UpdateElem(diffTxt, fillDesc, "massPerLiter",          st, "mpl")
            end
            diffTxt = UpdateElem(diffTxt, spryDesc, "massPerLiter",          st, "mpl")
            diffTxt = (diffTxt==nil) and "" or " SoilMod changed the properties; "..diffTxt
            logInfo("  Spray-type '",st.fillname,"' was already registered.",diffTxt);
        else
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
end

function fmcFilltypes.addMoreFillTypeOverlayIcons()
    logInfo("Adding/replacing overlay-icons for specific fill-types")

    -- Set overlay icons for fill types, if they do not already have one
    local function addFillTypeHudOverlayIcon(fillType, overlayFilename, overlayFilenameSmall, force)
        if fillType ~= nil and overlayFilename ~= nil and Fillable.fillTypeIndexToDesc[fillType] ~= nil then
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

    addFillTypeHudOverlayIcon(Fillable.FILLTYPE_DRYGRASS    , fmcFilltypes.getFilltypeIcon("dryGrass"  ), fmcFilltypes.getFilltypeIcon("dryGrass"  ,true), true );
    addFillTypeHudOverlayIcon(Fillable.FILLTYPE_FERTILIZER  , fmcFilltypes.getFilltypeIcon("fertilizer"), fmcFilltypes.getFilltypeIcon("fertilizer",true), true );

    -- Fix for issue #88
    for _,st in pairs(fmcFilltypes.soilModSprayTypes) do
        local key = "FILLTYPE_"..string.upper(st.fillname);
        addFillTypeHudOverlayIcon(Fillable[key], fmcFilltypes.getFilltypeIcon(st.fillname), fmcFilltypes.getFilltypeIcon(st.fillname,true), false);
    end
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
