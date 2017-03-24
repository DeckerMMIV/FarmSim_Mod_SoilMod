--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-03-xx
--

--
soilmod.soilModFillTypes = nil

function soilmod:preSetupSprayers()
    --soilmod:setKeyAttrValue("customSettings", "sprayTypeChangeMethod", "")
end

function soilmod:setupSprayers()
    -- Enhance functionality, so a sprayer 'fillType' can be changed
    soilmod:overwriteFillableAndSprayer()
    soilmod:overwriteSprayerAreas()
end

--
--

-- Event to change the currentFillType --
ChangeFillTypeEvent = {};
ChangeFillTypeEvent_mt = Class(ChangeFillTypeEvent, Event);

InitEventClass(ChangeFillTypeEvent, "ChangeFillTypeEvent");

function ChangeFillTypeEvent:emptyNew()
    local self = Event:new(ChangeFillTypeEvent_mt);
    self.className="ChangeFillTypeEvent";
    return self;
end;

function ChangeFillTypeEvent:new(vehicle, action)
    local self = ChangeFillTypeEvent:emptyNew()
    self.vehicle = vehicle;
    self.action = action;
    return self;
end;

function ChangeFillTypeEvent:readStream(streamId, connection)
    self.vehicle = networkGetObject(streamReadInt32(streamId));
    self.action  = streamReadInt8(streamId);
    self:run(connection);
end;

function ChangeFillTypeEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, networkGetObjectId(self.vehicle));
    streamWriteInt8(streamId, self.action);
end;

function ChangeFillTypeEvent:run(connection)
    if self.vehicle ~= nil then
        Sprayer.sm3ChangeFillType(self.vehicle, self.action, connection:getIsServer());
    end
end;

