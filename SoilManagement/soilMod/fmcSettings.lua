--
--  The Soil Management and Growth Control Project - version 2 (FS15)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modhoster.com
-- @date    2015-01-xx
--

fmcSettings = {}
fmcSettings.keys = {}

function fmcSettings.setKeyAttrValue(keyName, attrName, value)
    if not fmcSettings.keys[keyName] then
        fmcSettings.keys[keyName] = {}
    end
    fmcSettings.keys[keyName][attrName] = value
end

function fmcSettings.getKeyAttrValue(keyName, attrName, defaultValue)
    if fmcSettings.keys[keyName] then
        return Utils.getNoNil(fmcSettings.keys[keyName][attrName], defaultValue)
    end
    return defaultValue
end

--
function fmcSettings.onLoadCareerSavegame(xmlFile, rootXmlKey)
    --
    for keyName,attrs in pairs(fmcSettings.keys) do
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
            
            fmcSettings.setKeyAttrValue(keyName, attrName, value)
        end
    end
    --
    fmcGrowthControl.loadBatchActions(xmlFile, rootXmlKey)
end

--
function fmcSettings.onSaveCareerSavegame(xmlFile, rootXmlKey)
    --
    for keyName,attrs in pairs(fmcSettings.keys) do
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
    --
    fmcGrowthControl.saveBatchActions(xmlFile, rootXmlKey)
end

--
function fmcSettings.loadFromSavegame()
    if g_currentMission ~= nil and g_currentMission:getIsServer() then
        if g_currentMission.missionInfo.isValid then
            local fileName = g_currentMission.missionInfo.savegameDirectory .. "/careerSavegame.xml"
    
            local xmlFile = loadXMLFile("xml", fileName);
            if xmlFile ~= nil then
                local xmlKey = "careerSavegame"
                fmcSettings.onLoadCareerSavegame(xmlFile, xmlKey..".modsSettings.fmcSoilMod")
                delete(xmlFile);
            end
        end
    end
end

-- Working in the blind here... Hoping 'FSCareerMissionInfo.saveToXML' is the same in FS15, as it was in FS2013.
FSCareerMissionInfo.saveToXML = Utils.prependedFunction(FSCareerMissionInfo.saveToXML, function(self)
    if fmcSoilMod.enabled and self.isValid and self.xmlKey ~= nil then
        -- Apparently FSCareerMissionInfo's 'xmlFile' variable isn't always assigned, previous to it calling saveToXml()?
        if self.xmlFile ~= nil then
            fmcSettings.onSaveCareerSavegame(self.xmlFile, self.xmlKey..".modsSettings.fmcSoilMod")
        else
            g_currentMission.inGameMessage:showMessage("SoilMod", g_i18n:getText("SaveFailed"), 10000);
        end
    end
end);
