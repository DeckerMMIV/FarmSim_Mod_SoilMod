--
--  The Soil Management and Growth Control Project - version 2 (FS15)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modhoster.com
-- @date    2016-03-xx
--


fmcModifyMultiSiloTrigger = {}

function fmcModifyMultiSiloTrigger.getIsValidTrailer(self,superFunc,trailer)
    -- Do not allow liquid-sprayer equipment to be filled from a solid-silo.
    -- TODO: However there could be map-authors out there, that uses such a MultiSiloTrigger for liquids only!?
    if trailer.fmcSprayerSolidMaterial == false then
        return false;
    end

    return superFunc(self,trailer)
end;
MultiSiloTrigger.getIsValidTrailer = Utils.overwrittenFunction(MultiSiloTrigger.getIsValidTrailer, fmcModifyMultiSiloTrigger.getIsValidTrailer)


-- Change the entire 'MultiSiloTrigger.onActivateObject' to present only those fill-types the trailer supports.
function fmcModifyMultiSiloTrigger.onActivateObject(self,superFunc)
    if not self.isFilling and self.siloTrailer ~= nil then
        if self.siloTrailer.fillLevel > 0 then
            self:setIsFilling(true, self.siloTrailer.currentFillType);
        else
            -- Only present the set of fill-types that both trailer and silo has in common
            local fillTypes={}
            for fillType,_ in pairs(self.fillTypes) do
                if self.siloTrailer.fillTypes[fillType] then
                    fillTypes[fillType] = fillType;
                end
            end
            g_multiSiloDialog:setFillTypes(fillTypes);
            g_multiSiloDialog:setTitle(self.stationName);
            g_multiSiloDialog:setSelectionCallback(self.onFillTypeSelection, self);
            self.multiSiloDialog = g_gui:showGui("MultiSiloDialog");
        end;
    else
        self:setIsFilling(false, Fillable.FILLTYPE_UNKNOWN);
    end;
    g_currentMission:addActivatableObject(self);
end;
MultiSiloTrigger.onActivateObject = Utils.overwrittenFunction(MultiSiloTrigger.onActivateObject, fmcModifyMultiSiloTrigger.onActivateObject)
