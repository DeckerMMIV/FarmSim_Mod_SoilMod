--
--  The Soil Management and Growth Control Project - version 2 (FS15)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modhoster.com
-- @date    2015-02-xx
--

fmcDisplay = {}

--
local modItem = ModsUtil.findModItemByModName(g_currentModName);
fmcDisplay.version = (modItem and modItem.version) and modItem.version or "?.?.?";
fmcDisplay.modDir = g_currentModDirectory;

fmcDisplay.sumDt = 0
fmcDisplay.lines = {}
fmcDisplay.gridCurrentLayer = 0
fmcDisplay.fontSize = 0.012

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
end

function fmcDisplay.update(dt)
    if InputBinding.hasEvent(InputBinding.SOILMOD_GRIDOVERLAY) then
        fmcDisplay.gridCurrentLayer = (fmcDisplay.gridCurrentLayer + 1) % 5
        fmcDisplay.sumDt = fmcDisplay.sumDt + 1000
    end

    fmcDisplay.sumDt = fmcDisplay.sumDt + dt
    if fmcDisplay.sumDt > 1000 then
        fmcDisplay.sumDt = fmcDisplay.sumDt - 1000
        fmcDisplay.updateSec()
    end
end

function fmcDisplay.updateSec()
    --
    local cx,cy,cz
    if g_currentMission.controlPlayer and g_currentMission.player ~= nil then
        cx,cy,cz = getWorldTranslation(g_currentMission.player.rootNode)
    elseif g_currentMission.controlledVehicle ~= nil then
        cx,cy,cz = getWorldTranslation(g_currentMission.controlledVehicle.rootNode)
    end

    if cx ~= nil and cx==cx and cz==cz then
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
        end
        
        fmcDisplay.grid = {}
        if fmcDisplay.gridCurrentLayer > 0 then
            local infoRow = fmcDisplay.infoRows[fmcDisplay.gridCurrentLayer]
            squareSize = 2
            cx,cz = math.floor(cx/squareSize)*squareSize,math.floor(cz/squareSize)*squareSize
            local widthX,widthZ, heightX,heightZ = squareSize-0.5,0, 0,squareSize-0.5
            local gridRadius = squareSize * 10
            for gx = cx - gridRadius, cx + gridRadius, squareSize do
                local cols={}
                for gz = cz - gridRadius, cz + gridRadius, squareSize do
                    local x,z = gx - (squareSize/2), gz - (squareSize/2)
                    local sumPixels,numPixels,totPixels = getDensityParallelogram(infoRow.layerId, x,z, widthX,widthZ, heightX,heightZ, 0,infoRow.numChnl)
                    table.insert(cols, {
                        y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, gx, 1, gz) + 0,
                        z = gz,
                        color = { fmcDisplay.gridColors[fmcDisplay.gridCurrentLayer]:get( 100 * (sumPixels / ((2^infoRow.numChnl - 1) * numPixels)) ) }
                    })
                end
                table.insert(fmcDisplay.grid, {x=gx,cols=cols})
            end
        end
    end
end

function fmcDisplay.draw()
    setTextColor(1,1,1,1)
    setTextAlignment(RenderText.ALIGN_LEFT)

    local w,h = fmcDisplay.fontSize * 13 , fmcDisplay.fontSize * 7.1
    local x,y = 1.0 - w , g_currentMission.hudBackgroundOverlay.y + g_currentMission.hudBackgroundOverlay.height

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
    
    --
    if fmcDisplay.gridCurrentLayer > 0 then
        local fontSize = 0.05
        for _,row in pairs(fmcDisplay.grid) do
            for _,col in pairs(row.cols) do
                local mx,my,mz = project(row.x,col.y,col.z);
                if  mx<1 and mx>0  -- When "inside" screen
                and my<1 and my>0  -- When "inside" screen
                and          mz<1  -- Only draw when "in front of" camera
                then
                    setTextColor(col.color[1], col.color[2], col.color[3], col.color[4])
                    renderText(mx,my, fontSize, ".")
                end
            end
        end
        setTextColor(1,1,1,1)
    end
end

--
print(("Script loaded: fmcDisplay.LUA (v%s)"):format(fmcDisplay.version))
