extends Control

const worlds_list_txtfile_location: String = "user://storage/worlds_list.txt"


func _ready():
	# Connect popup buttons to their associated functions.
	$NewWorldPopup/Confirm.pressed.connect(self.confirm_new_world)
	$NewWorldPopup/Cancel.pressed.connect($NewWorldPopup.hide)
	$EditWorldPopup/Confirm.pressed.connect(self.confirm_edit_world)
	$EditWorldPopup/Cancel.pressed.connect($EditWorldPopup.hide)
	$DeleteWorldPopup/Confirm.pressed.connect(self.confirm_delete_world)
	$DeleteWorldPopup/Cancel.pressed.connect($DeleteWorldPopup.hide)
	
	disable_world_selected_requiring_buttons()
	hide_all_worlds_menu_popups()
	return


func start_world_by_index(worlds_list_index: int = -1):
	if worlds_list_index == -1:
		if not $WorldsScreenUI/SavedWorldsList.get_selected_items().is_empty():
			worlds_list_index = $WorldsScreenUI/SavedWorldsList.get_selected_items()[0]
		else:
			push_error("No worlds list index was specified for starting playing a world. (Aborting starting world.)")
			return
	
	var worlds_list_lines: Array[String] = FileManager.read_txtfile_lines_as_array(worlds_list_txtfile_location)
	var world_dir_path: String = "user://storage/worlds/" + worlds_list_lines[(worlds_list_index * 2) + 2]
	
	start_world_by_specifics(world_dir_path, $WorldsScreenUI/Toggles/AllowJoining.button_pressed, $WorldsScreenUI/Toggles/HostWithoutPlay.button_pressed)
	return

func start_world_by_specifics(world_dir_path: String, allow_multiplayer_joining: bool = $WorldsScreenUI/Toggles/AllowJoining.button_pressed, host_without_playing: bool = $WorldsScreenUI/Toggles/HostWithoutPlay.button_pressed):
	if not DirAccess.dir_exists_absolute(world_dir_path):
		push_warning("Attempted to start a world, but its specified directory path couldn't be found: ", world_dir_path, " (Aborting starting world.)")
		return
	NetworkManager.start_game(not host_without_playing, true, allow_multiplayer_joining)
	return


func open_new_world_popup():
	hide_all_worlds_menu_popups()
	$NewWorldPopup/WorldNameInput.clear()
	$NewWorldPopup/WorldSeedInput.clear()
	$NewWorldPopup.show()
	$NewWorldPopup/WorldNameInput.grab_focus()
	return

func confirm_new_world():
	var popup: Node = $NewWorldPopup
	var world_name: String = popup.get_node("WorldNameInput").text
	if world_name == "":
		world_name = "new world"
	var world_seed: String = str(int(popup.get_node("WorldSeedInput").text))
	if world_seed == "":
		world_seed = str(GlobalStuff.random_worldgen_seed())
	var world_dir_name: String = FileManager.first_unused_dir_alt("user://storage/worlds/", world_name)
	var world_dir_path: String = "user://storage/worlds/" + world_dir_name
	
	# Determine the updated worlds-list txtfile contents and replace the old contents.
	var file_contents: Array[String] = FileManager.read_txtfile_lines_as_array(worlds_list_txtfile_location)
	file_contents.append(world_name)
	file_contents.append(world_dir_name)
	print(file_contents)
	FileManager.write_txtfile_from_array_of_lines(worlds_list_txtfile_location, file_contents)
	
	# Set-up the new world's directories and files.
	DirAccess.make_dir_recursive_absolute(world_dir_path)
	DirAccess.make_dir_recursive_absolute(world_dir_path + "/chunks")
	var world_info_lines: Array[String] = [
		GlobalStuff.game_version_entire,
		"creation date-time (utc): " + Time.get_datetime_string_from_system(true, true),
		"last-played date-time (utc): unplayed",
		"world generation seed: " + world_seed,
	]
	FileManager.write_txtfile_from_array_of_lines(world_dir_path + "/world_info.txt", world_info_lines)
	
	update_displayed_worlds_list_text()
	popup.hide()
	return

