-- MOBILE FACTORY OBJECT --
require("utils/functions")

-- Create the Mobile Factory Object --
MF = {
	ent = nil,
	lastSurface = nil,
	lastPosX = 0,
	lastPosY = 0,
	shield = 0,
	maxShield = _mfMaxShield,
	fS = nil,
	ccS = nil,
	fChest = nil,
	internalEnergy = _mfInternalEnergy,
	maxInternalEnergy = _mfInternalEnergyMax,
	jumpTimer = _mfBaseJumpTimer,
	baseJumpTimer = _mfBaseJumpTimer,
	laserRadiusMultiplier = 0,
	laserDrainMultiplier = 0,
	laserNumberMultiplier = 0,
	energyLaserActivated = false,
	fluidLaserActivated = false,
	itemLaserActivated = false,
	internalEnergyDistributionActivated = false
}

-- Constructor --
function MF:new(object)
	if object == nil then return end
	t = {}
	mt = {}
	-- for k, j in pairs(MF) do
		-- mt[k] = j
	-- end
	setmetatable(t, mt)
	mt.__index = MF
	t.ent = object
	t.lastSurface = object.surface
	t.lastPosX = object.position.x
	t.lastPosY = object.position.y
	return t
end

-- Reconstructor --
function MF:rebuild(object)
	if object == nil then return end
	mt = {}
	-- for k, j in pairs(MF) do
		-- mt[k] = j
	-- end
	mt.__index = MF
	setmetatable(object, mt)
end

-- Synchronize Factory Chest --
function MF:syncFChest()
	if self.fChest ~= nil and self.fChest.valid == true then
		synchronizeInventory(self.ent.get_inventory(defines.inventory.car_trunk), self.fChest.get_inventory(defines.inventory.chest))
	end
end

-- Return the Lasers radius --
function MF:getLaserRadius()
	return _mfBaseLaserRadius + (self.laserRadiusMultiplier * 2)
end

-- Return the Energy Lasers Drain --
function MF:getLaserEnergyDrain()
	return _mfEnergyDrain * (self.laserDrainMultiplier + 1)
end

-- Return the Fluid Lasers Drain --
function MF:getLaserFluidDrain()
	return _mfFluidDrain * (self.laserDrainMultiplier + 1)
end

-- Return the Logistic Lasers Drain --
function MF:getLaserItemDrain()
	return _mfItemsDrain * (self.laserDrainMultiplier + 1)
end

-- Return the number of Lasers --
function MF:getLaserNumber()
	return _mfBaseLaserNumber + self.laserNumberMultiplier
end

