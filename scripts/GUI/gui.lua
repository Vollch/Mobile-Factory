require("scripts/GUI/main-gui.lua")
require("scripts/GUI/info-gui.lua")
require("scripts/GUI/option-gui.lua")
require("scripts/GUI/tooltip-gui.lua")
require("scripts/GUI/options.lua")
require("scripts/GUI/tp-gui.lua")
require("scripts/GUI/recipe-gui.lua")
require("utils/functions.lua")

-- Create a new GUI --
function GUI.createGUI(name, MFPlayer, direction, visible, posX, posY)
	if visible == nil then visible = false end
	if posX == nil then posX = 0 end
	if posY == nil then posY = 0 end
	local newGUIObj = GO:new(name, MFPlayer, direction)
	newGUIObj.gui.location = {posX,posY}
	newGUIObj.gui.style.margin = 0
	newGUIObj.gui.style.padding = 0
	return newGUIObj
end

-- Create a top Bar --
function GUI.createTopBar(GUIObj, minimalWidth, title)

	-- Create the Menu Bar --
	local topBar = GUIObj:addFrame("", GUIObj.gui, "vertical")
	local topBarFlow = GUIObj:addFlow("", topBar, "horizontal")
	topBarFlow.style.vertical_align = "center"

	-- Add the Draggable Area 1 --
	local dragArea1 = GUIObj:addEmptyWidget("", topBarFlow, GUIObj.gui, 20, nil)
	dragArea1.style.minimal_width = minimalWidth

	-- Add the Title Label --
	local barTitle = title or {"gui-description." .. GUIObj.gui.name .. "Title"}
	GUIObj:addLabel("", topBarFlow, barTitle, _mfOrange, nil, false, "TitleFont")

	-- Add the Draggable Area 2 --
	local dragArea2 = GUIObj:addEmptyWidget("", topBarFlow, GUIObj.gui, 20, nil)
	dragArea2.style.minimal_width = minimalWidth

	-- Add the Close Button --
	GUIObj:addButton("onToggleGui;GUI;"..GUIObj.gui.name, topBarFlow, "CloseIcon", "CloseIcon", {"gui-description.closeButton"}, 15)

	-- Return the TopBar --
	return topBar

end

-- Create a Camera Frame --
function GUI.createCamera(MFPlayer, name, ent, size, zoom)

	-- Create the Frame --
	local frameObj = GUI.createGUI("Camera" .. name, MFPlayer, "vertical", true)
	frameObj.style.width = size
	frameObj.style.height = size
	
	-- Add the Top Bar --
	GUI.createTopBar(frameObj, nil, name)
	
	-- Create the Camera --
    local camera = frameObj.gui.add{type="camera", position=ent.position, surface=ent.surface, zoom=zoom or 1}
    camera.style.vertically_stretchable = true
	camera.style.horizontally_stretchable = true

	-- Center the Frame --
	frameObj.force_auto_center()

	-- Return the Frame --
	return frameObj
	
end

function GUI.updatePlayerGUIs(event)
	local MFPlayer = getMFPlayer(event.player_index)
	for _, GUI in pairs(MFPlayer.GUI) do
		if valid(GUI) then GUI:update() end
	end
end

-- Update all GUIs --
function GUI.updateAllGUIs(force)
	
		for k, MFPlayer in pairs(global.playersTable or {}) do

			-- Update all Progress Bars of the Data Assembler  --
			if game.tick%_eventTick7 == 0 or force then
				if MFPlayer.GUI ~= nil and MFPlayer.GUI.MFTooltipGUI ~= nil and MFPlayer.GUI.MFTooltipGUI.DA ~= nil then
					MFPlayer.GUI.MFTooltipGUI.DA:updatePBars(MFPlayer.GUI.MFTooltipGUI)
				end
			end

			-- Update all GUIs --
			if game.tick%_eventTick55 == 0 or force then
			for k2, go in pairs(MFPlayer.GUI or {}) do
				if valid(go) then go:update() end
			end

		end
	end
end

