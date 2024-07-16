local g_vehicleComponentWindow = {}
local g_vehicleComponents = {}

function populateComponentGridList()
    -- check if the player is driving a car. Abort if they aren't
    local thePlayer = getLocalPlayer()
    local vehicle = getPedOccupiedVehicle(thePlayer)
    if not vehicle then
        return
    end

    -- first, clear possible old data from the list
    g_vehicleComponents = {}

    -- retrieve the components from the vehicle and add them to the list
    local components = getVehicleComponents(vehicle)
    for name,visibility in pairs(components) do
        g_vehicleComponents[name] = tostring(visibility)
    end

    -- (re-)apply the filter
    filterChanged()
end

function filterChanged()
    -- get the user input from the edit
    local findstring = guiGetText(g_vehicleComponentWindow.filterEdit)

    -- first, remove all elements from the gridlist
    guiGridListClear(g_vehicleComponentWindow.componentGridlist)

    -- now add the components that match the filter string back
    local totalCount = 0
    for name,visibility in pairs(g_vehicleComponents) do
        if string.find(string.lower(name), string.lower(findstring)) then
            guiGridListAddRow(g_vehicleComponentWindow.componentGridlist, name, visibility)
        end
        totalCount = totalCount + 1
    end

    -- update the row count label
    local filteredCount = guiGridListGetRowCount(g_vehicleComponentWindow.componentGridlist)
    guiSetText(g_vehicleComponentWindow.listLengthLabel, string.format("%i/%i rows", filteredCount, totalCount))
end

function selectAll()
    -- loop through all items and set them selected
    local count = guiGridListGetRowCount(g_vehicleComponentWindow.componentGridlist)
    for i = 0, count do
        guiGridListSetSelectedItem(g_vehicleComponentWindow.componentGridlist, i, 1, false)
    end
end

function getWindowCenterPositionOnScreen(windowWidth, windowHeight)
    local screenWidth, screenHeight = guiGetScreenSize()
    if screenWidth < windowWidth or screenHeight < windowHeight then
        return 0, 0
    end
    local windowX = screenWidth / 2 - windowWidth / 2
    local windowY = screenHeight / 2 - windowHeight / 2
    return windowX, windowY
end

function createvehicleComponentWindow()
    -- create a new window centered on the screen
    local windowWidth = 574
    local windowHeight = 369
    local windowX, windowY = getWindowCenterPositionOnScreen(windowWidth, windowHeight)
    g_vehicleComponentWindow.window = guiCreateWindow(windowX, windowY, windowWidth, windowHeight, "Vehicle Components", false)
    guiWindowSetSizable(g_vehicleComponentWindow.window, false)
    guiSetVisible(g_vehicleComponentWindow.window, false)

    -- add a gridlist with 2 columns to the window
    g_vehicleComponentWindow.componentGridlist = guiCreateGridList(9, 22, 442, 339, false, g_vehicleComponentWindow.window)
    guiGridListAddColumn(g_vehicleComponentWindow.componentGridlist, "Component", 0.7)
    guiGridListAddColumn(g_vehicleComponentWindow.componentGridlist, "Visibility", 0.2)
    guiGridListSetSelectionMode(g_vehicleComponentWindow.componentGridlist, 1)

    -- create a filter edit
    g_vehicleComponentWindow.filterLabel = guiCreateLabel(459, 22, 106, 15, "Filter", false, g_vehicleComponentWindow.window)
    g_vehicleComponentWindow.filterEdit = guiCreateEdit(459, 42, 106, 23, "", false, g_vehicleComponentWindow.window)
    g_vehicleComponentWindow.selectAllButton = guiCreateButton(459, 70, 106, 17, "Select all", false, g_vehicleComponentWindow.window)    

    -- create buttons to toggle visibility
    g_vehicleComponentWindow.showButton = guiCreateButton(459, 92, 106, 17, "Show", false, g_vehicleComponentWindow.window)
    g_vehicleComponentWindow.hideButton = guiCreateButton(459, 114, 106, 17, "Hide", false, g_vehicleComponentWindow.window)
    
    -- create button to close the window
    --g_vehicleComponentWindow.closeButton = guiCreateButton(459, 266, 106, 17, "Close window", false, g_vehicleComponentWindow.window)

    -- list length label
    g_vehicleComponentWindow.listLengthLabel = guiCreateLabel(459, 348, 103, 13, "x/x rows", false, g_vehicleComponentWindow.window)
    
    -- add functionality to buttons and gridList
    addEventHandler("onClientGUIDoubleClick", g_vehicleComponentWindow.componentGridlist, toggleVisiblity, false)
    addEventHandler("onClientGUIChanged", g_vehicleComponentWindow.filterEdit, filterChanged, false)
    addEventHandler("onClientGUIClick", g_vehicleComponentWindow.selectAllButton, selectAll, false)
    addEventHandler("onClientGUIClick", g_vehicleComponentWindow.showButton, function(button) visibilityButtonClicked(true) end, false)
    addEventHandler("onClientGUIClick", g_vehicleComponentWindow.hideButton, function(button) visibilityButtonClicked(false) end, false)
    --addEventHandler("onClientGUIClick", g_vehicleComponentWindow.closeButton, function(button) guiSetInputEnabled(false) guiSetVisible(g_vehicleComponentWindow.window, false) end, false)
