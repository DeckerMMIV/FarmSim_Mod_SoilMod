--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-03-xx
--

--
function soilmod:loadFillPlaneMaterials(mapSelf)
    if soilmod.disabledLoadingMaterials == true then
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
                    if fileExists(self.mapBaseDirectory .. pathAndFilename) then
                        found = true
                        logInfo("Loading: ",pathAndFilename)
                        if i>1 then
                            logInfo("NOTE! For customized fill-plane materials, copy 'fruitMaterials/*' into your own map!")
                        end
                        mapSelf:loadI3D(pathAndFilename);
                        return;
                    end
                end
            end
        end
    end
end

--
function soilmod:getFilltypeIcon(fillname, useSmall)
    local folder = "fruitHuds/"
    local searchPaths = {
        self.mapBaseDirectory,                          -- First look in map-mod's fruitHuds folder - same folder as zzz_multiFruit.zip
        self.modDir .. "Requirements_for_your_MapI3D/", -- If not found in map-mod's fruitHuds folder, then fall-back to using SoilMod.
        "dataS2/menu/hud/fillTypes/",                   -- else examine base-game's data directory
    }
    local filenames = {}
    if useSmall then
        table.insert(filenames, folder .. "hud_fruit_" .. fillname .. "_sml")
        table.insert(filenames, folder .. "hud_spray_" .. fillname .. "_sml")
        table.insert(filenames, folder .. "hud_fill_"  .. fillname .. "_sml")
        table.insert(filenames,           "hud_fill_"  .. fillname .. "_sml") -- base-game
        table.insert(filenames, folder ..                 fillname .. "_sml")
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
    table.insert(filenames, folder .. "hud_fruit_" .. fillname)
    table.insert(filenames, folder .. "hud_spray_" .. fillname)
    table.insert(filenames, folder .. "hud_fill_"  .. fillname)
    table.insert(filenames,           "hud_fill_"  .. fillname) -- base-game
    table.insert(filenames, folder ..                 fillname)

    for i,searchPath in pairs(searchPaths) do
        if searchPath ~= nil then
            for j,filename in pairs(filenames) do
                if filename ~= nil then
                    for _,fileExt in pairs({".dds",".png"}) do
                        filename = filename .. fileExt
                        local pathAndFilename = Utils.getFilename(filename, searchPath)
                        if fileExists(pathAndFilename) then
                            filename = useSmall~=j and log("Found icon-file; ",pathAndFilename)
                            return pathAndFilename
                        end
                    end
                end
            end
        end
    end
    
    logInfo("Failed to find icon-file for; ",fillname)
    return nil
end

local fruitWeightScale = 0.5 
-- price-per-liter (ppl), liters-per-sqm (lps), part-of-economy (poe), mass-per-liter (mpl)
soilmod.soilModSprayTypes = {
    { fillname="kalk"                        , ppl=0.1, lps=0.0110, poe=false, mpl= 800 * 0.000001 * fruitWeightScale, categories={"bulk"  ,"spreader","augerWagon" } },
  --{ fillname="fertilizer"                  , ppl=0.3, lps=0.0090, poe=false, mpl= 400 * 0.000001 * fruitWeightScale, categories={"bulk"  ,"spreader","augerWagon" } },
    { fillname="fertilizer2"                 , ppl=0.5, lps=0.0110, poe=false, mpl= 700 * 0.000001 * fruitWeightScale, categories={"bulk"  ,"spreader","augerWagon" } },
    { fillname="fertilizer3"                 , ppl=0.5, lps=0.0110, poe=false, mpl= 700 * 0.000001 * fruitWeightScale, categories={"bulk"  ,"spreader","augerWagon" } },
  --{ fillname="liquidFertilizer"            , ppl=0.3, lps=0.0090, poe=false, mpl= 400 * 0.000001 * fruitWeightScale, categories={"liquid","sprayer" } },
    { fillname="liquidFertilizer2"           , ppl=0.3, lps=0.0090, poe=false, mpl= 400 * 0.000001 * fruitWeightScale, categories={"liquid","sprayer" } },
    { fillname="liquidFertilizer3"           , ppl=0.5, lps=0.0110, poe=false, mpl= 700 * 0.000001 * fruitWeightScale, categories={"liquid","sprayer" } },
    { fillname="herbicide"                   , ppl=1.5, lps=0.0095, poe=false, mpl= 400 * 0.000001 * fruitWeightScale, categories={"liquid","sprayer" } },
    { fillname="herbicide2"                  , ppl=1.6, lps=0.0100, poe=false, mpl= 500 * 0.000001 * fruitWeightScale, categories={"liquid","sprayer" } },
    { fillname="herbicide3"                  , ppl=1.7, lps=0.0105, poe=false, mpl= 600 * 0.000001 * fruitWeightScale, categories={"liquid","sprayer" } },
    { fillname="plantKiller"                 , ppl=7.0, lps=0.0150, poe=false, mpl= 600 * 0.000001 * fruitWeightScale, categories={"liquid","sprayer" } },
    { fillname="water"           , base=true , ppl=0.1, lps=0.0080, poe=false, mpl=1000 * 0.000001 * fruitWeightScale, categories={"liquid","sprayer" } },
    { fillname="water2"                      , ppl=0.1, lps=0.0080, poe=false, mpl=1000 * 0.000001 * fruitWeightScale, categories={"liquid","sprayer" } },
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
function soilmod:preSetupFillTypes()
    logInfo("Registering fill-types")
    
    -- Register fill-types
    for _,st in pairs(self.soilModSprayTypes) do
        local fillDesc = FillUtil.fillTypeNameToDesc[st.fillname];
        if st.base and fillDesc ~= nil then
            -- Do nothing
        elseif fillDesc ~= nil then
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
                self:i18nText(st.fillname),         -- <nameI18N>
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
function soilmod:setupFillTypes(mapSelf)
    logInfo("Registering spray-types")

    self.mapBaseDirectory = mapSelf.baseDirectory
    
    -- Update the internationalized name for vanilla fill-type fertilizer.
    FillUtil.fillTypeIndexToDesc[FillUtil.FILLTYPE_FERTILIZER].nameI18N = self:i18nText("fertilizer")

    -- Register some new spray types
    for _,st in pairs(self.soilModSprayTypes) do
        local spryDesc = Sprayer.sprayTypes[st.fillname]
        local fillDesc = FillUtil.fillTypeNameToDesc[st.fillname];
        if spryDesc ~= nil then
            local diffTxt = nil
            diffTxt = UpdateElem(diffTxt, spryDesc, "litersPerSecond", st, "lps")
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
                st.fillname,                            -- <name>
                self:i18nText(st.fillname),             -- <nameI18N>
                mainCategoryIndex,                      -- <category>
                st.ppl,                                 -- <pricePerLiter>
                st.lps,                                 -- <litersPerSecond>
                st.poe,                                 -- <showOnPriceTable>
                self:getFilltypeIcon(st.fillname),      -- <hudOverlayFilename>
                self:getFilltypeIcon(st.fillname,true), -- <hudOverlayFilenameSmall>
                st.mpl                                  -- <massPerLiter>
            )
        end
    end
