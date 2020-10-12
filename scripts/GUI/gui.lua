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
	GUIObj:addButton(GUIObj.gui.name.. "CloseButton", topBarFlow, "CloseIcon", "CloseIcon", {"gui-description.closeButton"}, 15)

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

	-- Close the Option GUI --
	if event.element.name == "MFOptionGUI" then
		MFPlayer.GUI["MFOptionGUI"].destroy()
		MFPlayer.GUI["MFOptionGUI"] = nil
		return
	end

	-- Close the Info GUI --
	if event.element.name == "MFInfoGUI" then
		MFPlayer.GUI["MFInfoGUI"].destroy()
		MFPlayer.GUI["MFInfoGUI"] = nil
		return
	end

	-- Close the Tootip GUI --
	if event.element.name == "MFTooltipGUI" then
		MFPlayer.GUI["MFTooltipGUI"].destroy()
		MFPlayer.GUI["MFTooltipGUI"] = nil
		return
	end

	-- Close the TP GUI --
	if event.element.name == "MFTPGUI" then
		MFPlayer.GUI["MFTPGUI"].destroy()
		MFPlayer.GUI["MFTPGUI"] = nil
		return
	end

	-- Close Camera GUI --
	if string.match(event.element.name, "Camera") then
		local cameraName = event.element.name
		if MFPlayer.GUI[cameraName] ~= nil then
			MFPlayer.GUI[cameraName].destroy()
			MFPlayer.GUI[cameraName] = nil
		end
		return
	end

end

