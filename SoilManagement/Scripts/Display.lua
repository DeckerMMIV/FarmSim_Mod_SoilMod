--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-03-xx
--

soilmod.gridFontSize     = 0.05  -- Now configurable via the 'ModsSettings'-mod.
soilmod.gridFontFactor   = 0.025 -- Now configurable via the 'ModsSettings'-mod.
soilmod.gridSquareSize   = 2     -- Now configurable via the 'ModsSettings'-mod.
soilmod.gridCells        = 10    -- Now configurable via the 'ModsSettings'-mod.
soilmod.debugGraph       = false
soilmod.debugGraphs      = {}

--
local function healthToText(sumPixels,numPixels,totPixels,numChnl)
    local pct = (sumPixels / ((2^numChnl - 1) * numPixels))
    return ("%.0f%%"):format(pct*100), pct
end

local function pHtoText(sumPixels,numPixels,totPixels,numChnl)
    local phValue = soilmod:density_to_pH(sumPixels,numPixels,numChnl)    
    return ("%.1f %s"):format(phValue, g_i18n:getText(soilmod:pH_to_Denomination(phValue))), (sumPixels / ((2^numChnl - 1) * numPixels))
end

local function moistureToText(sumPixels,numPixels,totPixels,numChnl)
    local pct = (sumPixels / ((2^numChnl - 1) * numPixels))
    return ("%.0f%%"):format(pct*100), pct
end

local function nutrientToText(sumPixels,numPixels,totPixels,numChnl)
    local pct = sumPixels / numPixels
    local txt = "-"
    if pct > 0 then
        txt = ("x%.0f"):format(pct)
    end
    return txt, pct
end

local function weedsToText(sumPixels,numPixels,totPixels,numChnl)
    local pct = (sumPixels / ((2^numChnl - 1) * numPixels))
    local txt = "-"
    if pct > 0 then
        txt = ("%.0f%%"):format(pct*100)
    end
    return txt, pct
end

soilmod.herbicideTypesToText = { "-","A","B","C" }
local function herbicideToText(sumPixels,numPixels,totPixels,numChnl)
    local pct = sumPixels / numPixels
    return Utils.getNoNil(soilmod.herbicideTypesToText[math.floor(pct) + 1], "?"), pct
end

local function germinationPreventionToText(sumPixels,numPixels,totPixels,numChnl)
    local pct = sumPixels / numPixels
    local days = math.ceil(pct)
    local txt = "-"
    if days > 0 then
        txt = (g_i18n:getText("GermRemainDays")):format("+"..days)
    end
    return txt, pct
end

