--
--  The Soil Management and Growth Control Project - version 2 (FS15)
--
-- @author  Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modhoster.com
-- @date    2015-07-xx
--

fmcModifySowingMachines = {}

--
function fmcModifySowingMachines.setup()
    if not fmcModifySowingMachines.initialized then
        fmcModifySowingMachines.initialized = true
        -- Add functionality
        fmcModifySowingMachines.modifySowingMachine()
    end
end

--
function fmcModifySowingMachines.teardown()
end

--
function fmcModifySowingMachines.modifySowingMachine()

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