end

function soilmod:postSetupFillTypes()
    logInfo("Verifying that SoilMod's custom spray-/fill-types are available for use.")
    
    local allOk = true
    for _,st in pairs(self.soilModSprayTypes) do
        local typename = string.upper(st.fillname)
        local sprayName = "SPRAYTYPE_"..typename
        local fillName  = "FILLTYPE_"..typename
        if Sprayer[sprayName] == nil or FillUtil[fillName] == nil then
            allOk = false
            logInfo("ERROR! Failed to register spray-/fill-type '",st.fillname,"', which SoilMod depends on.")
        end
    end
    if not allOk or soilmod.logVerbose then
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
function soilmod:addMoreFillTypeOverlayIcons()
    logInfo("Adding/replacing overlay-icons for specific fill-types")

    local uiScale = g_gameSettings:getValue("uiScale")
    local levelIconWidth, levelIconHeight = getNormalizedScreenValues(20*uiScale, 20*uiScale)
    
    -- Set overlay icons for fill types, if they do not already have one
    local function addFillTypeHudOverlayIcon(fillType, overlayFilename, overlayFilenameSmall, force)
        if fillType ~= nil and overlayFilename ~= nil and FillUtil.fillTypeIndexToDesc[fillType] ~= nil then
            local fillTypeDesc = FillUtil.fillTypeIndexToDesc[fillType]
            if force or fillTypeDesc.hudOverlayFilename == nil then
                fillTypeDesc.hudOverlayFilename       = overlayFilename;
                fillTypeDesc.hudOverlayFilenameSmall  = overlayFilenameSmall;
            end
            if force or g_currentMission.fillTypeOverlays[fillType] == nil then
                if g_currentMission.fillTypeOverlays[fillType] ~= nil then
                    g_currentMission.fillTypeOverlays[fillType]:delete();
                    g_currentMission.fillTypeOverlays[fillType] = nil
                end
                g_currentMission:addFillTypeOverlay(fillTypeDesc.index, fillTypeDesc.hudOverlayFilenameSmall, levelIconWidth, levelIconHeight);
            end
        end
    end

    addFillTypeHudOverlayIcon(FillUtil.FILLTYPE_FERTILIZER       ,self:getFilltypeIcon("fertilizer")       ,self:getFilltypeIcon("fertilizer"      ,true) ,true );
    addFillTypeHudOverlayIcon(FillUtil.FILLTYPE_LIQUIDFERTILIZER ,self:getFilltypeIcon("liquidFertilizer") ,self:getFilltypeIcon("liquidFertilizer",true) ,true );

    for _,st in pairs(self.soilModSprayTypes) do
        if st.base ~= true then
            local key = "FILLTYPE_"..string.upper(st.fillname);
            addFillTypeHudOverlayIcon(FillUtil[key], self:getFilltypeIcon(st.fillname), self:getFilltypeIcon(st.fillname,true), false);
        end
    end
end

--
function soilmod:updateFillTypeOverlays()
    logInfo("Updating fill-types HUD overlay-icons")
    for _,fillTypeDesc in pairs(FillUtil.fillTypeIndexToDesc) do
        if g_currentMission.fillTypeOverlays[fillTypeDesc.index] == nil and fillTypeDesc.hudOverlayFilename ~= nil and fillTypeDesc.hudOverlayFilename ~= "" then
            g_currentMission:addFillTypeOverlay(fillTypeDesc.index, fillTypeDesc.hudOverlayFilename)
        end
    end
end