-- A GUI was oppened --
function GUI.guiOpened(event)
	
	-- Check the Entity --
	if event.entity == nil or event.entity.valid == false then return end

	-- Get the Player --
	local player = getPlayer(event.player_index)

	-- Check the Player --
	if player == nil or player.valid == false then return end

	-- do not open custom GUI if player is connecting wires --
	local cursorStack = player.cursor_stack
	if cursorStack and cursorStack.valid_for_read then
		if cursorStack.name == "green-wire" or cursorStack.name == "red-wire" or cursorStack.type == "repair-tool" then return end
	end

	-- Check the Bypass --
	if getMFPlayer(player.index).varTable.bypassGUI == true then
		getMFPlayer(player.index).varTable.bypassGUI = false
		return
	end

	-- Check if a GUI exist --
	local obj = global.entsTable[event.entity.unit_number]
	
	-- Check the Object --
	if valid(obj) == false or obj.getTooltipInfos == nil then return end

	-- Check Permissions --
	if Util.canUse(getMFPlayer(event.player_index), obj) == false then return end

	-- Create and save the Tooltip gui --
	player.opened = GUI.createTooltipGUI(player, obj).gui
end

-- A GUI was closed --
function GUI.guiClosed(event)
	-- Check the Element --
	if event.element == nil or event.element.valid ~= true then return end

	-- Get the Player --
	local playerIndex = event.player_index
	local MFPlayer = getMFPlayer(playerIndex)

	-- Close the GUI --
	local guiName = event.element.name
	if MFPlayer.GUI[guiName] ~= nil then
		MFPlayer.GUI[guiName].destroy()
		MFPlayer.GUI[guiName] = nil
		return
	end
end

-- When a GUI Button is clicked --
function GUI.onGuiEvent(event)
	-- Return if this is not a Mobile Factory element -
	if event.element.get_mod() ~= "Mobile_Factory" then return end
	-- Return if the Element is not valid --
	if event.element == nil or event.element.valid == false then return end
	game.print("GUI Event: "..event.name)
	------- Read if the Element came from the Option GUI -------
	GUI.readOptions(event)
	if event.element == nil or event.element.valid == false then return end

	-- Format: callback;tag-or-entid;comma-separated-cb-arguments,arg2,arg3
	-- Something like onItemClicked;123;1 -or- onOptionChanged;GUI;foo,bar,baz -or- onStorageChanged;123 -or- onMainGUIMinimized;GUI
	local args = split(event.element.name, ";")
	if table_size(args) >= 2 then
		-- Read args
		local callback = args[1]
		local objID = tonumber(args[2])
		local cbArgs = args[3] and split(args[3], ",") or {}
		-- Call callback
		if objID ~= nil then
			local obj = global.entsTable[objID]
			if valid(obj) == true and type(obj[callback]) == "function" then
				local ret = obj[callback](obj, event, cbArgs)
				if ret ~= false then
					GUI.updatePlayerGUIs(event)
					return
				end
			end
		else
			local tagTable = _G[args[2]]
			if type(tagTable) == "table" and type(tagTable[callback]) == "function" then
				local ret = tagTable[callback](event, cbArgs)
				if ret ~= false then 
					GUI.updatePlayerGUIs(event)
					return
				end
			end
		end
	end
end

-- Open or close GUI --
function GUI.onToggleGui(event, args)
	local guiName = args[1]
	local playerIndex = event.player_index
	local player = getPlayer(playerIndex)
	local MFPlayer = getMFPlayer(playerIndex)
	if MFPlayer.GUI[guiName] == nil then
		local GUIObj = GUI["create" .. guiName](player)
		if args[2] ~= "stackOnTop" then
			player.opened = GUIObj.gui
		end
	else
		MFPlayer.GUI[guiName].destroy()
		MFPlayer.GUI[guiName] = nil
	end
end

-- Called when a Localized Name is requested --
function onStringTranslated(event)
	local MFPlayer = getMFPlayer(event.player_index)
	if MFPlayer == nil then return end
	if MFPlayer.varTable and MFPlayer.varTable.tmpLocal == nil then
		MFPlayer.varTable.tmpLocal = {}
	end
	if event.localised_string[1] == nil then return end
	MFPlayer.varTable.tmpLocal[event.localised_string[1]] = event.result
end
