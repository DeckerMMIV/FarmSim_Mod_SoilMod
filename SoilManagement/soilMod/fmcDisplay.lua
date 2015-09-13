--
--  The Soil Management and Growth Control Project - version 2 (FS15)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modhoster.com
-- @date    2015-02-xx
--

fmcDisplay = {}
fmcDisplay.gridFontSize     = 0.05  -- Now configurable via the 'ModsSettings'-mod.
fmcDisplay.gridFontFactor   = 0.025 -- Now configurable via the 'ModsSettings'-mod.
fmcDisplay.gridSquareSize   = 2     -- Now configurable via the 'ModsSettings'-mod.
fmcDisplay.gridCells        = 10    -- Now configurable via the 'ModsSettings'-mod.
fmcDisplay.debugGraph       = false
fmcDisplay.debugGraphs      = {}

--
function pHtoText(sumPixels,numPixels,totPixels,numChnl)
    local phValue = fmcSoilMod.density_to_pH(sumPixels,numPixels,numChnl)    
    return ("%.1f %s"):format(phValue, g_i18n:getText(fmcSoilMod.pH_to_Denomination(phValue))), (sumPixels / ((2^numChnl - 1) * numPixels))
end

function moistureToText(sumPixels,numPixels,totPixels,numChnl)
    local pct = (sumPixels / ((2^numChnl - 1) * numPixels))
    return ("%.0f%%"):format(pct*100), pct
end

function nutrientToText(sumPixels,numPixels,totPixels,numChnl)
    local pct = sumPixels / numPixels
    local txt = "-"
    if pct > 0 then
        txt = ("x%.0f"):format(pct)
    end
    return txt, pct
end

function weedsToText(sumPixels,numPixels,totPixels,numChnl)
    local pct = (sumPixels / ((2^numChnl - 1) * numPixels))
    local txt = "-"
    if pct > 0 then
        txt = ("%.0f%%"):format(pct*100)
    end
    return txt, pct
end

fmcDisplay.herbicideTypesToText = { "-","A","B","C" }
function herbicideToText(sumPixels,numPixels,totPixels,numChnl)
    local pct = sumPixels / numPixels
    return Utils.getNoNil(fmcDisplay.herbicideTypesToText[math.floor(pct) + 1], "?"), pct
end

function germinationPreventionToText(sumPixels,numPixels,totPixels,numChnl)
    local pct = sumPixels / numPixels
    local days = math.ceil(pct)
    local txt = "-"
    if days > 0 then
        txt = (g_i18n:getText("GermRemainDays")):format("+"..days)
    end
    return txt, pct
end

