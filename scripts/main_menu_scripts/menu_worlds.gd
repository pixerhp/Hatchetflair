extends Control

const worlds_list_txtfile_location: String = "user://storage/worlds_list.txt"

@onready var worlds_list_text = $WorldsScreenUI/SavedWorldsList
var worlds_names: Array[String] = []
var worlds_seeds: Array[int] = []


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

# Start playing/hosting one of your worlds.
func start_world(worlds_list_index: int = 0):#world_file_name: String, allow_multiplayer: bool, host_without_playing: bool):
	var worlds_txtfile_lines: Array[String] = FileManager.read_txtfile_lines_as_array(worlds_list_txtfile_location)
	print("Chosen world's list-index: " + str(worlds_list_index))
	print("Chosen world's name: " + worlds_txtfile_lines[(worlds_list_index * 2) + 1])
	print("Chosen world's folder/directory name: " + worlds_txtfile_lines[(worlds_list_index * 2) + 2])
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
	var worlds_list_text_file_contents = FileManager.read_txtfile_lines_as_array(worlds_list_txtfile_location)
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
	new_world_info_file.store_line("creation date-time (utc): " + Time.get_datetime_string_from_system(true, true))
	new_world_info_file.store_line("last-played date-time (utc): unplayed")
	new_world_info_file.store_line("world generation seed: " + new_world_popup.get_node("WorldSeedInput").text)
	new_world_info_file.close()
	
	# Replace the current worlds list file contents with newer updated contents.
	FileManager.write_txtfile_from_array_of_lines(worlds_list_txtfile_location, worlds_list_text_file_contents)
	
	update_displayed_worlds_list_text()
	new_world_popup.hide()

func open_edit_world_popup():
	hide_all_worlds_menu_popups()
	var displayed_worlds_list_text = get_node("WorldsScreenUI/SavedWorldsList")
	if not displayed_worlds_list_text.get_selected_items().is_empty(): # Don't do anything if no world is selected.
		var edit_world_popup = get_node("EditWorldPopup")
		edit_world_popup.get_node("PopupTitleText").text = "[center]Edit world: \"" + FileManager.read_txtfile_lines_as_array(worlds_list_txtfile_location)[(displayed_worlds_list_text.get_selected_items()[0] * 2) + 1] +"\""
		edit_world_popup.get_node("WorldNameInput").text = FileManager.read_txtfile_lines_as_array(worlds_list_txtfile_location)[(displayed_worlds_list_text.get_selected_items()[0] * 2) + 1]
		edit_world_popup.get_node("WorldSeedInput").text = FileManager.read_txtfile_lines_as_array("user://storage/worlds/"+FileManager.read_txtfile_lines_as_array(worlds_list_txtfile_location)[(displayed_worlds_list_text.get_selected_items()[0] * 2) + 2]+"/world_info.txt")[3].substr(23)
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
	var displayed_worlds_list_text = get_node("WorldsScreenUI/SavedWorldsList")
	if not displayed_worlds_list_text.get_selected_items().is_empty(): # Don't do anything if no world is selected.
		var delete_world_popup = get_node("DeleteWorldPopup")
		delete_world_popup.get_node("PopupTitleText").text = "[center]Are you sure you want to delete world:\n\"" + FileManager.read_txtfile_lines_as_array(worlds_list_txtfile_location)[(displayed_worlds_list_text.get_selected_items()[0] * 2) + 1] +"\"?\n(This action cannot be undone.)[/center]"
		delete_world_popup.show()

func confirm_delete_world():
	if not worlds_list_text.get_selected_items().is_empty(): # Crash prevention for if no world is selected.
		var worlds_list_file_contents: Array[String] = FileManager.read_txtfile_lines_as_array(worlds_list_txtfile_location)
		var dir_to_delete: String = "user://storage/worlds/" + worlds_list_file_contents[(worlds_list_text.get_selected_items()[0] * 2) + 2]
		
		# It doesn't make sense to try to delete the world if you can't even find it.
		if DirAccess.dir_exists_absolute(dir_to_delete):
			# Delete all of the files in the world's folder and then said folder itself.
			if (FileManager.recursively_delete_all_files_inside_directory(dir_to_delete) == false):
				DirAccess.remove_absolute(dir_to_delete)
				
				# If successful, remove knowledge of the world from the worlds list text file.
				worlds_list_file_contents.remove_at((worlds_list_text.get_selected_items()[0] * 2) + 2)
				worlds_list_file_contents.remove_at((worlds_list_text.get_selected_items()[0] * 2) + 1)
			else:
				push_warning("When attempting to delete a world, an error was encountered trying to delete its folder.(Aborting complete deletion, however some files may have already been removed.)")
		else:
			push_warning("When attempting to delete a world, its folder could not be found. (Aborting deletion.)")
		
		get_node("DeleteWorldPopup").hide()
		disable_world_selected_requiring_buttons()
		update_displayed_worlds_list_text()