--
function soilmod:setupDisplay()
    --
    -- DID YOU KNOW - That if using the 'ModsSettings'-mod, you can easily modify these values in the "modsSettings.XML" file,
    --                which is located in the same folder as the "game.xml" and "inputBinding.xml" files.
    --
    local function setPanelPropertiesFromFontsize(fontSize)
        local uiScale = g_gameSettings:getValue("uiScale")
        local _,startY = getNormalizedScreenValues(1*uiScale, 151*uiScale)
        
        soilmod.fontSize    = fontSize
        soilmod.panelWidth  = soilmod.fontSize * 13   -- TODO
        soilmod.panelHeight = soilmod.fontSize * 8.1  -- TODO
        soilmod.panelPosX   = 1.0 - soilmod.panelWidth
        soilmod.panelPosY   = startY
        soilmod.autoHide    = false
    end
    setPanelPropertiesFromFontsize(0.012)
    
    if ModsSettings == nil then
        logInfo("Optional 'ModsSettings'-mod not found. Using builtin default position-values for info-panel/-grid.")
    else
        local modName = "SoilMod"
        --
        local keyPath = "infoPanel"
        soilmod.fontSize     = ModsSettings.getFloatLocal(modName, keyPath, "fontSize",  soilmod.fontSize);
        -- update the values again, as the fontSize could have been changed in settings.
        setPanelPropertiesFromFontsize(soilmod.fontSize)
        soilmod.panelWidth   = ModsSettings.getFloatLocal(modName, keyPath, "w",        soilmod.panelWidth );
        soilmod.panelHeight  = ModsSettings.getFloatLocal(modName, keyPath, "h",        soilmod.panelHeight);
        soilmod.panelPosX    = ModsSettings.getFloatLocal(modName, keyPath, "x",        soilmod.panelPosX  );
        soilmod.panelPosY    = ModsSettings.getFloatLocal(modName, keyPath, "y",        soilmod.panelPosY  );
        soilmod.autoHide     = ModsSettings.getBoolLocal( modName, keyPath, "autoHide", soilmod.autoHide   );
        --
        keyPath = "infoGrid"
        soilmod.gridFontSize   = ModsSettings.getFloatLocal(modName, keyPath, "fontSize",    soilmod.gridFontSize  );
        soilmod.gridFontFactor = ModsSettings.getFloatLocal(modName, keyPath, "fontFactor",  soilmod.gridFontFactor);
        soilmod.gridSquareSize = ModsSettings.getIntLocal(  modName, keyPath, "cellSize",    soilmod.gridSquareSize);
        soilmod.gridCells      = ModsSettings.getIntLocal(  modName, keyPath, "numCells",    soilmod.gridCells     );
    end

    --
    soilmod.infoRows = {
        { t1=soilmod:i18nText("Health")            , c2=0, t2="" , v1=0, layerId=soilmod:getLayerId("health")        , numChnl=4 , func=healthToText                 }, 
        { t1=soilmod:i18nText("Soil_pH")           , c2=0, t2="" , v1=0, layerId=soilmod:getLayerId("soil_pH")       , numChnl=4 , func=pHtoText                     }, 
        { t1=soilmod:i18nText("Soil_Moisture")     , c2=0, t2="" , v1=0, layerId=soilmod:getLayerId("moisture")      , numChnl=3 , func=moistureToText               }, 
        { t1=soilmod:i18nText("Nutrients_N")       , c2=0, t2="" , v1=0, layerId=soilmod:getLayerId("nutrientN")     , numChnl=4 , func=nutrientToText               }, 
        { t1=soilmod:i18nText("Nutrients_PK")      , c2=0, t2="" , v1=0, layerId=soilmod:getLayerId("nutrientPK")    , numChnl=3 , func=nutrientToText               }, 
        { t1=soilmod:i18nText("WeedsAmount")       , c2=0, t2="" , v1=0, layerId=soilmod:getLayerId("weed")          , numChnl=3 , func=weedsToText                  }, 
        { t1=soilmod:i18nText("HerbicideType")     , c2=0, t2="" , v1=0, layerId=soilmod:getLayerId("herbicide")     , numChnl=2 , func=herbicideToText              }, 
        { t1=soilmod:i18nText("GerminationRemain") , c2=0, t2="" , v1=0, layerId=soilmod:getLayerId("herbicideTime") , numChnl=2 , func=germinationPreventionToText  }, 
    }

    --
    local maxTextWidth = 0
    for _,elem in pairs(soilmod.infoRows) do
        maxTextWidth = math.max(maxTextWidth, getTextWidth(soilmod.fontSize, elem.t1))
    end
    maxTextWidth = maxTextWidth + getTextWidth(soilmod.fontSize, "  ")
    for _,elem in pairs(soilmod.infoRows) do
        elem.c2 = maxTextWidth
    end
    --
    soilmod.infoRows[1].c2 = getTextWidth(soilmod.fontSize, soilmod.infoRows[1].t1 .. "  ")

    -- Solid background
    soilmod.hudBlack = createImageOverlay("dataS2/menu/blank.png");
    setOverlayColor(soilmod.hudBlack, 0,0,0,0.5)

    --
    soilmod.inputNextUpdateTime = 0
    soilmod.inputTime = nil
    soilmod.lines = {}

    soilmod.currentDisplay = 1
    soilmod.gridCurrentLayer = 0
    
--DEBUG
    if g_currentMission:getIsServer() then    
        addConsoleCommand("modSoilModGraph", "", "consoleCommandSoilModGraph", soilmod)
    end
