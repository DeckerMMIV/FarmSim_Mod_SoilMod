--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-03-xx
--

function soilmod:modifyManureBarrelCultivator()
    logInfo("Modifying vehicle-type 'manureBarrelCultivator', so specialization 'cultivator' comes _after_ the 'sprayer'. Fix the Zunhammer-Zunidisc for slurry graphics")
    
    local typeName = 'manureBarrelCultivator'
    local vehicleType = VehicleTypeUtil.vehicleTypes[typeName]
    if vehicleType ~= nil then
        local delPos = nil
        local insPos = nil
        for i,spec in ipairs(vehicleType.specializations) do
            if spec == Cultivator then
                delPos = i
            elseif spec == Sprayer then
                insPos = i
            end
        end
        if delPos ~= nil and insPos ~= nil and insPos > delPos then
            table.remove(vehicleType.specializations, delPos)
            table.insert(vehicleType.specializations, insPos, Cultivator)
            return
        end
    end
    log("WARNING: Did not modify vehicle-type 'manureBarrelCultivator'")
end
