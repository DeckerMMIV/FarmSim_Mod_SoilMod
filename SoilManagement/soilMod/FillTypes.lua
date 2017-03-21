--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-01-xx
--

sm3Filltypes = {}
sm3Filltypes.modDir = g_currentModDirectory;

--
function sm3Filltypes.setup(mapSelf)
    sm3Filltypes.mapBaseDirectory = mapSelf.baseDirectory
    sm3Filltypes.setupFillTypes()
end

function sm3Filltypes.teardown()
end

--
function sm3Filltypes.loadFillPlaneMaterials(mapSelf)
    if sm3SoilMod.disabledLoadingMaterials == true then
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

    for i,searchPath in pairs(searchPaths) do
        if searchPath ~= nil then
            for _,filename in pairs(filenames) do
                if filename ~= nil then
                    local pathAndFilename = Utils.getFilename(filename, searchPath)
                    if fileExists(sm3Filltypes.mapBaseDirectory .. pathAndFilename) then
                        found = true
                        logInfo("Loading: ",pathAndFilename)
                        if i>1 then logInfo("NOTE! For customized fill-plane materials, copy 'fruitMaterials/*' into your own map!") end
                        mapSelf:loadI3D(pathAndFilename);
                        return;
                    end
                end
            end
        end
    end
end


