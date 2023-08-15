extends Control

const worlds_list_file_location: String = "user://storage/worlds_list.txt"

@onready var worlds_list_text = get_node("WorldsScreenUI/SavedWorldsList")
var worlds_names: Array[String] = []
var worlds_seeds: Array[int] = []


# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect worlds menu popups and their buttons to functions.
	var new_world_popup = get_node("NewWorldPopup")
	new_world_popup.get_node("Okay").pressed.connect(self.confirm_new_world)
	new_world_popup.get_node("Cancel").pressed.connect(new_world_popup.hide)
	var edit_world_popup = get_node("EditWorldPopup")
	edit_world_popup.get_node("Okay").pressed.connect(self.confirm_edit_world)
	edit_world_popup.get_node("Cancel").pressed.connect(edit_world_popup.hide)
	var delete_world_popup = get_node("DeleteWorldPopup")
	delete_world_popup.get_node("Confirm").pressed.connect(self.confirm_delete_world)
	delete_world_popup.get_node("Cancel").pressed.connect(delete_world_popup.hide)
	
	disable_world_selected_requiring_buttons()
	hide_all_worlds_menu_popups()


# Start playing/hosting one of your worlds.
func start_world(worlds_list_index: int = 0):#world_file_name: String, allow_multiplayer: bool, host_without_playing: bool):
	print("Chosen world's list-index: " + str(worlds_list_index))
	print("Chosen world's name: " + get_worlds_list_file_contents()[(worlds_list_index * 2) + 1])
	print("Chosen world's folder/directory name: " + get_worlds_list_file_contents()[(worlds_list_index * 2) + 2])
	NetworkManager.start_game(not $WorldsScreenUI/Toggles/HostWithoutPlay.button_pressed, true, $WorldsScreenUI/Toggles/AllowJoining.button_pressed)

func _on_play_button_pressed():
	if not worlds_list_text.get_selected_items().is_empty(): # Don't do anything if no worlds are selected.
		start_world(worlds_list_text.get_selected_items()[0])


func open_new_world_popup():
	hide_all_worlds_menu_popups()
	var new_world_popup = get_node("NewWorldPopup")
	new_world_popup.get_node("WorldNameInput").clear()
	new_world_popup.get_node("WorldSeedInput").clear()
	new_world_popup.show()

func confirm_new_world():
	var new_world_popup = get_node("NewWorldPopup")
	
	# Randomize the seed if the seed input was left blank.
	if (new_world_popup.get_node("WorldSeedInput").text == ""):
		var random = RandomNumberGenerator.new()
		random.randomize()
		new_world_popup.get_node("WorldSeedInput").text = str(random.randi() - 4294967296 + random.randi())
	
	# Figure out what the new worlds list items should look like.
	var worlds_list_text_file_contents = get_worlds_list_file_contents()
	worlds_list_text_file_contents.append(new_world_popup.get_node("WorldNameInput").text)
	# (Find an appropriate unused internal directory/folder name for the world.)
	if (DirAccess.dir_exists_absolute("user://storage/worlds/" + worlds_list_text_file_contents[worlds_list_text_file_contents.size()-1])):
		var alt_dir_name_attempt: int = 1
		while(true == DirAccess.dir_exists_absolute("user://storage/worlds/" + worlds_list_text_file_contents[worlds_list_text_file_contents.size()-1] + " alt_" + str(alt_dir_name_attempt))):
				alt_dir_name_attempt += 1
		worlds_list_text_file_contents.append(new_world_popup.get_node("WorldNameInput").text + " alt_" + str(alt_dir_name_attempt))
	else:
		worlds_list_text_file_contents.append(new_world_popup.get_node("WorldNameInput").text)
	# (Create the world's directory/folder and it's essential files.)
	DirAccess.make_dir_recursive_absolute("user://storage/worlds/" + worlds_list_text_file_contents[worlds_list_text_file_contents.size()-1])
	DirAccess.make_dir_recursive_absolute("user://storage/worlds/" + worlds_list_text_file_contents[worlds_list_text_file_contents.size()-1] + "/chunks")
	var new_world_info_file
	new_world_info_file = FileAccess.open("user://storage/worlds/" + worlds_list_text_file_contents[worlds_list_text_file_contents.size()-1] + "/world_info.txt", FileAccess.WRITE)
	new_world_info_file.store_line(GlobalStuff.game_version_entire)
	new_world_info_file.store_line("date created: " + Time.get_datetime_string_from_system())
	new_world_info_file.store_line("last played: unplayed")
	new_world_info_file.store_line("world generation seed: " + new_world_popup.get_node("WorldSeedInput").text)
	new_world_info_file.close()
	
	# Replace the current worlds list file contents with newer updated contents.
	replace_worlds_list_file_contents(worlds_list_text_file_contents)
	
	update_displayed_worlds_list_text()
	new_world_popup.hide()