func open_edit_world_popup():
	hide_all_worlds_menu_popups()
	
	var displayed_worlds_itemlist: Node = $WorldsScreenUI/SavedWorldsList
	if displayed_worlds_itemlist.get_selected_items().is_empty():
		push_warning("Attempted to open the edit world popup despite no displayed world items being selected. (Aborted popup.)")
		return
	var selected_world_index: int = displayed_worlds_itemlist.get_selected_items()[0]
	var worlds_list_lines: Array[String] = FileManager.read_txtfile_lines_as_array(worlds_list_txtfile_location)
	var world_info_lines: Array[String] = FileManager.read_txtfile_lines_as_array("user://storage/worlds/" + worlds_list_lines[(selected_world_index*2)+2] + "/world_info.txt")
	if world_info_lines.size() < 4:
		push_error("When opening the edit world popup, the file contents of world_info.txt were not long enough to have a seed. (Aborted popup.)")
		return
	var popup: Node = $EditWorldPopup
	var world_name: String = worlds_list_lines[(selected_world_index*2)+1]
	var world_seed: String = world_info_lines[3].substr(23)
	
	popup.get_node("PopupTitleText").text = "[center]Edit world: \"" + world_name + "\""
	popup.get_node("WorldNameInput").text = world_name
	popup.get_node("WorldSeedInput").text = world_seed
	popup.show()
	popup.get_node("WorldNameInput").grab_focus()
	return

func confirm_edit_world():
	var displayed_worlds_itemlist: Node = $WorldsScreenUI/SavedWorldsList
	if displayed_worlds_itemlist.get_selected_items().is_empty():
		push_warning("Attempted to finilize editing a saved world whilst none of the displayed worlds items were selected. (Did nothing.)")
		return
	var selected_server_index: int = displayed_worlds_itemlist.get_selected_items()[0]
	var file_contents: Array[String] = FileManager.read_txtfile_lines_as_array(worlds_list_txtfile_location)
	
	var popup: Node = $EditWorldPopup
	var edited_name: String = popup.get_node("WorldNameInput").text
	var edited_seed: String = str(int(popup.get_node("WorldSeedInput").text))
	if edited_seed == "":
		edited_seed = str(GlobalStuff.random_worldgen_seed())
	var original_world_dir: String = "user://storage/worlds/" + file_contents[(selected_server_index*2)+2]
	var new_world_dir_name: String = FileManager.first_unused_dir_alt("user://storage/worlds/", edited_name)
	var new_world_dir: String = "user://storage/worlds/" + new_world_dir_name
	
	# Determine what the contents of the worlds list text file should be after editing and replace its old contents.
	file_contents[(selected_server_index*2)+1] = edited_name
	file_contents[(selected_server_index*2)+2] = new_world_dir_name
	FileManager.write_txtfile_from_array_of_lines(worlds_list_txtfile_location, file_contents)
	
	# Determine what the contents of the world info text file should be after editing and replace its old contents.
	file_contents = FileManager.read_txtfile_lines_as_array(original_world_dir + "/world_info.txt")
	if file_contents.size() < 4:
		push_error("When finalizing editing a world, the file contents of world_info.txt were not long enough to have a seed. (Skipping seed-related portion.)")
	else:
		file_contents[3] = "world generation seed: " + edited_seed
		FileManager.write_txtfile_from_array_of_lines(original_world_dir + "/world_info.txt", file_contents)
	
	if original_world_dir != new_world_dir:
		DirAccess.rename_absolute(original_world_dir, new_world_dir)
	
	update_displayed_worlds_list_text()
	popup.hide()
	return

func open_delete_world_popup():
	hide_all_worlds_menu_popups()
	
	var displayed_worlds_itemlist: Node = $WorldsScreenUI/SavedWorldsList
	if displayed_worlds_itemlist.get_selected_items().is_empty():
		push_warning("Attempted to open the delete world popup despite no displayed world items being selected. (Did nothing.)")
		return
	var name_of_world_to_delete: String = FileManager.read_txtfile_lines_as_array(worlds_list_txtfile_location)[(displayed_worlds_itemlist.get_selected_items()[0]*2)+1]
	
	$DeleteWorldPopup/PopupTitleText.text = "[center]Are you sure you want to delete world:\n\"" + name_of_world_to_delete +"\"?\n(This action cannot be undone.)[/center]"
	$DeleteWorldPopup.show()
	return

