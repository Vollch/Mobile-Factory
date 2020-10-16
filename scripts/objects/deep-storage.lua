-- DEEP STORAGE OBJECT --

-- Create the Deep Storage base object --
DSR = {
	ent = nil,
	player = "",
	MF = nil,
	entID = 0,
	updateTick = 80,
	lastUpdate = 0,
	inventoryItem = nil,
	inventoryCount = 0,
	ID = 0,
	filter = nil
}

-- Constructor --
function DSR:new(object)
	if object == nil then return end
	local t = {}
	local mt = {}
	setmetatable(t, mt)
	mt.__index = DSR
	t.ent = object
	if object.last_user == nil then return end
	t.player = object.last_user.name
	t.MF = getMF(t.player)
	t.entID = object.unit_number
	t.ID = Util.getEntID(global.deepStorageTable)
	t.MF.dataNetwork.DSRTable[object.unit_number] = t
	UpSys.addObj(t)
	return t
end

-- Reconstructor --
function DSR:rebuild(object)
	if object == nil then return end
	local mt = {}
	mt.__index = DSR
	setmetatable(object, mt)
end

-- Destructor --
function DSR:remove()
	-- Remove from the Update System --
	UpSys.removeObj(self)
	-- Remove from the MF Object --
	self.MF.dataNetwork.DSRTable[self.ent.unit_number] = nil
end

-- Is valid --
function DSR:valid()
	if self.ent ~= nil and self.ent.valid then return true end
	return false
end

-- Copy Settings --
function DSR:copySettings(obj)
	self.filter = obj.filter
end

-- Item Tags to Content --
function DSR:itemTagsToContent(tags)
	self.inventoryItem = tags.inventoryItem or nil
	self.inventoryCount = tags.inventoryCount or 0
	self.filter = tags.filter or nil
end

-- Content to Item Tags --
function DSR:contentToItemTags(tags)
	if self.inventoryItem ~= nil or self.filter ~= nil then
		tags.set_tag("Infos", {inventoryItem=self.inventoryItem, inventoryCount=self.inventoryCount, filter=self.filter})
		tags.custom_description = {"", tags.prototype.localised_description, {"item-description.DeepStorageC", self.inventoryItem or self.filter, self.inventoryCount or 0}}
	end
end

-- Update --
function DSR:update()
	-- Set the lastUpdate variable --
	self.lastUpdate = game.tick
	
	-- Check the Validity --
	if valid(self) == false then
		self:remove()
		return
	end
	
	-- Remove the Item if it doesn't exist anymore --
	if self.inventoryItem ~= nil and game.item_prototypes[self.inventoryItem] == nil then
		self.inventoryItem = nil
		self.inventoryCount = 0
		return
	end

	-- Remove the Item Filter if it doesn't exist anymore --
	if self.filter ~= nil and game.item_prototypes[self.filter] == nil then
		self.filter = nil
		return
	end
	
	-- Display the Item Icon --
	if self.inventoryItem == nil and self.filter == nil then return true end
	local sprite = "item/" .. (self.inventoryItem or self.filter)
	rendering.draw_sprite{sprite=sprite, target=self.ent, surface=self.ent.surface, time_to_live=self.updateTick + 1, target_offset={0,-0.35}, render_layer=131}
end

-- Tooltip Infos --
function DSR:getTooltipInfos(GUIObj, gui, justCreated)

	-- Get the Flow --
	local inventoryFlow = GUIObj.InventoryFlow

	if justCreated == true then
		
		-- Create the Inventory Title --
		local inventoryTitle = GUIObj:addTitledFrame("", gui, "vertical", {"gui-description.Inventory"}, _mfOrange)
		inventoryFlow = GUIObj:addFlow("InventoryFlow", inventoryTitle, "vertical", true)

		-- Create the Settings Title --
		local settingTitle = GUIObj:addTitledFrame("", gui, "vertical", {"gui-description.Settings"}, _mfOrange)

		-- Create the Filter Selection Label and Filter --
		GUIObj:addLabel("", settingTitle, {"gui-description.ChangeFilter"}, _mfOrange)
		GUIObj:addFilter("onChangeFilter;"..self.entID, settingTitle, {"gui-description.FilterSelect"}, true, "item", 40)

	end

	-- Clear the Flow --
	inventoryFlow.clear()

	-- Create the Item Frame --
	if self.inventoryItem ~= nil or self.filter ~= nil then
		Util.itemToFrame(self.inventoryItem or self.filter, self.inventoryCount or 0, GUIObj, inventoryFlow)
	end

	-- Create the Item Name Label --
	local itemName = Util.getLocItemName(self.inventoryItem) or Util.getLocItemName(self.filter) or {"gui-description.Empty"}
	GUIObj:addDualLabel(inventoryFlow, {"", {"gui-description.ItemName"}, ":"}, itemName, _mfOrange, _mfGreen)

	-- Create the Item Amount Label --
	local itemAmount = self.inventoryCount or 0
	GUIObj:addDualLabel(inventoryFlow, {"", {"gui-description.Amount"}, ":"}, Util.toRNumber(itemAmount), _mfOrange, _mfGreen, nil, nil, itemAmount)

	-- Create the Filter Label --
	local filterName = Util.getLocItemName(self.filter) or {"gui-description.None"}
	GUIObj:addDualLabel(inventoryFlow, {"", {"gui-description.Filter"}, ":"}, filterName, _mfOrange, _mfGreen)

	-- Update the Filter --
	if game.item_prototypes[self.filter] ~= nil and GUIObj["onChangeFilter;" .. tostring(self.ent.unit_number)] ~= nil then
		GUIObj["onChangeFilter;" .. tostring(self.ent.unit_number)].elem_value = self.filter
	end

end

function DSR:onChangeFilter(event, args)
	local MFPlayer = getMFPlayer(event.player_index)
	self.filter = event.element.elem_value
	if MFPlayer.GUI["MFInfoGUI"] ~= nil then
		GUI.updateDeepStorageInfo(MFPlayer.GUI["MFInfoGUI"], self.ent.unit_number)
	end
end

-- Return the number of item present inside the Inventory --
function DSR:hasItem(name)
	if self.inventoryItem ~= nil and self.inventoryItem == name then
		return self.inventoryCount
	end
	return 0
end

-- Return if the Item can be accepted --
function DSR:canAccept(name)
	if self.filter == nil then return false end
	if self.filter ~= nil and self.filter ~= name then return false end
	if self.inventoryItem ~= nil and self.inventoryItem ~= name then return false end
	return true
end

-- Add Items --
function DSR:addItem(name, count)
	if self:canAccept(name) == true then
		self.inventoryItem = name
		self.inventoryCount = self.inventoryCount + count
		return count
	end
	return 0
end

-- Remove Items --
function DSR:getItem(name, count)
	if self.inventoryItem ~= nil and self.inventoryItem == name then
		local removed = math.min(count, self.inventoryCount)
		self.inventoryCount = self.inventoryCount - removed
		if self.inventoryCount == 0 then self.inventoryItem = nil end
		return removed
	end
	return 0
end

-- Settings To Blueprint Tags --
function DSR:settingsToBlueprintTags()
	local tags = {}
	tags["selfFilter"] = self.filter
	return tags
end

-- Blueprint Tags To Settings --
function DSR:blueprintTagsToSettings(tags)
	self.filter = tags["selfFilter"]
end