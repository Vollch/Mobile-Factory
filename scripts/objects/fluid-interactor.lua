-- FLUID INTERACTOR OBJECT --

-- Create the Fluid Interactor base object --
FI = {
	ent = nil,
	player = "",
	MF = nil,
	entID = 0,
	stateSprite = 0,
	levelSprite = 0,
	active = false,
	consumption = _mfFIQuatronDrainPerUpdate,
	updateTick = 60,
	lastUpdate = 0,
	dataNetwork = nil,
	networkAccessPoint = nil,
	selectedInv = 0,
	selectedMode = "input" -- input or output
}

-- Constructor --
function FI:new(object)
	if object == nil then return end
	local t = {}
	local mt = {}
	setmetatable(t, mt)
	mt.__index = FI
	t.ent = object
	if object.last_user == nil then return end
	t.player = object.last_user.name
	t.MF = getMF(t.player)
	t.entID = object.unit_number
	t.dataNetwork = t.MF.dataNetwork
	-- Draw the state Sprite --
	t.stateSprite = rendering.draw_sprite{sprite="FluidInteractorSprite1", target=object, surface=object.surface, render_layer=131}
	UpSys.addObj(t)
	return t
end

-- Reconstructor --
function FI:rebuild(object)
	if object == nil then return end
	local mt = {}
	mt.__index = FI
	setmetatable(object, mt)
end

-- Destructor --
function FI:remove()
	-- Destroy the Sprites --
	rendering.destroy(self.stateSprite)
	rendering.destroy(self.levelSprite)
	-- Remove from the Update System --
	UpSys.removeObj(self)
	-- Remove from the Network Access Point --
	if self.networkAccessPoint ~= nil and self.ent ~= nil and self.ent.valid == true then
		self.networkAccessPoint.objTable[self.ent.unit_number] = nil
	end
end

-- Is valid --
function FI:valid()
	if self.ent ~= nil and self.ent.valid then return true end
	return false
end

-- Copy Settings --
function FI:copySettings(obj)
	if obj.selectedInv ~= nil then
		self.selectedInv = obj.selectedInv
    end
    if obj.selectedMode ~= nil then
		self.selectedMode = obj.selectedMode
	end
end

-- Update --
function FI:update()

	-- Set the lastUpdate variable --
	self.lastUpdate = game.tick
	
	-- Check the Validity --
	if valid(self) == false then
		self:remove()
		return
    end
    
    -- Update the level Sprite --
    local amount = nil
    local capacity = self.ent.fluidbox.get_capacity(1)
    for k3, i in pairs(self.ent.get_fluid_contents()) do
        amount = math.floor(i)
    end
    rendering.destroy(self.levelSprite)
    if amount ~= nil then
        local spriteNumber = math.floor(amount/capacity*10)
        if spriteNumber == 0 then
            rendering.destroy(self.levelSprite)
        else
            self.levelSprite = rendering.draw_sprite{sprite="FluidInteractorSprite3" .. spriteNumber, target=self.ent, surface=self.ent.surface, render_layer=131}
        end
    end
	
	-- Try to find a Network Access Point if needed --
	if valid(self.networkAccessPoint) == false then
		self.networkAccessPoint = self.dataNetwork:getCloserNAP(self)
		if self.networkAccessPoint ~= nil then
			self.networkAccessPoint.objTable[self.ent.unit_number] = self
		end
	end

	-- Set Active or Not --
	if self.networkAccessPoint ~= nil and self.networkAccessPoint.quatronCharge > 0 then
		self:setActive(true)
	else
		self:setActive(false)
    end

    if self.active == false then return end

    -- Update Inventory --
	self:updateInventory()
	
end

-- Tooltip Infos --
function FI:getTooltipInfos(GUIObj, gui, justCreated)

	-- Create the Data Network Frame --
	GUIObj:addDataNetworkFrame(gui, self)
	
    -- Check if the Parameters can be modified --
	if justCreated ~= true or valid(self.dataNetwork) == false then return end
	
	-- Create the Parameters Title --
	local titleFrame = GUIObj:addTitledFrame("", gui, "vertical", {"gui-description.Settings"}, _mfOrange)

	-- Create the Mode Selection --
	GUIObj:addLabel("", titleFrame, {"gui-description.SelectMode"}, _mfOrange)
	local state = "left"
	if self.selectedMode == "output" then state = "right" end
	GUIObj:addSwitch("onChangeMode;"..self.entID, titleFrame, {"gui-description.Input"}, {"gui-description.Output"}, {"gui-description.InputTT"}, {"gui-description.OutputTT"}, state)

	-- Create the Inventory Selection --
	GUIObj:addLabel("", titleFrame, {"gui-description.MSTarget"}, _mfOrange)
	
	local invs = {{"", {"gui-description.None"}}}


	-- Create the Deep Tank List --
	local selectedIndex = 1
	local i = 1
	for k, deepTank in pairs(self.dataNetwork.DTKTable) do
		if deepTank ~= nil and deepTank.ent ~= nil then
			i = i + 1
			local fluid
			if deepTank.filter ~= nil and game.fluid_prototypes[deepTank.filter] ~= nil then
				fluid = deepTank.filter
			elseif deepTank.inventoryFluid ~= nil and game.fluid_prototypes[deepTank.inventoryFluid] ~= nil then
				fluid = deepTank.inventoryFluid
			end

			if fluid then
				invs[k+1] = {"", "[img=fluid/"..fluid.."] ", game.fluid_prototypes[fluid].localised_name, " - ", deepTank.ID}
			else
				invs[k+1] = {"", "", {"gui-description.Empty"}, "", " - ", deepTank.ID}
			end

			if self.selectedInv and type(self.selectedInv) == "table" and self.selectedInv.entID == deepTank.entID then
				selectedIndex = i
			end
		end
	end
	if selectedIndex > table_size(invs) then selectedIndex = nil end
	GUIObj:addDropDown("onChangeInventory;"..self.entID, titleFrame, invs, selectedIndex)