--
function sm3Filltypes.getFilltypeIcon(fillname, useSmall)
    local folder = "fruitHuds/"
    local ext0, ext1, ext2 = ".dds", "_sml.dds", "_small.dds"
    local searchPaths = {
        sm3Filltypes.mapBaseDirectory,                          -- First look in map-mod's fruitHuds folder - same folder as zzz_multiFruit.zip
        sm3Filltypes.modDir .. "Requirements_for_your_MapI3D/", -- If not found in map-mod's fruitHuds folder, then fall-back to using SoilMod.
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
--[[    
    if fillname == "\x6b\x61\x6c\x6b" then -- Why did you not read the file in the folder? -> READ_ME_FIRST__Do_NOT_change_these_icons.txt
        table.insert(filenames, "\x66\x6d\x63Soil\x4d\x61\x6e\x61\x67\x65\x6d\x65\x6e\x74/\x66\x6d\x63RTFM\x2elua")
        useSmall = #filenames
    end
--]]    
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
sm3Filltypes.soilModSprayTypes = {
  --{ fillname="liquidfertilizer", ppl=0.3, lpsps=0.90, poe=false, mpl=0.0004, categories={"liquid","sprayer" } },
    { fillname="fertilizer2"     , ppl=0.3, lpsps=0.90, poe=false, mpl=0.0004, categories={"liquid","sprayer" } },
    { fillname="fertilizer3"     , ppl=0.5, lpsps=1.10, poe=false, mpl=0.0007, categories={"liquid","sprayer" } },
  --{ fillname="fertilizer"      , ppl=0.3, lpsps=0.90, poe=false, mpl=0.0004, categories={"bulk"  ,"spreader","augerWagon" } },
    { fillname="fertilizer4"     , ppl=0.5, lpsps=1.10, poe=false, mpl=0.0007, categories={"bulk"  ,"spreader","augerWagon" } },
    { fillname="fertilizer5"     , ppl=0.5, lpsps=1.10, poe=false, mpl=0.0007, categories={"bulk"  ,"spreader","augerWagon" } },
    { fillname="fertilizer6"     , ppl=0.5, lpsps=1.10, poe=false, mpl=0.0007, categories={"bulk"  ,"spreader","augerWagon" } },
    { fillname="kalk"            , ppl=0.1, lpsps=1.10, poe=false, mpl=0.0008, categories={"bulk"  ,"spreader","augerWagon" } },
    { fillname="herbicide"       , ppl=0.5, lpsps=0.95, poe=false, mpl=0.0004, categories={"liquid","sprayer" } },
    { fillname="herbicide2"      , ppl=0.6, lpsps=1.00, poe=false, mpl=0.0005, categories={"liquid","sprayer" } },
    { fillname="herbicide3"      , ppl=0.7, lpsps=1.05, poe=false, mpl=0.0006, categories={"liquid","sprayer" } },
    { fillname="herbicide4"      , ppl=3.5, lpsps=1.55, poe=false, mpl=0.0005, categories={"liquid","sprayer" } },
    { fillname="herbicide5"      , ppl=3.6, lpsps=1.50, poe=false, mpl=0.0006, categories={"liquid","sprayer" } },
    { fillname="herbicide6"      , ppl=3.7, lpsps=1.45, poe=false, mpl=0.0007, categories={"liquid","sprayer" } },
    { fillname="plantKiller"     , ppl=7.0, lpsps=1.50, poe=false, mpl=0.0006, categories={"liquid","sprayer" } },
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
function sm3Filltypes.preSetupFillTypes()
    logInfo("Registering fill-types")
    
    -- Register fill-types
    for _,st in pairs(sm3Filltypes.soilModSprayTypes) do
        local fillDesc = FillUtil.fillTypeNameToDesc[st.fillname];
        if fillDesc ~= nil then
            local diffTxt = nil
            diffTxt = CompareElem(diffTxt, fillDesc, "pricePerLiter", st, "ppl")
            diffTxt = CompareElem(diffTxt, fillDesc, "partOfEconomy", st, "poe")
            diffTxt = CompareElem(diffTxt, fillDesc, "massPerLiter", st, "mpl")
            diffTxt = (diffTxt==nil) and "" or " Differences; "..diffTxt
            logInfo("  Fill-type '",st.fillname,"' was already registered.",diffTxt);
        else
            local mainCategoryIndex = FillUtil.fillTypeCategoryNameToInt[st.categories[1]]
            FillUtil.registerFillType(
                st.fillname,                        -- <name>
                sm3SoilMod.i18nText(st.fillname),   -- <nameI18N>
                mainCategoryIndex,                  -- <category>
                st.ppl,                             -- <pricePerLiter>
                st.poe,                             -- <showOnPriceTable>
                nil,                                -- <hudOverlayFilename>
                nil,                                -- <hudOverlayFilenameSmall>
                st.mpl,                             -- <massPerLiter>
                nil                                 -- <maxPhysicalSurfaceAngle>
            );
        end
    end
end

--
function sm3Filltypes.setupFillTypes()
    logInfo("Registering spray-types")

    -- Update the internationalized name for vanilla fill-type fertilizer.
    FillUtil.fillTypeIndexToDesc[FillUtil.FILLTYPE_FERTILIZER].nameI18N = sm3SoilMod.i18nText("fertilizer")

    -- Register some new spray types
    for _,st in pairs(sm3Filltypes.soilModSprayTypes) do
        local spryDesc = Sprayer.sprayTypes[st.fillname]
        local fillDesc = FillUtil.fillTypeNameToDesc[st.fillname];
        if spryDesc ~= nil then
            local diffTxt = nil
            diffTxt = UpdateElem(diffTxt, spryDesc, "litersPerSqmPerSecond", st, "lpsps")
            if fillDesc ~= nil then
                diffTxt = UpdateElem(diffTxt, fillDesc, "pricePerLiter", st, "ppl")
                diffTxt = UpdateElem(diffTxt, fillDesc, "massPerLiter",  st, "mpl")
            end
            diffTxt = UpdateElem(diffTxt, spryDesc, "massPerLiter", st, "mpl")
            
            diffTxt = (diffTxt==nil) and "" or " SoilMod changed the properties; "..diffTxt
            logInfo("  Spray-type '",st.fillname,"' was already registered.",diffTxt);
        else
            local mainCategoryIndex = FillUtil.fillTypeCategoryNameToInt[st.categories[1]]
            Sprayer.registerSprayType(
                st.fillname,                                    -- <name>
                sm3SoilMod.i18nText(st.fillname),               -- <nameI18N>
                mainCategoryIndex,                              -- <category>
                st.ppl,                                         -- <pricePerLiter>
                st.lpsps,                                       -- <litersPerSqmPerSecond>
                st.poe,                                         -- <showOnPriceTable>
                sm3Filltypes.getFilltypeIcon(st.fillname),      -- <hudOverlayFilename>
                sm3Filltypes.getFilltypeIcon(st.fillname,true), -- <hudOverlayFilenameSmall>
                st.mpl                                          -- <massPerLiter>
            )
        end
    end
end

function sm3Filltypes.postSetup()
    logInfo("Verifying that SoilMod's custom spray-/fill-types are available for use.")
    
    local allOk = true
    for _,st in pairs(sm3Filltypes.soilModSprayTypes) do
        local typename = string.upper(st.fillname)
        local sprayName = "SPRAYTYPE_"..typename
        local fillName  = "FILLTYPE_"..typename
        if Sprayer[sprayName] == nil or FillUtil[fillName] == nil then
            allOk = false
            logInfo("ERROR! Failed to register spray-/fill-type '",st.fillname,"', which SoilMod depends on.")
        end
    end
    if not allOk or sm3SoilMod.logVerbose then
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
        dumpList(FillUtil.fillTypeIndexToDesc ," Fill-types: ")
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
function sm3Filltypes.addMoreFillTypeOverlayIcons()
    logInfo("Adding/replacing overlay-icons for specific fill-types")

    -- Set overlay icons for fill types, if they do not already have one
    local function addFillTypeHudOverlayIcon(fillType, overlayFilename, overlayFilenameSmall, force)
        if fillType ~= nil and overlayFilename ~= nil and FillUtil.fillTypeIndexToDesc[fillType] ~= nil then
            if force or FillUtil.fillTypeIndexToDesc[fillType].hudOverlayFilename == nil then
                FillUtil.fillTypeIndexToDesc[fillType].hudOverlayFilename       = overlayFilename;
                FillUtil.fillTypeIndexToDesc[fillType].hudOverlayFilenameSmall  = overlayFilenameSmall;
            end
            if force and g_currentMission.fillTypeOverlays[fillType] ~= nil then
                -- Remove filltype overlay icon, so it can be correctly updated later.
                g_currentMission.fillTypeOverlays[fillType]:delete();
                g_currentMission.fillTypeOverlays[fillType] = nil;
            end
        end
    end

    --addFillTypeHudOverlayIcon(FillUtil.FILLTYPE_DRYGRASS    , sm3Filltypes.getFilltypeIcon("dryGrass"  ), sm3Filltypes.getFilltypeIcon("dryGrass"  ,true), true );
    addFillTypeHudOverlayIcon(FillUtil.FILLTYPE_FERTILIZER  , sm3Filltypes.getFilltypeIcon("fertilizer"), sm3Filltypes.getFilltypeIcon("fertilizer",true), true );

    -- Fix for issue #88
    for _,st in pairs(sm3Filltypes.soilModSprayTypes) do
        local key = "FILLTYPE_"..string.upper(st.fillname);
        addFillTypeHudOverlayIcon(FillUtil[key], sm3Filltypes.getFilltypeIcon(st.fillname), sm3Filltypes.getFilltypeIcon(st.fillname,true), false);
    end
end

--
function sm3Filltypes.updateFillTypeOverlays()
    logInfo("Updating fill-types HUD overlay-icons")
    for _,fillTypeDesc in pairs(FillUtil.fillTypeIndexToDesc) do
        if g_currentMission.fillTypeOverlays[fillTypeDesc.index] == nil and fillTypeDesc.hudOverlayFilename ~= nil and fillTypeDesc.hudOverlayFilename ~= "" then
            g_currentMission:addFillTypeOverlay(fillTypeDesc.index, fillTypeDesc.hudOverlayFilename)
        end
    end
end
