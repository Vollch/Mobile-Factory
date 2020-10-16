-- Create the Main GUI --
function GUI.createMFMainGUI(player)

	local posX = 300
	local posY = 0
	local visible = true
	local playerIndex = player.index
	local MFPlayer = getMFPlayer(playerIndex)
	if MFPlayer.GUI == nil then MFPlayer.GUI = {} end

	local existingGUI = MFPlayer.GUI["MFMainGUI"]
	if valid(player) == true then
		if valid(existingGUI) then
			if existingGUI.location then
				-- no location if it has not been moved/set
				posX = existingGUI.location.x
				posY = existingGUI.location.y
			end
			visible = existingGUI.MFMainGUIFrame2.visible
		else
			MFPlayer.GUI["MFMainGUI"] = nil
		end
	else
		MFPlayer.GUI["MFMainGUI"] = nil
		return nil
	end

	-- Create the GUI --
	local GUIObj = GUI.createGUI("MFMainGUI", getMFPlayer(player.name), "horizontal", true, posX, posY)
	local mfGUI = GUIObj.gui

	-- Create the Main Frame --
	local MFMainGUIMainFlow = GUIObj:addFlow("MFMainGUIMainFlow", mfGUI, "horizontal")

	-- Create the Frames --
	local MFMainGUIFrame1 = nil
	local MFMainGUIFrame2 = nil
	local MFMainGUIFrame3 = nil
	local ExtendButtonSprite = "ArrowIconLeft"
	if GUIObj.MFPlayer.varTable.MainGUIDirection == "left" then
		MFMainGUIFrame3 = GUIObj:addFrame("MFMainGUIFrame3", MFMainGUIMainFlow, "horizontal", true)
		MFMainGUIFrame2 = GUIObj:addFrame("MFMainGUIFrame2", MFMainGUIMainFlow, "vertical", true)
		MFMainGUIFrame1 = GUIObj:addFrame("MFMainGUIFlow1", MFMainGUIMainFlow, "vertical")
		if visible == true then ExtendButtonSprite = "ArrowIconRight" end
	else
		MFMainGUIFrame1 = GUIObj:addFrame("MFMainGUIFlow1", MFMainGUIMainFlow, "vertical")
		MFMainGUIFrame2 = GUIObj:addFrame("MFMainGUIFrame2", MFMainGUIMainFlow, "vertical", true)
		MFMainGUIFrame3 = GUIObj:addFrame("MFMainGUIFrame3", MFMainGUIMainFlow, "horizontal", true)
		if visible == false then ExtendButtonSprite = "ArrowIconRight" end
	end

	-- Add the Draggable Area  --
	GUIObj:addEmptyWidget("MainGUIDragArea", MFMainGUIFrame1, mfGUI, 15, 15)

	-- Add All Buttons --
	GUIObj:addButton("onToggleGui;GUI;MFOptionGUI", MFMainGUIFrame1, "OptionIcon", "OptionIcon", {"gui-description.optionButton"}, 15)
	GUIObj:addButton("onToggleGui;GUI;MFInfoGUI", MFMainGUIFrame1, "MFIconI", "MFIconI", {"gui-description.MFInfosButton"}, 15)
	GUIObj:addButton("onReduceMainGUI;GUI", MFMainGUIFrame1, ExtendButtonSprite, ExtendButtonSprite, {"gui-description.reduceButton"}, 15, "MainGUIReduceButton")

	-- Make the GUI visible or not --
	MFMainGUIFrame2.visible = visible
	MFMainGUIFrame3.visible = visible

	-- Update the GUI and return the GUI Object --
	GUI.updateMFMainGUI(GUIObj)
	return mfGUI

end