--
function fmcDisplay.setup()
    --
    -- DID YOU KNOW - That if using the 'ModsSettings'-mod, you can easily modify these values in the "modsSettings.XML" file,
    --                which is located in the same folder as the "game.xml" and "inputBinding.xml" files.
    --
    local function setPanelPropertiesFromFontsize(fontSize)
        fmcDisplay.fontSize    = fontSize
        fmcDisplay.panelWidth  = fmcDisplay.fontSize * 13
        fmcDisplay.panelHeight = fmcDisplay.fontSize * 7.1
        fmcDisplay.panelPosX   = 1.0 - fmcDisplay.panelWidth
        fmcDisplay.panelPosY   = g_currentMission.hudBackgroundOverlay.y + g_currentMission.hudBackgroundOverlay.height
        fmcDisplay.autoHide    = false
    end
    setPanelPropertiesFromFontsize(0.012)
    
    if ModsSettings == nil then
        logInfo("Optional 'ModsSettings'-mod not found. Using builtin default position-values for info-panel/-grid.")
    else
        local modName = "fmcSoilMod"
        --
        local keyPath = "infoPanel"
        fmcDisplay.fontSize     = ModsSettings.getFloatLocal(modName, keyPath, "fontSize",  fmcDisplay.fontSize);
        -- update the values again, as the fontSize could have been changed in settings.
        setPanelPropertiesFromFontsize(fmcDisplay.fontSize)
        fmcDisplay.panelWidth   = ModsSettings.getFloatLocal(modName, keyPath, "w",        fmcDisplay.panelWidth );
        fmcDisplay.panelHeight  = ModsSettings.getFloatLocal(modName, keyPath, "h",        fmcDisplay.panelHeight);
        fmcDisplay.panelPosX    = ModsSettings.getFloatLocal(modName, keyPath, "x",        fmcDisplay.panelPosX  );
        fmcDisplay.panelPosY    = ModsSettings.getFloatLocal(modName, keyPath, "y",        fmcDisplay.panelPosY  );
        fmcDisplay.autoHide     = ModsSettings.getBoolLocal( modName, keyPath, "autoHide", fmcDisplay.autoHide   );
        --
        keyPath = "infoGrid"
        fmcDisplay.gridFontSize   = ModsSettings.getFloatLocal(modName, keyPath, "fontSize",    fmcDisplay.gridFontSize  );
        fmcDisplay.gridFontFactor = ModsSettings.getFloatLocal(modName, keyPath, "fontFactor",  fmcDisplay.gridFontFactor);
        fmcDisplay.gridSquareSize = ModsSettings.getIntLocal(  modName, keyPath, "cellSize",    fmcDisplay.gridSquareSize);
        fmcDisplay.gridCells      = ModsSettings.getIntLocal(  modName, keyPath, "numCells",    fmcDisplay.gridCells     );
    end

    --
    fmcDisplay.infoRows = {
        { t1=g_i18n:getText("Soil_pH")           , c2=0, t2="" , v1=0, layerId=g_currentMission.fmcFoliageSoil_pH         , numChnl=4 , func=pHtoText                     }, 
        { t1=g_i18n:getText("Soil_Moisture")     , c2=0, t2="" , v1=0, layerId=g_currentMission.fmcFoliageMoisture        , numChnl=3 , func=moistureToText               }, 
        { t1=g_i18n:getText("Nutrients_N")       , c2=0, t2="" , v1=0, layerId=g_currentMission.fmcFoliageFertN           , numChnl=4 , func=nutrientToText               }, 
        { t1=g_i18n:getText("Nutrients_PK")      , c2=0, t2="" , v1=0, layerId=g_currentMission.fmcFoliageFertPK          , numChnl=3 , func=nutrientToText               }, 
        { t1=g_i18n:getText("WeedsAmount")       , c2=0, t2="" , v1=0, layerId=g_currentMission.fmcFoliageWeed            , numChnl=3 , func=weedsToText                  }, 
        { t1=g_i18n:getText("HerbicideType")     , c2=0, t2="" , v1=0, layerId=g_currentMission.fmcFoliageHerbicide       , numChnl=2 , func=herbicideToText              }, 
        { t1=g_i18n:getText("GerminationRemain") , c2=0, t2="" , v1=0, layerId=g_currentMission.fmcFoliageHerbicideTime   , numChnl=2 , func=germinationPreventionToText  }, 
    }

    --
    local maxTextWidth = 0
    for _,elem in pairs(fmcDisplay.infoRows) do
        maxTextWidth = math.max(maxTextWidth, getTextWidth(fmcDisplay.fontSize, elem.t1))
    end
    maxTextWidth = maxTextWidth + getTextWidth(fmcDisplay.fontSize, "  ")
    for _,elem in pairs(fmcDisplay.infoRows) do
        elem.c2 = maxTextWidth
    end
    --
    fmcDisplay.infoRows[1].c2 = getTextWidth(fmcDisplay.fontSize, fmcDisplay.infoRows[1].t1 .. "  ")

    -- Solid background
    fmcDisplay.hudBlack = createImageOverlay("dataS2/menu/blank.png");
    setOverlayColor(fmcDisplay.hudBlack, 0,0,0,0.5)

    --
    fmcDisplay.nextUpdateTime = 0
    fmcDisplay.inputTime = nil
    fmcDisplay.lines = {}

    fmcDisplay.currentDisplay = 1
    fmcDisplay.gridCurrentLayer = 0
    
