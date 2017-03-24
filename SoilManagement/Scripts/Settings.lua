--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-03-xx
--

soilmod.cfgKeys = {}
soilmod.cfgUser = {}

--
-- Callback method, to be used in loadMapFinished() in the map's SampleModMap.LUA (or whatever its renamed to)
--
modSoilMod.setCustomSetting = function(attrName, value)
    soilmod.cfgUser[tostring(attrName)] = value
end

--
function soilmod:updateCustomSettings()
    for attrName,value in pairs(self.cfgUser) do
        local savedValue = self:getKeyAttrValue("customSettings", attrName, nil)
        if savedValue == nil or savedValue == "" then
            -- No previous value in savegame, so set it.
            self:setKeyAttrValue("customSettings", attrName, value)
        end
    end
end

function soilmod:setKeyAttrValue(keyName, attrName, value)
    if not self.cfgKeys[keyName] then
        self.cfgKeys[keyName] = {}
    end
    self.cfgKeys[keyName][attrName] = value
end

function soilmod:getKeyAttrValue(keyName, attrName, defaultValue)
    if self.cfgKeys[keyName] then
        return Utils.getNoNil(self.cfgKeys[keyName][attrName], defaultValue)
    end
    return defaultValue
end

--
function soilmod:onLoadCareerSavegame(xmlFile, rootXmlKey)
    for keyName,attrs in pairs(self.cfgKeys) do
        local xmlKey = rootXmlKey.."."..keyName
        for attrName,value in pairs(attrs) do
            local xmlKeyAttr = xmlKey.."#"..attrName

            if type(value)=="boolean" then
                value = Utils.getNoNil(getXMLBool(xmlFile, xmlKeyAttr), value)
            elseif type(value)=="number" then
                value = Utils.getNoNil(getXMLFloat(xmlFile, xmlKeyAttr), value)
            else
                value = Utils.getNoNil(getXMLString(xmlFile, xmlKeyAttr), value)
            end
            
            self:setKeyAttrValue(keyName, attrName, value)
        end
    end
end

--
function soilmod:onSaveCareerSavegame(xmlFile, rootXmlKey)
    for keyName,attrs in pairs(self.cfgKeys) do
        local xmlKey = rootXmlKey.."."..keyName
        for attrName,value in pairs(attrs) do
            local xmlKeyAttr = xmlKey.."#"..attrName

            if type(value)=="boolean" then
                setXMLBool(xmlFile, xmlKeyAttr, value)
            elseif type(value)=="number" then
                if math.floor(value) == math.ceil(value) then
                    setXMLInt(xmlFile, xmlKeyAttr, value)
                else
                    setXMLFloat(xmlFile, xmlKeyAttr, value)
                end
            else
                setXMLString(xmlFile, xmlKeyAttr, tostring(value))
            end
        end
    end
end

--
function soilmod:loadFromSavegame()
    if g_currentMission ~= nil and g_currentMission:getIsServer() then
        if g_currentMission.missionInfo.isValid then
            local fileName = g_currentMission.missionInfo.savegameDirectory .. "/careerSavegame.xml"
    
            local xmlFile = loadXMLFile("xml", fileName);
            if xmlFile ~= nil then
                local xmlKey = "careerSavegame"
                self:onLoadCareerSavegame(xmlFile, xmlKey..".modsSettings.SoilMod")
                delete(xmlFile);
            end
        end
    end
end

-- Working in the blind here... Hoping 'FSCareerMissionInfo.saveToXML' is the same in FS15, as it was in FS2013.
FSCareerMissionInfo.saveToXML = Utils.prependedFunction(FSCareerMissionInfo.saveToXML, function(self)
    if soilmod.enabled and self.isValid and self.xmlKey ~= nil then
        -- Apparently FSCareerMissionInfo's 'xmlFile' variable isn't always assigned, previous to it calling saveToXml()?
        if self.xmlFile ~= nil then
            soilmod:onSaveCareerSavegame(self.xmlFile, self.xmlKey..".modsSettings.SoilMod")
        else
            g_currentMission.inGameMessage:showMessage("SoilMod", g_i18n:getText("SaveFailed"), 10000);
        end
    end
end);