func _on_duplicate_world_pressed():
	if not worlds_list_text.get_selected_items().is_empty(): # Crash prevention for if no world is selected.
		worlds_names.append("Copy of " + worlds_names[worlds_list_text.get_selected_items()[0]])
		disable_world_selected_requiring_buttons()
		update_displayed_worlds_list_text()


# Update the text of the visible worlds-list for the player.
func update_displayed_worlds_list_text():
	sync_worlds_list_to_what_world_folders_actually_exist()
	FileManager.sort_txtfile_contents_alphabetically(worlds_list_txtfile_location, 1, 2)
	
	var displayed_worlds_list_text = get_node("WorldsScreenUI/SavedWorldsList")
	displayed_worlds_list_text.clear()
	
	var worlds_list_file_contents = FileManager.read_txtfile_lines_as_array(worlds_list_txtfile_location)
	# Only use the regular world names for the displayed text. (It starts at index 1 to skip the version string.)
	for index in range(1, worlds_list_file_contents.size()-1, 2):
		displayed_worlds_list_text.add_item(worlds_list_file_contents[index])

# Helpful in the instance that any world folders exist without the worlds list text file "knowing" about them.
func sync_worlds_list_to_what_world_folders_actually_exist():
	# Ensure that the storage folder worlds folder exists before opening it.
	if not DirAccess.dir_exists_absolute("user://storage/worlds"):
		push_warning("When trying to ensure all world folders are known, the main \"worlds\" folder could not be found. (Creating it now.)")
		DirAccess.make_dir_recursive_absolute("user://storage/worlds")
	
	# Get all of the raw info needed for comparison.
	var list_of_world_folder_names: PackedStringArray = DirAccess.open("user://storage/worlds").get_directories()
	var worlds_list_file_contents: Array[String] = FileManager.read_txtfile_lines_as_array(worlds_list_txtfile_location)
	
	# Remove listed worlds but which don't actually exist from what will be the replacement worlds list text file contents.
	var indeces_for_removal: Array[int] = []
	for index in range(worlds_list_file_contents.size()-1, 0, -2): # (We want the list of indeces to remove from last to first, so we check these in a similar order.)
		if (list_of_world_folder_names.count(worlds_list_file_contents[index]) == 0):
			indeces_for_removal.append(index)
	for index in indeces_for_removal:
		worlds_list_file_contents.remove_at(index)
		worlds_list_file_contents.remove_at(index - 1)
	
	# Add unaccounted-for found world folders to what will be the replacement worlds list text file contents.
	var already_known_folder_names: Array[String] = []
	for index in range(2, worlds_list_file_contents.size(), 2):
		already_known_folder_names.append(worlds_list_file_contents[index])
	for folder_name in list_of_world_folder_names:
		if (already_known_folder_names.count(folder_name) == 0):
			worlds_list_file_contents.append(folder_name) # (We do this once for world name, twice for world folder name.)
			worlds_list_file_contents.append(folder_name)
	
	# Replace the worlds list text file's contents with the new ensuredly-synced file contents.
	FileManager.write_txtfile_from_array_of_lines(worlds_list_txtfile_location, worlds_list_file_contents)

func ensure_world_folder_has_its_essential_files(name_of_directory_folder_for_world: String):
	if not DirAccess.dir_exists_absolute("user://storage/worlds/" + name_of_directory_folder_for_world):
		push_warning("Tried to ensure that the world folder: \"" + name_of_directory_folder_for_world +"\" has all essential files, but that world folder didn't even exist. (Creating it now.)")
		DirAccess.make_dir_recursive_absolute("user://storage/worlds/" + name_of_directory_folder_for_world)
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
