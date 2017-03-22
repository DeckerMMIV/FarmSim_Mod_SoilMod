--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-01-xx
--

sm3ModifySprayers = {}

--
function sm3ModifySprayers.preSetup()
    --sm3Settings.setKeyAttrValue("customSettings", "sprayTypeChangeMethod", "")
end

function sm3ModifySprayers.setup()
    if not sm3ModifySprayers.initialized then
        sm3ModifySprayers.initialized = true
        -- Change functionality, so 'fillType' is also used/sent.
        --sm3ModifySprayers.overwriteSprayerAreaEvent()
        sm3ModifySprayers.overwriteSprayer1()
        --sm3ModifySprayers.overwriteSprayer2()
        --sm3ModifySprayers.overwriteSprayer3()
        sm3ModifySprayers.overwriteSprayer4()
    end
    --
    sm3ModifySprayers.soilModFillTypes = nil;    
end

--
function sm3ModifySprayers.teardown()
end


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

--[[
function sm3ModifySprayers.overwriteSprayerAreaEvent()
    logInfo("Overwriting SprayerAreaEvent functions, to take extra argument; 'augmentedFillType'.")
  
    SprayerAreaEvent.new = function(self, workAreas
    -- Decker_MMIV >>
        , augmentedFillType
    -- << Decker_MMIV
    )
        local self = SprayerAreaEvent:emptyNew()
        self.workAreas = workAreas;
    -- Decker_MMIV >>
        -- Fix "adjustment" for not being able to access the internals of Sprayer.updateTick() method.
        if augmentedFillType == nil then
            augmentedFillType = Utils.getNoNil(SprayerAreaEvent.sm3SprayerCurrentFillType, FillUtil.FILLTYPE_UNKNOWN)
        end
        self.augmentedFillType = augmentedFillType
    -- << Decker_MMIV
        return self;
    end;
    
    SprayerAreaEvent.readStream = function(self, streamId, connection)
    -- Decker_MMIV >>
        local augmentedFillType = streamReadUIntN(streamId, sm3SoilMod.fillTypeSendNumBits)
    -- << Decker_MMIV
        local numAreas = streamReadUIntN(streamId, 4);
        local refX = streamReadFloat32(streamId);
        local refY = streamReadFloat32(streamId);
        local values = Utils.readCompressed2DVectors(streamId, refX, refY, numAreas*3-1, 0.01, true);
        for i=1,numAreas do
            local vi = i-1;
            local x = values[vi*3+1].x;
            local z = values[vi*3+1].y;
            local x1 = values[vi*3+2].x;
            local z1 = values[vi*3+2].y;
            local x2 = values[vi*3+3].x;
            local z2 = values[vi*3+3].y;
    -- Decker_MMIV >>
            -- Utils.updateSprayArea(x, z, x1, z1, x2, z2);
            Utils.updateSprayArea(x, z, x1, z1, x2, z2, augmentedFillType);
    -- << Decker_MMIV
        end;
    end;
    
    SprayerAreaEvent.writeStream = function(self, streamId, connection)
    -- Decker_MMIV >>
        streamWriteUIntN(streamId, self.augmentedFillType, sm3SoilMod.fillTypeSendNumBits)
    -- << Decker_MMIV
        local numAreas = table.getn(self.workAreas);
        streamWriteUIntN(streamId, numAreas, 4);
        local refX, refY;
        local values = {};
        for i=1, numAreas do
            local d = self.workAreas[i];
            if i==1 then
                refX = d[1];
                refY = d[2];
                streamWriteFloat32(streamId, d[1]);
                streamWriteFloat32(streamId, d[2]);
            else
                table.insert(values, {x=d[1], y=d[2]});
            end;
            table.insert(values, {x=d[3], y=d[4]});
            table.insert(values, {x=d[5], y=d[6]});
        end;
        assert(table.getn(values) == numAreas*3 - 1);
        Utils.writeCompressed2DVectors(streamId, refX, refY, values, 0.01);
    end;
    
    SprayerAreaEvent.runLocally = function(workAreas
    -- Decker_MMIV >>
        , augmentedFillType
    -- << Decker_MMIV
    )
    -- Decker_MMIV >>
        -- Fix "adjustment" for not being able to access the internals of Sprayer.updateTick() method.
        if augmentedFillType == nil then
            augmentedFillType = Utils.getNoNil(SprayerAreaEvent.sm3SprayerCurrentFillType, FillUtil.FILLTYPE_UNKNOWN)
        end
    -- << Decker_MMIV
        local numAreas = table.getn(workAreas);
        local refX, refY;
        local values = {};
        for i=1, numAreas do
            local d = workAreas[i];
            if i==1 then
                refX = d[1];
                refY = d[2];
            else
                table.insert(values, {x=d[1], y=d[2]});
            end;
            table.insert(values, {x=d[3], y=d[4]});
            table.insert(values, {x=d[5], y=d[6]});
        end;
        assert(table.getn(values) == numAreas*3 - 1);
    
        local values = Utils.simWriteCompressed2DVectors(refX, refY, values, 0.01, true);
    
        for i=1, numAreas do
            local vi = i-1;
            local x = values[vi*3+1].x;
            local z = values[vi*3+1].y;
            local x1 = values[vi*3+2].x;
            local z1 = values[vi*3+2].y;
            local x2 = values[vi*3+3].x;
            local z2 = values[vi*3+3].y;
    -- Decker_MMIV >>
            -- Utils.updateSprayArea(x, z, x1, z1, x2, z2);
            Utils.updateSprayArea(x, z, x1, z1, x2, z2, augmentedFillType);
    -- << Decker_MMIV
        end;
    end;
end
--]]


