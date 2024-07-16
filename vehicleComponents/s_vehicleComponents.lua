addEvent("OnClientVehicleComponentVisibilityChanged", true)
function handleOnClientVehicleComponentVisibilityChanged(vehicle, component, visible)
	--outputDebugString(string.format("event OnClientVehicleComponentVisibilityChanged triggered by player %s", getPlayerName(source)))
	local players = getElementsByType("player")
	for k, player in ipairs(players) do
		if player ~= source then
			--outputDebugString(string.format("triggering Client event OnServerVehicleComponentVisibilityChanged for player %s", getPlayerName(player)))
			triggerClientEvent(player, "OnServerVehicleComponentVisibilityChanged", source, vehicle, component, visible)
		end
	end
end
addEventHandler("OnClientVehicleComponentVisibilityChanged", root, handleOnClientVehicleComponentVisibilityChanged)

function addButtonShortcut()    
    local resName = getResourceName(resource)
	local button = get(string.format("%s.ButtonToggleComponentGuiVisibility", resName))
	bindKey(source, button, "down", "vehicleComponentGui")
end
addEventHandler("onPlayerResourceStart", root, addButtonShortcut)