-- When a GUI Button is clicked --
function GUI.buttonClicked(event)
	-- Get the Player --
	local playerIndex = event.player_index
	local player = getPlayer(playerIndex)
	local MFPlayer = getMFPlayer(playerIndex)

	-- Get the Mobile Factory --
	local MF = getMF(player.name)
	if MF == nil then return end

	-- Get the Main GUI Object --
	local mainGUI = MFPlayer.GUI["MFMainGUI"]

	------- Read if the Element came from the Option GUI -------
	GUI.readOptions(event.element, player)
	if event.element == nil or event.element.valid == false then return end

	-- Open Options GUI Button --
	if event.element.name == "MainGUIOptionButton" then
		if MFPlayer.GUI["MFOptionGUI"] == nil then
			local GUIObj = GUI.createOptionGUI(player)
			player.opened = GUIObj.gui
		else
			MFPlayer.GUI["MFOptionGUI"].destroy()
			MFPlayer.GUI["MFOptionGUI"] = nil
		end
		return
	end

	-- Open Info GUI Button --
	if event.element.name == "MainGUIInfosButton" then
		if MFPlayer.GUI["MFInfoGUI"] == nil then
			local GUIObj = GUI.createInfoGui(player)
			player.opened = GUIObj.gui
		else
			MFPlayer.GUI["MFInfoGUI"].destroy()
			MFPlayer.GUI["MFInfoGUI"] = nil
		end
		return
	end

	-- Extend or reduce the Main GUI --
	if event.element.name == "MainGUIReduceButton" then
		local leftSprite = "ArrowIconLeft"
		local rightSprite = "ArrowIconRight"
		if mainGUI.MFPlayer.varTable.MainGUIDirection == "left" then
			leftSprite = "ArrowIconRight"
			rightSprite = "ArrowIconLeft"
		end
		local columns = ((math.floor((table_size(mainGUI.MFMainGUIFrame3.children)-1 ))))
		local decal = 138
        if columns > 0 then decal = decal + 29 + (18 * (columns-1)) end
		decal = decal * player.display_scale
		if mainGUI.MFMainGUIFrame2.visible == false then
			if mainGUI.MFPlayer.varTable.MainGUIDirection == "left" then mainGUI.location = {mainGUI.location.x - decal, mainGUI.location.y} end
			mainGUI.MFMainGUIFrame2.visible = true
			mainGUI.MFMainGUIFrame3.visible = true
			mainGUI.MainGUIReduceButton.sprite = leftSprite
			mainGUI.MainGUIReduceButton.hovered_sprite = leftSprite
		else
			if mainGUI.MFPlayer.varTable.MainGUIDirection == "left" then mainGUI.location = {mainGUI.location.x + decal, mainGUI.location.y} end
			mainGUI.MFMainGUIFrame2.visible = false
			mainGUI.MFMainGUIFrame3.visible = false
			mainGUI.MainGUIReduceButton.sprite = rightSprite
			mainGUI.MainGUIReduceButton.hovered_sprite = rightSprite
		end
		GUI.updateMFMainGUI(MFPlayer.GUI["MFMainGUI"])
		return
	end

	-- Jump Drive Button --
	if event.element.name == "JumpDriveButton" then
		if MFPlayer.GUI["MFTPGUI"] == nil then
			local GUIObj = GUI.createTPGui(player)
			player.opened = GUIObj.gui
		else
			MFPlayer.GUI["MFTPGUI"].destroy()
			MFPlayer.GUI["MFTPGUI"] = nil
		end
		return
	end

	-- PortOutside button --
	if event.element.name == "PortOutsideButton" then
		teleportPlayerOutside(player)
		return
	end

	-- SyncArea button --
	if event.element.name == "SyncAreaButton" then
		if MF.syncAreaEnabled == true then MF.syncAreaEnabled = false
		elseif MF.syncAreaEnabled == false then MF.syncAreaEnabled = true end
		return
	end

	-- Fix Mobile Factory Button --
	if event.element.name == "FindMFButton" then
		fixMB(event)
		return
	end

	-- MFTPInside button --
	if event.element.name == "TPInsideButton" then
		if MF.tpEnabled == true then MF.tpEnabled = false
		elseif MF.tpEnabled == false then MF.tpEnabled = true end
		return
	end

	-- MFLock button --
	if event.element.name == "LockMFButton" then
		if MF.locked == true then
			MF.locked = false
			player.print({"gui-description.MFUnlocked"})
		else
			MF.locked = true
			player.print({"gui-description.MFLocked"})
		end
		return
	end

	-- EnergyDrain button --
	if event.element.name == "EnergyDrainButton" then
		if MF.energyLaserActivated == true then MF.energyLaserActivated = false
		elseif MF.energyLaserActivated == false then MF.energyLaserActivated = true end
		return
	end

	-- FluidDrain button --
	if event.element.name == "FluidDrainButton" then
		if MF.fluidLaserActivated == true then MF.fluidLaserActivated = false
		elseif MF.fluidLaserActivated == false then MF.fluidLaserActivated = true end
		return
	end

	-- ItemDrain button --
	if event.element.name == "ItemDrainButton" then
		if MF.itemLaserActivated == true then MF.itemLaserActivated = false
		elseif MF.itemLaserActivated == false then MF.itemLaserActivated = true end
		return
	end

	-- Send Quatron button --
	if event.element.name == "QuatronDrainButton" then
		if MF.quatronLaserActivated == true then MF.quatronLaserActivated = false
		elseif MF.quatronLaserActivated == false then MF.quatronLaserActivated = true end
		return
	end

	-- Close Recipe GUI Button --
	if event.element.name == "RecipeGUICloseButton" then
		if MFPlayer.GUI["RecipeGUI"] ~= nil then
			MFPlayer.GUI["RecipeGUI"].destroy()
			MFPlayer.GUI["RecipeGUI"] = nil
		end
		return
	end

	-- Close Info GUI Button --
	if event.element.name == "MFInfoGUICloseButton" then
		if MFPlayer.GUI["MFInfoGUI"] ~= nil then
			MFPlayer.GUI["MFInfoGUI"].destroy()
			MFPlayer.GUI["MFInfoGUI"] = nil
		end
		return
	end

	-- Close Options GUI Button --
	if event.element.name == "MFOptionGUICloseButton" then
		if MFPlayer.GUI["MFOptionGUI"] ~= nil then
			MFPlayer.GUI["MFOptionGUI"].destroy()
			MFPlayer.GUI["MFOptionGUI"] = nil
		end
		return
	end

	-- Close Tooltip GUI Button --
	if event.element.name == "MFTooltipGUICloseButton" then
		if MFPlayer.GUI["MFTooltipGUI"] ~= nil then
			MFPlayer.GUI["MFTooltipGUI"].destroy()
			MFPlayer.GUI["MFTooltipGUI"] = nil
		end
		return
	end

	-- Close TP GUI Button --
	if event.element.name == "MFTPGUICloseButton" then
		if MFPlayer.GUI["MFTPGUI"] ~= nil then
			MFPlayer.GUI["MFTPGUI"].destroy()
			MFPlayer.GUI["MFTPGUI"] = nil
		end
		return
	end

	-- Close Camera Button --
	if string.match(event.element.name, "Camera") then
		local text = string.gsub(event.element.name, "CloseButton", "")
		if MFPlayer.GUI[text] ~= nil then
			MFPlayer.GUI[text].destroy()
			MFPlayer.GUI[text] = nil
		end
		return
	end

	-- Info GUI Deep Tank Button --
	if string.match(event.element.name, "DTB") then
		-- Get the Deep Tank ID --
		local id = tonumber(split(event.element.name, "DTB")[1])
		if global.deepTankTable[id] == nil then return end
		GUI.updateDeepTankInfo(MFPlayer.GUI["MFInfoGUI"], id)
		return
	end

	-- Info GUI Deep Storage Button --
	if string.match(event.element.name, "DSRB") then
		-- Get the Deep Storage ID --
		local id = tonumber(split(event.element.name, "DSRB")[1])
		if global.deepStorageTable[id] == nil then return end
		GUI.updateDeepStorageInfo(MFPlayer.GUI["MFInfoGUI"], id)
		return
	end

	-- Info GUI Inventory Item Button -> Deep Tank --
	if string.match(event.element.name, "INVBDT") then
		-- Get the Fluid --
		local id = tonumber(split(event.element.name, ",")[2])
		GUI.updateInventoryInfo(MFPlayer.GUI["MFInfoGUI"], id, "DT")
		return
	end

	-- Info GUI Inventory Item Button -> Deep Storage --
	if string.match(event.element.name, "INVBDSR") then
		-- Get the Item --
		local id = tonumber(split(event.element.name, ",")[2])
		GUI.updateInventoryInfo(MFPlayer.GUI["MFInfoGUI"], id, "DSR")
		return
	end

	-- Info GUI Inventory Item Button -> Inventory --
	if string.match(event.element.name, "INVBINV") then
		-- Get the Item --
		local item = split(event.element.name, ",")[2]
		local amount = split(event.element.name, ",")[3]
		GUI.updateInventoryInfo(MFPlayer.GUI["MFInfoGUI"], nil, "INV", item, amount)
		return
	end

	-- If this is a Mobile Factory Button -> Open Inventory --
	if string.match(event.element.name, "MFOpenI") then
		-- Get the Object --
		local objId = split(event.element.name, ",")[2]
		local ent = global.MFTable[objId].ent
		if ent ~= nil and ent.valid == true then
			getMFPlayer(player.name).varTable.bypassGUI = true
			player.opened = ent
		end
		return
	end

	-- If this is a Mater Interactor Button -> Open Inventory --
	if string.match(event.element.name, "MIOpenI") then
		-- Get the Object --
		local objId = tonumber(split(event.element.name, ",")[2])
		local ent = global.matterInteractorTable[objId].ent
		if ent ~= nil and ent.valid == true then
			getMFPlayer(player.name).varTable.bypassGUI = true
			player.opened = ent
		end
		return
	end

	-- If this is a Wireless Data Transmitter Button -> Show WDR --
	-- if string.match(event.element.name, "WDTCam") then
	-- 	-- Get the Object --
	-- 	local objId = tonumber(split(event.element.name, ",")[2])
	-- 	local ent = global.wirelessDataReceiverTable[objId].ent
	-- 	if ent ~= nil and ent.valid == true then
	-- 		local cameraObj = GUI.createCamera(getMFPlayer(player.name), ent.unit_number, ent, 250, 0.5)
	-- 		cameraObj:addDualLabel(cameraObj.gui, {"", {"gui-description.Position"}, ":"}, "{".. ent.position.x .. ";" .. ent.position.y .. "}", _mfOrange, _mfGreen)
	-- 		player.opened = cameraObj.gui
	-- 	end
	-- 	return
	-- end

	-- If this is a Network Explorer --
	if string.match(event.element.name, "NE") then
		local count = 1
		if event.alt == true then count = 10 end
		if event.control == true then count = 100 end
		if event.shift == true then count = nil end
		if event.button == defines.mouse_button_type.right then count = -1 end
		if event.button == defines.mouse_button_type.right and event.shift == true then count = 99999999 end
		-- If it's a Deep Tank, do nothing --
		if string.match(event.element.name, "NEBDT") then
			return
		end
		-- If it's a Deep Storage --
		if string.match(event.element.name, "BDS") then
			local objId = tonumber(split(event.element.name, ",")[4])
			local obj = global.deepStorageTable[objId]
			NE.transferItemsFromDS(obj, getMFPlayer(playerIndex).ent.get_main_inventory(), count)
		end
		-- If it's a Data Network Inventory --
		if string.match(event.element.name, "BINV") then
			local objId = tonumber(split(event.element.name, ",")[2])
			local obj = global.networkExplorerTable[objId]
			NE.transferItemsFromDNInv(obj, getMFPlayer(playerIndex).ent.get_main_inventory(), split(event.element.name, ",")[4], count)
		end
		-- If it's a player Inventory --
		if string.match(event.element.name, "BPINV") then
			local objId = tonumber(split(event.element.name, ",")[2])
			local obj = global.networkExplorerTable[objId]
			NE.transferItemsFromPInv(getMFPlayer(playerIndex).ent.get_main_inventory(), getMFPlayer(playerIndex).name, obj, split(event.element.name, ",")[4], count)
		end
		-- Update all GUIs --
		GUI.updateAllGUIs(true)
		return
	end

	-- Recipe Selector
	if string.match(event.element.name, "RS") then
		if string.match(event.element.name, "RSCat") then
			local GUIObj = MFPlayer.GUI["RecipeGUI"]
			local Category = tonumber(split(event.element.name, ",")[2]) or 1
			GUIObj["RSCat," .. GUIObj.selectedCategory].enabled = true
			GUIObj["RSCat," .. Category].enabled = false
			GUIObj.selectedCategory = Category
			GUI.doUpdateRecipeGUI(GUIObj)
			return
		end
		if string.match(event.element.name, "RSSel") then
			local GUIObj = MFPlayer.GUI["RecipeGUI"]
			local tGUI = MFPlayer.GUI["MFTooltipGUI"]
			if tGUI ~= nil and tGUI.DA ~= nil then
				tGUI.DARecipe.elem_value = split(event.element.name, ",")[2]
			end
			MFPlayer.GUI["RecipeGUI"].destroy()
			MFPlayer.GUI["RecipeGUI"] = nil
			GUI.updateAllGUIs(true)
		  return
		end
	end

	-- If this is a Data Assembler --
	-- Select Recipe --
	if event.element.name == "DARecipe" and global.useVanillaChooseElem == false then
		if MFPlayer.GUI["RecipeGUI"] ~= nil then
			MFPlayer.GUI["RecipeGUI"].destroy()
			MFPlayer.GUI["RecipeGUI"] = nil
		end
		GUI.createRecipeGUI(player)
		return
	end
	if string.match(event.element.name, "DA") and event.element.type == "sprite-button" then
		-- If a Recipe must be added --
		if string.match(event.element.name, "DAAddR") then
			local GUIObj = MFPlayer.GUI["MFTooltipGUI"]
			local objID = tonumber(split(event.element.name, ",")[2])
			local obj = global.dataAssemblerTable[objID]
			if valid(obj) == false then return end
			local recipe = GUIObj.DARecipe.elem_value
			local amount = GUIObj.DAAmount.text
			GUIObj.DARecipe.elem_value = nil
			GUIObj.DAAmount.text = ""
			obj:addRecipe(recipe, amount)
		end
		if string.match(event.element.name, "DARem") and event.button == defines.mouse_button_type.right then
			local objID = tonumber(split(event.element.name, ",")[2])
			local obj = global.dataAssemblerTable[objID]
			local recipeID = tonumber(split(event.element.name, ",")[3])
			if valid(obj) == false then return end
			obj:removeRecipe(recipeID)
		end
		if string.match(event.element.name, "DASwap") then
			local objID = tonumber(split(event.element.name, ",")[2])
			local obj = global.dataAssemblerTable[objID]
			local recipeID = tonumber(split(event.element.name, ",")[3])
			local productID = tonumber(split(event.element.name, ",")[4])
			if valid(obj) == false then return end
			local products = obj.recipeTable[recipeID].products
			products[1], products[productID] = products[productID], products[1]
		end
		-- Update all GUIs --
		GUI.updateAllGUIs(true)
		return
	end

	-- If this is a Network Access Point Area Switch --
	if string.match(event.element.name, "NAPAreaSwitch") then
		-- Get the Object --
		local objID = tonumber(split(event.element.name, ",")[2])
		local obj = global.networkAccessPointTable[objID]
		if valid(obj) == false then return end
		if event.element.switch_state == "left" then 
			obj.showArea = false
		else
			obj.showArea = true
		end
		return
	end

	-- If this is The Jump Drive GUI --
	if string.match(event.element.name, "TPGUI") and event.element.type == "sprite-button" then
		-- If a location is added --
		if string.match(event.element.name, "TPGUIAddLoc") then
			local GUIObj = MFPlayer.GUI["MFTPGUI"]
			local jumpDrive = GUIObj.MF.jumpDriveObj
			jumpDrive:addLocation(GUIObj.AddLocName.text, GUIObj.AddLocFilter.elem_value)
		end
		if string.match(event.element.name, "TPGUILoc") then
			local GUIObj = MFPlayer.GUI["MFTPGUI"]
			local jumpDrive = GUIObj.MF.jumpDriveObj
			local location = split(event.element.name, ",")[2]
			-- Start the Jump --
			if event.button == defines.mouse_button_type.left then
				jumpDrive:jump(location)
			end
			-- Remove a Location --
			if event.button == defines.mouse_button_type.right then
				jumpDrive:removeLocation(location)
			end
		end
		-- Update all GUIs --
		GUI.updateAllGUIs(true)
		return
	end