--DEBUG]]

    addConsoleCommand("modSoilModField", "", "consoleCommandSoilModField", soilmod)
end

function soilmod:consoleCommandSoilModField(fieldNo)
    fieldNo = tonumber(fieldNo)
    if fieldNo == nil then
        print("modSoilModField <field#>")
        return
    end
    local fieldDef = g_currentMission.fieldDefinitionBase.fieldDefsByFieldNumber[fieldNo]
    if fieldDef == nil then
        print("Field-number "..fieldNo.." not found (maybe the map has no field-borders defined?)")
        return
    end

    local numFieldBorders = getNumOfChildren(fieldDef.fieldDimensions)
    if numFieldBorders == nil or numFieldBorders <= 0 then
        logInfo("Field #",fieldNo," has no field-borders, so unable to get easy status from it.")
    else
        logInfo("Field #",fieldNo," --------")
        for i = 1, numFieldBorders do
            local p0 = getChildAt(fieldDef.fieldDimensions, i - 1)
            local p1 = getChildAt(p0, 0)
            local p2 = getChildAt(p0, 1)
            local x0, _, z0 = getWorldTranslation(p0)
            local x1, _, z1 = getWorldTranslation(p1)
            local x2, _, z2 = getWorldTranslation(p2)
    
            local sx,sz,wx,wz,hx,hz = Utils.getXZWidthAndHeight(nil, x0,z0, x1,z1, x2,z2);
    
            logInfo(" Field-border ",i,":")
            for _,infoRow in ipairs(soilmod.infoRows) do
                if infoRow.layerId ~= nil and infoRow.layerId ~= 0 then
                    setDensityCompareParams(infoRow.layerId, "greater", -1)
                    local sumPixels,numPixels,totPixels = getDensityParallelogram(infoRow.layerId, sx,sz,wx,wz,hx,hz, 0,infoRow.numChnl)
                    local t2,v1 = infoRow.func(sumPixels,numPixels,totPixels,infoRow.numChnl)
                    --
                    logInfo("  ",infoRow.t1,": ",t2)
                end
            end
        end
    end
end

function soilmod:consoleCommandSoilModGraph(arg1)
    soilmod.debugGraph = not soilmod.debugGraph
    logInfo("modSoilModGraph = ",tostring(soilmod.debugGraph))
end

function soilmod:doShortEvent()
    soilmod.gridCurrentLayer = (soilmod.gridCurrentLayer + 1) % 5
    soilmod.inputNextUpdateTime = g_currentMission.time -- Update at soon as possible.
end

function soilmod:doLongEvent()
    -- todo
    soilmod.currentDisplay = (soilmod.currentDisplay + 1) % 2
end

function soilmod:updateDisplay(dt)

    if soilmod.inputTime == nil then
        if InputBinding.isPressed(InputBinding.SOILMOD_GRIDOVERLAY) then
            soilmod.inputTime = g_currentMission.time
        end
        
        if g_currentMission.time > soilmod.inputNextUpdateTime then
            soilmod.inputNextUpdateTime = g_currentMission.time + 1000
            soilmod:refreshAreaInfo()
        end
    elseif InputBinding.isPressed(InputBinding.SOILMOD_GRIDOVERLAY) then
        local inputDuration = g_currentMission.time - soilmod.inputTime
        if inputDuration > 450 then
            soilmod.drawLongEvent = inputDuration / 1000; -- Start drawing
            if inputDuration > 1000 then
                soilmod.inputTime = g_currentMission.time + (1000*60*60*24) -- Hoping that none would hold input for more than 24hours
                -- Do hasLongEvent action
                soilmod:doLongEvent(InputBinding.SOILMOD_GRIDOVERLAY)
                soilmod.drawLongEvent = nil -- Stop drawing
            end
        end
    else
        local inputDuration = g_currentMission.time - soilmod.inputTime
        soilmod.inputTime = nil
        soilmod.drawLongEvent = nil -- Stop drawing
        if inputDuration > 0 and inputDuration < 500 then
            -- Do hasShortEvent action
            soilmod:doShortEvent(InputBinding.SOILMOD_GRIDOVERLAY)
        end
    end