--DEBUG
    if g_currentMission:getIsServer() then    
        addConsoleCommand("modSoilModGraph", "", "consoleCommandSoilModGraph", fmcDisplay)
    end
--DEBUG]]

    addConsoleCommand("modSoilModField", "", "consoleCommandSoilModField", fmcDisplay)
end

function fmcDisplay.consoleCommandSoilModField(self, fieldNo)
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
            for _,infoRow in ipairs(fmcDisplay.infoRows) do
                if infoRow.layerId ~= nil and infoRow.layerId ~= 0 then
                    local sumPixels,numPixels,totPixels = getDensityParallelogram(infoRow.layerId, sx,sz,wx,wz,hx,hz, 0,infoRow.numChnl)
                    local t2,v1 = infoRow.func(sumPixels,numPixels,totPixels,infoRow.numChnl)
                    --
                    logInfo("  ",infoRow.t1,": ",t2)
                end
            end
        end
    end
end

function fmcDisplay.consoleCommandSoilModGraph(self, arg1)
    fmcDisplay.debugGraph = not fmcDisplay.debugGraph
    logInfo("modSoilModGraph = ",tostring(fmcDisplay.debugGraph))
end

function fmcDisplay.doShortEvent()
    fmcDisplay.gridCurrentLayer = (fmcDisplay.gridCurrentLayer + 1) % 5
    fmcDisplay.nextUpdateTime = g_currentMission.time -- Update at soon as possible.
end

function fmcDisplay.doLongEvent()
    -- todo
    fmcDisplay.currentDisplay = (fmcDisplay.currentDisplay + 1) % 2
end

function fmcDisplay.update(dt)

    if fmcDisplay.inputTime == nil then
        if InputBinding.isPressed(InputBinding.SOILMOD_GRIDOVERLAY) then
            fmcDisplay.inputTime = g_currentMission.time
        end
        
        if g_currentMission.time > fmcDisplay.nextUpdateTime then
            fmcDisplay.nextUpdateTime = g_currentMission.time + 1000
            fmcDisplay.refreshAreaInfo()
        end
    elseif InputBinding.isPressed(InputBinding.SOILMOD_GRIDOVERLAY) then
        local inputDuration = g_currentMission.time - fmcDisplay.inputTime
        if inputDuration > 450 then
            fmcDisplay.drawLongEvent = inputDuration / 1000; -- Start drawing
            if inputDuration > 1000 then
                fmcDisplay.inputTime = g_currentMission.time + (1000*60*60*24) -- Hoping that none would hold input for more than 24hours
                -- Do hasLongEvent action
                fmcDisplay.doLongEvent(InputBinding.SOILMOD_GRIDOVERLAY)
                fmcDisplay.drawLongEvent = nil -- Stop drawing
            end
        end
    else
        local inputDuration = g_currentMission.time - fmcDisplay.inputTime
        fmcDisplay.inputTime = nil
        fmcDisplay.drawLongEvent = nil -- Stop drawing
        if inputDuration > 0 and inputDuration < 500 then
            -- Do hasShortEvent action
            fmcDisplay.doShortEvent(InputBinding.SOILMOD_GRIDOVERLAY)
        end
    end

end