end

-- Change the Mode --
function FI:onChangeMode(event, args)
	local mode = event.element.switch_state
	if mode == "left" then
		self.selectedMode = "input"
	elseif mode == "right" then
		self.selectedMode = "output"
	end
end

-- Change the Targeted Inventory --
function FI:onChangeInventory(event, args)
	-- Check the ID --
	local ID = tonumber(event.element.items[event.element.selected_index][5])
	if ID == nil then
		self.selectedInv = nil
		return
	end
	-- Select the Inventory --
	self.selectedInv = nil
	for k, deepTank in pairs(self.dataNetwork.DTKTable) do
		if valid(deepTank) then
			if ID == deepTank.ID then
				self.selectedInv = deepTank
			end
		end
	end
end

-- Set Active --
function FI:setActive(set)
    self.active = set
    if set == true then
        -- Create the Active Sprite --
        rendering.destroy(self.stateSprite)
        self.stateSprite = rendering.draw_sprite{sprite="FluidInteractorSprite2", target=self.ent, surface=self.ent.surface, render_layer=131}
    else
        -- Create the Inactive Sprite --
        rendering.destroy(self.stateSprite)
        self.stateSprite = rendering.draw_sprite{sprite="FluidInteractorSprite1", target=self.ent, surface=self.ent.surface, render_layer=131}
    end
end

-- Update the Tank Inventory --
function FI:updateInventory()
    -- Check the selected Inventory --
    if self.selectedInv == 0 or valid(self.selectedInv) == false then return end

    -- Get both Tanks and their characteristics --
    local localTank = self.ent
    local distantTank = self.selectedInv
    local localFluid = nil

    -- Get the Fluid inside the local Tank --
    for i=1,#localTank.fluidbox do
		if localTank.fluidbox[i] then
			localFluid = localTank.fluidbox[i]
			break
		end
	end
	
	-- Check if the Fluid still exist --
	if localFluid ~= nil and game.fluid_prototypes[localFluid.name] == nil then return end

    -- Input mode --
    if self.selectedMode == "input" then
		-- Do Nothing if no Fluid
		if localFluid == nil then return end
        -- Check the local and distant Tank --
        if distantTank:canAccept(localFluid) == false then return end
        -- Send the Fluid --
        local amountAdded = distantTank:addFluid(localFluid)
        -- Remove the local Fluid --
		localTank.remove_fluid{name=localFluid.name, amount=amountAdded, minimum_temperature = -300, maximum_temperature = 1e7}
	-- Output mode --
    elseif self.selectedMode == "output" then
        -- Check the local and distant Tank --
        if localFluid and localFluid.name ~= distantTank.inventoryFluid then return end
        if distantTank.inventoryFluid == nil or distantTank.inventoryCount == 0 then return end
        -- Get the Fluid --
        local amountAdded = localTank.insert_fluid({name=distantTank.inventoryFluid, amount=distantTank.inventoryCount, temperature = distantTank.inventoryTemperature})
        -- Remove the distant Fluid --
        distantTank:getFluid({name = distantTank.inventoryFluid, amount = amountAdded})
    end
end

-- Settings To Blueprint Tags --
function FI:settingsToBlueprintTags()
	local tags = {}
	local filter = nil
	local ID = nil

	-- Get Deep Tank and Filter --
	if self.selectedInv and valid(self.selectedInv) then
		ID = self.selectedInv.ID
		filter = self.selectedInv.filter
	end

	tags["deepTankID"] = ID
	tags["deepTankFilter"] = filter
	tags["selectedMode"] = self.selectedMode
	return tags
end

-- Blueprint Tags To Settings --
function FI:blueprintTagsToSettings(tags)
	local ID = tags["deepTankID"]
	local filter = tags["deepTankFilter"]
	--self.selectedInv = tags["selectedInv"]
	for k, deepTank in pairs(self.MF.dataNetwork.DTKTable) do
		if valid(deepTank) then
			if deepTank.ID == ID and filter == deepTank.filter then
				self.selectedInv = deepTank
				break
			elseif filter == deepTank.filter then
				self.selectedInv = deepTank
			end
		end
	end
	-- be careful of a nil selectedMode
	if tags["selectedMode"] then self.selectedMode = tags["selectedMode"] end
end