end

-- Called when a GUI Element have changed it's state --
function GUI.onGuiElemChanged(event)
	-- Return if this is not a Mobile Factory element -
	if event.element.get_mod() ~= "Mobile_Factory" then return end
	-- Return if the Element is not valid --
	if event.element == nil or event.element.valid == false then return end
	-- Get the Player --
	local playerIndex = event.player_index
	local player = getPlayer(playerIndex)
	local MFPlayer = getMFPlayer(playerIndex)
	-- Return if the Player is not valid --
	if player == nil then return end
	-- Get the Mobile Factory --
	local MF = getMF(player.name)
	if MF == nil then return end

	-- Check whose event it is
	if event.element.get_mod() ~= script.mod_name then return end

	-- Format: callback;tag;entid-or-0;comma-separated-cb-arguments,arg2,arg3
	-- Something like onItemClicked;NE;123;1 -or- onOptionChanged;GUI;0;foo,bar,baz -or- onStorageChanged;OC;123 -or- onMainGUIMinimized;GUI
	local args = split(event.element.name, ";")
	if table_size(args) >= 2 then
		-- Read args
		local callback = args[1]
		local tag =_G[args[2]]
		-- Check callback
		if tag == nil or tag[callback] == nil then return end
		local objID = args[3] or "0"
		local args = split(args[4] or "", ",")
		-- Call callback
		if objID ~= "0" then
			local obj = global.entsTable[objID]
			if not valid(obj) then return end
			tag[callback](obj, event, MFPlayer, args)
		else
			tag[callback](event, MFPlayer, args)
		end
		-- This thing is horrible performance-wise, it need to update single gui, not everything for everyone. Acts as placeholder for now.
		GUI.updateAllGUIs(true)
		return
	end
	
	------- Read if the Element came from the Option GUI -------
	GUI.readOptions(event.element, player)
	if event.element == nil or event.element.valid == false then return end
	
	------- Save the filter -------
	if event.element.type == "choose-elem-button" and event.element.get_mod() == "Mobile_Factory" then
		local id = event.element.name

		-- If this is a Deep Storage --
		if string.match(id, "DSRF") then
			id = tonumber(split(id, "DSRF")[1])
			if global.deepStorageTable[id] == nil then return end
			if event.element.elem_value ~= nil then
				global.deepStorageTable[id].filter = event.element.elem_value
			else
				global.deepStorageTable[id].filter = nil
			end
			if MFPlayer.GUI["MFInfoGUI"] ~= nil then GUI.updateDeepStorageInfo(MFPlayer.GUI["MFInfoGUI"], id) end
			GUI.updateAllGUIs(true)
			return
		end

		-- If this is a Deep Tank --
		if string.match(id, "TF") then
			-- Get the Deep Tank ID --
			id = tonumber(split(id, "TF")[1])
			if global.deepTankTable[id] == nil then return end
			if event.element.elem_value ~= nil then
				global.deepTankTable[id].filter = event.element.elem_value
			else
				global.deepTankTable[id].filter = nil
			end
			if MFPlayer.GUI["MFInfoGUI"] ~= nil then GUI.updateDeepTankInfo(MFPlayer.GUI["MFInfoGUI"], id) end
			GUI.updateAllGUIs(true)
			return
		end

		-- If this is a Matter Interactor --
		if string.match(id, "MIFilter") then
			id = tonumber(split(id, "MIFilter")[1])
			if global.matterInteractorTable[id] == nil then return end
			if event.element.elem_value ~= nil then
				global.matterInteractorTable[id].selectedFilter = event.element.elem_value
			else
				global.matterInteractorTable[id].selectedFilter = nil
			end
			GUI.updateAllGUIs(true)
			return
		end
	end


	------- Read if the Element comes from a Fluid Extractor -------
	if string.match(event.element.name, "FE") then
		-- Find the Fluid Extractor ID --
		local ID = split(event.element.name, "FE")
		ID = tonumber(ID[1])
		-- Check the ID --
		if ID == nil then return end
		-- Find the Fluid Extractor --
		local fluidExtractor = nil
		for k, fe in pairs(global.fluidExtractorTable) do
			if valid(fe) == true and fe.ent.unit_number == ID then
				fluidExtractor = fe
			end
		end
		-- Check if a Fluid Extractor was found --
		if fluidExtractor == nil then return end
		-- Change the Fluid Extractor targeted Dimensional Tank --
		fluidExtractor:changeDimTank(tonumber(event.element.items[event.element.selected_index][4]))
	end
	
	------- Read if the Element comes from a Matter Serializer -------
	if string.match(event.element.name, "MS") then
		-- Find the Matter Serializer ID --
		local ID = split(event.element.name, "MS")
		ID = tonumber(ID[1])
		-- Check the ID --
		if ID == nil then return end
		-- Find the Matter Serializer --
		local matterS = nil
		for k, ms in pairs(global.matterSerializerTable) do
			if valid(ms) == true and ms.ent.unit_number == ID then
				matterS = ms
			end
		end
		-- Check if a Matter Serializer was found --
		if matterS == nil then return end
		-- Change the Matter Serializer targeted Inventory --
		matterS:changeInventory(tonumber(event.element.items[event.element.selected_index][4]))
	end
	
	------- Read if the Element comes from a Matter Printer -------
	if string.match(event.element.name, "MP") then
		-- Find the Matter Printer ID --
		local ID = split(event.element.name, "MP")
		ID = tonumber(ID[1])
		-- Check the ID --
		if ID == nil then return end
		-- Find the Matter Printer --
		local matterP = nil
		for k, mp in pairs(global.matterPrinterTable) do
			if valid(mp) == true and mp.ent.unit_number == ID then
				matterP = mp
			end
		end
		-- Check if a Matter Printer was found --
		if matterP == nil then return end
		-- Change the Matter Printer targeted Inventory --
		matterP:changeInventory(tonumber(event.element.items[event.element.selected_index][4]))
	end

	------- Read if the Element comes from a Matter Interactor Mode -------
	if string.match(event.element.name, "MIMode") then
		local ID = split(event.element.name, "MIMode")
		ID = tonumber(ID[1])
		-- Check the ID --
		if ID == nil then return end
		-- Find the Matter Manipulator --
		local matterI = nil
		for k, mi in pairs(global.matterInteractorTable) do
			if valid(mi) == true and mi.ent.unit_number == ID then
				matterI = mi
			end
		end
		-- Check if a Fluid Interactor was found --
		if matterI == nil then return end
		-- Change the Mode --
		matterI:changeMode(event.element.switch_state)
	end

	------- Read if the Element comes from a Matter Interactor Player Target -------
	if string.match(event.element.name, "MIPlayerTarget") then
		local ID = split(event.element.name, "MIPlayerTarget")
		ID = tonumber(ID[1])
		-- Check the ID --
		if ID == nil then return end
		-- Find the Matter Interactor --
		local matterI = nil
		for k, mi in pairs(global.matterInteractorTable) do
			if valid(mi) == true and mi.ent.unit_number == ID then
				matterI = mi
			end
		end
		-- Check if a Matter Interactor was found --
		if matterI == nil then return end
		-- Change the Matter Interactor Player Target --
		matterI:changePlayer(event.element.items[event.element.selected_index][2])
	end

	------- Read if the Element comes from a Matter Interactor Target -------
	if string.match(event.element.name, "MITarget") then
		local ID = split(event.element.name, "MITarget")
		ID = tonumber(ID[1])
		-- Check the ID --
		if ID == nil then return end
		-- Find the Matter Interactor --
		local matterI = nil
		for k, mi in pairs(global.matterInteractorTable) do
			if valid(mi) == true and mi.ent.unit_number == ID then
				matterI = mi
			end
		end
		-- Check if a Matter Interactor was found --
		if matterI == nil then return end
		-- Change the Matter Interactor Target --
		matterI:changeInventory(tonumber(event.element.items[event.element.selected_index][5]))
	end

	------- Read if the Element comes from a Fluid Interactor Mode -------
	if string.match(event.element.name, "FIMode") then
		local ID = split(event.element.name, "FIMode")
		ID = tonumber(ID[1])
		-- Check the ID --
		if ID == nil then return end
		-- Find the Fluid Manipulator --
		local fluidI = nil
		for k, fi in pairs(global.fluidInteractorTable) do
			if valid(fi) == true and fi.ent.unit_number == ID then
				fluidI = fi
			end
		end
		-- Check if a Fluid Interactor was found --
		if fluidI == nil then return end
		-- Change the Mode --
		fluidI:changeMode(event.element.switch_state)
	end

	------- Read if the Element comes from a Fluid Interactor Target -------
	if string.match(event.element.name, "FITarget") then
		local ID = split(event.element.name, "FITarget")
		ID = tonumber(ID[1])
		-- Check the ID --
		if ID == nil then return end
		-- Find the Fluid Manipulator --
		local fluidI = nil
		for k, fi in pairs(global.fluidInteractorTable) do
			if valid(fi) == true and fi.ent.unit_number == ID then
				fluidI = fi
			end
		end
		-- Check if a Fluid Interactor was found --
		if fluidI == nil then return end
		-- Change the Fluid Interactor Target --
		fluidI:changeInventory(tonumber(event.element.items[event.element.selected_index][5]))
	end

	------- Read if the Element comes from The Mobile Factory Energy Laser -------
	if string.match(event.element.name, "MFEL") then
		-- Change the Matter Serializer targeted Inventory --
		if event.element.switch_state == "left" then
			MF.selectedEnergyLaserMode = "input"
		else
			MF.selectedEnergyLaserMode = "output"
		end
	end

	------- Read if the Element comes from The Mobile Factory Quatron Laser -------
	if string.match(event.element.name, "MFQL") then
		-- Change the Matter Serializer targeted Inventory --
		if event.element.switch_state == "left" then
			MF.selectedQuatronLaserMode = "input"
		else
			MF.selectedQuatronLaserMode = "output"
		end
	end

	------- Read if the Element comes from the Mobile Factory Fluid Laser mode -------
	if string.match(event.element.name, "MFFMode") then
		-- Change the Mode --
		if event.element.switch_state == "left" then
			MF.selectedFluidLaserMode = "input"
		else
			MF.selectedFluidLaserMode = "output"
		end
	end

	------- Read if the Element comes from the Mobile Factory Fluid Laser Target -------
	if string.match(event.element.name, "MFFTarget") then
		-- Change the Fluid Interactor Target --
		MF:fluidLaserTarget(tonumber(event.element.items[event.element.selected_index][4]))
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
