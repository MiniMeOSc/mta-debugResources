function addButtonShortcut()    
    local resName = getResourceName(resource)
	local button = get(string.format("%s.ButtonToggleEffectGuiVisibility", resName))
	bindKey(source, button, "down", "effectGui")
end
addEventHandler("onPlayerResourceStart", root, addButtonShortcut)