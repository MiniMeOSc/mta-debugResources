local effectsWindow = {
    labels = {},
    comboboxes = {},
    tabpanels = {},
    tabs = {},
    scrollbars = {},
    edits = {},
    checkboxes = {},
    radiobuttons = {},
    buttons = {}
}
local availableEffects = {}
local createdEffects = {}

local handlingEditChanged = false
local handlingScrollbarScrolled = false

-- function to (re-)load the effects file
function readEffectsFile()
    local effects = {}

    -- try loading the file and output an error message if it fails
    local file = xmlLoadFile("effects.xml")
    if not file then
        outputDebugString("Failed to load the file effects.xml")
        return
    end

    local availableEffects = xmlNodeGetChildren(file)
    for i, node in ipairs(availableEffects) do
        effects[i] = xmlNodeGetAttribute(node, "name")
    end

    -- free memory
    xmlUnloadFile(file)

    return effects
end

function guiComboBoxAdjustHeight ( combobox, itemcount )
    if getElementType ( combobox ) ~= "gui-combobox" or type ( itemcount ) ~= "number" then error ( "Invalid arguments @ 'guiComboBoxAdjustHeight'", 2 ) end
    local width = guiGetSize ( combobox, false )
    return guiSetSize ( combobox, width, ( itemcount * 20 ) + 20, false )
end

function guiComboBoxFindTextIndex(combobox, text)
    local c = guiComboBoxGetItemCount(combobox)
    for i = 0, c do
        if guiComboBoxGetItemText(combobox, i) == text then
            return i
        end
    end
    return -1
end

function scrollbarScrolled(scrollbar, edit)
    -- prevent this event handler from executing after the scrollbar position was changed from code
    --outputDebugString(string.format("scrollbarScrolled, handlingEditChanged = %s", tostring(handlingEditChanged)))
    if handlingEditChanged then return end

    -- get the current scrollbar position
    local number = guiScrollBarGetScrollPosition(scrollbar)
    
    -- scale the value
    local min = getElementData(scrollbar, 'minimumValue')
    local max = getElementData(scrollbar, 'maximumValue')
    local range = max - min
    number = number / 100 * range + min
    
    local text = tostring(number)

    -- set the value and mark that we're changing it from the code
    handlingScrollbarScrolled = true
    --outputDebugString("handlingScrollbarScrolled = true")
    guiSetText(edit, text)
    handlingScrollbarScrolled = false
    --outputDebugString("handlingScrollbarScrolled = false")

    updateEffectProperties()
end

function editChanged(edit, scrollbar)
    -- prevent this event handler from executing after the edit text was changed from code
    --outputDebugString(string.format("editChanged, handlingScrollbarScrolled = %s", tostring(handlingScrollbarScrolled)))
    if handlingScrollbarScrolled then return end
    
    -- ensure the user input a valid number
    local text = guiGetText(edit)
    local number = tonumber(text)
    if not number then return end

    local min = getElementData(scrollbar, 'minimumValue')
    local max = getElementData(scrollbar, 'maximumValue')
    
    -- ensure our value is in the correct range
    if number < min or number > max then return end

    -- scale the value
    local range = max - min
    number = (number - min) / range * 100

    -- set the value and mark that we're changing it from the code
    handlingEditChanged = true
    --outputDebugString("handlingEditChanged = true")
    guiScrollBarSetScrollPosition(scrollbar, number)
    handlingEditChanged = false
    --outputDebugString("handlingEditChanged = false")

    updateEffectProperties()
