--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-01-xx
--

sm3Display = {}
sm3Display.gridFontSize     = 0.05  -- Now configurable via the 'ModsSettings'-mod.
sm3Display.gridFontFactor   = 0.025 -- Now configurable via the 'ModsSettings'-mod.
sm3Display.gridSquareSize   = 2     -- Now configurable via the 'ModsSettings'-mod.
sm3Display.gridCells        = 10    -- Now configurable via the 'ModsSettings'-mod.
sm3Display.debugGraph       = false
sm3Display.debugGraphs      = {}

--
function pHtoText(sumPixels,numPixels,totPixels,numChnl)
    local phValue = sm3SoilMod.density_to_pH(sumPixels,numPixels,numChnl)    
    return ("%.1f %s"):format(phValue, g_i18n:getText(sm3SoilMod.pH_to_Denomination(phValue))), (sumPixels / ((2^numChnl - 1) * numPixels))
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

sm3Display.herbicideTypesToText = { "-","A","B","C" }
function herbicideToText(sumPixels,numPixels,totPixels,numChnl)
    local pct = sumPixels / numPixels
    return Utils.getNoNil(sm3Display.herbicideTypesToText[math.floor(pct) + 1], "?"), pct
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
function sm3Display:setup()
    --
    -- DID YOU KNOW - That if using the 'ModsSettings'-mod, you can easily modify these values in the "modsSettings.XML" file,
    --                which is located in the same folder as the "game.xml" and "inputBinding.xml" files.
    --
    local function setPanelPropertiesFromFontsize(fontSize)
        local uiScale = g_gameSettings:getValue("uiScale")
        local _,startY = getNormalizedScreenValues(1*uiScale, 151*uiScale)
        
        sm3Display.fontSize    = fontSize
        sm3Display.panelWidth  = sm3Display.fontSize * 13   -- TODO
        sm3Display.panelHeight = sm3Display.fontSize * 7.1  -- TODO
        sm3Display.panelPosX   = 1.0 - sm3Display.panelWidth
        sm3Display.panelPosY   = startY
        sm3Display.autoHide    = false
    end
    setPanelPropertiesFromFontsize(0.012)
    
    if ModsSettings == nil then
        logInfo("Optional 'ModsSettings'-mod not found. Using builtin default position-values for info-panel/-grid.")
    else
        local modName = "sm3SoilMod"
        --
        local keyPath = "infoPanel"
        sm3Display.fontSize     = ModsSettings.getFloatLocal(modName, keyPath, "fontSize",  sm3Display.fontSize);
        -- update the values again, as the fontSize could have been changed in settings.
        setPanelPropertiesFromFontsize(sm3Display.fontSize)
        sm3Display.panelWidth   = ModsSettings.getFloatLocal(modName, keyPath, "w",        sm3Display.panelWidth );
        sm3Display.panelHeight  = ModsSettings.getFloatLocal(modName, keyPath, "h",        sm3Display.panelHeight);
        sm3Display.panelPosX    = ModsSettings.getFloatLocal(modName, keyPath, "x",        sm3Display.panelPosX  );
        sm3Display.panelPosY    = ModsSettings.getFloatLocal(modName, keyPath, "y",        sm3Display.panelPosY  );
        sm3Display.autoHide     = ModsSettings.getBoolLocal( modName, keyPath, "autoHide", sm3Display.autoHide   );
        --
        keyPath = "infoGrid"
        sm3Display.gridFontSize   = ModsSettings.getFloatLocal(modName, keyPath, "fontSize",    sm3Display.gridFontSize  );
        sm3Display.gridFontFactor = ModsSettings.getFloatLocal(modName, keyPath, "fontFactor",  sm3Display.gridFontFactor);
        sm3Display.gridSquareSize = ModsSettings.getIntLocal(  modName, keyPath, "cellSize",    sm3Display.gridSquareSize);
        sm3Display.gridCells      = ModsSettings.getIntLocal(  modName, keyPath, "numCells",    sm3Display.gridCells     );
    end

    --
    sm3Display.infoRows = {
        { t1=g_i18n:getText("Soil_pH")           , c2=0, t2="" , v1=0, layerId=g_currentMission.sm3FoliageSoil_pH         , numChnl=4 , func=pHtoText                     }, 
        { t1=g_i18n:getText("Soil_Moisture")     , c2=0, t2="" , v1=0, layerId=g_currentMission.sm3FoliageMoisture        , numChnl=3 , func=moistureToText               }, 
        { t1=g_i18n:getText("Nutrients_N")       , c2=0, t2="" , v1=0, layerId=g_currentMission.sm3FoliageFertN           , numChnl=4 , func=nutrientToText               }, 
        { t1=g_i18n:getText("Nutrients_PK")      , c2=0, t2="" , v1=0, layerId=g_currentMission.sm3FoliageFertPK          , numChnl=3 , func=nutrientToText               }, 
        { t1=g_i18n:getText("WeedsAmount")       , c2=0, t2="" , v1=0, layerId=g_currentMission.sm3FoliageWeed            , numChnl=3 , func=weedsToText                  }, 
        { t1=g_i18n:getText("HerbicideType")     , c2=0, t2="" , v1=0, layerId=g_currentMission.sm3FoliageHerbicide       , numChnl=2 , func=herbicideToText              }, 
        { t1=g_i18n:getText("GerminationRemain") , c2=0, t2="" , v1=0, layerId=g_currentMission.sm3FoliageHerbicideTime   , numChnl=2 , func=germinationPreventionToText  }, 
    }

    --
    local maxTextWidth = 0
    for _,elem in pairs(sm3Display.infoRows) do
        maxTextWidth = math.max(maxTextWidth, getTextWidth(sm3Display.fontSize, elem.t1))
    end
    maxTextWidth = maxTextWidth + getTextWidth(sm3Display.fontSize, "  ")
    for _,elem in pairs(sm3Display.infoRows) do
        elem.c2 = maxTextWidth
    end
    --
    sm3Display.infoRows[1].c2 = getTextWidth(sm3Display.fontSize, sm3Display.infoRows[1].t1 .. "  ")

    -- Solid background
    sm3Display.hudBlack = createImageOverlay("dataS2/menu/blank.png");
    setOverlayColor(sm3Display.hudBlack, 0,0,0,0.5)

    --
    sm3Display.nextUpdateTime = 0
    sm3Display.inputTime = nil
    sm3Display.lines = {}

    sm3Display.currentDisplay = 1
    sm3Display.gridCurrentLayer = 0
    