function fmcDisplay.refreshAreaInfo()
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
        
        for _,infoRow in ipairs(fmcDisplay.infoRows) do
            if infoRow.layerId ~= nil and infoRow.layerId ~= 0 then
                local sumPixels,numPixels,totPixels = getDensityParallelogram(infoRow.layerId, x,z, widthX,widthZ, heightX,heightZ, 0,infoRow.numChnl)
                infoRow.t2,infoRow.v1 = infoRow.func(sumPixels,numPixels,totPixels,infoRow.numChnl)
            end
        end
        
        --
        if fmcDisplay.gridColors == nil then
            fmcDisplay.gridColors = {}
            -- soil pH
            fmcDisplay.gridColors[1] = AnimCurve:new(linearInterpolator4)
            fmcDisplay.gridColors[1]:addKeyframe({ x=1.0, y=0.0, z=0.0, w=1.0, time=  0 })
            fmcDisplay.gridColors[1]:addKeyframe({ x=1.0, y=1.0, z=0.0, w=1.0, time= 25 })
            fmcDisplay.gridColors[1]:addKeyframe({ x=0.0, y=1.0, z=0.0, w=1.0, time= 50 })
            fmcDisplay.gridColors[1]:addKeyframe({ x=0.7, y=1.0, z=0.7, w=1.0, time= 75 })
            fmcDisplay.gridColors[1]:addKeyframe({ x=1.0, y=0.0, z=1.0, w=1.0, time=100 })
            -- soil Moisture
            fmcDisplay.gridColors[2] = AnimCurve:new(linearInterpolator4)
            fmcDisplay.gridColors[2]:addKeyframe({ x=1.0, y=0.0, z=0.0, w=0.3, time=  0 })
            fmcDisplay.gridColors[2]:addKeyframe({ x=0.1, y=0.1, z=1.0, w=0.6, time= 25 })
            fmcDisplay.gridColors[2]:addKeyframe({ x=0.2, y=0.2, z=1.0, w=0.9, time= 50 })
          --fmcDisplay.gridColors[2]:addKeyframe({ x=0.2, y=0.2, z=1.0, w=1.0, time= 75 })
            fmcDisplay.gridColors[2]:addKeyframe({ x=0.3, y=0.3, z=1.0, w=1.0, time=100 })
            -- nutrients(N)
            fmcDisplay.gridColors[3] = AnimCurve:new(linearInterpolator4)
            fmcDisplay.gridColors[3]:addKeyframe({ x=1.0, y=0.0, z=0.0, w=0.1, time=  0 })
            fmcDisplay.gridColors[3]:addKeyframe({ x=1.0, y=1.0, z=0.0, w=0.8, time= 25 })
          --fmcDisplay.gridColors[3]:addKeyframe({ x=0.0, y=1.0, z=0.0, w=1.0, time= 50 })
            fmcDisplay.gridColors[3]:addKeyframe({ x=0.0, y=1.0, z=0.0, w=1.0, time= 75 })
            fmcDisplay.gridColors[3]:addKeyframe({ x=0.0, y=1.0, z=0.0, w=1.0, time=100 })
            -- nutrients(PK)
            fmcDisplay.gridColors[4] = AnimCurve:new(linearInterpolator4)
            fmcDisplay.gridColors[4]:addKeyframe({ x=1.0, y=0.0, z=0.0, w=0.1, time=  0 })
            fmcDisplay.gridColors[4]:addKeyframe({ x=1.0, y=1.0, z=0.0, w=0.8, time= 25 })
          --fmcDisplay.gridColors[4]:addKeyframe({ x=0.0, y=1.0, z=0.0, w=1.0, time= 50 })
            fmcDisplay.gridColors[4]:addKeyframe({ x=0.0, y=1.0, z=0.0, w=1.0, time= 75 })
            fmcDisplay.gridColors[4]:addKeyframe({ x=0.0, y=1.0, z=0.0, w=1.0, time=100 })
          ---- herbicide-type
          --fmcDisplay.gridColors[5] = AnimCurve:new(linearInterpolator4)
          --fmcDisplay.gridColors[5]:addKeyframe({ x=0.0, y=0.0, z=0.0, w=0.0, time=  0 })
          --fmcDisplay.gridColors[5]:addKeyframe({ x=1.0, y=1.0, z=0.0, w=0.9, time=100 })
          --fmcDisplay.gridColors[5]:addKeyframe({ x=0.0, y=1.0, z=1.0, w=0.9, time=200 })
          --fmcDisplay.gridColors[5]:addKeyframe({ x=1.0, y=0.0, z=1.0, w=0.9, time=300 })
          
          
            --
            fmcDisplay.gridCurves = {}
            fmcDisplay.gridCurves[1] = fmcSoilModPlugins.pHCurve
            fmcDisplay.gridCurves[2] = fmcSoilModPlugins.moistureCurve
            fmcDisplay.gridCurves[3] = fmcSoilModPlugins.fertNCurve
            fmcDisplay.gridCurves[4] = fmcSoilModPlugins.fertPKCurve
        end
        
        fmcDisplay.grid = {}
        if fmcDisplay.gridCurrentLayer > 0 then
            local infoRow = fmcDisplay.infoRows[fmcDisplay.gridCurrentLayer]
            squareSize = math.max(1, math.floor(fmcDisplay.gridSquareSize))
            local halfSquareSize = squareSize/2
            cx,cz = math.floor(cx/squareSize)*squareSize,math.floor(cz/squareSize)*squareSize
            local widthX,widthZ, heightX,heightZ = squareSize-0.5,0, 0,squareSize-0.5
            local gridRadius = squareSize * fmcDisplay.gridCells
            local maxLayerValue = (2^infoRow.numChnl - 1)
            for gx = cx - gridRadius, cx + gridRadius, squareSize do
                local cols={}
                for gz = cz - gridRadius, cz + gridRadius, squareSize do
                    local x,z = gx - halfSquareSize, gz - halfSquareSize
                    local sumPixels,numPixels,totPixels = getDensityParallelogram(infoRow.layerId, x,z, widthX,widthZ, heightX,heightZ, 0,infoRow.numChnl)
                    table.insert(cols, {
                        y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, gx, 1, gz) + 0,
                        z = gz,
                        color = { fmcDisplay.gridColors[fmcDisplay.gridCurrentLayer]:get( 100 * (sumPixels / (maxLayerValue * numPixels)) ) },
                        pct = fmcDisplay.gridCurves[fmcDisplay.gridCurrentLayer]:get(sumPixels / totPixels)
                    })
                end
                table.insert(fmcDisplay.grid, {x=gx,cols=cols})
            end
        end
    end