function GUI.updateMFMainGUI(GUIObj)

	-- Get MF and Player --
	local MF = GUIObj.MF
	local player = GUIObj.MFPlayer.ent

	-- Clear the Frame --
	GUIObj.MFMainGUIFrame2.clear()

	-------------------------------------------------------- Get Information Variables --------------------------------------------------------
	local mfPositionText = {"", {"gui-description.mfPosition"}, ": ", {"gui-description.Unknow"}}
	local mfHealthValue = 0
	local mfHealthText = {"", {"gui-description.mfHealth"}, ": ", {"gui-description.Unknow"}}
	local mfShielValue = 0
	local mfShieldText = {"", {"gui-description.mfShield"}, ": ", {"gui-description.Unknow"}}
	local mfEnergyValue = 0
	local mfEnergyText = {"", {"gui-description.mfEnergyCharge"}, ": ", {"gui-description.Unknow"}}
	local mfQuatronValue = 0
	local mfQuatronText = {"", {"gui-description.mQuatronCharge"}, ": ", {"gui-description.Unknow"}}
	local mfJumpDriveValue = 0
	local mfJumpDriveText = {"", {"gui-description.mfJumpCharge"}, ": ", {"gui-description.Unknow"}}

	if MF.ent ~= nil and MF.ent.valid == true then
		mfPositionText = {"", {"gui-description.mfPosition"}, ": (", math.floor(MF.ent.position.x), " ; ", math.floor(MF.ent.position.y), ")  ", MF.ent.surface.name}
		mfHealthValue = MF.ent.health / MF.ent.prototype.max_health
		mfHealthText = {"", {"gui-description.mfHealth"}, ": ", math.floor(MF.ent.health), "/", MF.ent.prototype.max_health}
		mfShielValue = 0
		mfShieldText = {"", {"gui-description.mfShield"}, ": ", 0}
		if MF:maxShield() > 0 then
			mfShielValue = MF:shield() / MF:maxShield()
			mfShieldText = {"", {"gui-description.mfShield"}, ": ", math.floor(MF:shield()), "/", MF:maxShield()}
		end
		mfEnergyValue = 1 - (math.floor(100 - MF.internalEnergyObj:energy() / MF.internalEnergyObj:maxEnergy() * 100)) / 100
		mfEnergyText = {"", {"gui-description.mfEnergyCharge"}, ": ", Util.toRNumber(MF.internalEnergyObj:energy()), "J/", Util.toRNumber(MF.internalEnergyObj:maxEnergy()), "J"}
		mfQuatronValue = 1 - (math.floor(100 - MF.internalQuatronObj.quatronCharge / MF.internalQuatronObj.quatronMax * 100)) / 100
		mfQuatronText = {"", {"gui-description.mQuatronCharge"}, ": ", Util.toRNumber(MF.internalQuatronObj.quatronCharge), "/", Util.toRNumber(MF.internalQuatronObj.quatronMax)}
		mfJumpDriveValue = (math.floor(MF.jumpDriveObj.charge / MF.jumpDriveObj.maxCharge * 100)) / 100
		mfJumpDriveText = {"", {"gui-description.mfJumpCharge"}, ": ", MF.jumpDriveObj.charge, "/", MF.jumpDriveObj.maxCharge, " (", MF.jumpDriveObj.chargeRate, "/s)"}
	end

	-------------------------------------------------------- Update Information --------------------------------------------------------
	GUIObj:addLabel("PositionLabel", GUIObj.MFMainGUIFrame2, mfPositionText, _mfGreen, "Mobile Factory")
	GUIObj:addProgressBar("HealBar", GUIObj.MFMainGUIFrame2, "", mfHealthText, false, _mfRed, mfHealthValue)
	GUIObj:addProgressBar("ShieldBar", GUIObj.MFMainGUIFrame2, "", mfShieldText, false, _mfBlue, mfShielValue)
	GUIObj:addProgressBar("EnergyBar", GUIObj.MFMainGUIFrame2, "", mfEnergyText, false, _mfYellow, mfEnergyValue)
	GUIObj:addProgressBar("QuatronBar", GUIObj.MFMainGUIFrame2, "", mfQuatronText, false, _mfPurple, mfQuatronValue)
	GUIObj:addProgressBar("JumpDriveBar", GUIObj.MFMainGUIFrame2, "", mfJumpDriveText, false, _mfOrange, mfJumpDriveValue)

	-- Set Style --
	GUIObj.MFMainGUIFrame2.JumpDriveBar.style.bottom_padding = 1

	-- Clear the Buttons Frame --
	GUIObj.MFMainGUIFrame3.clear()
	-- No need to show buttons if player don't have MF
	if MF.ent == nil then
		GUIObj.MFMainGUIFrame3.visible = false
		return
	else
		GUIObj.MFMainGUIFrame3.visible = true
	end
	local entID = MF.ent.valid and MF.ent.unit_number or 0

	-------------------------------------------------------- Get Buttons Variables --------------------------------------------------------
	local showCallMFButton = technologyUnlocked("JumpDrive", getForce(player.name))
	local syncAreaSprite = MF.syncAreaEnabled == true and "SyncAreaIcon" or "SyncAreaIconDisabled"
	local syncAreaHovSprite = MF.syncAreaEnabled == true and "SyncAreaIconDisabled" or "SyncAreaIcon"
	local showFindMFButton = MF.ent.valid == false and true or false
	local tpInsideSprite = MF.tpEnabled == true and "MFTPIcon" or "MFTPIconDisabled"
	local tpInsideHovSprite = MF.tpEnabled == true and "MFTPIconDisabled" or "MFTPIcon"
	local lockMFSprite = MF.locked == true and "LockMFCIcon" or "LockMFOIcon"
	local lockMFHovSprite = MF.locked == true and "LockMFOIcon" or "LockMFCIcon"
	local showEnergyDrainButton = technologyUnlocked("EnergyDrain1", getForce(player.name)) and true or false
	local energyDrainSprite = MF.energyLaserActivated == true and "EnergyDrainIcon" or "EnergyDrainIconDisabled"
	local energyDrainHovSprite = MF.energyLaserActivated == true and "EnergyDrainIconDisabled" or "EnergyDrainIcon"
	local showFluidDrainButton = technologyUnlocked("FluidDrain1", getForce(player.name)) and true or false
	local fluidDrainSprite = MF.fluidLaserActivated == true and "FluidDrainIcon" or "FluidDrainIconDisabled"
	local fluidDrainHovSprite = MF.fluidLaserActivated == true and "FluidDrainIconDisabled" or "FluidDrainIcon"
	local showItemDrainButton = technologyUnlocked("TechItemDrain", getForce(player.name)) and true or false
	local itemDrainSprite = MF.itemLaserActivated == true and "ItemDrainIcon" or "ItemDrainIconDisabled"
	local itemDrainHovSprite = MF.itemLaserActivated == true and "ItemDrainIconDisabled" or "ItemDrainIcon"
	local showQuatronDrainButton = technologyUnlocked("EnergyDrain1", getForce(player.name)) and technologyUnlocked("QuatronLogistic", getForce(player.name)) and true or false
	local quatronDrainSprite = MF.quatronLaserActivated == true and "QuatronIcon" or "QuatronIconDisabled"
	local quatronDrainHovSprite = MF.quatronLaserActivated == true and "QuatronIconDisabled" or "QuatronIcon"


	-------------------------------------------------------- Update all Buttons --------------------------------------------------------
	local buttonsSize = 15
	GUI.addButtonToMainGui(GUIObj, {label="PortOutsideButton", name="onTeleportOutside;GUI", sprite="PortIcon", hovSprite="PortIcon", tooltip={"gui-description.teleportOutsideButton"}, size=buttonsSize, save=false})
	GUI.addButtonToMainGui(GUIObj, {label="SyncAreaButton", name="onToggleOption;"..entID..";syncAreaEnabled", sprite=syncAreaSprite, hovSprite=syncAreaHovSprite, tooltip={"gui-description.syncAreaButton"}, size=buttonsSize, save=false})
	GUI.addButtonToMainGui(GUIObj, {label="FindMFButton", name="fixMF;Util", sprite="MFIconExc", hovSprite="MFIconExc", tooltip={"gui-description.fixMFButton"}, size=buttonsSize, save=false, visible=showFindMFButton})
	GUI.addButtonToMainGui(GUIObj, {label="TPInsideButton", name="onToggleOption;"..entID..";tpEnabled", sprite=tpInsideSprite, hovSprite=tpInsideHovSprite, tooltip={"gui-description.MFTPInside"}, size=buttonsSize, save=false})
	GUI.addButtonToMainGui(GUIObj, {label="LockMFButton", name="onToggleOption;"..entID..";locked", sprite=lockMFSprite, hovSprite=lockMFHovSprite, tooltip={"gui-description.LockMF"}, size=buttonsSize, save=false})
	GUI.addButtonToMainGui(GUIObj, {label="JumpDriveButton", name="onToggleGui;GUI;MFTPGUI", sprite="MFJDIcon", hovSprite="MFJDIcon", tooltip={"gui-description.jumpDriveButton"}, size=buttonsSize, save=false, visible=showCallMFButton})
	GUI.addButtonToMainGui(GUIObj, {label="EnergyDrainButton", name="onToggleOption;"..entID..";energyLaserActivated", sprite=energyDrainSprite, hovSprite=energyDrainHovSprite, tooltip={"gui-description.mfEnergyDrainButton"}, size=buttonsSize, save=false, visible=showEnergyDrainButton})
	GUI.addButtonToMainGui(GUIObj, {label="FluidDrainButton", name="onToggleOption;"..entID..";fluidLaserActivated", sprite=fluidDrainSprite, hovSprite=fluidDrainHovSprite, tooltip={"gui-description.mfFluidDrainButton"}, size=buttonsSize, save=false, visible=showFluidDrainButton})
	GUI.addButtonToMainGui(GUIObj, {label="ItemDrainButton", name="onToggleOption;"..entID..";itemLaserActivated", sprite=itemDrainSprite, hovSprite=itemDrainHovSprite, tooltip={"gui-description.mfItemDrainButton"}, size=buttonsSize, save=false, visible=showItemDrainButton})
	GUI.addButtonToMainGui(GUIObj, {label="QuatronDrainButton", name="onToggleOption;"..entID..";quatronLaserActivated", sprite=quatronDrainSprite, hovSprite=quatronDrainHovSprite, tooltip={"gui-description.mfQuatronDrainButton"}, size=buttonsSize, save=false, visible=showQuatronDrainButton})

	GUI.renderMainGuiButtons(GUIObj)
