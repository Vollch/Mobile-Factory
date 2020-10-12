-- ORE CLEANER OBJECT --

OC = {
	ent = nil,
	player = "",
	MF = nil,
	entID = 0,
	oreTable = nil,
	selectedInv = nil,
	animID = 0,
	animTick = 0,
	updateTick = 1,
	lastUpdate = 0,
	lastExtraction = 0,
	mfTooFar = false,
	quatronCharge = 0,
	quatronLevel = 1,
	quatronMax = _mfOreCleanerMaxCharge,
	quatronMaxInput = 100,
	quatronMaxOutput = 0
}

-- Constructor --
function OC:new(object)
	if object == nil then return end
	local t = {}
	local mt = {}
	setmetatable(t, mt)
	mt.__index = OC
	t.ent = object
	if object.last_user == nil then return end
	t.player = object.last_user.name
	t.MF = getMF(t.player)
	t.entID = object.unit_number
	t.oreTable = {}
	t.inventory = {}
	t:scanOres(object)
	UpSys.addObj(t)
	return t
end

-- Reconstructor --
function OC:rebuild(object)
	if object == nil then return end
	local mt = {}
	mt.__index = OC
	setmetatable(object, mt)
end

-- Destructor --
function OC:remove()
	-- Destroy the Animation --
	rendering.destroy(self.animID)
	-- Remove from the Update System --
	UpSys.removeObj(self)
end

-- Is valid --
function OC:valid()
	if self.ent ~= nil and self.ent.valid then return true end
	return false
end

-- Copy Settings --
function OC:copySettings(obj)
	self.selectedInv = obj.selectedInv
end

-- Item Tags to Content --
function OC:itemTagsToContent(tags)
	self.quatronLevel = tags.purity or 0
	self.quatronCharge = tags.charge or 0
end

-- Content to Item Tags --
function OC:contentToItemTags(tags)
	if self.quatronCharge > 0 then
		tags.set_tag("Infos", {purity=self.quatronLevel, charge=self.quatronCharge})
		tags.custom_description = {"", tags.prototype.localised_description, {"item-description.OreCleanerC", math.floor(self.quatronCharge), string.format("%.3f", self.quatronLevel)}}
	end
end

-- Update --
function OC:update(event)
	-- Set the lastUpdate variable --
	self.lastUpdate = game.tick
	-- Check the Validity --
	if valid(self) == false then
		self:remove()
		return
	end
	-- The Ore Cleaner can work only if the Mobile Factory Entity is valid --
	if self.MF.ent == nil or self.MF.ent.valid == false then return end
	-- Check the Surface --
	if self.ent.surface ~= self.MF.ent.surface then return end
	-- Check the Distance --
	if Util.distance(self.ent.position, self.MF.ent.position) > _mfOreCleanerMaxDistance then
		self.MFTooFar = true
	else
		self.MFTooFar = false
	end
	-- Set the Ore Cleaner Energy --
	self.ent.energy = 600
	-- Collect Ores --
	if event.tick%_mfOreCleanerExtractionTicks == 0 and self.MFTooFar == false then
		self:collectOres(event)
	end
	-- Update Animation --
	 self:updateAnimation(event)
end

-- Tooltip Infos --
function OC:getTooltipInfos(GUIObj, gui, justCreated)

	-- Get the Flow --
	local informationFlow = GUIObj.InformationFlow

	if justCreated == true then

		-- Create the Information Title --
		local informationTitle = GUIObj:addTitledFrame("", gui, "vertical", {"gui-description.Information"}, _mfOrange)
		informationFlow = GUIObj:addFlow("InformationFlow", informationTitle, "vertical", true)

		-- Create the Settings Title --
		local settingsTitle = GUIObj:addTitledFrame("", gui, "vertical", {"gui-description.Settings"}, _mfOrange)

		-- Create the Select Storage Label --
		GUIObj:addLabel("", settingsTitle, {"", {"gui-description.TargetedStorage"}}, _mfOrange)

		-- Create the Storage List --
		local invs = {{"gui-description.All"}}
		local selectedIndex = 1
		local i = 1
		for k, deepStorage in pairs(self.MF.dataNetwork.DSRTable) do
			if deepStorage ~= nil and deepStorage.ent ~= nil then
				i = i + 1
				local itemText = {"", " (", {"gui-description.Empty"}, " - ", deepStorage.player, ")"}
				if deepStorage.filter ~= nil and game.item_prototypes[deepStorage.filter] ~= nil then
					itemText = {"", " (", game.item_prototypes[deepStorage.filter].localised_name, ")"}
				elseif deepStorage.inventoryItem ~= nil and game.item_prototypes[deepStorage.inventoryItem] ~= nil then
					itemText = {"", " (", game.item_prototypes[deepStorage.inventoryItem].localised_name, ")"}
				end
				invs[k+1] = {"", {"gui-description.DS"}, " ", tostring(deepStorage.ID), itemText}
				if self.selectedInv and self.selectedInv.entID == deepStorage.entID then
					selectedIndex = i
				end
			end
		end
		if selectedIndex ~= nil and selectedIndex > table_size(invs) then selectedIndex = nil end
		GUIObj:addDropDown("onSelectStorage;OC;"..self.ent.unit_number, settingsTitle, invs, selectedIndex)

	end

	-- Clear the Flow --
	informationFlow.clear()
	
	-- Create the Quatron Charge --
	GUIObj:addDualLabel(informationFlow, {"", {"gui-description.Charge"}, ": "}, math.floor(self.quatronCharge), _mfOrange, _mfGreen)
	GUIObj:addProgressBar("", informationFlow, "", "", false, _mfPurple, self.quatronCharge/_mfOreCleanerMaxCharge, 100)

	-- Create the Quatron Purity --
	GUIObj:addDualLabel(informationFlow, {"", {"gui-description.Purity"}, ": "}, string.format("%.3f", self.quatronLevel), _mfOrange, _mfGreen)
	GUIObj:addProgressBar("", informationFlow, "", "", false, _mfPurple, self.quatronCharge/20, 100)

	-- Create the Speed --
	GUIObj:addDualLabel(informationFlow, {"", {"gui-description.Speed"}, ": "}, self:orePerExtraction() .. " ore/s", _mfOrange, _mfGreen)

	-- Create the Resource Label --
	GUIObj:addDualLabel(informationFlow, {"", {"gui-description.NumberOfOrePath"}, ": "}, table_size(self.oreTable), _mfOrange, _mfGreen)

	-- Create the Mobile Factory Too Far Label --
	if self.MFTooFar == true then
		GUIObj:addLabel("", informationFlow, {"", {"gui-description.MFTooFar"}}, _mfRed)
	end

