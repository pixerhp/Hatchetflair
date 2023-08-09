extends Control

# Called when this script is loaded into the scene
func _ready() -> void:
	# Sets a callback for when connection status changes.
	NetworkManager.network_status_update.connect(self.network_status_update)
	
	# Update all essential files to work with the current version of the game.
	# Does NOT update each world and its contents, that'd be done in the worlds menu.
	if ensure_essential_files_are_up_to_date():
		push_error("There was an error checking/updating one or more essential files,\nthis may lead to crashes or unintended behavior.")


# Display the current connecting status using the NetworkInfoOverlay menu.
# I think we should rename this function later.
func network_status_update(message: String, should_display: bool, show_back_button: bool):
	$Menus/NetworkInfoOverlay.visible = should_display
	$Menus/NetworkInfoOverlay/RichTextLabel.text = message
	$Menus/NetworkInfoOverlay/BackButton.visible = show_back_button

func ensure_essential_files_are_up_to_date() -> bool:
	return(false) # A placeholder. In the future, return true if something goes wrong.


# Open one of the screens on the menu and close all others.
func open_menu(screen_name: String) -> void:
	for child in $Menus.get_children():
		child.visible = false
	get_node("Menus/" + screen_name).visible = true

# Close the game.
func quit() -> void:
	get_tree().quit()  
