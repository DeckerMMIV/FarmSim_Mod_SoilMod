--
-- Weeder  (based on Cultivator.LUA)
--
-- Note: Requires SoilMod v2.0.53 or higher!
--

Weeder = {};

function Weeder.initSpecialization()
    WorkArea.registerAreaType("weeder");
end;

function Weeder.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(WorkArea, specializations);
end;

function Weeder:preLoad(xmlFile)
    self.loadWorkAreaFromXML = Utils.overwrittenFunction(self.loadWorkAreaFromXML, Weeder.loadWorkAreaFromXML);
end

function Weeder:load(xmlFile)

    self.getDoGroundManipulation = Utils.overwrittenFunction(self.getDoGroundManipulation, Weeder.getDoGroundManipulation);
    self.doCheckSpeedLimit = Utils.overwrittenFunction(self.doCheckSpeedLimit, Weeder.doCheckSpeedLimit);
    self.getDirtMultiplier = Utils.overwrittenFunction(self.getDirtMultiplier, Weeder.getDirtMultiplier);

    if next(self.groundReferenceNodes) == nil then
        print("Warning: No ground reference nodes in  "..self.configFileName);
    end;

    if self.isClient then
        self.sampleWeeder = Utils.loadSample(xmlFile, {}, "vehicle.cultivatorSound", nil, self.baseDirectory);
    end;

    self.cultivatorDirectionNode = Utils.getNoNil(Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.cultivatorDirectionNode#index")), self.components[1].node);

    self.onlyActiveWhenLowered = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.onlyActiveWhenLowered#value"), true);

    self.aiTerrainDetailChannel1 = g_currentMission.sowingChannel;
    self.aiTerrainDetailChannel2 = g_currentMission.cultivatorChannel;
    self.aiTerrainDetailChannel3 = g_currentMission.ploughChannel;

    self.startActivationTimeout = 2000;
    self.startActivationTime = 0;

    self.weederHasGroundContact = false;
    self.doGroundManipulation = false;
    self.weederLimitToField = false;
    self.weederForceLimitToField = true;
    self.lastWeederArea = 0;

    self.isWeederSpeedLimitActive = false;

    self.showFieldNotOwnedWarning = false;

    self.weederGroundContactFlag = self:getNextDirtyFlag();
end;

function Weeder:delete()
    if self.isClient then
        Utils.deleteSample(self.sampleWeeder);
    end;
end;

function Weeder:readUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        self.weederHasGroundContact = streamReadBool(streamId);
        self.showFieldNotOwnedWarning = streamReadBool(streamId);
    end;
end;

function Weeder:writeUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        streamWriteBool(streamId, self.weederHasGroundContact);
        streamWriteBool(streamId, self.showFieldNotOwnedWarning);
    end;
end;

function Weeder:mouseEvent(posX, posY, isDown, isUp, button)
end;

function Weeder:keyEvent(unicode, sym, modifier, isDown)
end;

function Weeder:update(dt)
end;

function Weeder:updateTick(dt)
    self.isWeederSpeedLimitActive = false;
    if self:getIsActive() then
        self.lastWeederArea = 0;
        local showFieldNotOwnedWarning = false;

        if self.isServer then
            local hasGroundContact = self:getIsTypedWorkAreaActive(WorkArea.AREATYPE_WEEDER);
            if self.weederHasGroundContact ~= hasGroundContact then
                self:raiseDirtyFlags(self.weederGroundContactFlag);
                self.weederHasGroundContact = hasGroundContact;
            end;
        end;
        local hasGroundContact = self.weederHasGroundContact;

        self.doGroundManipulation = (hasGroundContact and (not self.onlyActiveWhenLowered or self:isLowered(false)) and self.startActivationTime <= g_currentMission.time);

        local foldAnimTime = self.foldAnimTime;
        if self.doGroundManipulation then
            self.isWeederSpeedLimitActive = true;
            if self.isServer then
                local workAreasSend, showWarning, _ = self:getTypedNetworkAreas(WorkArea.AREATYPE_WEEDER, true);
                showFieldNotOwnedWarning = showWarning;

                if table.getn(workAreasSend) > 0 then
                    local limitToField = self.weederLimitToField or self.weederForceLimitToField;
                    local limitGrassDestructionToField = self.weederLimitToField or self.weederForceLimitToField;
                    if not g_currentMission:getHasPermission("createFields", self:getOwner()) then
                        limitToField = true;
                        limitGrassDestructionToField = true;
                    end;

                    local dx,dy,dz = localDirectionToWorld(self.cultivatorDirectionNode, 0, 0, 1);
                    local angle = Utils.convertToDensityMapAngle(Utils.getYRotationFromDirection(dx, dz), g_currentMission.terrainDetailAngleMaxValue);

                    local realArea = WeederAreaEvent.runLocally(workAreasSend, limitToField, limitGrassDestructionToField, angle);
                    g_server:broadcastEvent(WeederAreaEvent:new(workAreasSend, limitToField, limitGrassDestructionToField, angle));

                    self.lastWeederArea = Utils.areaToHa(realArea, g_currentMission:getFruitPixelsToSqm()); -- 4096px are mapped to 2048m
                    g_currentMission.missionStats:updateStats("hectaresWorked", self.lastWeederArea);
                end;
            end;
            g_currentMission.missionStats:updateStats("workingDuration", dt/(1000*60));
        end

        if self.isClient then
            if self.doGroundManipulation and self:getLastSpeed() > 3 then
                if self:getIsActiveForSound() then
                    Utils.playSample(self.sampleWeeder, 0, 0, nil);
                end;
            else
                Utils.stopSample(self.sampleWeeder);
            end;
        end;

        if self.isServer then
            if showFieldNotOwnedWarning ~= self.showFieldNotOwnedWarning then
                self.showFieldNotOwnedWarning = showFieldNotOwnedWarning;
                self:raiseDirtyFlags(self.weederGroundContactFlag);
            end
        end
    end;

end;

function Weeder:draw()
    if self.showFieldNotOwnedWarning then
        g_currentMission:showBlinkingWarning(g_i18n:getText("You_dont_own_this_field"));
    end;
end;

function Weeder:onAttach(attacherVehicle)
    Weeder.onActivate(self);
    self.startActivationTime = g_currentMission.time + self.startActivationTimeout;
end;

function Weeder:onDetach()
    self.weederLimitToField = false;
end;

function Weeder:onEnter(isControlling)
    if isControlling then
        Weeder.onActivate(self);
    end;
end;

function Weeder:onActivate()
end;

function Weeder:onDeactivate()
    self.showFieldNotOwnedWarning = false;
end;

function Weeder:onDeactivateSounds()
    if self.isClient then
        Utils.stopSample(self.sampleWeeder, true);
    end;
end;

function Weeder:aiTurnOn()
    self.weederLimitToField = true;
end;

function Weeder:aiTurnOff()
    self.weederLimitToField = false;
end;

function Weeder:doCheckSpeedLimit(superFunc)
    local parent = true;
    if superFunc ~= nil then
        parent = superFunc(self);
    end

    return parent and self.isWeederSpeedLimitActive;
end;

function Weeder:getDoGroundManipulation(superFunc)
    if not self.doGroundManipulation then
        return false;
    end;

    if superFunc ~= nil then
        return superFunc(self, speedRotatingPart);
    end
    return true;
end;

--function Weeder:getIsReadyToSpray(superFunc)
--    local isReadyToSpray = true;
--    if superFunc ~= nil then
--        isReadyToSpray = isReadyToSpray and superFunc(self);
--    end;
--
--    isReadyToSpray = isReadyToSpray and self.doGroundManipulation;
--
--    return isReadyToSpray;
--end;

function Weeder:getDirtMultiplier(superFunc)
    local multiplier = 0;
    if superFunc ~= nil then
        multiplier = multiplier + superFunc(self);
    end;

    if self.doGroundManipulation then
        multiplier = multiplier + self.workMultiplier * self:getLastSpeed() / self.speedLimit;
    end;

    return multiplier;
end;

function Weeder:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
    local retValue = true;
    if superFunc ~= nil then
        retValue = superFunc(self, workArea, xmlFile, key)
    end

    if workArea.type == WorkArea.AREATYPE_DEFAULT then
        workArea.type = WorkArea.AREATYPE_WEEDER;
    end;

    return retValue;
end;

function Weeder.getDefaultSpeedLimit()
    return 20;
end;

--
-- WeederAreaEvent  (based on CultivatorAreaEvent.LUA)
--


WeederAreaEvent = {};
WeederAreaEvent_mt = Class(WeederAreaEvent, Event);

InitEventClass(WeederAreaEvent, "WeederAreaEvent");

function WeederAreaEvent:emptyNew()
    local self = Event:new(WeederAreaEvent_mt);
    return self;
end;

function WeederAreaEvent:new(workAreas, limitToField, limitGrassDestructionToField, angle)
    local self = WeederAreaEvent:emptyNew()
    assert(table.getn(workAreas) > 0);
    self.workAreas = workAreas;
    self.limitToField = limitToField;
    self.limitGrassDestructionToField = Utils.getNoNil(limitGrassDestructionToField, limitToField);
    self.angle = angle;
    return self;
end;

function WeederAreaEvent:readStream(streamId, connection)
    local limitToField = streamReadBool(streamId);
    local limitGrassDestructionToField = streamReadBool(streamId);
    local angle = nil;
    if streamReadBool(streamId) then
        angle = streamReadUIntN(streamId, g_currentMission.terrainDetailAngleNumChannels);
    end
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
        Utils.updateWeederArea(x, z, x1, z1, x2, z2, not limitToField, not limitGrassDestructionToField, angle);
    end;
end;


function WeederAreaEvent:writeStream(streamId, connection)
    local numAreas = table.getn(self.workAreas);
    streamWriteBool(streamId, self.limitToField);
    streamWriteBool(streamId, self.limitGrassDestructionToField);
    if streamWriteBool(streamId, self.angle ~= nil) then
        streamWriteUIntN(streamId, self.angle, g_currentMission.terrainDetailAngleNumChannels);
    end
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

function WeederAreaEvent:run(connection)
    print("Error: Do not run WeederAreaEvent locally");
end;

function WeederAreaEvent.runLocally(workAreas, limitToField, limitGrassDestructionToField, angle)

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

    local areaSum = 0;
    for i=1, numAreas do
        local vi = i-1;
        local x = values[vi*3+1].x;
        local z = values[vi*3+1].y;
        local x1 = values[vi*3+2].x;
        local z1 = values[vi*3+2].y;
        local x2 = values[vi*3+3].x;
        local z2 = values[vi*3+3].y;
        areaSum = areaSum + Utils.updateWeederArea(x, z, x1, z1, x2, z2, not limitToField, not limitGrassDestructionToField, angle); -- TODO: this does not return the effectively worked area
    end;

    return areaSum;
end;