function sm3ModifySprayers.getSoilModFillTypes(fillTypes)
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


function sm3ModifySprayers.isSoilModFillType(fillType)
    if not sm3ModifySprayers.soilModFillTypes then
        sm3ModifySprayers.soilModFillTypes = {}
        local fillTypes = sm3ModifySprayers.getSoilModFillTypes();
        for _,fType in pairs(fillTypes) do
            sm3ModifySprayers.soilModFillTypes[fType] = true;
        end
    end
    return sm3ModifySprayers.soilModFillTypes[fillType];
end

function sm3ModifySprayers.overwriteSprayer1()

    -- Due to the vanilla sprayers only spray 'fertilizer', this modification will
    -- force addition of extra fill-types to be sprayed.
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
            
            addFillTypes = {
                FillUtil.FILLTYPE_FERTILIZER,
                FillUtil.FILLTYPE_FERTILIZER2,
                FillUtil.FILLTYPE_FERTILIZER3,
            }
            
            if not SpecializationUtil.hasSpecialization(SowingMachine, self.specializations) then    
                table.insert(addFillTypes, FillUtil.FILLTYPE_KALK)
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

        if fillUnit ~= nil then
            logInfo("Adding ",#addFillTypes," filltype(s) to fill-unit #",fillUnit.fillUnitIndex," ",reason)
            self.sm3Sprayer = true
        
            for _,fillType in pairs(addFillTypes) do
                if fillType then
                    fillUnit.fillTypes[fillType] = true
                end
            end
        end
    end);

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
    Sprayer.sm3AllowChangeFillType = function(self)
        local changeMethod = sm3Settings.getKeyAttrValue("customSettings", "sprayTypeChangeMethod", "")
        --if changeMethod == "" then
        --    changeMethod = "NearFertilizerTank"
        --    sm3Settings.setKeyAttrValue("customSettings", "sprayTypeChangeMethod", changeMethod)
        --end
        changeMethod = changeMethod:lower()
        ----
        if changeMethod == "everywhere" 
        or changeMethod == "anywhere" 
        or changeMethod == "always" 
        or changeMethod == "vanilla"
        or changeMethod == ""
        then
            -- Always possible
            logInfo("Switching spray-type is possible anywhere.")
            Sprayer.sm3AllowChangeFillType = function(self, showHint) return self.sm3Sprayer == true; end;
        --elseif changeMethod == "nearfertilizertank"
        --or     changeMethod == "neartank"
        --or     changeMethod == "default"
        --or     changeMethod == "soilmod"
        --or     changeMethod == "restrictive"
        --then
        else
          -- Only near fertilizer tanks (SoilMod default)
          logInfo("Switching spray-type will only be possible near a fertilizer-tank.")
          Sprayer.sm3AllowChangeFillType = function(self, showHint) return self.sm3Sprayer == true and (not self.isFilling) and (table.getn(self.fillTriggers) > 0); end;
        --else
        --    -- Never possible
        --    log("Switching spray-type has a wrong value for 'sprayTypeChangeMethod'.")
        --    Sprayer.sm3AllowChangeFillType = function(self, showHint)
        --        if showHint then
        --            g_currentMission.inGameMessage:showMessage(
        --                "SoilMod",
        --                g_i18n:getText("CustomSettingsError"):format("sprayTypeChangeMethod", tostring(changeMethod)),
        --                5000
        --            );
        --            return false;
        --        end
        --        return true;
        --    end;
        end
        return false;
    end

    -- TODO: This should be changed, once there are better support for spreaders/sprayers fill-types, and stations in maps where to refill.
    Sprayer.sm3ChangeFillType = function(self, newFillType, noEventSend)
        -- Only the server can determine what the next currentFillType should be
        -- 'Next available fillType' = -1 (yes, its a "magic number")
        if newFillType == -1 then
            if g_server ~= nil then
                local nextTypes = sm3ModifySprayers.getSoilModFillTypes()
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
                    if Sprayer.sm3AllowChangeFillType(self, true) then
                        Sprayer.sm3ChangeFillType(self, -1) -- 'Next available fillType' = -1 (yes, its a "magic number")
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
            if  Sprayer.sm3AllowChangeFillType(self)
            and self:getIsActiveForInput(true) 
            then
                g_currentMission:addHelpButtonText(g_i18n:getText("SelectSprayType"), InputBinding.IMPLEMENT_EXTRA4, nil, GS_PRIO_NORMAL)
            end
        end
    end);