--DEBUG
    if g_currentMission:getIsServer() then    
        addConsoleCommand("modSoilModGraph", "", "consoleCommandSoilModGraph", sm3Display)
    end
--DEBUG]]

    addConsoleCommand("modSoilModField", "", "consoleCommandSoilModField", sm3Display)
end

function sm3Display:consoleCommandSoilModField(fieldNo)
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
            for _,infoRow in ipairs(sm3Display.infoRows) do
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

function sm3Display:consoleCommandSoilModGraph(arg1)
    sm3Display.debugGraph = not sm3Display.debugGraph
    logInfo("modSoilModGraph = ",tostring(sm3Display.debugGraph))
end

function sm3Display:doShortEvent()
    sm3Display.gridCurrentLayer = (sm3Display.gridCurrentLayer + 1) % 5
    sm3Display.nextUpdateTime = g_currentMission.time -- Update at soon as possible.
end

function sm3Display:doLongEvent()
    -- todo
    sm3Display.currentDisplay = (sm3Display.currentDisplay + 1) % 2
end

function sm3Display:update(dt)

    if sm3Display.inputTime == nil then
        if InputBinding.isPressed(InputBinding.SOILMOD_GRIDOVERLAY) then
            sm3Display.inputTime = g_currentMission.time
        end
        
        if g_currentMission.time > sm3Display.nextUpdateTime then
            sm3Display.nextUpdateTime = g_currentMission.time + 1000
            sm3Display:refreshAreaInfo()
        end
    elseif InputBinding.isPressed(InputBinding.SOILMOD_GRIDOVERLAY) then
        local inputDuration = g_currentMission.time - sm3Display.inputTime
        if inputDuration > 450 then
            sm3Display.drawLongEvent = inputDuration / 1000; -- Start drawing
            if inputDuration > 1000 then
                sm3Display.inputTime = g_currentMission.time + (1000*60*60*24) -- Hoping that none would hold input for more than 24hours
                -- Do hasLongEvent action
                sm3Display:doLongEvent(InputBinding.SOILMOD_GRIDOVERLAY)
                sm3Display.drawLongEvent = nil -- Stop drawing
            end
        end
    else
        local inputDuration = g_currentMission.time - sm3Display.inputTime
        sm3Display.inputTime = nil
        sm3Display.drawLongEvent = nil -- Stop drawing
        if inputDuration > 0 and inputDuration < 500 then
            -- Do hasShortEvent action
            sm3Display:doShortEvent(InputBinding.SOILMOD_GRIDOVERLAY)
        end
    end