end

function OC:onSelectStorage(event, MFPlayer, args)
	self:changeInventory(tonumber(event.element.items[event.element.selected_index][4]))
end

-- Change the Targeted Inventory --
function OC:changeInventory(ID)
	-- Check the ID --
	if ID == nil then
		self.selectedInv = nil
		return
	end
	-- Select the Inventory --
	self.selectedInv = nil
	for k, deepStorage in pairs(self.MF.dataNetwork.DSRTable) do
		if valid(deepStorage) == true then
			if ID == deepStorage.ID then
				self.selectedInv = deepStorage
			end
		end
	end
end

-- Get the number of Ores per extraction --
function OC:orePerExtraction()
	return math.floor(_mfOreCleanerOrePerExtraction * math.pow(self.quatronLevel, _mfQuatronScalePower))
end

-- Scan surronding Ores --
function OC:scanOres(entity)
	-- Test if the Entity is valid --
	if entity == nil or entity.valid == false then return end
	-- Test if the Surface is valid --
	if entity.surface == nil then return end
	-- Add all surrounding Ores and add them to the oreTable --
	self.oreTable = entity.surface.find_entities_filtered{position=entity.position, radius=_mfOreCleanerRadius, type="resource"}
end

-- Collect surrounding Ores --
function OC:collectOres(event)
	-- Test if the Mobile Factory and the Ore Cleaner are valid --
	if valid(self) == false or valid(self.MF) == false then return end
	-- Return if the Ore Table is empty --
	if table_size(self.oreTable) <= 0 then return end
	-- Return if there are not Quatron Charge remaining --
	if self.quatronCharge <= 0 then return end
	-- Create the OrePath and randomNum variable --
	local orePath = nil
	local randomNum  = 0
	-- Look for a random Ore Path --
	for i=0, 1000 do
		-- Calcul a random Ore Path --
		randomNum = math.random(1, table_size(self.oreTable))
		-- Get the Ore Path --
		orePath = self.oreTable[randomNum]
		-- If the Ore Path is valid, break --
		if orePath ~= nil and orePath.valid == true then
			break
		else
			-- Remove invalid Ore Path, and return if there is no more --
			table.remove(self.oreTable, randomNum)
			if table_size(self.oreTable) <= 0 then return end
		end
	end
	-- Test if the Ore Path exist and is valid --
	if orePath == nil or orePath.valid == false then return end
	local listProducts = orePath.prototype.mineable_properties.products

	if self.selectedInv ~= nil then
		-- Check Selected Inventory
		if valid(self.selectedInv) == false then return end
		-- Multiple products can't be stored in single storage
		if table_size(listProducts) > 1 then return end
	end

	-- Check if there is a room for all products
	local deepStorages = {}
	for _, product in pairs(listProducts) do
		-- Check if a Name was found, and Item Prototype exists --
		if product.name == nil or product.type ~= 'item' or game.item_prototypes[product.name] == nil then
			-- Remove unmineable patch from Ore Table
			table.remove(self.oreTable, randomNum)
			return
		end

		if self.selectedInv then
			-- Deep Storage is assigned, check if it fits
			if self.selectedInv:canAccept(product.name) then
				-- Selected inventory matches product, proceed
				deepStorages[product.name] = self.selectedInv
			else
				-- Selected inventory can't hold product, return
				return
			end
		else
			-- Try to find a Deep Storage if the Selected Inventory is All --
			for k, dp in pairs(self.MF.dataNetwork.DSRTable) do
				if dp:canAccept(product.name) == true then
					deepStorages[product.name] = dp
					break
				end
			end
			-- Return if storage not found
			if deepStorages[product.name] == nil then return end
		end
	end

	-- Extract Ore --
	local stats = self.ent.force.item_production_statistics
	local oreExtracted = math.min(self:orePerExtraction(), orePath.amount)
	for _, product in pairs(listProducts) do
		if product.probability == 1 or product.probability > math.random() then
			-- Add Ore to the Inventory --
			deepStorages[product.name]:addItem(product.name, oreExtracted * product.amount)
			-- Add Ore to Production Statistics
			stats.on_flow(product.name, oreExtracted * product.amount)
		end
	end

	if oreExtracted > 0 then
		-- Make the Beam --
		self.ent.surface.create_entity{name="OCBeam", duration=60, position=self.ent.position, target=orePath.position, source={self.ent.position.x,self.ent.position.y-3.2}}
		-- Set the lastUpdate variable --
		self.lastExtraction = event.tick
		-- Remove a charge --
		self.quatronCharge = self.quatronCharge - 1
		-- Remove Ores from the Ore Path --
		orePath.amount = math.max(orePath.amount - oreExtracted, 1)
		-- Remove the Ore Path if it is empty --
		if orePath.amount <= 1 then
			orePath.destroy()
			table.remove(self.oreTable, randomNum)
		end
	end
