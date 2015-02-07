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

fmcDisplay.layers = {}
fmcDisplay.sumDt = 0
fmcDisplay.lines = {}
fmcDisplay.gridCurrentLayer = 0

--
function pHtoText(sumPixels,numPixels,totPixels,numChnl)
    local phValue = fmcSoilMod.density_to_pH(sumPixels,numPixels,numChnl)    
    return ("%.1f %s"):format(phValue, g_i18n:getText(fmcSoilMod.pH_to_Denomination(phValue))), (sumPixels / ((2^numChnl - 1) * numPixels))
end

function moistureToText(sumPixels,numPixels,totPixels,numChnl)
    local pct = (sumPixels / ((2^numChnl - 1) * numPixels))
    return ("%.1f%%"):format(pct*100), pct
end

function nutrientToText(sumPixels,numPixels,totPixels,numChnl)
    local pct = sumPixels / numPixels
    return ("%.1f%%"):format(pct*100), pct
end

--
function fmcDisplay.setup()
    --
    fmcDisplay.infoRows = {
        { t1=g_i18n:getText("Soil_pH")       , t2="" , v1=0, layerId=g_currentMission.fmcFoliageSoil_pH    , numChnl=4 , func=pHtoText       }, 
        { t1=g_i18n:getText("Soil_Moisture") , t2="" , v1=0, layerId=g_currentMission.fmcFoliageMoisture   , numChnl=3 , func=moistureToText }, 
        { t1=g_i18n:getText("Nutrients_N")   , t2="" , v1=0, layerId=g_currentMission.fmcFoliageFertN      , numChnl=4 , func=nutrientToText }, 
        { t1=g_i18n:getText("Nutrients_PK")  , t2="" , v1=0, layerId=g_currentMission.fmcFoliageFertPK     , numChnl=3 , func=nutrientToText }, 
    }

    -- Solid background
    fmcDisplay.hudBlack = createImageOverlay("dataS2/menu/blank.png");
    setOverlayColor(fmcDisplay.hudBlack, 0,0,0,0.5)

    --
    fmcDisplay.layers = {
        {
            layerId = g_currentMission.fmcFoliageManure,
            func = function(self, x,z, wx,wz, hx,hz)
                local sumPixels,numPixels,totPixels = getDensityParallelogram(self.layerId, x,z, wx,wz, hx,hz, 0,2)
                return ("Manure: %.2f"):format(sumPixels/totPixels)
            end
        },
        {
            layerId = g_currentMission.fmcFoliageSlurry,
            func = function(self, x,z, wx,wz, hx,hz)
                local sumPixels1,numPixels1,totPixels1 = getDensityParallelogram(self.layerId, x,z, wx,wz, hx,hz, 0,1)
                local sumPixels2,numPixels2,totPixels2 = getDensityParallelogram(self.layerId, x,z, wx,wz, hx,hz, 1,1)
                return ("Slurry: %.2f/%.2f"):format(sumPixels1/totPixels1, sumPixels2/totPixels2)
            end
        },
        {
            layerId = g_currentMission.fmcFoliageWeed,
            func = function(self, x,z, wx,wz, hx,hz)
                setDensityMaskParams(self.layerId, "equals", 0)
                local sumPixels1,numPixels1,totPixels1 = getDensityMaskedParallelogram(self.layerId, x,z, wx,wz, hx,hz, 0,3, self.layerId,3,1)
                setDensityMaskParams(self.layerId, "equals", 1)
                local sumPixels2,numPixels2,totPixels2 = getDensityMaskedParallelogram(self.layerId, x,z, wx,wz, hx,hz, 0,3, self.layerId,3,1)
                return ("Weed: %.2f/%.2f"):format(sumPixels1/totPixels1, sumPixels2/totPixels2)
            end
        },
        {
            layerId = g_currentMission.fmcFoliageLime,
            func = function(self, x,z, wx,wz, hx,hz)
                local sumPixels,numPixels,totPixels = getDensityParallelogram(self.layerId, x,z, wx,wz, hx,hz, 0,1)
                return ("Lime: %.2f"):format(sumPixels/totPixels)
            end
        },
        {
            layerId = g_currentMission.fmcFoliageFertilizer,
            func = function(self, x,z, wx,wz, hx,hz)
                local txt="Fertilizer: "
                local delim=""
                for idx=1,7 do
                    setDensityMaskParams(self.layerId, "equals", idx)
                    local sumPixels,numPixels,totPixels = getDensityMaskedParallelogram(self.layerId, x,z, wx,wz, hx,hz, 0,3, self.layerId,0,3)
                    txt = txt .. delim .. ("%.2f"):format(sumPixels/totPixels)
                    delim="/"
                end
                return txt
            end
        },
        {
            layerId = g_currentMission.fmcFoliageHerbicide,
            func = function(self, x,z, wx,wz, hx,hz)
                local txt="Herbicide: "
                local delim=""
                for idx=1,3 do
                    setDensityMaskParams(self.layerId, "equals", idx)
                    local sumPixels,numPixels,totPixels = getDensityMaskedParallelogram(self.layerId, x,z, wx,wz, hx,hz, 0,2, self.layerId,0,2)
                    txt = txt .. delim .. ("%.2f"):format(sumPixels/totPixels)
                    delim="/"
                end
                return txt
            end
        },
        {
            layerId = g_currentMission.fmcFoliageWater,
            func = function(self, x,z, wx,wz, hx,hz)
                local sumPixels,numPixels,totPixels = getDensityParallelogram(self.layerId, x,z, wx,wz, hx,hz, 0,2)
                return ("Water: %.2f"):format(sumPixels/totPixels)
            end
        },
        {
            layerId = g_currentMission.fmcFoliageSoil_pH,
            func = function(self, x,z, wx,wz, hx,hz)
                local sumPixels,numPixels,totPixels = getDensityParallelogram(self.layerId, x,z, wx,wz, hx,hz, 0,4)
                local phValue = fmcSoilMod.density_to_pH(sumPixels,numPixels,4)
                return ("pH: %.2f (%.1f %s)"):format(sumPixels/totPixels, phValue, g_i18n:getText(fmcSoilMod.pH_to_Denomination(phValue)))
            end
        },
        {
            layerId = g_currentMission.fmcFoliageFertN,
            func = function(self, x,z, wx,wz, hx,hz)
                local sumPixels,numPixels,totPixels = getDensityParallelogram(self.layerId, x,z, wx,wz, hx,hz, 0,4)
                return ("FertN: %.2f"):format(sumPixels/totPixels)
            end
        },
        {
            layerId = g_currentMission.fmcFoliageFertPK,
            func = function(self, x,z, wx,wz, hx,hz)
                local sumPixels,numPixels,totPixels = getDensityParallelogram(self.layerId, x,z, wx,wz, hx,hz, 0,3)
                return ("FertPK: %.2f"):format(sumPixels/totPixels)
            end
        },
        {
            layerId = g_currentMission.fmcFoliageMoisture,
            func = function(self, x,z, wx,wz, hx,hz)
                local sumPixels,numPixels,totPixels = getDensityParallelogram(self.layerId, x,z, wx,wz, hx,hz, 0,3)
                return ("Moisture: %.2f"):format(sumPixels/totPixels)
            end
        },
        {
            layerId = g_currentMission.fmcFoliageHerbicideTime,
            func = function(self, x,z, wx,wz, hx,hz)
                local sumPixels,numPixels,totPixels = getDensityParallelogram(self.layerId, x,z, wx,wz, hx,hz, 0,2)
                return ("GermPrev: %.2f"):format(sumPixels/totPixels)
            end
        },
        {
            layerId = g_currentMission.terrainDetailId,
            func = function(self, x,z, wx,wz, hx,hz)
                local sumPixels,numPixels,totPixels = getDensityParallelogram(self.layerId, x,z, wx,wz, hx,hz, g_currentMission.sprayChannel, 1)
                return ("Spray: %.2f"):format(sumPixels/totPixels)
            end
        },
    }