end

function sm3Display:refreshAreaInfo()
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
        
        for _,infoRow in ipairs(sm3Display.infoRows) do
            if infoRow.layerId ~= nil and infoRow.layerId ~= 0 then
                local sumPixels,numPixels,totPixels = getDensityParallelogram(infoRow.layerId, x,z, widthX,widthZ, heightX,heightZ, 0,infoRow.numChnl)
                infoRow.t2,infoRow.v1 = infoRow.func(sumPixels,numPixels,totPixels,infoRow.numChnl)
            end
        end
        
        --
        if sm3Display.gridColors == nil then
            sm3Display.gridColors = {}
            -- soil pH
            sm3Display.gridColors[1] = AnimCurve:new(linearInterpolator4)
            sm3Display.gridColors[1]:addKeyframe({ x=1.0, y=0.0, z=0.0, w=1.0, time=  0 })
            sm3Display.gridColors[1]:addKeyframe({ x=1.0, y=1.0, z=0.0, w=1.0, time= 25 })
            sm3Display.gridColors[1]:addKeyframe({ x=0.0, y=1.0, z=0.0, w=1.0, time= 50 })
            sm3Display.gridColors[1]:addKeyframe({ x=0.7, y=1.0, z=0.7, w=1.0, time= 75 })
            sm3Display.gridColors[1]:addKeyframe({ x=1.0, y=0.0, z=1.0, w=1.0, time=100 })
            -- soil Moisture
            sm3Display.gridColors[2] = AnimCurve:new(linearInterpolator4)
            sm3Display.gridColors[2]:addKeyframe({ x=1.0, y=0.0, z=0.0, w=0.3, time=  0 })
            sm3Display.gridColors[2]:addKeyframe({ x=0.1, y=0.1, z=1.0, w=0.6, time= 25 })
            sm3Display.gridColors[2]:addKeyframe({ x=0.2, y=0.2, z=1.0, w=0.9, time= 50 })
          --sm3Display.gridColors[2]:addKeyframe({ x=0.2, y=0.2, z=1.0, w=1.0, time= 75 })
            sm3Display.gridColors[2]:addKeyframe({ x=0.3, y=0.3, z=1.0, w=1.0, time=100 })
            -- nutrients(N)
            sm3Display.gridColors[3] = AnimCurve:new(linearInterpolator4)
            sm3Display.gridColors[3]:addKeyframe({ x=1.0, y=0.0, z=0.0, w=0.1, time=  0 })
            sm3Display.gridColors[3]:addKeyframe({ x=1.0, y=1.0, z=0.0, w=0.8, time= 25 })
          --sm3Display.gridColors[3]:addKeyframe({ x=0.0, y=1.0, z=0.0, w=1.0, time= 50 })
            sm3Display.gridColors[3]:addKeyframe({ x=0.0, y=1.0, z=0.0, w=1.0, time= 75 })
            sm3Display.gridColors[3]:addKeyframe({ x=0.0, y=1.0, z=0.0, w=1.0, time=100 })
            -- nutrients(PK)
            sm3Display.gridColors[4] = AnimCurve:new(linearInterpolator4)
            sm3Display.gridColors[4]:addKeyframe({ x=1.0, y=0.0, z=0.0, w=0.1, time=  0 })
            sm3Display.gridColors[4]:addKeyframe({ x=1.0, y=1.0, z=0.0, w=0.8, time= 25 })
          --sm3Display.gridColors[4]:addKeyframe({ x=0.0, y=1.0, z=0.0, w=1.0, time= 50 })
            sm3Display.gridColors[4]:addKeyframe({ x=0.0, y=1.0, z=0.0, w=1.0, time= 75 })
            sm3Display.gridColors[4]:addKeyframe({ x=0.0, y=1.0, z=0.0, w=1.0, time=100 })
          ---- herbicide-type
          --sm3Display.gridColors[5] = AnimCurve:new(linearInterpolator4)
          --sm3Display.gridColors[5]:addKeyframe({ x=0.0, y=0.0, z=0.0, w=0.0, time=  0 })
          --sm3Display.gridColors[5]:addKeyframe({ x=1.0, y=1.0, z=0.0, w=0.9, time=100 })
          --sm3Display.gridColors[5]:addKeyframe({ x=0.0, y=1.0, z=1.0, w=0.9, time=200 })
          --sm3Display.gridColors[5]:addKeyframe({ x=1.0, y=0.0, z=1.0, w=0.9, time=300 })
          
          
            --
            sm3Display.gridCurves = {}
            sm3Display.gridCurves[1] = sm3SoilModPlugins.pHCurve
            sm3Display.gridCurves[2] = sm3SoilModPlugins.moistureCurve
            sm3Display.gridCurves[3] = sm3SoilModPlugins.fertNCurve
            sm3Display.gridCurves[4] = sm3SoilModPlugins.fertPKCurve
        end
        
        sm3Display.grid = {}
        if sm3Display.gridCurrentLayer > 0 then
            local infoRow = sm3Display.infoRows[sm3Display.gridCurrentLayer]
            squareSize = math.max(1, math.floor(sm3Display.gridSquareSize))
            local halfSquareSize = squareSize/2
            cx,cz = math.floor(cx/squareSize)*squareSize,math.floor(cz/squareSize)*squareSize
            local widthX,widthZ, heightX,heightZ = squareSize-0.5,0, 0,squareSize-0.5
            local gridRadius = squareSize * sm3Display.gridCells
            local maxLayerValue = (2^infoRow.numChnl - 1)
            for gx = cx - gridRadius, cx + gridRadius, squareSize do
                local cols={}
                for gz = cz - gridRadius, cz + gridRadius, squareSize do
                    local x,z = gx - halfSquareSize, gz - halfSquareSize
                    local sumPixels,numPixels,totPixels = getDensityParallelogram(infoRow.layerId, x,z, widthX,widthZ, heightX,heightZ, 0,infoRow.numChnl)
                    table.insert(cols, {
                        y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, gx, 1, gz) + 0,
                        z = gz,
                        color = { sm3Display.gridColors[sm3Display.gridCurrentLayer]:get( 100 * (sumPixels / (maxLayerValue * numPixels)) ) },
                        pct = sm3Display.gridCurves[sm3Display.gridCurrentLayer]:get(sumPixels / totPixels)
                    })
                end
                table.insert(sm3Display.grid, {x=gx,cols=cols})
            end
        end
    end