end

-- Add a Button to the Main GUI --
function GUI.addButtonToMainGui(GUIObj, button)
	if GUIObj.buttonsTable == nil then GUIObj.buttonsTable = {} end
	GUIObj.buttonsTable[button.label] = button
end

-- Render all Buttons of the Main GUI --
function GUI.renderMainGuiButtons(GUIObj)
	-- Create values --
	local i = 0
	local y = 1
	-- Create the first Flow --
	local flow = GUIObj:addFlow("buttonFlow" .. y, GUIObj.MFMainGUIFrame3, "vertical")
	-- Itinerate the Buttons Table --
	for k, button in pairs(GUIObj.buttonsTable or {}) do
		if button.visible == false then goto continue end
		if GUIObj.MFPlayer.varTable["Show"..button.label] == false then goto continue end
		-- Create a new Flow --
		if i % 4 == 0 then
			y = y + 1
			flow = GUIObj:addFlow("buttonFlow" .. y, GUIObj.MFMainGUIFrame3, "vertical")
		end
		-- Add the Button --
		GUIObj:addButton(button.name, flow, button.sprite, button.hovSprite, button.tooltip, button.size, button.save)
		i = i + 1
		::continue::
	end
	-- Make the Frame invisible if no Button was added --
	if i == 0 then GUIObj.MFMainGUIFrame3.visible = false end
end

function GUI.onReduceMainGUI(event, args)
	local MFPlayer = getMFPlayer(event.player_index)
	-- Get the Main GUI Object --
	local mainGUI = MFPlayer.GUI["MFMainGUI"]
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
end