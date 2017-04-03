--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-04-xx
--

local timeScales = {
    1,
    5,
    60,
    120,
    240,
    480,
    960,
}

Utils.getNumTimeScales = function()
    return #timeScales
end

Utils.getTimeScaleFromIndex = function(idx)
    idx = Utils.clamp(idx, 1, #timeScales)
    return timeScales[idx]
end

Utils.getTimeScaleIndex = function(timeScale)
    local i = #timeScales
    while i > 1 do
        if timeScale >= timeScales[i] then
            break
        end
        i=i-1
    end
    return i
end

-- Refresh in-game-menu's gui element
g_inGameMenu:onCreateTimeScale(g_inGameMenu.timeScaleElement)