end

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function createOrUpdateEffect(effect)
    local name = guiGetText(effectsWindow.comboboxes.name)
    if not table.contains(availableEffects, name) then outputChatBox("invalid effect name") return end

    local offX = tonumber(guiGetText(effectsWindow.edits.xOffset))
    local offY = tonumber(guiGetText(effectsWindow.edits.yOffset))
    local offZ = tonumber(guiGetText(effectsWindow.edits.zOffset))
    if not offX or not offY or not offZ then outputChatBox("offset not a number") return end
    
    local rX = tonumber(guiGetText(effectsWindow.edits.rX))
    local rY = tonumber(guiGetText(effectsWindow.edits.rY))
    local rZ = tonumber(guiGetText(effectsWindow.edits.rZ))
    if not rX or not rY or not rZ then outputChatBox("rotation not a number") return end

    local drawDistance = tonumber(guiGetText(effectsWindow.edits.drawDistance))
    if not drawDistance then outputChatBox("drawDistance not a number") return end

    local soundEnable = guiCheckBoxGetSelected(effectsWindow.checkboxes.soundEnable)

    local attach = guiCheckBoxGetSelected(effectsWindow.checkboxes.attach)
    local attachToPlayer = guiRadioButtonGetSelected(effectsWindow.radiobuttons.attachToPlayer)
    local attachToVehicle = guiRadioButtonGetSelected(effectsWindow.radiobuttons.attachToVehicle)
    local theAttachToElement
    if attach then
        if attachToPlayer then
            theAttachToElement = localPlayer
        end

        if attachToVehicle then
            theAttachToElement = getPedOccupiedVehicle(localPlayer)
            if not theAttachToElement then
                outputChatBox("You need to be in a vehicle to attach an effect to it.")
                return
            end
        end
    end

    local x, y, z = getPositionFromElementOffset(localPlayer, offX, offY, offZ)
    -- effect createEffect ( string name, float x, float y, float z [, float rX, float rY, float rZ, float drawDistance = 0, bool soundEnable = false ] )
    if not effect then    
        effect = createEffect(name, x, y, z, rX, rY, rZ, drawDistance, soundEnable)
    end
    
    -- if the user chose to attach the effect, do so
    -- if they deselected the option on an existing one, detach it
    if attach then
        attachEffect(effect, theAttachToElement, offX, offY, offZ, rX, rY, rZ)
    elseif effect then
        detatchEffect(effect, theAttachToElement)
        setElementPosition(effect, x, y, z)
        setElementRotation(effect, rX, rY, rZ)
    end

    -- return the effect data
    return { 
        element = effect,
        data = {
            name = name,
            offX = offX,
            offY = offY,
            offZ = offZ,
            rX = rX,
            rY = rY,
            rZ = rZ,
            drawDistance = drawDistance,
            soundEnable = soundEnable,
            attach = attach,
            attachToPlayer = attachToPlayer,
            attachToVehicle = attachToVehicle
        }
    }
end