end

-- Update the Animation --
function OC:updateAnimation(event)
	-- Test if they was any extraction since the last tick --
	if event.tick - self.lastExtraction > _mfOreCleanerExtractionTicks + 10 and self.animID ~= 0 then
		-- Destroy the Animation --
		rendering.destroy(self.animID)
		self.animID = 0
		-- Make the transfer Beam --
		self.ent.surface.create_entity{name="OCBigBeam", duration=16, position=self.ent.position, target=self.MF.ent.position, source={self.ent.position.x-0.3,self.ent.position.y-4}}
		return
	-- If they was extraction but the animation doesn't exist --
	elseif event.tick - self.lastExtraction <= _mfOreCleanerExtractionTicks + 10 and self.animID == 0 then
		-- Create the Orb Animation --
		self.animID = rendering.draw_animation{animation="RedEnergyOrb", target={self.ent.position.x,self.ent.position.y - 3.25}, surface=self.ent.surface, render_layer=144}
		-- I don't know what this do, but it work (reset the animation) --
		rendering.set_animation_offset(self.animID, 240 - (event.tick%240))
		self.animTick = event.tick
	-- Make the Beam if the animation ended --
	elseif (event.tick - self.animTick)%240 == 0 and self.animID ~= 0 then
		-- Make the transfer Beam --
		self.ent.surface.create_entity{name="OCBigBeam", duration=16, position=self.ent.position, target=self.MF.ent.position, source={self.ent.position.x-0.3,self.ent.position.y-4}}
	end
end

-- Settings To Blueprint Tags --
function OC:settingsToBlueprintTags()
	local tags = {}
	if self.selectedInv and valid(self.selectedInv) then
		tags["deepStorageID"] = self.selectedInv.ID
		tags["deepStorageFilter"] = self.selectedInv.filter
	end
	return tags
end

-- Blueprint Tags To Settings --
function OC:blueprintTagsToSettings(tags)
	local ID = tags["deepStorageID"]
	local deepStorageFilter = tags["deepStorageFilter"]
	if ID then
		for _, deepStorage in pairs(self.MF.dataNetwork.DSRTable) do
			if valid(deepStorage) then
				if ID == deepStorage.ID and deepStorageFilter == deepStorage.filter then
					-- We Should Have the Exact Inventory --
					self.selectedInv = deepStorage
					break
				elseif deepStorageFilter ~= nil and deepStorageFilter == deepStorage.filter then
					-- We Have A Similar Inventory And Will Keep Checking --
					self.selectedInv = deepStorage
				end
			end
		end
	end
end

-- Return the amount of Quatron --
function OC:quatron()
	return self.quatronCharge
end

-- Return the Quatron Buffer size --
function OC:maxQuatron()
	return self.quatronMax
end

-- Add Quatron (Return the amount added) --
function OC:addQuatron(amount, level)
	local added = math.min(amount, self.quatronMax - self.quatronCharge)
	if self.quatronCharge > 0 then
		mixQuatron(self, added, level)
	else
		self.quatronCharge = added
		self.quatronLevel = level
	end
	return added
end

-- Remove Quatron (Return the amount removed) --
function OC:removeQuatron(amount)
	local removed = math.min(amount, self.quatronCharge)
	self.quatronCharge = self.quatronCharge - removed
	return removed
end

-- Return the max input flow --
function OC:maxInput()
	return self.quatronMaxInput
end

-- Return the max output flow --
function OC:maxOutput()
	return self.quatronMaxOutput
end