function ChangeFillTypeEvent.sendEvent(vehicle, action, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(ChangeFillTypeEvent:new(vehicle, action), nil, nil, vehicle);
        else
            g_client:getServerConnection():sendEvent(ChangeFillTypeEvent:new(vehicle, action));
        end;
    end;
end;

--
--

function soilmod:getSoilModFillTypes(fillTypes)
    fillTypes = Utils.getNoNil(fillTypes, {})

    if FillUtil.FILLTYPE_FERTILIZER  then table.insert(fillTypes, FillUtil.FILLTYPE_FERTILIZER ); end;
    if FillUtil.FILLTYPE_FERTILIZER2 then table.insert(fillTypes, FillUtil.FILLTYPE_FERTILIZER2); end;
    if FillUtil.FILLTYPE_FERTILIZER3 then table.insert(fillTypes, FillUtil.FILLTYPE_FERTILIZER3); end;
  --if FillUtil.FILLTYPE_FERTILIZER4 then table.insert(fillTypes, FillUtil.FILLTYPE_FERTILIZER4); end;
  --if FillUtil.FILLTYPE_FERTILIZER5 then table.insert(fillTypes, FillUtil.FILLTYPE_FERTILIZER5); end;
  --if FillUtil.FILLTYPE_FERTILIZER6 then table.insert(fillTypes, FillUtil.FILLTYPE_FERTILIZER6); end;

    if FillUtil.FILLTYPE_LIQUIDFERTILIZER  then table.insert(fillTypes, FillUtil.FILLTYPE_LIQUIDFERTILIZER ); end;
    if FillUtil.FILLTYPE_LIQUIDFERTILIZER2 then table.insert(fillTypes, FillUtil.FILLTYPE_LIQUIDFERTILIZER2); end;
    if FillUtil.FILLTYPE_LIQUIDFERTILIZER3 then table.insert(fillTypes, FillUtil.FILLTYPE_LIQUIDFERTILIZER3); end;
  
    if FillUtil.FILLTYPE_HERBICIDE   then table.insert(fillTypes, FillUtil.FILLTYPE_HERBICIDE  ); end;
    if FillUtil.FILLTYPE_HERBICIDE2  then table.insert(fillTypes, FillUtil.FILLTYPE_HERBICIDE2 ); end;
    if FillUtil.FILLTYPE_HERBICIDE3  then table.insert(fillTypes, FillUtil.FILLTYPE_HERBICIDE3 ); end;
  --if FillUtil.FILLTYPE_HERBICIDE4  then table.insert(fillTypes, FillUtil.FILLTYPE_HERBICIDE4 ); end;
  --if FillUtil.FILLTYPE_HERBICIDE5  then table.insert(fillTypes, FillUtil.FILLTYPE_HERBICIDE5 ); end;
  --if FillUtil.FILLTYPE_HERBICIDE6  then table.insert(fillTypes, FillUtil.FILLTYPE_HERBICIDE6 ); end;

    if FillUtil.FILLTYPE_KALK        then table.insert(fillTypes, FillUtil.FILLTYPE_KALK       ); end;
    if FillUtil.FILLTYPE_WATER       then table.insert(fillTypes, FillUtil.FILLTYPE_WATER      ); end;
    if FillUtil.FILLTYPE_WATER2      then table.insert(fillTypes, FillUtil.FILLTYPE_WATER2     ); end;

    if FillUtil.FILLTYPE_PLANTKILLER then table.insert(fillTypes, FillUtil.FILLTYPE_PLANTKILLER); end;
--[[
    -- Broadcast spreader
    if FillUtil.FILLTYPE_RAPE        then table.insert(fillTypes, FillUtil.FILLTYPE_RAPE       ); end;
    if FillUtil.FILLTYPE_CLOVER      then table.insert(fillTypes, FillUtil.FILLTYPE_CLOVER     ); end;
    if FillUtil.FILLTYPE_ALFALFA     then table.insert(fillTypes, FillUtil.FILLTYPE_ALFALFA    ); end;
    if FillUtil.FILLTYPE_LUZERNE     then table.insert(fillTypes, FillUtil.FILLTYPE_LUZERNE    ); end;
--]]    
    return fillTypes
end

function soilmod:isSoilModFillType(fillType)
    if self.soilModFillTypes == nil then
        self.soilModFillTypes = {}
        local fillTypes = self:getSoilModFillTypes();
        for _,fType in pairs(fillTypes) do
            self.soilModFillTypes[fType] = true;
        end
    end
    return self.soilModFillTypes[fillType]
end

function soilmod:overwriteFillableAndSprayer()
    -- Due to the vanilla sprayers can only spray one type of 'fertilizer', this 
    -- modification will force addition of extra fill-types to be sprayed.
    logInfo("Prepending to Fillable.postLoad, for adding extra fill-types")
    Fillable.postLoad = Utils.prependedFunction(Fillable.postLoad, function(self, savegame)
        -- Only consider tools that can spread/spray
        if not SpecializationUtil.hasSpecialization(Sprayer, self.specializations) then
            return
        end

        local fillUnitsSolid  = self:getFillUnitsWithFillType(FillUtil.FILLTYPE_FERTILIZER) 
        local fillUnitsLiquid = self:getFillUnitsWithFillType(FillUtil.FILLTYPE_LIQUIDFERTILIZER) 
        
        local addFillTypes = {}
        local fillUnit = nil
        local reason = ""
        
        if #fillUnitsSolid > 0 then
            reason = "(solid spreader)"
            fillUnit = fillUnitsSolid[1]
            
            if SpecializationUtil.hasSpecialization(SowingMachine, self.specializations) then    
                addFillTypes = {
                    FillUtil.FILLTYPE_FERTILIZER,
                    FillUtil.FILLTYPE_FERTILIZER2,
                    FillUtil.FILLTYPE_FERTILIZER3,
                }
            else
                addFillTypes = {
                    FillUtil.FILLTYPE_FERTILIZER,
                    FillUtil.FILLTYPE_FERTILIZER2,
                    FillUtil.FILLTYPE_FERTILIZER3,
                    FillUtil.FILLTYPE_KALK,                    
                }
--[[                    
                -- Broadcast spreader
                FillUtil.FILLTYPE_RAPE,
                FillUtil.FILLTYPE_CLOVER,
                FillUtil.FILLTYPE_ALFALFA,
                FillUtil.FILLTYPE_LUZERNE,
--]]                    
            end
            
            --if self.allowFillFromAir == false then
            --    logInfo(self.name," - Changing allow-fill-from-air to 'true' (solid spreader",reason,")")
            --    self.allowFillFromAir = true;
            --elseif self.fillRootNode == nil then
            --    log(self.name," - not possible to allow-fill-from-air, due to fillRootNode==nil")
            --elseif self.allowFillFromAir == nil then
            --    log(self.name," - not possible to allow-fill-from-air, due to allowFillFromAir==nil")
            --end
        elseif #fillUnitsLiquid > 0 then
            reason = "(liquid sprayer)"
            fillUnit = fillUnitsLiquid[1]
            
            if SpecializationUtil.hasSpecialization(SowingMachine, self.specializations) then    
                addFillTypes = {
                    FillUtil.FILLTYPE_LIQUIDFERTILIZER,
                    FillUtil.FILLTYPE_LIQUIDFERTILIZER2,
                    FillUtil.FILLTYPE_LIQUIDFERTILIZER3,
                }
            else
                addFillTypes = {
                    FillUtil.FILLTYPE_LIQUIDFERTILIZER,
                    FillUtil.FILLTYPE_LIQUIDFERTILIZER2,
                    FillUtil.FILLTYPE_LIQUIDFERTILIZER3,
                    FillUtil.FILLTYPE_HERBICIDE,
                    FillUtil.FILLTYPE_HERBICIDE2,
                    FillUtil.FILLTYPE_HERBICIDE3,
                    FillUtil.FILLTYPE_PLANTKILLER,
                    FillUtil.FILLTYPE_WATER,
                    FillUtil.FILLTYPE_WATER2,
                }
            end
        end

        if fillUnit ~= nil then
            logInfo("Adding ",#addFillTypes," filltype(s) to fill-unit #",fillUnit.fillUnitIndex," ",reason)
            self.soilModSprayer = true
        
            for _,fillType in pairs(addFillTypes) do
                if fillType then
                    fillUnit.fillTypes[fillType] = true
                end
            end
        end
    end);

--[[    
    logInfo("Creating Sprayer.soilModAllowFillType (TODO!)")
    Sprayer.soilModAllowFillType = function(self, superFunc, fillType, allowEmptying)
        local result = superFunc(self, fillType, allowEmptying);
        
-- TODO
        --if false == result then
        --    -- Recheck, to ensure ability to switch spray-type
        --    local foundFillUnit = nil
        --    for i,fillUnit in pairs(self.fillUnits) do
        --        if fillUnit.fillTypes[fillType] then
        --            foundFillUnit = fillUnit
        --            break
        --        end
        --    end
        --    if foundFillUnit then
        --        if fillUnit.fillLevel > fillUnit.capacity*self.fillTypeChangeThreshold then
        --            -- It was disallowed due to current fillLevel higher than threshold.
        --            local fillTypeGroups = {}
        --            fillTypeGroups[FillUtil.FILLTYPE_FERTILIZER] = {}
        --        end
        --    end
        --end
        
        return result
    end
    
    logInfo("Appending functionality to Sprayer.postLoad")
    Sprayer.postLoad = Utils.appendedFunction(Sprayer.postLoad, function(self)
        self.allowFillType = Utils.overwrittenFunction(self.allowFillType, Sprayer.soilModAllowFillType);
    end);
--]]    

    ---- Set up spray usage.
    --logInfo("Appending to Sprayer.postLoad, to set spray-usages for spray-types - incl. fix for mrLight mod.")
    --Sprayer.postLoad = Utils.appendedFunction(Sprayer.postLoad, function(self)
    --    if not self.sprayLitersPerSecond or self.defaultSprayLitersPerSecond == 0 then
    --        return
    --    end
    --    --
    --    local baseLPS = math.max(Utils.getNoNil(self.sprayLitersPerSecond[FillUtil.FILLTYPE_FERTILIZER], self.defaultSprayLitersPerSecond), 0.01)
    --    local factorSqm = baseLPS / math.max(Utils.getNoNil(Sprayer.sprayTypeIndexToDesc[Sprayer.SPRAYTYPE_FERTILIZER].litersPerSqmPerSecond, 0), 1)
    --    log(self.name,": base-LPS=",baseLPS," (factor ",factorSqm,")")
    --    
    --    for fillType,accepted in pairs(self.fillTypes) do
    --        --log("  ft=",fillType," ",FillUtil.fillTypeIntToName[fillType]," / sp=",Sprayer.fillTypeToSprayType[fillType])
    --        if accepted and fillType ~= FillUtil.FILLTYPE_UNKNOWN and Sprayer.fillTypeToSprayType[fillType] ~= nil then
    --            if Utils.getNoNil(self.sprayLitersPerSecond[fillType], 0) == 0 then
    --                local sprayType = Sprayer.fillTypeToSprayType[fillType]
    --                self.sprayLitersPerSecond[fillType] = factorSqm * Sprayer.sprayTypeIndexToDesc[sprayType].litersPerSqmPerSecond
    --                log(self.name,": forced liters-per-sec for ",FillUtil.fillTypeIntToName[fillType],"=",self.sprayLitersPerSecond[fillType])
    --            else
    --                log(self.name,": exist  liters-per-sec for ",FillUtil.fillTypeIntToName[fillType],"=",self.sprayLitersPerSecond[fillType])
    --            end
    --        end
    --    end
    --    
    --    -- Work-around for 'mrLight' to make it "not fail"
    --    if self.sprayLitersPerHectare ~= nil then
    --        for fillType,accepted in pairs(self.fillTypes) do
    --            if accepted and fillType ~= FillUtil.FILLTYPE_UNKNOWN then
    --                if self.sprayLitersPerHectare[fillType] == nil then
    --                    self.sprayLitersPerHectare[fillType] = self.sprayLitersPerHectare[FillUtil.FILLTYPE_FERTILIZER]
    --                end
    --            end
    --        end
    --    end
    --end);

    -- Add possibility to 'change fill-type'.
    Sprayer.soilModAllowChangeFillType = function(self)
        local changeMethod = soilmod:getKeyAttrValue("customSettings", "sprayTypeChangeMethod", "Anywhere")
        changeMethod = changeMethod:lower()
        ----
        if changeMethod == "everywhere" 
        or changeMethod == "anywhere" 
        or changeMethod == "always" 
        or changeMethod == "vanilla"
        then
            -- Always possible
            logInfo("Switching spray-type is possible anywhere.")
            Sprayer.soilModAllowChangeFillType = function(self, showHint)
                return true == self.soilModSprayer;
            end;
        else
            -- Only near fertilizer tanks (SoilMod default)
            logInfo("Switching spray-type will only be possible near a fertilizer-tank.")
            Sprayer.soilModAllowChangeFillType = function(self, showHint)
                return true == self.soilModSprayer and (not self.isFilling) and (table.getn(self.fillTriggers) > 0);
            end;
        end
        return false;
    end

    -- TODO: This should be changed, once there are better support for spreaders/sprayers fill-types, and stations in maps where to refill.
    Sprayer.soilModChangeFillType = function(self, newFillType, noEventSend)
        -- Only the server can determine what the next currentFillType should be
        -- 'Next available fillType' = -1 (yes, its a "magic number")
        if newFillType == -1 then
            if g_server ~= nil then
                local nextTypes = soilmod:getSoilModFillTypes()
                for i,fillType in ipairs(nextTypes) do
                    local fullUnits = self:getFillUnitsWithFillType(fillType)
                    local fillUnit = fullUnits[1]
                    if fillUnit ~= nil and fillType == fillUnit.currentFillType then
                        for k=0,table.getn(nextTypes) do
                            i = (i % table.getn(nextTypes))+1
                            if nextTypes[i] and fillUnit.fillTypes[nextTypes[i]] then
                                newFillType = nextTypes[i]
                                break
                            end
                        end
                        break
                    end
                end
            end
        end
        if newFillType >= 0 then
            if self.isServer then
                local fullUnits = self:getFillUnitsWithFillType(newFillType)
                local fillUnit = fullUnits[1]
                if fillUnit ~= nil then
                    -- Adjust money, if possible
                    local oldPrice=0
                    local newPrice=0
                    if fillUnit.currentFillType ~= FillUtil.FILLTYPE_UNKNOWN then
                        oldPrice = (FillUtil.fillTypeIndexToDesc[fillUnit.currentFillType].pricePerLiter * fillUnit.fillLevel)
                    end
                    if newFillType ~= FillUtil.FILLTYPE_UNKNOWN then
                        newPrice = (FillUtil.fillTypeIndexToDesc[newFillType].pricePerLiter * fillUnit.fillLevel)
                    end
                    local priceDiff = oldPrice - newPrice
                    if priceDiff ~= 0 then
                        g_currentMission:addSharedMoney(priceDiff, "other")
                    end
                    
                    self:setUnitFillLevel(fillUnit.fillUnitIndex, fillUnit.fillLevel, newFillType, true)
                    
                    log("Changed fill-unit's currentFillType to: ",FillUtil.fillTypeIntToName[fillUnit.currentFillType],"(",fillUnit.currentFillType,")"
                        --,", spray-usage: ",self.sprayLitersPerSecond[self.currentFillType]
                        --,", default: ",self.defaultSprayLitersPerSecond
                    );
                else
                    log("No corresponding fill-unit for fill-type; ",newFillType)
                end
            end
        end
        --
        ChangeFillTypeEvent.sendEvent(self, newFillType, noEventSend)
    end
    
    logInfo("Appending to Sprayer.update, to let player change fill-type")
    Sprayer.update = Utils.appendedFunction(Sprayer.update, function(self, dt)
        if self.isClient then
            if  (self.allowsSpraying or self.isSprayerTank) 
            then
                if  InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA4)
                and self:getIsActiveForInput(true) 
                then
                    if Sprayer.soilModAllowChangeFillType(self, true) then
                        Sprayer.soilModChangeFillType(self, -1) -- 'Next available fillType' = -1 (yes, its a "magic number")
                    else
                        if self.isFilling then
                            g_currentMission:showBlinkingWarning(g_i18n:getText("NotWhileRefilling"), 2000)
                        else
                            g_currentMission:showBlinkingWarning(g_i18n:getText("OnlyNearSprayerFillTrigger"), 2000)
                        end
                    end;
                end
            end;
        end;
    end);

    logInfo("Appending to Sprayer.draw, to draw action in F1 help box");
    Sprayer.draw = Utils.appendedFunction(Sprayer.draw, function(self)
        if self.isClient then
            if  Sprayer.soilModAllowChangeFillType(self)
            and self:getIsActiveForInput(true) 
            then
                g_currentMission:addHelpButtonText(g_i18n:getText("SelectSprayType"), InputBinding.IMPLEMENT_EXTRA4, nil, GS_PRIO_NORMAL)
            end
        end
    end);
end

function soilmod:overwriteSprayerAreas()
    logInfo("Overwriting Sprayer.processSprayerAreas function, so 'fillType' is also given to Utils.updateSprayArea().")

    Sprayer.processSprayerAreas = function(self, workAreas, fillType)
        local sprayType = 1
        if fillType == FillUtil.FILLTYPE_MANURE then
            sprayType = 2
        end
        local totalPixels = 0
        local numAreas = table.getn(workAreas)
        for i=1, numAreas do
            local x = workAreas[i][1]
            local z = workAreas[i][2]
            local x1 = workAreas[i][3]
            local z1 = workAreas[i][4]
            local x2 = workAreas[i][5]
            local z2 = workAreas[i][6]
    
            local pixels, pixelsTotal        
            if self.cultivatorGroundContactFlag ~= nil and self.sowingMachineGroundContactFlag == nil then
              --pixels, pixelsTotal = Utils.updateSprayArea(x, z, x1, z1, x2, z2, g_currentMission.cultivatorValue, sprayType)
                pixels, pixelsTotal = Utils.updateSprayArea(x, z, x1, z1, x2, z2, g_currentMission.cultivatorValue, sprayType, fillType)
            else
              --pixels, pixelsTotal = Utils.updateSprayArea(x, z, x1, z1, x2, z2, nil, sprayType)
                pixels, pixelsTotal = Utils.updateSprayArea(x, z, x1, z1, x2, z2, nil, sprayType, fillType)
            end
            totalPixels = totalPixels + pixels
        end
        return totalPixels
    end
end