-- Search energy sources near Mobile Factory and update the burning fuel --
function MF:updateLasers()
	-- Search Energy sources"
	if technologyUnlocked("EnergyDrain1") or technologyUnlocked("FluidDrain1") then
		-- Get Bounding Box --
		local mfB = self.ent.bounding_box
		-- Get all entities around --
		local entities = self.ent.surface.find_entities_filtered{position=self.ent.position, radius=self:getLaserRadius()}
		i = 1
		-- Look each entity --
		for k, entity in pairs(entities) do
			-- Energy Laser --
			if i > self:getLaserNumber() then break end
			-- Exclude Character, Power Drain Pole and Entities with 0 energy --
			if entity.type ~= "character" and entity.name ~= "PowerDrainPole" and entity.energy > 0 then
			-- Missing Internal Energy or Structure Energy --
			local energyDrain = math.min(self.maxInternalEnergy - self.internalEnergy, entity.energy)
			-- EnergyDrain or LaserDrain Caparity --
			local drainedEnergy = math.min(self:getLaserEnergyDrain(), energyDrain)
			-- Test if some Energy was drained --
			if drainedEnergy > 0 then
				-- Add the Energy to the Mobile Factory Batteries --
				global.MF.internalEnergy = global.MF.internalEnergy + drainedEnergy
				-- Remove the Energy from the Structure --
				entity.energy = entity.energy - drainedEnergy
				-- Create the Beam --
				self.ent.surface.create_entity{name="BlueBeam", duration=60, position=self.ent.position, target_position=entity.position, source_position={self.ent.position.x,self.ent.position.y-4}}
				-- One less Beam to the Beam capacity --
				i = i + 1
			end
		end
			-- Fluid Laser --
			if self.fluidLaserActivated == true and entity.type == "storage-tank" and global.IDModule > 0 then
				if self.ccS ~= nil then
					-- Get the Internal Tank --
					local name
					local pos
					local filter
					if global.tankTable ~= nil and global.tankTable[global.IDModule] ~= nil then
						name = global.tankTable[global.IDModule].name
						pos = global.tankTable[global.IDModule].position
						filter = global.tankTable[global.IDModule].filter
					end
					if name ~= nil and pos ~= nil and filter ~= nil then
					-- Get the Internal Tank entity --
					local ccTank = self.ccS.find_entity(name, pos)
					if ccTank ~= nil then
						-- Get the focused Tank --
						local name
						local amount
						pTank = entity
						for k, i in pairs(pTank.get_fluid_contents()) do
							name = k
							amount = i
						end
							if name ~= nil and name == filter and self.internalEnergy > _lfpFluidConsomption * math.min(amount, self:getLaserFluidDrain()) then
								-- Add fluid to the Internal Tank --
								local amountRm = ccTank.insert_fluid({name=name, amount=math.min(amount, getLaserFluidDrain())})
								-- Remove fluid from the focused Tank --
								pTank.remove_fluid{name=name, amount=amountRm}
								if amountRm > 0 then
									-- Create the Laser --
									self.ent.surface.create_entity{name="PurpleBeam", duration=60, position=self.ent.position, target=pTank.position, source=self.ent.position}
									-- Drain Energy --
									self.internalEnergy = self.internalEnergy - (_mfFluidConsomption*amountRm)
									-- One less Beam to the Beam capacity --
									i = i + 1
								end
							end
						end
					end
				end
			end
			-- Logistic Laser --
			if self.itemLaserActivated == true and self.internalEnergy > _mfBaseItemEnergyConsumption * self:getLaserItemDrain() and (entity.type == "container" or entity.type == "logistic-container") then
				-- Get Chest Inventory --
				local inv = entity.get_inventory(defines.inventory.chest)
				if inv ~= nil and inv.valid == true then
					-- Create the Laser Capacity variable --
					local capItems = self:getLaserItemDrain()
					-- Get all Items --
					local invItems = inv.get_contents()
					-- Retrieve items from the Inventory --
					for iName, iCount in pairs(invItems) do
						-- Retrieve item --
						local removedItems = inv.remove({name=iName, count=capItems})
						-- Add items to the Internal Inventory --
						local added = addItemStackToII({name=iName, count=removedItems})
						-- Test if not all amount was added --
						if added ~= removedItems then
							-- Send back to the Chest --
							inv.insert({name=iName, count=removedItems-added})
						end
						-- Recalcule the capItems --
						capItems = capItems - added
						-- Create the laser and remove energy --
						if added > 0 then
							self.ent.surface.create_entity{name="GreenBeam", duration=60, position=self.ent.position, target=entity.position, source=self.ent.position}
							self.internalEnergy = self.internalEnergy - _mfBaseItemEnergyConsumption * removedItems
							-- One less Beam to the Beam capacity --
							i = i + 1
						end
						-- Test if capItems is empty --
						if capItems <= 0 then
							-- Stop --
							break
						end
					end
				end
			end
		end
	end
	-- Recharge the tank fuel --
	if self.internalEnergy > 0 and self.ent.get_inventory(defines.inventory.fuel).get_item_count() < 2 then
		if self.ent.burner.remaining_burning_fuel == 0 and self.ent.get_inventory(defines.inventory.fuel).is_empty() == true then
			-- Insert coal in case of the Tank is off --
			self.ent.get_inventory(defines.inventory.fuel).insert({name="coal", count=1})
		elseif self.ent.burner.remaining_burning_fuel > 0 then
			-- Calcule the missing Fuel amount --
			local missingFuelValue = math.floor((_mfMaxFuelValue - self.ent.burner.remaining_burning_fuel) /_mfFuelMultiplicator)
			if math.floor(missingFuelValue/_mfFuelMultiplicator) < self.internalEnergy then
				-- Add the missing Fuel to the Tank --
				self.ent.burner.remaining_burning_fuel = _mfMaxFuelValue
				-- Drain energy --
				self.internalEnergy = math.floor(self.internalEnergy - missingFuelValue/_mfFuelMultiplicator)
			end
		end
	end
end

-- Update the Shield --
function MF:updateShield(tick)
	if self.ent == nil or self.ent.valid == false or technologyUnlocked("MFShield") == false then return end
	-- Create the visual --
	if self.shield > 0 then
		self.ent.surface.create_trivial_smoke{name="mfShield", position=self.ent.position}
	end
	-- Charge the Shield --
	if tick%60 == 0 and self.internalEnergy*_mfShieldChargeRate > _mfShieldComsuption and self.shield < self.maxShield then
		-- Charge rate or Shield charge missing --
		local charge = math.min(self.maxShield - self.shield, _mfShieldChargeRate)
		-- Add the charge --
		self.shield = self.shield + charge
		-- Remove the energy --
		self.internalEnergy = self.internalEnergy - _mfShieldComsuption*charge
	end
end