end


--[[
function sm3ModifySprayers.overwriteSprayer2()
-- Due to requirement of 'fill-type' to be send to SprayerAreaEvent/Utils.updateSprayArea,
-- the sprayer's updateTick() function is "adjusted" in a 'this-needs-to-be-done-better-once-the-FS15-scripts-becomes-public' way.
-- ...
-- And now that the FS15 script documentation is available, it seems that there really isn't a better way, other than
-- re-implemeting the entire Sprayer.updateTick() again. So keeping this 'hack' as-is for now.

    logInfo("Prepending to Sprayer.updateTick function, so fill-type can be accessed by SprayerAreaEvent.")
    Sprayer.updateTick = Utils.prependedFunction(Sprayer.updateTick, 
        function(self, dt)
            -- Tell the SprayerAreaEvent what fill-type is currently "selected", since we can't access the internals of the updateTick() method.
            -- The first time the sprayer is turned on, it will probably change 'self.currentFillType'.
            -- Also: If the GIANTS game-engine suddently decides to execute scripts concurrently, this "adjustment" will most likely cause a race-condition.
            if self.currentFillType ~= FillUtil.FILLTYPE_UNKNOWN then
                SprayerAreaEvent.sm3SprayerCurrentFillType = 
                    self.currentFillType 
                    -- If solid-sprayer/spreader, then 'augment' the fill-type value
                    + ((true == self.sm3SprayerSolidMaterial) and sm3SoilMod.fillTypeAugmented or 0)
                    ;
            else
                -- Found someone mentioning a "bug" at http://steamcommunity.com/app/313160/discussions/0/451850020334333438/
                if self.lastValidFillType ~= FillUtil.FILLTYPE_UNKNOWN
                and self:getIsHired()
                then
                    SprayerAreaEvent.sm3SprayerCurrentFillType = 
                        self.lastValidFillType
                        -- If solid-sprayer/spreader, then 'augment' the fill-type value
                        + ((true == self.sm3SprayerSolidMaterial) and sm3SoilMod.fillTypeAugmented or 0)
                        ;
                end
            end
        end
    )
end
--]]
--[[
function sm3ModifySprayers.overwriteSprayer3()

    sm3ModifySprayers.getFirstEnabledFillType = function(self)
        local foundFillType = FillUtil.FILLTYPE_UNKNOWN
        if self.fillLevel > 0 or self.isSprayerTank then
            -- This sprayer (or sprayer-tank) is not empty, so do normal operation...
            for fillType, enabled in pairs(self.fillTypes) do
                if fillType ~= FillUtil.FILLTYPE_UNKNOWN and enabled then
                    foundFillType = fillType;
                    break
                end
            end
        else
            -- Attempt to locate a sprayer-tank's current-fill-type, by looping though all possible filltypes this sprayer has enabled
            local rootVehicle = self:getRootAttacherVehicle()
            for fillType, enabled in pairs(self.fillTypes) do
                if fillType ~= FillUtil.FILLTYPE_UNKNOWN and enabled then
                    if Sprayer.findAttachedSprayerTank(rootVehicle, fillType) ~= nil then
                        foundFillType = fillType;
                        break
                    end
                end
            end
        end

        -- Found someone mentioning a "bug" at http://steamcommunity.com/app/313160/discussions/0/451850020334333438/
        if  foundFillType == FillUtil.FILLTYPE_UNKNOWN 
        and self.lastValidFillType ~= FillUtil.FILLTYPE_UNKNOWN 
        then
            if self:getIsHired() then
                foundFillType = self.lastValidFillType
                --log("foundFillType=",foundFillType)
            end
        end

        ---- Tell the SprayerAreaEvent what fill-type is currently "selected", since we can't access the internals of the updateTick() method.
        ---- The first time the sprayer is turned on, it will probably change 'self.currentFillType'.
        ---- Also: If the GIANTS game-engine suddently decides to execute scripts concurrently, this "adjustment" will most likely cause a race-condition.
        --if true == self.sm3SprayerSolidMaterial -- If solid-sprayer/spreader, then 'augment' the fill-type value
        --or nil ~= self.cultivatorDirectionNode  -- Zunhammer Zunidisk fix: in case this sprayer also have the cultivator-specialization, then "augment" the fill-type value
        --then
        --    SprayerAreaEvent.sm3SprayerCurrentFillType = foundFillType + sm3SoilMod.fillTypeAugmented
        --else
        --    SprayerAreaEvent.sm3SprayerCurrentFillType = foundFillType
        --end

        return foundFillType;
    end

    logInfo("Appending to Sprayer.postLoad, for getting fill-type from sprayer-tanks.")
    Sprayer.postLoad = Utils.appendedFunction(Sprayer.postLoad, function(self, xmlFile)
        self.getFirstEnabledFillType = sm3ModifySprayers.getFirstEnabledFillType;
    end);

end
--]]

function sm3ModifySprayers.overwriteSprayer4()
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