end

function visibilityButtonClicked(visible)
    -- check if the player is driving a car. Abort if they aren't
    local thePlayer = getLocalPlayer()
    local vehicle = getPedOccupiedVehicle(thePlayer)
    if not vehicle then
        return
    end

    -- get which components are selected and toggle their visibility
    local selectedItems = guiGridListGetSelectedItems(g_vehicleComponentWindow.componentGridlist)
    -- loop through all selected items -> the list contains an item each for both columns
    for i, data in ipairs(selectedItems) do
        -- only process the first column
        if data["column"] == 1 then
            setVisibility(vehicle, data["row"], visible)
        end
    end
end

function toggleVisiblity()
    -- check if the player is driving a car. Abort if they aren't
    local thePlayer = getLocalPlayer()
    local vehicle = getPedOccupiedVehicle(thePlayer)
    if not vehicle then
        return
    end

    -- get which component was selected and toggle its visibility
    local i, j = guiGridListGetSelectedItem(g_vehicleComponentWindow.componentGridlist)
    
    -- "convert" the text from the ui to a boolean value
    local visible = guiGridListGetItemText(g_vehicleComponentWindow.componentGridlist, i, 2) ~= "true"
    
    -- apply
    setVisibility(vehicle, i, visible)
end

function setVisibility(vehicle, i, visible)
    -- get the component name from the ui
    local component = guiGridListGetItemText(g_vehicleComponentWindow.componentGridlist, i, 1)

    -- apply the visibility and inform the server so it can inform other clients
    setVehicleComponentVisible(vehicle, component, visible)
    triggerServerEvent("OnClientVehicleComponentVisibilityChanged", localPlayer, vehicle, component, visible)

    -- update the ui with the actual state after attempting to toggle a component's visibility
    visible = getVehicleComponentVisible(vehicle, component)
    guiGridListSetItemText(g_vehicleComponentWindow.componentGridlist, i, 2, tostring(visible), false, false)
end

-- apply visibility changes sent from the server
addEvent("OnServerVehicleComponentVisibilityChanged", true)
function handleOnServerVehicleComponentVisibilityChanged(vehicle, component, visible)
    --outputDebugString(string.format("event OnServerVehicleComponentVisibilityChanged triggered by player %s", getPlayerName(source)))
    setVehicleComponentVisible(vehicle, component, visible)
end
addEventHandler("OnServerVehicleComponentVisibilityChanged", root, handleOnServerVehicleComponentVisibilityChanged)

-- add a command to set a components visibility manually
function handleComponentCommand(commandName, component, strVisible)
    -- check if the player is in a vehicle
    local thePlayer = getLocalPlayer()
    local vehicle = getPedOccupiedVehicle(thePlayer)
    if not vehicle then
        outputChatBox("You need to be in a vehicle to use this command.")
        return
    end

    -- verify user input
    local visible
    if strVisible == "true" then
        visible = true
    elseif strVisible == "false" then
        visible = false
    else 
        outputChatBox(string.format("Invalid argument for visibility, expected bool, got %s."))
        return
    end

    -- apply visibility
    setVehicleComponentVisible(vehicle, component, visible)
    triggerServerEvent("OnClientVehicleComponentVisibilityChanged", localPlayer, vehicle, component, visible)
end

function handleComponentGuiCommand(commandName)
    -- check if the player is driving a car. Abort if they aren't
    local thePlayer = getLocalPlayer()
    if not getPedOccupiedVehicle(thePlayer) then
        return
    end

    -- update the list's content and show the window
    populateComponentGridList()

    local visible = not guiGetVisible(g_vehicleComponentWindow.window)
    guiSetVisible(g_vehicleComponentWindow.window, visible)
    showCursor(visible)
    if visible then 
        guiSetInputMode("no_binds_when_editing")
    else
        guiSetInputMode("allow_binds")
    end
end

function onStart()
    addCommandHandler("component", handleComponentCommand)
    addCommandHandler("vehicleComponentGui", handleComponentGuiCommand)
    createvehicleComponentWindow()
end
addEventHandler("onClientResourceStart", resourceRoot, onStart)