end

function sm3Display:draw()
    if sm3Display.autoHide and not g_currentMission.showVehicleInfo then
        -- Do not show the panel
    else
        local alpha = 1.0
        if sm3Display.drawLongEvent ~= nil then
            --setTextColor(1,1,1,sm3Display.drawLongEvent * 0.1)
            --setTextAlignment(RenderText.ALIGN_CENTER)
            --local fontSize = sm3Display.drawLongEvent * 0.15
            --renderText(0.5, 0.5 - fontSize/2, fontSize, "SoilMod")
            
            alpha = (1 - sm3Display.drawLongEvent)
        end
    
        if sm3Display.currentDisplay == 1 then
            setTextColor(1,1,1,alpha)
            setTextAlignment(RenderText.ALIGN_LEFT)
        
            --
            -- DID YOU KNOW - That if using the 'ModsSettings'-mod, you can easily modify these values in the "modsSettings.XML" file,
            --                which is located in the same folder as the "game.xml" and "inputBinding.xml" files.
            --
            local w,h = sm3Display.panelWidth, sm3Display.panelHeight 
            local x,y = sm3Display.panelPosX,  sm3Display.panelPosY   
    
            renderOverlay(sm3Display.hudBlack, x,y, w,h);
            
            y = y + h + (sm3Display.fontSize * 0.1)
            x = x + sm3Display.fontSize * 0.25
            for i,infoRow in ipairs(sm3Display.infoRows) do
                setTextBold(i == sm3Display.gridCurrentLayer)
                y = y - sm3Display.fontSize
                renderText(x,            y, sm3Display.fontSize, infoRow.t1)
                renderText(x+infoRow.c2, y, sm3Display.fontSize, infoRow.t2)
            end
            setTextBold(false)
        elseif sm3Display.currentDisplay == 2 then
            -- todo
        end
    end
    
    --
    if sm3Display.gridCurrentLayer > 0 then
        setTextAlignment(RenderText.ALIGN_CENTER)
        for _,row in pairs(sm3Display.grid) do
            for _,col in pairs(row.cols) do
                local mx,my,mz = project(row.x,col.y,col.z);
                if  mx<1 and mx>0  -- When "inside" screen
                and my<1 and my>0  -- When "inside" screen
                and          mz<1  -- Only draw when "in front of" camera
                then
                    setTextColor(col.color[1], col.color[2], col.color[3], col.color[4])
                    renderText(mx,my, sm3Display.gridFontSize + (col.pct * sm3Display.gridFontFactor), ".")
                end
            end
        end
        setTextColor(1,1,1,1)
        setTextAlignment(RenderText.ALIGN_LEFT)
    end
    
