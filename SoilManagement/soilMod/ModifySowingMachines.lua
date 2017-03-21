--
--  SoilMod Project - version 3 (FS17)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modcentral.co.uk
-- @date    2017-01-xx
--
--[[
sm3ModifySowingMachines = {}

--
function sm3ModifySowingMachines.setup()
    if not sm3ModifySowingMachines.initialized then
        sm3ModifySowingMachines.initialized = true
        -- Add functionality
        sm3ModifySowingMachines.modifySowingMachine()
    end
end

--
function sm3ModifySowingMachines.teardown()
end

--
function sm3ModifySowingMachines.modifySowingMachine()

    logInfo("Appending to SowingMachine.postLoad, to enable 'dryGrass' seeding if 'grass' can.")
    SowingMachine.postLoad = Utils.appendedFunction(SowingMachine.postLoad, function(self)
        local canSeedGrass = false;
        local seedIdx;
        for idx,fruitIndex in ipairs(self.seeds) do
            if  fruitIndex == FruitUtil.FRUITTYPE_GRASS then
                canSeedGrass = true;
                seedIdx = idx;
            end
            if  fruitIndex == FruitUtil.FRUITTYPE_DRYGRASS then
                -- 'dryGrass' is already in list, so do not add a second element.
                canSeedGrass = false;
                break;
            end
        end
        if canSeedGrass then
            -- Add possibility to seed 'dryGrass' too.
            table.insert(self.seeds, seedIdx+1, FruitUtil.FRUITTYPE_DRYGRASS);
            log(self.name, ": added 'dryGrass' to seeds.");
        end
    end);

end;
--]]