function createButtonClicked()
    local effect = createOrUpdateEffect()

    table.insert(createdEffects, effect)
    local i = guiComboBoxAddItem(effectsWindow.comboboxes.instance, string.format("effect#%i (%s)", #createdEffects, effect.data.name))
    guiComboBoxSetSelected(effectsWindow.comboboxes.instance, i)
    instanceComboboxAccepted()
    guiComboBoxAdjustHeight(effectsWindow.comboboxes.instance, i + 1)
end

function destroyButtonClicked()
    -- get the selection and abort if none or the first row ("New...") was selected
    local i = guiComboBoxGetSelected(effectsWindow.comboboxes.instance)
    if i < 1 then return end

    -- remove it from the ui
    guiComboBoxRemoveItem(effectsWindow.comboboxes.instance, i)
    guiComboBoxSetSelected(effectsWindow.comboboxes.instance, i - 1)
    instanceComboboxAccepted()

    -- The gui functions work with a 0 based index, but lua functions with a 1 based index.
    -- Because our combobox has an additional "New..." item that won't be in the effects table
    -- we don't need to change i from a 0 based index to a 1 based index.
    local effect = table.remove(createdEffects, i)
    destroyElement(effect.element)
end

function updateEffectProperties()
    -- get the selection and abort if none or the first row ("New...") was selected
    local i = guiComboBoxGetSelected(effectsWindow.comboboxes.instance)
    if i < 1 then return end

    local effect = createOrUpdateEffect(createdEffects[i].element)

    createdEffects[i] = effect
end

function updateAttachRadioButtonsEnabled()
    local enabled = guiCheckBoxGetSelected(effectsWindow.checkboxes.attach)
    guiSetEnabled(effectsWindow.radiobuttons.attachToPlayer, enabled)
    guiSetEnabled(effectsWindow.radiobuttons.attachToVehicle, enabled)

    updateEffectProperties()
end

function instanceComboboxAccepted()
    local i = guiComboBoxGetSelected(effectsWindow.comboboxes.instance)
    if i < 0 then return end

    -- check if the "New..." option or a real one is selected
    local isNewOptionSelected = i == 0
    guiSetEnabled(effectsWindow.comboboxes.name, isNewOptionSelected)
    guiSetEnabled(effectsWindow.scrollbars.drawDistance, isNewOptionSelected)
    guiSetEnabled(effectsWindow.edits.drawDistance, isNewOptionSelected)
    guiSetEnabled(effectsWindow.checkboxes.soundEnable, isNewOptionSelected)
    if isNewOptionSelected then return end

    local effect = createdEffects[i]

    -- name
    local j = guiComboBoxFindTextIndex(effectsWindow.comboboxes.name, effect.data.name)
    guiComboBoxSetSelected(effectsWindow.comboboxes.name, j)

    -- position
    guiSetText(effectsWindow.edits.xOffset, tostring(effect.data.offX))
    guiSetText(effectsWindow.edits.yOffset, tostring(effect.data.offY))
    guiSetText(effectsWindow.edits.zOffset, tostring(effect.data.offZ))

    -- rotation
    guiSetText(effectsWindow.edits.rX, tostring(effect.data.rX))
    guiSetText(effectsWindow.edits.rY, tostring(effect.data.rY))
    guiSetText(effectsWindow.edits.rZ, tostring(effect.data.rZ))

    -- attach
    guiCheckBoxSetSelected(effectsWindow.checkboxes.attach, effect.data.attach)
    guiRadioButtonSetSelected(effectsWindow.radiobuttons.attachToPlayer, effect.data.attachToPlayer)
    guiRadioButtonSetSelected(effectsWindow.radiobuttons.attachToVehicle, effect.data.attachToVehicle)
    updateAttachRadioButtonsEnabled()

    -- drawDistance
    guiSetText(effectsWindow.edits.drawDistance, effect.data.drawDistance)

    -- soundEnable
    guiCheckBoxSetSelected(effectsWindow.checkboxes.soundEnable, effect.data.soundEnable)
end

function handleEffectGuiCommand(commandName)
    local visible = not guiGetVisible(effectsWindow.window)
    guiSetVisible(effectsWindow.window, visible)
    showCursor(visible)
    if visible then 
        guiSetInputMode("no_binds_when_editing")
    else
        guiSetInputMode("allow_binds")
    end
end

function createEffectsWindow()
    -- create the window in the bottom right corner of the screen
    local windowWidth = 224
    local windowHeight = 398
    local screenWidth, screenHeight = guiGetScreenSize()
    local windowX = screenWidth - windowWidth - 10
    local windowY = screenHeight - windowHeight - 10
    effectsWindow.window = guiCreateWindow(windowX, windowY, windowWidth, windowHeight, "Effects", false)
    guiSetVisible(effectsWindow.window, false)
    guiWindowSetSizable(effectsWindow.window, false)    

    -- instance selection
    effectsWindow.labels.instance = guiCreateLabel(14, 19, 199, 15, "Instance", false, effectsWindow.window) 
    effectsWindow.comboboxes.instance = guiCreateComboBox(14, 39, 199, 21, "", false, effectsWindow.window)
    guiComboBoxAddItem(effectsWindow.comboboxes.instance, "New...")
    guiComboBoxSetSelected(effectsWindow.comboboxes.instance, 0)
    guiComboBoxAdjustHeight(effectsWindow.comboboxes.instance, 2)
    addEventHandler("onClientGUIComboBoxAccepted", effectsWindow.comboboxes.instance, instanceComboboxAccepted, false)

    -- effect name selection
    effectsWindow.labels.name = guiCreateLabel(14, 69, 199, 15, "Name", false, effectsWindow.window)
    effectsWindow.comboboxes.name = guiCreateComboBox(14, 89, 199, 21, "", false, effectsWindow.window)
    availableEffects = readEffectsFile() 
    local effectsCount = 0
    for _,v in ipairs(availableEffects) do
        guiComboBoxAddItem(effectsWindow.comboboxes.name, v)
        effectsCount = effectsCount + 1
    end
    guiComboBoxAdjustHeight(effectsWindow.comboboxes.name, effectsCount)

    -- create a tab panel for position and rotation settings
    effectsWindow.tabpanels.posRot = guiCreateTabPanel(14, 118, 201, 173, false, effectsWindow.window)
    effectsWindow.tabs.position = guiCreateTab("Position", effectsWindow.tabpanels.posRot)
    effectsWindow.tabs.rotation = guiCreateTab("Rotation", effectsWindow.tabpanels.posRot)
    effectsWindow.tabs.attach = guiCreateTab("Attach", effectsWindow.tabpanels.posRot)

    -- position x
    effectsWindow.labels.xOffset = guiCreateLabel(6, 5, 189, 15, "xOffset", false, effectsWindow.tabs.position)
    effectsWindow.scrollbars.xOffset = guiCreateScrollBar(6, 23, 143, 23, true, false, effectsWindow.tabs.position)
    effectsWindow.edits.xOffset = guiCreateEdit(149, 23, 46, 23, "0", false, effectsWindow.tabs.position)
    setElementData(effectsWindow.scrollbars.xOffset, 'minimumValue', -50.0)
    setElementData(effectsWindow.scrollbars.xOffset, 'maximumValue', 50.0)
    guiScrollBarSetScrollPosition(effectsWindow.scrollbars.xOffset, 50.0)
    addEventHandler("onClientGUIScroll", effectsWindow.scrollbars.xOffset, function() scrollbarScrolled(source, effectsWindow.edits.xOffset) end, false)
    addEventHandler("onClientGUIChanged", effectsWindow.edits.xOffset, function() editChanged(source, effectsWindow.scrollbars.xOffset) end, false)

    -- position y
    effectsWindow.labels.yOffset = guiCreateLabel(6, 51, 189, 15, "yOffset", false, effectsWindow.tabs.position)
    effectsWindow.scrollbars.yOffset = guiCreateScrollBar(6, 69, 143, 23, true, false, effectsWindow.tabs.position)
    effectsWindow.edits.yOffset = guiCreateEdit(149, 69, 46, 23, "0", false, effectsWindow.tabs.position)
    setElementData(effectsWindow.scrollbars.yOffset, 'minimumValue', -50.0)
    setElementData(effectsWindow.scrollbars.yOffset, 'maximumValue', 50.0)
    guiScrollBarSetScrollPosition(effectsWindow.scrollbars.yOffset, 50.0)
    addEventHandler("onClientGUIScroll", effectsWindow.scrollbars.yOffset, function() scrollbarScrolled(source, effectsWindow.edits.yOffset) end, false)
    addEventHandler("onClientGUIChanged", effectsWindow.edits.yOffset, function() editChanged(source, effectsWindow.scrollbars.yOffset) end, false)

    -- position z
    effectsWindow.labels.zOffset = guiCreateLabel(6, 97, 189, 15, "zOffset", false, effectsWindow.tabs.position)
    effectsWindow.scrollbars.zOffset = guiCreateScrollBar(6, 117, 143, 23, true, false, effectsWindow.tabs.position)
    effectsWindow.edits.zOffset = guiCreateEdit(149, 117, 46, 23, "0", false, effectsWindow.tabs.position)
    setElementData(effectsWindow.scrollbars.zOffset, 'minimumValue', -50.0)
    setElementData(effectsWindow.scrollbars.zOffset, 'maximumValue', 50.0)
    guiScrollBarSetScrollPosition(effectsWindow.scrollbars.zOffset, 50.0)
    addEventHandler("onClientGUIScroll", effectsWindow.scrollbars.zOffset, function() scrollbarScrolled(source, effectsWindow.edits.zOffset) end, false)
    addEventHandler("onClientGUIChanged", effectsWindow.edits.zOffset, function() editChanged(source, effectsWindow.scrollbars.zOffset) end, false)
  
    -- rotation x
    effectsWindow.labels.rX = guiCreateLabel(6, 5, 189, 15, "rX", false, effectsWindow.tabs.rotation)
    effectsWindow.scrollbars.rX = guiCreateScrollBar(6, 23, 143, 23, true, false, effectsWindow.tabs.rotation)
    effectsWindow.edits.rX = guiCreateEdit(149, 23, 46, 23, "0", false, effectsWindow.tabs.rotation)
    setElementData(effectsWindow.scrollbars.rX, 'minimumValue', 0.0)
    setElementData(effectsWindow.scrollbars.rX, 'maximumValue', 360.0)
    addEventHandler("onClientGUIScroll", effectsWindow.scrollbars.rX, function() scrollbarScrolled(source, effectsWindow.edits.rX) end, false)
    addEventHandler("onClientGUIChanged", effectsWindow.edits.rX, function() editChanged(source, effectsWindow.scrollbars.rX) end, false)
 
    -- rotation y
    effectsWindow.labels.rY = guiCreateLabel(6, 51, 189, 15, "rY", false, effectsWindow.tabs.rotation)
    effectsWindow.scrollbars.rY = guiCreateScrollBar(6, 69, 143, 23, true, false, effectsWindow.tabs.rotation)
    effectsWindow.edits.rY = guiCreateEdit(149, 69, 46, 23, "0", false, effectsWindow.tabs.rotation)
    setElementData(effectsWindow.scrollbars.rY, 'minimumValue', 0.0)
    setElementData(effectsWindow.scrollbars.rY, 'maximumValue', 360.0)
    addEventHandler("onClientGUIScroll", effectsWindow.scrollbars.rY, function() scrollbarScrolled(source, effectsWindow.edits.rY) end, false)
    addEventHandler("onClientGUIChanged", effectsWindow.edits.rY, function() editChanged(source, effectsWindow.scrollbars.rY) end, false)

    -- rotation z
    effectsWindow.labels.rZ = guiCreateLabel(6, 97, 189, 15, "rZ", false, effectsWindow.tabs.rotation)
    effectsWindow.scrollbars.rZ = guiCreateScrollBar(6, 117, 143, 23, true, false, effectsWindow.tabs.rotation)
    effectsWindow.edits.rZ = guiCreateEdit(149, 117, 46, 23, "0", false, effectsWindow.tabs.rotation)
    setElementData(effectsWindow.scrollbars.rZ, 'minimumValue', 0.0)
    setElementData(effectsWindow.scrollbars.rZ, 'maximumValue', 360.0)
    addEventHandler("onClientGUIScroll", effectsWindow.scrollbars.rZ, function() scrollbarScrolled(source, effectsWindow.edits.rZ) end, false)
    addEventHandler("onClientGUIChanged", effectsWindow.edits.rZ, function() editChanged(source, effectsWindow.scrollbars.rZ) end, false)

    -- attach
    effectsWindow.checkboxes.attach = guiCreateCheckBox(8, 8, 188, 15, "attach effect to", false, false, effectsWindow.tabs.attach)
    effectsWindow.radiobuttons.attachToPlayer = guiCreateRadioButton(26, 28, 170, 15, "player", false, effectsWindow.tabs.attach)
    effectsWindow.radiobuttons.attachToVehicle = guiCreateRadioButton(26, 48, 170, 15, "vehicle", false, effectsWindow.tabs.attach)
    addEventHandler("onClientGUIClick", effectsWindow.checkboxes.attach, updateAttachRadioButtonsEnabled, false)
    addEventHandler("onClientGUIClick", effectsWindow.radiobuttons.attachToPlayer, updateEffectProperties, false)
    addEventHandler("onClientGUIClick", effectsWindow.radiobuttons.attachToVehicle, updateEffectProperties, false)
    updateAttachRadioButtonsEnabled()
    guiRadioButtonSetSelected(effectsWindow.radiobuttons.attachToPlayer, true)
    
    -- draw distance
    effectsWindow.labels.drawDistance = guiCreateLabel(14, 296, 199, 17, "drawDistance", false, effectsWindow.window)
    effectsWindow.scrollbars.drawDistance = guiCreateScrollBar(14, 318, 153, 23, true, false, effectsWindow.window)
    effectsWindow.edits.drawDistance = guiCreateEdit(167, 318, 46, 23, "0", false, effectsWindow.window)
    setElementData(effectsWindow.scrollbars.drawDistance, 'minimumValue', 0.0)
    setElementData(effectsWindow.scrollbars.drawDistance, 'maximumValue', 8191.0)
    addEventHandler("onClientGUIScroll", effectsWindow.scrollbars.drawDistance, function() scrollbarScrolled(source, effectsWindow.edits.drawDistance) end, false)
    addEventHandler("onClientGUIChanged", effectsWindow.edits.drawDistance, function() editChanged(source, effectsWindow.scrollbars.drawDistance) end, false)
    
    -- sound effect
    effectsWindow.checkboxes.soundEnable = guiCreateCheckBox(14, 346, 199, 17, "soundEnable", false, false, effectsWindow.window)
    
    -- create button
    effectsWindow.buttons.create = guiCreateButton(46, 368, 81, 20, "create", false, effectsWindow.window)
    addEventHandler("onClientGUIClick", effectsWindow.buttons.create, createButtonClicked, false)
    
    -- destroy button
    effectsWindow.buttons.destroy = guiCreateButton(132, 368, 81, 20, "destroy", false, effectsWindow.window)
    addEventHandler("onClientGUIClick", effectsWindow.buttons.destroy, destroyButtonClicked, false)
end

function onStart()	
    createEffectsWindow()
    addCommandHandler("effectGui", handleEffectGuiCommand)
end
addEventHandler("onClientResourceStart", resourceRoot, onStart)