--DEBUG
    if sm3Display.debugGraph then
        for i,graph in pairs(sm3Display.debugGraphs) do
            graph:draw()
            
            local idx = (graph.nextIndex == 1) and graph.numValues or (graph.nextIndex - 1)
            local value = graph.values[idx]
            if value ~= nil then
                local posY = graph.bottom + graph.height / (graph.maxValue - graph.minValue) * (value - graph.minValue)
            
                setTextColor( unpack(sm3Display.graphMeta[i].color) )
                renderText(graph.left + graph.width + 0.005, posY, 0.01, sm3Display.graphMeta[i].name .. ("%.f%%"):format(value))
            end
        end
    end
--DEBUG]]
end

        
sm3Display.graphMeta = {
    [1] = { color={1.0, 1.0, 1.0, 0.9}, name="Yield:"    },
    [2] = { color={1.0, 1.0, 0.0, 0.9}, name="Weed:"     },
    [3] = { color={0.3, 1.0, 0.3, 0.9}, name="FertN:"    },
    [4] = { color={0.1, 1.0, 0.1, 0.9}, name="FertPK:"   },
    [5] = { color={1.0, 0.0, 1.0, 0.9}, name="Soil pH:"  },
    [6] = { color={0.1, 0.1, 1.0, 0.9}, name="Moisture:" },
}
sm3Display.last1Value = {0,0}

function sm3Display.debugGraphAddValue(layerType, value, sumPixel, numPixel, totPixel)
    if sm3Display.debugGraphs[layerType] == nil then
        local numGraphValues = 100
        local w,h = 0.4, 0.15
        local x,y = 0.5 - (w/2), 0.05 --+ ((h * 1.05) * layerType)
        local minVal,maxVal = 0,100
        local showLabels,labelText = false, "L"..layerType
        sm3Display.debugGraphs[layerType] = Graph:new(numGraphValues, x,y, w,h, minVal,maxVal, showLabels,labelText);
        sm3Display.debugGraphs[layerType]:setColor( unpack(sm3Display.graphMeta[layerType].color) )
    end
    if layerType==1 then
        if value==nil then
            sm3Display.last1Value[2] = sm3Display.last1Value[2] + 1
            if sm3Display.last1Value[2] < 5 then
                value = sm3Display.last1Value[1]
            end
        else
            sm3Display.last1Value = {value,0}
        end
    end
    value = Utils.getNoNil(value,0) * 100
    sm3Display.debugGraphs[layerType]:addValue(value, value - 1)
end


sm3Display.debugGraphOn = true
--function sm3Display.graphForSelectedImplement(self, dt)
--    if self.isEntered and self.selectedImplement ~= nil then
--        sm3Display.graphForSelectedImplement = self.selectedImplement.object
--    end
--    sm3Display.debugGraphOn = (self == sm3Display.graphForSelectedImplement)
--end
--
--Vehicle.update = Utils.prependedFunction(Vehicle.update, sm3Display.graphForSelectedImplement)
