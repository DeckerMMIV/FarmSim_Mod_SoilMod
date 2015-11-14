--
--  The Soil Management and Growth Control Project - version 2 (FS15)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modhoster.com
-- @date    2015-11-xx
--

-- Register the 'weeder' specialization.
local specName = "weeder"
if SpecializationUtil.specializations[specName] == nil then
    SpecializationUtil.registerSpecialization(specName, "Weeder", g_currentModDirectory .. "specializations/Weeder.lua")
end;
