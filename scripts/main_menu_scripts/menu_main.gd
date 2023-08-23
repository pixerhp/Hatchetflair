extends Control

# Called when this script is loaded into the scene
func _ready() -> void:
	# Sets a callback for when connection status changes.
	NetworkManager.network_status_update.connect(self.network_status_update)
	
	# Update all essential files to work with the current version of the game.
	# Does NOT update each world and its contents, that'd be done in the worlds menu.
	if ensure_essential_files_are_up_to_date():
		push_error("There was an error checking/updating one or more essential files,\nthis may lead to crashes or unintended behavior.")
	
	# JUST FOR TESTING THE FILEMANAGER ALPHABETICAL SORT FUNCTION:
	var file = FileAccess.open("user://sort_test.txt", FileAccess.WRITE)
	file.store_line(GlobalStuff.game_version_entire)
	file.store_line("zzzzzitem_3_name")
	file.store_line("aitem_3_thing")
	file.store_line("item_1_name")
	file.store_line("zitem_1_thing")
	file.store_line("item_4_name")
	file.store_line("item_4_thing")
	file.store_line("item_2_name")
	file.store_line("item_2_thing")
	file.close()
	FileManager.sort_txtfile_contents_alphabetically("user://sort_test.txt", 1, 2)


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