end

function fmcDisplay.update(dt)
    if InputBinding.hasEvent(InputBinding.SOILMOD_GRIDOVERLAY) then
        fmcDisplay.gridCurrentLayer = (fmcDisplay.gridCurrentLayer + 1) % 5
        fmcDisplay.sumDt = fmcDisplay.sumDt + 1000
    end

    fmcDisplay.sumDt = fmcDisplay.sumDt + dt
    if fmcDisplay.sumDt < 1000 then
        return
    end
    fmcDisplay.sumDt = fmcDisplay.sumDt - 1000

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
        
        --fmcDisplay.lines = {}
        --table.insert(fmcDisplay.lines, ("Pos-XZ: %.1f/%.1f (%.0f)"):format(cx,cz, g_currentMission.time))
        --for _,layer in ipairs(fmcDisplay.layers) do
        --    if layer.layerId ~= nil and layer.layerId ~= 0 and layer.func ~= nil then
        --        local txt = layer:func(x,z, widthX,widthZ, heightX,heightZ)
        --        if txt ~= nil then
        --            table.insert(fmcDisplay.lines, txt)
        --        end
        --    end
        --end
        
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
    --setTextBold(false)
    setTextColor(1,1,1,1)
    setTextAlignment(RenderText.ALIGN_LEFT)

    --local fontSize = 0.015
    --local x,y = 0.5,1.0-(fontSize * 2)
    --for _,txt in pairs(fmcDisplay.lines) do
    --    renderText(x,y, fontSize, txt)
    --    y=y-fontSize
    --end

    --
    local fontSize = 0.012
    local w,h = fontSize * 13 , fontSize * 4
    local x,y = 1.0 - w, g_currentMission.speedHud.y + g_currentMission.speedHud.height + fontSize

    renderOverlay(fmcDisplay.hudBlack, x,y, w,h);
    
    y = y + h
    local xcol1 =     x + fontSize * 0.25
    local xcol2 = xcol1 + fontSize * 6
    for i,infoRow in ipairs(fmcDisplay.infoRows) do
        setTextBold(i == fmcDisplay.gridCurrentLayer)
        y=y-fontSize
        renderText(xcol1,y, fontSize, infoRow.t1)
        renderText(xcol2,y, fontSize, infoRow.t2)
    end
    setTextBold(false)
    
    --
    if fmcDisplay.gridCurrentLayer > 0 then
        fontSize = 0.05
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
