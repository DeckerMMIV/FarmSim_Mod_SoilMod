--
--  The Soil Management and Growth Control Project - version 2 (FS15)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modhoster.com
-- @date    2015-11-xx
--

-- Register the 'SoilMod_weeder' specialization.
local specName = "SoilMod_weeder"
if SpecializationUtil.specializations[specName] == nil then
    print("SoilMod: Registering specialization '"..specName.."'.");
    SpecializationUtil.registerSpecialization(specName, "Weeder", g_currentModDirectory .. "soilMod/fmcWeeder.lua")
end;

-- The below code should be credited to the MoreRealistic mod for Farming Simulator 2013.
print("SoilMod: Attempting to re-registering vehicleTypes that earlier may have failed using a 'SoilMod_...' specialization.");

local function reregSoilModTypes(modName, xmlFile)
    local i=0;
    while true do
        local tagName = string.format("modDesc.vehicleTypes.type(%d)", i)
        i=i+1
        
        local vehTypeName  = getXMLString(xmlFile, tagName.."#name")
        if vehTypeName == nil
        or vehTypeName == ""
        then
            break
        end
        local vehTypeClass = getXMLString(xmlFile, tagName.."#className")
        local vehTypeFile  = getXMLString(xmlFile, tagName.."#filename")

        local modVehTypeName = modName.."."..vehTypeName

        -- Is vehicleType not known?
        if VehicleTypeUtil.vehicleTypes[modVehTypeName] == nil then
            local j=0
            local specs = {}
            local reqSoilMod = false
            while true do
                local tagName2 = tagName .. string.format(".specialization(%d)#name", j)
                j=j+1
                
                local specName = getXMLString(xmlFile, tagName2)
                if specName == nil then
                    -- Only when vehicleType uses a SoilMod_... specialization
                    if reqSoilMod then
                        -- Re-register the vehicleType
                        print("SoilMod:  Found possibly failed vehicleType '"..modVehTypeName.."', attempting to re-register it.")
                        if vehTypeFile:sub(1,1) == "$" then
                            vehTypeFile = vehTypeFile:sub(2,vehTypeFile:len())
                        end
                        VehicleTypeUtil.registerVehicleType(modVehTypeName, vehTypeClass, vehTypeFile, specs);
                    end
                    break
                end
                if specName:sub(1,8) == "SoilMod_" then
                    reqSoilMod = true
                end

                if SpecializationUtil.getSpecialization(modName.."."..specName) ~= nil then
                    specName = modName.."."..specName
                elseif SpecializationUtil.getSpecialization(specName) ~= nil then
                    -- Do nothing
                else
                    -- Oops!? The specialization was not available.
                    break
                end
                table.insert(specs, specName)
            end
        end
    end
end

for modName,modDesc in pairs(ModsUtil.modNameToMod) do
    if Utils.endsWith(modDesc.modFile, "modDesc.xml") then
        local xmlFile = loadXMLFile("modDesc", modDesc.modFile);
        if xmlFile ~= nil then
            local ver = getXMLInt(xmlFile, "modDesc#descVersion")
            if ver ~= nil and ver >= 20 then
                reregSoilModTypes(modName, xmlFile)
            end
            delete(xmlFile);
        end
    end
end
--
