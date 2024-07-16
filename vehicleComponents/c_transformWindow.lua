function getBaseRadioButtonSelected(transformWindow, controlName)
    -- check which base radiobutton is selected
    for _, radioButtonName in ipairs({ "Root", "Parent", "World" }) do
        -- the controlName variable i.e. contains positionX
        -- the first radioButton is in the property positionBaseRootRadiobutton
        -- so we need to remove the last character from the controlName
        local trimmedControlName = string.sub(controlName, 1, -2)
        local radioButton = transformWindow[trimmedControlName .. "Base" .. radioButtonName .. "Radiobutton"]
        if guiRadioButtonGetSelected(radioButton) then
            return string.lower(radioButtonName)
        end
    end
    return false
end

function applyTransform(transformWindow, controlName, base)
    if not transformWindow.vehicle then return end
    
    -- the controlName variable i.e. contains positionX
    -- we need to remove the last character from the controlName
    local trimmedControlName = string.sub(controlName, 1, -2)
    
    -- get the values from the edit
    local values = {
        X = guiGetText(transformWindow[trimmedControlName .. "XEdit"]),
        Y = guiGetText(transformWindow[trimmedControlName .. "YEdit"]),
        Z = guiGetText(transformWindow[trimmedControlName .. "ZEdit"]),
    }

    -- depending on which control sent the event execute the relevant function
    if trimmedControlName == "position" then
        setVehicleComponentPosition(transformWindow.vehicle, transformWindow.component, values.X, values.Y, values.Z, base)
    elseif trimmedControlName == "rotation" then
        setVehicleComponentRotation(transformWindow.vehicle, transformWindow.component, values.X, values.Y, values.Z, base)
    elseif trimmedControlName == "scale" then
        setVehicleComponentScale(transformWindow.vehicle, transformWindow.component, values.X, values.Y, values.Z, base)
    end
end

function scrollbarScrolled(transformWindow, controlName)
    -- prevent this event handler from executing after the scrollbar position was changed from code
    --outputDebugString(string.format("scrollbarScrolled, handlingEditChanged = %s", tostring(handlingEditChanged)))
    if handlingEditChanged then return end

    -- retrieve the controls
    local scrollbar = transformWindow[controlName .. "Scrollbar"]
    local edit = transformWindow[controlName .. "Edit"]

    -- get which of the transform base radio boxes is checked
    local base = getBaseRadioButtonSelected(transformWindow, controlName)
    if not base then return end

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

    applyTransform(transformWindow, controlName, base)
end

function editChanged(transformWindow, controlName)
    -- prevent this event handler from executing after the edit text was changed from code
    --outputDebugString(string.format("editChanged, handlingScrollbarScrolled = %s", tostring(handlingScrollbarScrolled)))
    if handlingScrollbarScrolled then return end

    -- retrieve the controls
    local scrollbar = transformWindow[controlName .. "Scrollbar"]
    local edit = transformWindow[controlName .. "Edit"]
    
    -- get which of the transform base radio boxes is checked
    local base = getBaseRadioButtonSelected(transformWindow, controlName)
    if not base then return end

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

    applyTransform(transformWindow, controlName, base)
end

function closeVehicleComponentTransformWindow(transformWindow) 
    --guiSetVisible(transformWindow.window, false)
    destroyElement(transformWindow.window)
    transformWindow.closeCallback(transformWindow.index)
end