func open_edit_world_popup():
	hide_all_worlds_menu_popups()
	var displayed_worlds_list_text = get_node("WorldsScreenUI/SavedWorldsList")
	if not displayed_worlds_list_text.get_selected_items().is_empty(): # Don't do anything if no world is selected.
		var edit_world_popup = get_node("EditWorldPopup")
		edit_world_popup.get_node("PopupTitleText").text = "[center]Edit world: \"" + get_worlds_list_file_contents()[(displayed_worlds_list_text.get_selected_items()[0] * 2) + 1] +"\""
		edit_world_popup.get_node("WorldNameInput").text = get_worlds_list_file_contents()[(displayed_worlds_list_text.get_selected_items()[0] * 2) + 1]
		edit_world_popup.get_node("WorldSeedInput").text = get_world_info_file_contents(get_worlds_list_file_contents()[(displayed_worlds_list_text.get_selected_items()[0] * 2) + 2])[3].substr(23)
		edit_world_popup.show()

######## REMEMBER TO MAKE IT RENAME A DIRECTORY/FOLDER IF YOU RENAME THE WORLD
func confirm_edit_world():
	if not worlds_list_text.get_selected_items().is_empty(): # Crash prevention for if no world is selected.
		var edit_world_popup = get_node("EditWorldPopup")
		worlds_names[worlds_list_text.get_selected_items()[0]] = edit_world_popup.get_node("WorldNameInput").text
		if (edit_world_popup.get_node("WorldSeedInput").text == ""):
			var random = RandomNumberGenerator.new()
			random.randomize()
			worlds_seeds[worlds_list_text.get_selected_items()[0]] = random.randi() + random.randi() - 4294967296
		else:
			worlds_seeds[worlds_list_text.get_selected_items()[0]] = int(edit_world_popup.get_node("WorldSeedInput").text)
		update_displayed_worlds_list_text()
		edit_world_popup.hide()

func open_delete_world_popup():
	hide_all_worlds_menu_popups()
	if not worlds_list_text.get_selected_items().is_empty(): # Don't do anything if no world is selected.
		var delete_world_popup = get_node("DeleteWorldPopup")
		delete_world_popup.get_node("PopupTitleText").text = "[center]Are you sure you want to delete\n\"" + worlds_names[worlds_list_text.get_selected_items()[0]] +"\"?\n(This action cannot be undone.)[/center]"
		delete_world_popup.show()

func confirm_delete_world():
	if not worlds_list_text.get_selected_items().is_empty(): # Crash prevention for if no world is selected.
		var delete_world_popup = get_node("DeleteWorldPopup")
		worlds_names.remove_at(worlds_list_text.get_selected_items()[0])
		worlds_seeds.remove_at(worlds_list_text.get_selected_items()[0])
		delete_world_popup.hide()
		update_displayed_worlds_list_text()
		disable_world_selected_requiring_buttons()

func _on_duplicate_world_pressed():
	if not worlds_list_text.get_selected_items().is_empty(): # Crash prevention for if no world is selected.
		worlds_names.append("Copy of " + worlds_names[worlds_list_text.get_selected_items()[0]])
		update_displayed_worlds_list_text()
		disable_world_selected_requiring_buttons()


# Update the text of the visible worlds-list for the player.
func update_displayed_worlds_list_text():
	ensure_all_world_folders_are_known()
	reorder_worlds_alphabetically()
	
	var displayed_worlds_list_text = get_node("WorldsScreenUI/SavedWorldsList")
	displayed_worlds_list_text.clear()
	
	var worlds_list_file_contents = get_worlds_list_file_contents()
	# Only use the regular world names for the displayed text. (It starts at index 1 to skip the version string.)
	for index in range(1, worlds_list_file_contents.size()-1, 2):
		displayed_worlds_list_text.add_item(worlds_list_file_contents[index])

func reorder_worlds_alphabetically():
	pass

# Helpful in the instance that any world folders exist without the worlds list text file "knowing" about them.
func ensure_all_world_folders_are_known():
	pass

func ensure_world_folder_has_all_essential_files(name_of_directory_folder_for_world: String):
	if not DirAccess.dir_exists_absolute("user://storage/worlds/" + name_of_directory_folder_for_world):
		DirAccess.make_dir_recursive_absolute("user://storage/worlds/" + name_of_directory_folder_for_world)
		push_warning("Tried to ensure that the world folder: \"" + name_of_directory_folder_for_world +"\" has all essential files, but the folder didn't even exist. (Created it.)")
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