end

function soilmod:refreshAreaInfo()
    --
    local cx,cz
    if g_currentMission.controlPlayer and g_currentMission.player ~= nil then
        cx,_,cz = getWorldTranslation(g_currentMission.player.rootNode)
    elseif g_currentMission.controlledVehicle ~= nil then
        cx,_,cz = getWorldTranslation(g_currentMission.controlledVehicle.rootNode)
    end

    if cx ~= nil and cx==cx and cz==cz then -- Make extra sure that there actually is an x,z coordinate to use.
        local squareSize = 10
        local widthX,widthZ, heightX,heightZ = squareSize-0.5,0, 0,squareSize-0.5
        local x,z = cx - (squareSize/2), cz - (squareSize/2)
        
        for _,infoRow in ipairs(soilmod.infoRows) do
            if infoRow.layerId ~= nil and infoRow.layerId ~= 0 then
                setDensityCompareParams(infoRow.layerId, "greater", -1)
                local sumPixels,numPixels,totPixels = getDensityParallelogram(infoRow.layerId, x,z, widthX,widthZ, heightX,heightZ, 0,infoRow.numChnl)
                infoRow.t2,infoRow.v1 = infoRow.func(sumPixels,numPixels,totPixels,infoRow.numChnl)
            end
        end
        
        --
        if soilmod.gridColors == nil then
            soilmod.gridColors = {}
            -- soil pH
            soilmod.gridColors[1] = AnimCurve:new(linearInterpolator4)
            soilmod.gridColors[1]:addKeyframe({ x=1.0, y=0.0, z=0.0, w=1.0, time=  0 })
            soilmod.gridColors[1]:addKeyframe({ x=1.0, y=1.0, z=0.0, w=1.0, time= 25 })
            soilmod.gridColors[1]:addKeyframe({ x=0.0, y=1.0, z=0.0, w=1.0, time= 50 })
            soilmod.gridColors[1]:addKeyframe({ x=0.7, y=1.0, z=0.7, w=1.0, time= 75 })
            soilmod.gridColors[1]:addKeyframe({ x=1.0, y=0.0, z=1.0, w=1.0, time=100 })
            -- soil Moisture
            soilmod.gridColors[2] = AnimCurve:new(linearInterpolator4)
            soilmod.gridColors[2]:addKeyframe({ x=1.0, y=0.0, z=0.0, w=0.3, time=  0 })
            soilmod.gridColors[2]:addKeyframe({ x=0.1, y=0.1, z=1.0, w=0.6, time= 25 })
            soilmod.gridColors[2]:addKeyframe({ x=0.2, y=0.2, z=1.0, w=0.9, time= 50 })
          --soilmod.gridColors[2]:addKeyframe({ x=0.2, y=0.2, z=1.0, w=1.0, time= 75 })
            soilmod.gridColors[2]:addKeyframe({ x=0.3, y=0.3, z=1.0, w=1.0, time=100 })
            -- nutrients(N)
            soilmod.gridColors[3] = AnimCurve:new(linearInterpolator4)
            soilmod.gridColors[3]:addKeyframe({ x=1.0, y=0.0, z=0.0, w=0.1, time=  0 })
            soilmod.gridColors[3]:addKeyframe({ x=1.0, y=1.0, z=0.0, w=0.8, time= 25 })
          --soilmod.gridColors[3]:addKeyframe({ x=0.0, y=1.0, z=0.0, w=1.0, time= 50 })
            soilmod.gridColors[3]:addKeyframe({ x=0.0, y=1.0, z=0.0, w=1.0, time= 75 })
            soilmod.gridColors[3]:addKeyframe({ x=0.0, y=1.0, z=0.0, w=1.0, time=100 })
            -- nutrients(PK)
            soilmod.gridColors[4] = AnimCurve:new(linearInterpolator4)
            soilmod.gridColors[4]:addKeyframe({ x=1.0, y=0.0, z=0.0, w=0.1, time=  0 })
            soilmod.gridColors[4]:addKeyframe({ x=1.0, y=1.0, z=0.0, w=0.8, time= 25 })
          --soilmod.gridColors[4]:addKeyframe({ x=0.0, y=1.0, z=0.0, w=1.0, time= 50 })
            soilmod.gridColors[4]:addKeyframe({ x=0.0, y=1.0, z=0.0, w=1.0, time= 75 })
            soilmod.gridColors[4]:addKeyframe({ x=0.0, y=1.0, z=0.0, w=1.0, time=100 })
          ---- herbicide-type
          --soilmod.gridColors[5] = AnimCurve:new(linearInterpolator4)
          --soilmod.gridColors[5]:addKeyframe({ x=0.0, y=0.0, z=0.0, w=0.0, time=  0 })
          --soilmod.gridColors[5]:addKeyframe({ x=1.0, y=1.0, z=0.0, w=0.9, time=100 })
          --soilmod.gridColors[5]:addKeyframe({ x=0.0, y=1.0, z=1.0, w=0.9, time=200 })
          --soilmod.gridColors[5]:addKeyframe({ x=1.0, y=0.0, z=1.0, w=0.9, time=300 })
          
          
            --
            soilmod.gridCurves = {}
            soilmod.gridCurves[1] = soilmod.pHCurve
            soilmod.gridCurves[2] = soilmod.moistureCurve
            soilmod.gridCurves[3] = soilmod.fertNCurve
            soilmod.gridCurves[4] = soilmod.fertPKCurve
        end
        
        soilmod.displayGrid = {}
        if soilmod.gridCurrentLayer > 0 then
            local infoRow = soilmod.infoRows[soilmod.gridCurrentLayer]
            squareSize = math.max(1, math.floor(soilmod.gridSquareSize))
            local halfSquareSize = squareSize/2
            cx,cz = math.floor(cx/squareSize)*squareSize,math.floor(cz/squareSize)*squareSize
            local widthX,widthZ, heightX,heightZ = squareSize-0.5,0, 0,squareSize-0.5
            local gridRadius = squareSize * soilmod.gridCells
            local maxLayerValue = (2^infoRow.numChnl - 1)
            for gx = cx - gridRadius, cx + gridRadius, squareSize do
                local cols={}
                for gz = cz - gridRadius, cz + gridRadius, squareSize do
                    local x,z = gx - halfSquareSize, gz - halfSquareSize
                    setDensityCompareParams(infoRow.layerId, "greater", -1)
                    local sumPixels,numPixels,totPixels = getDensityParallelogram(infoRow.layerId, x,z, widthX,widthZ, heightX,heightZ, 0,infoRow.numChnl)
                    table.insert(cols, {
                        y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, gx, 1, gz) + 0,
                        z = gz,
                        color = { soilmod.gridColors[soilmod.gridCurrentLayer]:get( 100 * (sumPixels / (maxLayerValue * numPixels)) ) },
                        pct = soilmod.gridCurves[soilmod.gridCurrentLayer]:get(sumPixels / totPixels)
                    })
                end
                table.insert(soilmod.displayGrid, {x=gx,cols=cols})
            end
        end
    end