end

function fmcDisplay.draw()
    if fmcDisplay.autoHide and not g_currentMission.showVehicleInfo then
        -- Do not show the panel
    else
        local alpha = 1.0
        if fmcDisplay.drawLongEvent ~= nil then
            --setTextColor(1,1,1,fmcDisplay.drawLongEvent * 0.1)
            --setTextAlignment(RenderText.ALIGN_CENTER)
            --local fontSize = fmcDisplay.drawLongEvent * 0.15
            --renderText(0.5, 0.5 - fontSize/2, fontSize, "SoilMod")
            
            alpha = (1 - fmcDisplay.drawLongEvent)
        end
    
        if fmcDisplay.currentDisplay == 1 then
            setTextColor(1,1,1,alpha)
            setTextAlignment(RenderText.ALIGN_LEFT)
        
            --
            -- DID YOU KNOW - That if using the 'ModsSettings'-mod, you can easily modify these values in the "modsSettings.XML" file,
            --                which is located in the same folder as the "game.xml" and "inputBinding.xml" files.
            --
            local w,h = fmcDisplay.panelWidth, fmcDisplay.panelHeight 
            local x,y = fmcDisplay.panelPosX,  fmcDisplay.panelPosY   
    
            renderOverlay(fmcDisplay.hudBlack, x,y, w,h);
            
            y = y + h + (fmcDisplay.fontSize * 0.1)
            x = x + fmcDisplay.fontSize * 0.25
            for i,infoRow in ipairs(fmcDisplay.infoRows) do
                setTextBold(i == fmcDisplay.gridCurrentLayer)
                y = y - fmcDisplay.fontSize
                renderText(x,            y, fmcDisplay.fontSize, infoRow.t1)
                renderText(x+infoRow.c2, y, fmcDisplay.fontSize, infoRow.t2)
            end
            setTextBold(false)
        elseif fmcDisplay.currentDisplay == 2 then
            -- todo
        end
    end
    
    --
    if fmcDisplay.gridCurrentLayer > 0 then
        setTextAlignment(RenderText.ALIGN_CENTER)
        for _,row in pairs(fmcDisplay.grid) do
            for _,col in pairs(row.cols) do
                local mx,my,mz = project(row.x,col.y,col.z);
                if  mx<1 and mx>0  -- When "inside" screen
                and my<1 and my>0  -- When "inside" screen
                and          mz<1  -- Only draw when "in front of" camera
                then
                    setTextColor(col.color[1], col.color[2], col.color[3], col.color[4])
                    renderText(mx,my, fmcDisplay.gridFontSize + (col.pct * fmcDisplay.gridFontFactor), ".")
                end
            end
        end
        setTextColor(1,1,1,1)
        setTextAlignment(RenderText.ALIGN_LEFT)
    end
    
