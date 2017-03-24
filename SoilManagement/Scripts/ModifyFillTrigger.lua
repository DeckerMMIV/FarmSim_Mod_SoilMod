--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-03-xx
--

--
function soilmod_FillTrigger_load(self, superFunc, nodeId, fillType, parent)
    -- Support for 'fillTypes' (plural) user-attribute.
    local fillTypesStr = getUserAttribute(nodeId, "fillTypes")
    local implicitFillType = nil
    if fillType == nil and fillTypesStr ~= nil then
        local fillTypes = Utils.splitString(" ", fillTypesStr);
        for _,v in pairs(fillTypes) do
            local otherFillType = FillUtil.fillTypeNameToInt[v];
            if otherFillType ~= nil then
                implicitFillType = otherFillType
                break
            end;
        end
        logInfo("Modifying fill-trigger(",nodeId,") to deliver fill-types: ",fillTypesStr)
    end

    --
    superFunc(self, nodeId, Utils.getNoNil(fillType, implicitFillType), parent)
    
    -- If no explicit fill-type nor fill-types
    if fillType == nil and fillTypesStr == nil then
        -- Have SoilMod registered its spray-types?
        if Sprayer.SPRAYTYPE_PLANTKILLER ~= nil then
            -- Is this an 'infinite tank' for fertilizer?
            if  self.isSiloTrigger == false and self.parent == nil then
                if self.fillType == FillUtil.FILLTYPE_LIQUIDFERTILIZER then
                    -- SoilMod liquid fill-types
                    fillTypesStr = "liquidFertilizer liquidFertilizer2 liquidFertilizer3 herbicide herbicide2 herbicide3 plantKiller"
                    logInfo("Modifying fill-trigger(",nodeId,"), detected as infinite liquid-fertilizer tank, to deliver SoilMod spray-types: ",fillTypesStr)
                elseif self.fillType == FillUtil.FILLTYPE_FERTILIZER then
                    -- SoilMod soild fill-types
                    fillTypesStr = "fertilizer fertilizer2 fertilizer3 kalk"
                    logInfo("Modifying fill-trigger(",nodeId,"), detected as infinite soild-fertilizer tank, to deliver SoilMod spray-types: ",fillTypesStr)
                end
            end
        end
    end
    
    --
    if fillTypesStr ~= nil then
        self.modOrigFillType = self.fillType;
        self.modFillTypes = {}
        local fillTypes = Utils.splitString(" ", fillTypesStr);
        for _,v in pairs(fillTypes) do
            local otherFillType = FillUtil.fillTypeNameToInt[v];
            if otherFillType ~= nil then
                self.modFillTypes[otherFillType] = otherFillType;
            end;
        end;
    end
    
    return true;
end
FillTrigger.load = Utils.overwrittenFunction(FillTrigger.load, soilmod_FillTrigger_load)

--
function soilmod_FillTrigger_getIsActivatable(self,superFunc,fillable)
    if self.modFillTypes ~= nil then
        local found = false

        -- Check equipment's current fill-level for its fill-type, and if not empty and this tank can deliver it, then do so.
        if not found and fillable:getFillLevel(fillable.currentFillType) > 0 and self.modFillTypes[fillable.currentFillType] ~= nil then
            self.fillType = fillable.currentFillType;
            found = true
        end
        
        -- Check against the equipment's last-valid-fill-type if this tank can deliver it.
        if not found and fillable.lastValidFillType ~= nil and self.modFillTypes[fillable.lastValidFillType] ~= nil then
            self.fillType = fillable.lastValidFillType;
            found = true
        end

        -- Else check against this tank's possible fill-types to see if the equipment will accept one of them.
        if not found then
            for _,otherFillType in pairs(self.modFillTypes) do
                if fillable:allowFillType(otherFillType,false) then
                    self.fillType = otherFillType;
                    found = true
                    break
                end
            end
        end

        -- Else fall back to the game-default of only one fill-type.
        if not found then
            self.fillType = self.modOrigFillType;
        end
    end

    return superFunc(self,fillable)
end
FillTrigger.getIsActivatable = Utils.overwrittenFunction(FillTrigger.getIsActivatable, soilmod_FillTrigger_getIsActivatable)