# Outputs an array of strings who's items alternate between world names and then it's directory/folder name.
func get_worlds_list_file_contents() -> Array[String]:
	# If the worlds list text file is able to be found/accessed:
	if (FileAccess.file_exists(worlds_list_file_location)):
		var worlds_list_txt_file: FileAccess
		worlds_list_txt_file = FileAccess.open(worlds_list_file_location, FileAccess.READ)
		var text_lines: Array[String] = []
		while (worlds_list_txt_file.eof_reached() == false): # Store each line of text as an item in an array.
			text_lines.append(worlds_list_txt_file.get_line())
		worlds_list_txt_file.close()
		if (text_lines.size() > 0): # (crash prevention)
			if (text_lines[text_lines.size()-1] == ""): # Don't include the blank line in the end of text files.
				text_lines.pop_back()
		if not (text_lines[0] == GlobalStuff.game_version_entire):
			push_warning("The worlds list text file was found to have an outdated version when attempting to get it's file contents. (Contents used anyway.)")
		return(text_lines)
	else:
		push_error("The worlds list text file could not be found/accessed whilst attempted to be read.")
		return([])

func replace_worlds_list_file_contents(new_worlds_list_contents: Array[String]):
	# Ensure that the file can be accessed before proceeding.
	if not (FileAccess.file_exists(worlds_list_file_location)):
		push_warning("The worlds list text file could not be found/accessed whilst attempting to be written to / replaced. (Writing to its specified location anyway.)")
	var worlds_list_text_file: FileAccess
	worlds_list_text_file = FileAccess.open(worlds_list_file_location, FileAccess.WRITE)
	if (FileAccess.get_open_error() == 0):
		for line in new_worlds_list_contents:
			worlds_list_text_file.store_line(line)
	else:
		push_error("The worlds list file location could not be written to / created. (Does the program have proper OS permissions to create/write files?)")
	worlds_list_text_file.close()

func get_world_info_file_contents(name_of_directory_folder_for_world: String) -> Array[String]:
	# If the world info text file is able to be found/accessed:
	if (FileAccess.file_exists("user://storage/worlds/" + name_of_directory_folder_for_world + "/world_info.txt")):
		var world_info_text_file: FileAccess
		world_info_text_file = FileAccess.open("user://storage/worlds/" + name_of_directory_folder_for_world + "/world_info.txt", FileAccess.READ)
		var text_lines: Array[String] = []
		while (world_info_text_file.eof_reached() == false): # Store each line of text as an item in an array.
			text_lines.append(world_info_text_file.get_line())
		world_info_text_file.close()
		if (text_lines.size() > 0): # (crash prevention)
			if (text_lines[text_lines.size()-1] == ""): # Don't include the blank line in the end of text files.
				text_lines.pop_back()
		if not (text_lines[0] == GlobalStuff.game_version_entire):
			push_warning("The world item text file was found to have an outdated version when attempting to get it's file contents. (Contents used anyway.)")
		return(text_lines)
	else:
		push_error("The world info text file in directory: \"" + name_of_directory_folder_for_world + "\" could not be found/accessed whilst attempted to be read.")
		return([])

func replace_world_info_file_contents(name_of_directory_folder_for_world: String, new_file_contents: Array[String]):
	# Ensure that the file can be accessed before proceeding.
	if not (FileAccess.file_exists("user://storage/worlds/" + name_of_directory_folder_for_world + "/world_info.txt")):
		push_warning("The world info text file in directory: \"" + name_of_directory_folder_for_world + "\" could not be found/accessed whilst attempting to be written to / replaced. (Writing to its specified location anyway.)")
	var world_info_text_file: FileAccess
	world_info_text_file = FileAccess.open("user://storage/worlds/" + name_of_directory_folder_for_world + "/world_info.txt", FileAccess.WRITE)
	if (FileAccess.get_open_error() == 0):
		for line in new_file_contents:
			world_info_text_file.store_line(line)
	else:
		push_error("The world info text file in directory: \"" + name_of_directory_folder_for_world + "\" could not be written to / created. (Does the program have proper OS permissions to create/write files?)")
	world_info_text_file.close()


# Disables the host_without_playing_toggle if multiplayer joining is turned off.
func toggle_disabling_the_host_without_playing_toggle (button_value: bool) -> void:
	$WorldsScreenUI/Toggles/HostWithoutPlay.disabled = not button_value
	if not button_value:
		$WorldsScreenUI/Toggles/HostWithoutPlay.button_pressed = false

func _on_worlds_list_item_selected():
	hide_all_worlds_menu_popups()
	$WorldsScreenUI/WorldButtons/DeleteWorld.disabled = false
	$WorldsScreenUI/WorldButtons/EditWorld.disabled = false
	$WorldsScreenUI/WorldButtons/DuplicateWorld.disabled = false
	$WorldsScreenUI/WorldButtons/PlayWorld.disabled = false

func hide_all_worlds_menu_popups():
	get_node("NewWorldPopup").hide()
	get_node("EditWorldPopup").hide()
	get_node("DeleteWorldPopup").hide()

func disable_world_selected_requiring_buttons():
	$WorldsScreenUI/WorldButtons/DeleteWorld.disabled = true
	$WorldsScreenUI/WorldButtons/EditWorld.disabled = true
	$WorldsScreenUI/WorldButtons/DuplicateWorld.disabled = true
	$WorldsScreenUI/WorldButtons/PlayWorld.disabled = true