func confirm_delete_world():
	var displayed_worlds_itemlist: Node = $WorldsScreenUI/SavedWorldsList
	if displayed_worlds_itemlist.get_selected_items().is_empty():
		push_warning("Attempted to finilize deleting a world, but none of the displayed items were selected. (Aborted deletion.)")
		return
	var world_index: int = (displayed_worlds_itemlist.get_selected_items()[0]*2)+1
	var worlds_list_lines: Array[String] = FileManager.read_txtfile_lines_as_array(worlds_list_txtfile_location)
	var dir_to_delete: String = "user://storage/worlds/" + worlds_list_lines[(displayed_worlds_itemlist.get_selected_items()[0]*2)+2]
	if not DirAccess.dir_exists_absolute(dir_to_delete):
		push_warning("Attempted to finilize deleting a world, but its directory could not be found: ", dir_to_delete, " (Aborting deletion.)")
		return 
	
	# Delete the world's directory/folder and then edit the worlds list txtfile (second then first line due to array resizing.)
	if FileManager.delete_dir(dir_to_delete):
		push_warning("An error was encountered deleting a world's directory: ", dir_to_delete)
	worlds_list_lines.remove_at(world_index+1)
	worlds_list_lines.remove_at(world_index)
	FileManager.write_txtfile_from_array_of_lines(worlds_list_txtfile_location, worlds_list_lines)
	
	$DeleteWorldPopup.hide()
	disable_world_selected_requiring_buttons()
	update_displayed_worlds_list_text()
	return

func _on_duplicate_world_pressed():
	var displayed_worlds_itemlist: Node = $WorldsScreenUI/SavedWorldsList
	if displayed_worlds_itemlist.get_selected_items().is_empty():
		push_warning("Attempted to duplicate a world, but none of the displayed items were selected. (Did nothing.)")
		return
	var selected_world_index: int = displayed_worlds_itemlist.get_selected_items()[0]
	var worlds_list_lines: Array[String] = FileManager.read_txtfile_lines_as_array(worlds_list_txtfile_location)
	var originals_world_name: String = worlds_list_lines[(selected_world_index*2)+1]
	var originals_dir_path: String = "user://storage/worlds/" + worlds_list_lines[(selected_world_index*2)+2]
	var copys_world_name: String = "Copy of " + originals_world_name
	var copys_dir_name: String = FileManager.first_unused_dir_alt("user://storage/worlds/", copys_world_name)
	var copys_dir_path: String = "user://storage/worlds/" + copys_dir_name
	
	# Update the worlds-list text-file contents.
	worlds_list_lines.append(copys_world_name)
	worlds_list_lines.append(copys_dir_name)
	FileManager.write_txtfile_from_array_of_lines(worlds_list_txtfile_location, worlds_list_lines)
	
	# Create the copy's directory, and copy all of the contents of the original world's directory to it.
	FileManager.copy_dir_to_dir(originals_dir_path, copys_dir_path, false)
	
	disable_world_selected_requiring_buttons()
	update_displayed_worlds_list_text()
	return


func update_displayed_worlds_list_text():
	sync_worlds_list_txtfile_to_world_dirs()
	FileManager.sort_txtfile_contents_alphabetically(worlds_list_txtfile_location, 1, 2)
	
	var worlds_list_txtfile_lines = FileManager.read_txtfile_lines_as_array(worlds_list_txtfile_location)
	var displayed_worlds_itemlist: Node = $WorldsScreenUI/SavedWorldsList
	displayed_worlds_itemlist.clear()
	
	for index in range(1, worlds_list_txtfile_lines.size()-1, 2):
		displayed_worlds_itemlist.add_item(worlds_list_txtfile_lines[index])