function createVehicleComponentTransformWindow(vehicle, component)
    local transformWindow = {
        vehicle = vehicle, 
        component = component
    }
    
    -- create a new window centered on the screen
    local windowWidth = 224
    local windowHeight = 262
    local windowX, windowY = getWindowCenterPositionOnScreen(windowWidth, windowHeight)
    transformWindow.window = guiCreateWindow(windowX, windowY, windowWidth, windowHeight, "Transform - " .. component, false)
    guiWindowSetSizable(transformWindow.window, false)

    -- create a tab panel
    transformWindow.tabpanel = guiCreateTabPanel(14, 22, 201, 209, false, transformWindow.window)
    transformWindow.positionTab = guiCreateTab("Position", transformWindow.tabpanel)
    transformWindow.rotationTab = guiCreateTab("Rotation", transformWindow.tabpanel)
    transformWindow.scaleTab = guiCreateTab("Scale", transformWindow.tabpanel)

    -- position
    -- create controls for position x
    transformWindow.positionXLabel = guiCreateLabel(6, 5, 189, 15, "X", false, transformWindow.positionTab)
    transformWindow.positionXScrollbar = guiCreateScrollBar(6, 23, 143, 23, true, false, transformWindow.positionTab)
    transformWindow.positionXEdit = guiCreateEdit(149, 23, 46, 23, "0", false, transformWindow.positionTab)
    setElementData(transformWindow.positionXScrollbar, 'minimumValue', -10.0)
    setElementData(transformWindow.positionXScrollbar, 'maximumValue', 10.0)
    guiScrollBarSetScrollPosition(transformWindow.positionXScrollbar, 50.0)
    addEventHandler("onClientGUIScroll", transformWindow.positionXScrollbar, function() scrollbarScrolled(transformWindow, "positionX") end, false)
    addEventHandler("onClientGUIChanged", transformWindow.positionXEdit, function() editChanged(transformWindow, "positionX") end, false)

    -- create controls for position y
    transformWindow.positionYLabel = guiCreateLabel(6, 51, 189, 15, "Y", false, transformWindow.positionTab)
    transformWindow.positionYScrollbar = guiCreateScrollBar(6, 69, 143, 23, true, false, transformWindow.positionTab)
    transformWindow.positionYEdit = guiCreateEdit(149, 69, 46, 23, "0", false, transformWindow.positionTab)
    setElementData(transformWindow.positionYScrollbar, 'minimumValue', -10.0)
    setElementData(transformWindow.positionYScrollbar, 'maximumValue', 10.0)
    guiScrollBarSetScrollPosition(transformWindow.positionYScrollbar, 50.0)
    addEventHandler("onClientGUIScroll", transformWindow.positionYScrollbar, function() scrollbarScrolled(transformWindow, "positionY") end, false)
    addEventHandler("onClientGUIChanged", transformWindow.positionYEdit, function() editChanged(transformWindow, "positionY") end, false)
    
    -- create controls for position z
    transformWindow.positionZLabel = guiCreateLabel(6, 97, 189, 15, "Z", false, transformWindow.positionTab)
    transformWindow.positionZScrollbar = guiCreateScrollBar(6, 117, 143, 23, true, false, transformWindow.positionTab)
    transformWindow.positionZEdit = guiCreateEdit(149, 117, 46, 23, "0", false, transformWindow.positionTab)
    setElementData(transformWindow.positionZScrollbar, 'minimumValue', -10.0)
    setElementData(transformWindow.positionZScrollbar, 'maximumValue', 10.0)
    guiScrollBarSetScrollPosition(transformWindow.positionZScrollbar, 50.0)
    addEventHandler("onClientGUIScroll", transformWindow.positionZScrollbar, function() scrollbarScrolled(transformWindow, "positionZ") end, false)
    addEventHandler("onClientGUIChanged", transformWindow.positionZEdit, function() editChanged(transformWindow, "positionZ") end, false)
    
    -- create controls for position base selection
    transformWindow.positionBaseLabel = guiCreateLabel(6, 145, 189, 15, "Base", false, transformWindow.positionTab)
    transformWindow.positionBaseRootRadiobutton = guiCreateRadioButton(7, 162, 51, 15, "root", false, transformWindow.positionTab)
    transformWindow.positionBaseParentRadiobutton = guiCreateRadioButton(63, 162, 57, 15, "parent", false, transformWindow.positionTab)
    transformWindow.positionBaseWorldRadiobutton = guiCreateRadioButton(125, 162, 51, 15, "world", false, transformWindow.positionTab)
    guiRadioButtonSetSelected(transformWindow.positionBaseRootRadiobutton, true)

    -- rotation
    -- create controls for rotation x
    transformWindow.rotationXLabel = guiCreateLabel(6, 5, 189, 15, "X", false, transformWindow.rotationTab)
    transformWindow.rotationXScrollbar = guiCreateScrollBar(6, 23, 143, 23, true, false, transformWindow.rotationTab)
    transformWindow.rotationXEdit = guiCreateEdit(149, 23, 46, 23, "0", false, transformWindow.rotationTab)
    setElementData(transformWindow.rotationXScrollbar, 'minimumValue', 0)
    setElementData(transformWindow.rotationXScrollbar, 'maximumValue', 360.0)
    addEventHandler("onClientGUIScroll", transformWindow.rotationXScrollbar, function() scrollbarScrolled(transformWindow, "rotationX") end, false)
    addEventHandler("onClientGUIChanged", transformWindow.rotationXEdit, function() editChanged(transformWindow, "rotationX") end, false)

    -- create controls for rotation y
    transformWindow.rotationYLabel = guiCreateLabel(6, 51, 189, 15, "Y", false, transformWindow.rotationTab)
    transformWindow.rotationYScrollbar = guiCreateScrollBar(6, 69, 143, 23, true, false, transformWindow.rotationTab)
    transformWindow.rotationYEdit = guiCreateEdit(149, 69, 46, 23, "0", false, transformWindow.rotationTab)
    setElementData(transformWindow.rotationYScrollbar, 'minimumValue', 0.0)
    setElementData(transformWindow.rotationYScrollbar, 'maximumValue', 360.0)
    addEventHandler("onClientGUIScroll", transformWindow.rotationYScrollbar, function() scrollbarScrolled(transformWindow, "rotationY") end, false)
    addEventHandler("onClientGUIChanged", transformWindow.rotationYEdit, function() editChanged(transformWindow, "rotationY") end, false)
    
    -- create controls for rotation z
    transformWindow.rotationZLabel = guiCreateLabel(6, 97, 189, 15, "Z", false, transformWindow.rotationTab)
    transformWindow.rotationZScrollbar = guiCreateScrollBar(6, 117, 143, 23, true, false, transformWindow.rotationTab)
    transformWindow.rotationZEdit = guiCreateEdit(149, 117, 46, 23, "0", false, transformWindow.rotationTab)
    setElementData(transformWindow.rotationZScrollbar, 'minimumValue', 0.0)
    setElementData(transformWindow.rotationZScrollbar, 'maximumValue', 360.0)
    addEventHandler("onClientGUIScroll", transformWindow.rotationZScrollbar, function() scrollbarScrolled(transformWindow, "rotationZ") end, false)
    addEventHandler("onClientGUIChanged", transformWindow.rotationZEdit, function() editChanged(transformWindow, "rotationZ") end, false)
    
    -- create controls for rotation base selection
    transformWindow.rotationBaseLabel = guiCreateLabel(6, 145, 189, 15, "Base", false, transformWindow.rotationTab)
    transformWindow.rotationBaseRootRadiobutton = guiCreateRadioButton(7, 162, 51, 15, "root", false, transformWindow.rotationTab)
    transformWindow.rotationBaseParentRadiobutton = guiCreateRadioButton(63, 162, 57, 15, "parent", false, transformWindow.rotationTab)
    transformWindow.rotationBaseWorldRadiobutton = guiCreateRadioButton(125, 162, 51, 15, "world", false, transformWindow.rotationTab)
    guiRadioButtonSetSelected(transformWindow.rotationBaseRootRadiobutton, true)

    -- scale
    -- create controls for scale x
    transformWindow.scaleXLabel = guiCreateLabel(6, 5, 189, 15, "X", false, transformWindow.scaleTab)
    transformWindow.scaleXScrollbar = guiCreateScrollBar(6, 23, 143, 23, true, false, transformWindow.scaleTab)
    transformWindow.scaleXEdit = guiCreateEdit(149, 23, 46, 23, "0", false, transformWindow.scaleTab)
    setElementData(transformWindow.scaleXScrollbar, 'minimumValue', -10.0)
    setElementData(transformWindow.scaleXScrollbar, 'maximumValue', 10.0)
    guiScrollBarSetScrollPosition(transformWindow.scaleXScrollbar, 50.0)
    addEventHandler("onClientGUIScroll", transformWindow.scaleXScrollbar, function() scrollbarScrolled(transformWindow, "scaleX") end, false)
    addEventHandler("onClientGUIChanged", transformWindow.scaleXEdit, function() editChanged(transformWindow, "scaleX") end, false)

    -- create controls for scale y
    transformWindow.scaleYLabel = guiCreateLabel(6, 51, 189, 15, "Y", false, transformWindow.scaleTab)
    transformWindow.scaleYScrollbar = guiCreateScrollBar(6, 69, 143, 23, true, false, transformWindow.scaleTab)
    transformWindow.scaleYEdit = guiCreateEdit(149, 69, 46, 23, "0", false, transformWindow.scaleTab)
    setElementData(transformWindow.scaleYScrollbar, 'minimumValue', -10.0)
    setElementData(transformWindow.scaleYScrollbar, 'maximumValue', 10.0)
    guiScrollBarSetScrollPosition(transformWindow.scaleYScrollbar, 50.0)
    addEventHandler("onClientGUIScroll", transformWindow.scaleYScrollbar, function() scrollbarScrolled(transformWindow, "scaleY") end, false)
    addEventHandler("onClientGUIChanged", transformWindow.scaleYEdit, function() editChanged(transformWindow, "scaleY") end, false)
    
    -- create controls for scale z
    transformWindow.scaleZLabel = guiCreateLabel(6, 97, 189, 15, "Z", false, transformWindow.scaleTab)
    transformWindow.scaleZScrollbar = guiCreateScrollBar(6, 117, 143, 23, true, false, transformWindow.scaleTab)
    transformWindow.scaleZEdit = guiCreateEdit(149, 117, 46, 23, "0", false, transformWindow.scaleTab)
    setElementData(transformWindow.scaleZScrollbar, 'minimumValue', -10.0)
    setElementData(transformWindow.scaleZScrollbar, 'maximumValue', 10.0)
    guiScrollBarSetScrollPosition(transformWindow.scaleZScrollbar, 50.0)
    addEventHandler("onClientGUIScroll", transformWindow.scaleZScrollbar, function() scrollbarScrolled(transformWindow, "scaleZ") end, false)
    addEventHandler("onClientGUIChanged", transformWindow.scaleZEdit, function() editChanged(transformWindow, "scaleZ") end, false)
    
    -- create controls for scale base selection
    transformWindow.scaleBaseLabel = guiCreateLabel(6, 145, 189, 15, "Base", false, transformWindow.scaleTab)
    transformWindow.scaleBaseRootRadiobutton = guiCreateRadioButton(7, 162, 51, 15, "root", false, transformWindow.scaleTab)
    transformWindow.scaleBaseParentRadiobutton = guiCreateRadioButton(63, 162, 57, 15, "parent", false, transformWindow.scaleTab)
    transformWindow.scaleBaseWorldRadiobutton = guiCreateRadioButton(125, 162, 51, 15, "world", false, transformWindow.scaleTab)
    guiRadioButtonSetSelected(transformWindow.scaleBaseRootRadiobutton, true)

    -- close button
    transformWindow.closeButton = guiCreateButton(116, 236, 99, 17, "Close", false, transformWindow.window)
    addEventHandler("onClientGUIClick", transformWindow.closeButton, function() closeVehicleComponentTransformWindow(transformWindow) end, false)
    
    return transformWindow
end