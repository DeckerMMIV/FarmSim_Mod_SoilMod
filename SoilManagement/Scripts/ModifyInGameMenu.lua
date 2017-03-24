--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-03-xx
--

function soilmod:modifyInGameMenu()
    logInfo("Disabling the in-game-menu choices for; growth-rate, withering, fertilizer- and plough-levels")
    
    InGameMenu.updateGameSettings = Utils.appendedFunction(
        InGameMenu.updateGameSettings, 
        function(self)
            local function setDisabled(elem, value)
                if elem ~= nil and elem.setDisabled ~= nil then
                    elem:setDisabled(value)
                end
            end
            local function setTexts(elem, value)
                if elem ~= nil and elem.setTexts ~= nil then
                    elem:setTexts(value)
                end
            end
            
            -- Disable the gui-elements which SoilMod should have control off
            setDisabled(self.plantGrowthRateElement  ,true)
            setDisabled(self.plantWitheringElement   ,true)
            setDisabled(self.fertilizerStatesElement ,true)
            setDisabled(self.plowingRequiredElement  ,true)

            -- Change text to indicate that SoilMod is "in control".
            setTexts(self.plantGrowthRateElement  ,{"SoilMod"})
            setTexts(self.plantWitheringElement   ,{"SoilMod"})
            setTexts(self.fertilizerStatesElement ,{"SoilMod"})
            setTexts(self.plowingRequiredElement  ,{"SoilMod"})
        end
    )
end