end

function soilmod:drawDisplay()
    if soilmod.autoHide and not g_currentMission.showVehicleInfo then
        -- Do not show the panel
    else
        local alpha = 1.0
        if soilmod.drawLongEvent ~= nil then
            --setTextColor(1,1,1,soilmod.drawLongEvent * 0.1)
            --setTextAlignment(RenderText.ALIGN_CENTER)
            --local fontSize = soilmod.drawLongEvent * 0.15
            --renderText(0.5, 0.5 - fontSize/2, fontSize, "SoilMod")
            
            alpha = (1 - soilmod.drawLongEvent)
        end
    
        if soilmod.currentDisplay == 1 then
            setTextColor(1,1,1,alpha)
            setTextAlignment(RenderText.ALIGN_LEFT)
        
            --
            -- DID YOU KNOW - That if using the 'ModsSettings'-mod, you can easily modify these values in the "modsSettings.XML" file,
            --                which is located in the same folder as the "game.xml" and "inputBinding.xml" files.
            --
            local w,h = soilmod.panelWidth, soilmod.panelHeight 
            local x,y = soilmod.panelPosX,  soilmod.panelPosY   
    
            renderOverlay(soilmod.hudBlack, x,y, w,h);
            
            y = y + h + (soilmod.fontSize * 0.1)
            x = x + soilmod.fontSize * 0.25
            for i,infoRow in ipairs(soilmod.infoRows) do
                setTextBold(i == soilmod.gridCurrentLayer)
                y = y - soilmod.fontSize
                renderText(x,            y, soilmod.fontSize, infoRow.t1)
                renderText(x+infoRow.c2, y, soilmod.fontSize, infoRow.t2)
            end
            setTextBold(false)
        elseif soilmod.currentDisplay == 2 then
            -- todo
        end
    end
    
    --
    if soilmod.gridCurrentLayer > 0 then
        setTextAlignment(RenderText.ALIGN_CENTER)
        for _,row in pairs(soilmod.displayGrid) do
            for _,col in pairs(row.cols) do
                local mx,my,mz = project(row.x,col.y,col.z);
                if  mx<1 and mx>0  -- When "inside" screen
                and my<1 and my>0  -- When "inside" screen
                and          mz<1  -- Only draw when "in front of" camera
                then
                    setTextColor(col.color[1], col.color[2], col.color[3], col.color[4])
                    renderText(mx,my, soilmod.gridFontSize + (col.pct * soilmod.gridFontFactor), ".")
                end
            end
        end
        setTextColor(1,1,1,1)
        setTextAlignment(RenderText.ALIGN_LEFT)
    end
    
