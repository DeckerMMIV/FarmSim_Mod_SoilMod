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

function fmcDisplay.setup()
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
    fmcDisplay.sumDt = fmcDisplay.sumDt + dt
    if fmcDisplay.sumDt < 1000 then
        return
    end
    fmcDisplay.sumDt = fmcDisplay.sumDt - 1000

    --
    fmcDisplay.lines = {}
    local x,y,z
    if g_currentMission.controlPlayer and g_currentMission.player ~= nil then
        x,y,z = getWorldTranslation(g_currentMission.player.rootNode)
    elseif g_currentMission.controlledVehicle ~= nil then
        x,y,z = getWorldTranslation(g_currentMission.controlledVehicle.rootNode)
    end

    if x ~= nil and x==x and z==z then
    
        table.insert(fmcDisplay.lines, ("Pos-XZ: %.1f/%.1f (%.0f)"):format(x,z, g_currentMission.time))
        
        local squareSize = 10
        local widthX,widthZ, heightX,heightZ = squareSize-0.5,0, 0,squareSize-0.5
        x, z = x - (squareSize/2), z - (squareSize/2)

        for _,layer in ipairs(fmcDisplay.layers) do
            if layer.layerId ~= nil and layer.layerId ~= 0 and layer.func ~= nil then
                local txt = layer:func(x,z, widthX,widthZ, heightX,heightZ)
                if txt ~= nil then
                    table.insert(fmcDisplay.lines, txt)
                end
            end
        end
    end
end
    
function fmcDisplay.draw()
    local fontSize = 0.015
    local x,y = 0.5,1.0-(fontSize * 2)
    setTextBold(false)
    setTextColor(1,1,1,1)
    setTextAlignment(RenderText.ALIGN_LEFT)
    for _,txt in pairs(fmcDisplay.lines) do
        renderText(x,y, fontSize, txt)
        y=y-fontSize
    end
end

--
print(("Script loaded: fmcDisplay.LUA (v%s)"):format(fmcDisplay.version))