func sync_worlds_list_txtfile_to_world_dirs():
	if not DirAccess.dir_exists_absolute("user://storage/worlds"):
		push_warning("When syncing the worlds list to the existing directories, the \"worlds\" dir could not be found. (Creating it now.)")
		DirAccess.make_dir_recursive_absolute("user://storage/worlds")
		if not DirAccess.dir_exists_absolute("user://storage/worlds"):
			push_error("When syncing the worlds list to the existing directories, the \"worlds\" dir could not be found, even after a creation attempt. (Aborting worlds list sync.)")
			return
	
	var existing_world_dir_names: PackedStringArray = DirAccess.open("user://storage/worlds").get_directories()
	var worlds_list_txtfile_lines: Array[String] = FileManager.read_txtfile_lines_as_array(worlds_list_txtfile_location)
	
	# Remove listed worlds who's dirs don't exist (from what will become replacement worlds-list content lines.)
	var indeces_for_removal: Array[int] = []
	for index in range(worlds_list_txtfile_lines.size()-1, 0, -2): # (We want removal-indeces from last to first due to array resizing.)
		if (existing_world_dir_names.count(worlds_list_txtfile_lines[index]) == 0):
			indeces_for_removal.append(index - 1)
	for index in indeces_for_removal:
		worlds_list_txtfile_lines.remove_at(index + 1)
		worlds_list_txtfile_lines.remove_at(index)
	
	# Add unaccounted-for world dirs (to what will become replacement worlds-list content lines.)
	var already_known_folder_names: Array[String] = []
	for index in range(2, worlds_list_txtfile_lines.size(), 2):
		already_known_folder_names.append(worlds_list_txtfile_lines[index])
	for folder_name in existing_world_dir_names:
		if (already_known_folder_names.count(folder_name) == 0):
			worlds_list_txtfile_lines.append(folder_name) # (We do this once for world name, twice for world folder name.)
			worlds_list_txtfile_lines.append(folder_name)
	
	# Replace the worlds-list text file contents with the newly synchronized ones.
	FileManager.write_txtfile_from_array_of_lines(worlds_list_txtfile_location, worlds_list_txtfile_lines)

# !!! FUNCTION IS NOT USED YET, FEEL FREE TO GIVE IT USE LATER ON.
func ensure_world_dir_has_required_files(name_of_directory_folder_for_world: String):
	if not DirAccess.dir_exists_absolute("user://storage/worlds/" + name_of_directory_folder_for_world):
		push_error("Attempted to ensure that world dir: \"", name_of_directory_folder_for_world, "\" had all required files, but that world folder didn't even exist. (Aborting.)")
		return
	DirAccess.make_dir_recursive_absolute("user://storage/worlds/" + name_of_directory_folder_for_world + "/chunks")
	if not FileAccess.file_exists("user://storage/worlds/" + name_of_directory_folder_for_world + "/world_info.txt"):
		var file = FileAccess
		file = FileAccess.open("user://storage/worlds/" + name_of_directory_folder_for_world + "/world_info.txt", FileAccess.WRITE)
		file.store_line(GlobalStuff.game_version_entire)
		file.store_line("date created: " + Time.get_datetime_string_from_system())
		file.store_line("last played: unplayed")
		var random = RandomNumberGenerator.new()
		random.randomize()
		file.store_line("world generation seed: " + str(random.randi() - 4294967296 + random.randi()))
		file.close()


func toggle_visibility_of_host_without_playing_toggle (button_value: bool) -> void:
	$WorldsScreenUI/Toggles/HostWithoutPlay.disabled = not button_value
	if not button_value:
		$WorldsScreenUI/Toggles/HostWithoutPlay.button_pressed = false

func _on_worlds_list_item_selected():
	hide_all_worlds_menu_popups()
	$WorldsScreenUI/WorldButtons/DeleteWorld.disabled = false
	$WorldsScreenUI/WorldButtons/EditWorld.disabled = false
	$WorldsScreenUI/WorldButtons/DuplicateWorld.disabled = false
	$WorldsScreenUI/WorldButtons/PlayWorld.disabled = false

func disable_world_selected_requiring_buttons():
	$WorldsScreenUI/WorldButtons/DeleteWorld.disabled = true
	$WorldsScreenUI/WorldButtons/EditWorld.disabled = true
	$WorldsScreenUI/WorldButtons/DuplicateWorld.disabled = true
	$WorldsScreenUI/WorldButtons/PlayWorld.disabled = true

func hide_all_worlds_menu_popups():
	$NewWorldPopup.hide()
	$EditWorldPopup.hide()
	$DeleteWorldPopup.hide()