--DEBUG
    if soilmod.debugGraph then
        for i,graph in pairs(soilmod.debugGraphs) do
            graph:draw()
            
            local idx = (graph.nextIndex == 1) and graph.numValues or (graph.nextIndex - 1)
            local value = graph.values[idx]
            if value ~= nil then
                local posY = graph.bottom + graph.height / (graph.maxValue - graph.minValue) * (value - graph.minValue)
            
                setTextColor( unpack(soilmod.graphMeta[i].color) )
                renderText(graph.left + graph.width + 0.005, posY, 0.01, soilmod.graphMeta[i].name .. ("%.f%%"):format(value))
            end
        end
    end
--DEBUG]]
end

        
soilmod.graphMeta = {
    [1] = { color={1.0, 1.0, 1.0, 0.9}, name="Yield:"    },
    [2] = { color={1.0, 1.0, 0.0, 0.9}, name="Weed:"     },
    [3] = { color={0.3, 1.0, 0.3, 0.9}, name="FertN:"    },
    [4] = { color={0.1, 1.0, 0.1, 0.9}, name="FertPK:"   },
    [5] = { color={1.0, 0.0, 1.0, 0.9}, name="Soil pH:"  },
    [6] = { color={0.1, 0.1, 1.0, 0.9}, name="Moisture:" },
}
soilmod.last1Value = {0,0}

function soilmod.debugGraphAddValue(layerType, value, sumPixel, numPixel, totPixel)
    if soilmod.debugGraphs[layerType] == nil then
        local numGraphValues = 100
        local w,h = 0.4, 0.15
        local x,y = 0.5 - (w/2), 0.05 --+ ((h * 1.05) * layerType)
        local minVal,maxVal = 0,100
        local showLabels,labelText = false, "L"..layerType
        soilmod.debugGraphs[layerType] = Graph:new(numGraphValues, x,y, w,h, minVal,maxVal, showLabels,labelText);
        soilmod.debugGraphs[layerType]:setColor( unpack(soilmod.graphMeta[layerType].color) )
    end
    if layerType==1 then
        if value==nil then
            soilmod.last1Value[2] = soilmod.last1Value[2] + 1
            if soilmod.last1Value[2] < 5 then
                value = soilmod.last1Value[1]
            end
        else
            soilmod.last1Value = {value,0}
        end
    end
    value = Utils.getNoNil(value,0) * 100
    soilmod.debugGraphs[layerType]:addValue(value, value - 1)
end

soilmod.debugGraphOn = true