--DEBUG
    if fmcDisplay.debugGraph then
        for i,graph in pairs(fmcDisplay.debugGraphs) do
            graph:draw()
            
            local idx = (graph.nextIndex == 1) and graph.numValues or (graph.nextIndex - 1)
            local value = graph.values[idx]
            if value ~= nil then
                local posY = graph.bottom + graph.height / (graph.maxValue - graph.minValue) * (value - graph.minValue)
            
                setTextColor( unpack(fmcDisplay.graphMeta[i].color) )
                renderText(graph.left + graph.width + 0.005, posY, 0.01, fmcDisplay.graphMeta[i].name .. ("%.f%%"):format(value))
            end
        end
    end
--DEBUG]]
end

        
fmcDisplay.graphMeta = {
    [1] = { color={1.0, 1.0, 1.0, 0.9}, name="Yield:"    },
    [2] = { color={1.0, 1.0, 0.0, 0.9}, name="Weed:"     },
    [3] = { color={0.3, 1.0, 0.3, 0.9}, name="FertN:"    },
    [4] = { color={0.1, 1.0, 0.1, 0.9}, name="FertPK:"   },
    [5] = { color={1.0, 0.0, 1.0, 0.9}, name="Soil pH:"  },
    [6] = { color={0.1, 0.1, 1.0, 0.9}, name="Moisture:" },
}
fmcDisplay.last1Value = {0,0}

function fmcDisplay.debugGraphAddValue(layerType, value, sumPixel, numPixel, totPixel)
    if fmcDisplay.debugGraphs[layerType] == nil then
        local numGraphValues = 100
        local w,h = 0.4, 0.15
        local x,y = 0.5 - (w/2), 0.05 --+ ((h * 1.05) * layerType)
        local minVal,maxVal = 0,100
        local showLabels,labelText = false, "L"..layerType
        fmcDisplay.debugGraphs[layerType] = Graph:new(numGraphValues, x,y, w,h, minVal,maxVal, showLabels,labelText);
        fmcDisplay.debugGraphs[layerType]:setColor( unpack(fmcDisplay.graphMeta[layerType].color) )
    end
    if layerType==1 then
        if value==nil then
            fmcDisplay.last1Value[2] = fmcDisplay.last1Value[2] + 1
            if fmcDisplay.last1Value[2] < 5 then
                value = fmcDisplay.last1Value[1]
            end
        else
            fmcDisplay.last1Value = {value,0}
        end
    end
    value = Utils.getNoNil(value,0) * 100
    fmcDisplay.debugGraphs[layerType]:addValue(value, value - 1)
end


fmcDisplay.debugGraphOn = true
--function fmcDisplay.graphForSelectedImplement(self, dt)
--    if self.isEntered and self.selectedImplement ~= nil then
--        fmcDisplay.graphForSelectedImplement = self.selectedImplement.object
--    end
--    fmcDisplay.debugGraphOn = (self == fmcDisplay.graphForSelectedImplement)
--end
--
--Vehicle.update = Utils.prependedFunction(Vehicle.update, fmcDisplay.graphForSelectedImplement)
