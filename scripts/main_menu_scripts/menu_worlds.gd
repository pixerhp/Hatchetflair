extends Control

var world_dir_names: Array[String] = []
var dir_name_to_world_name: Dictionary = {}

@onready var worlds_list_node: Node = $WorldsScreenUI/SavedWorldsList



const worlds_list_txtfile_location = ""


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


func sync_worlds() -> Error:
	var any_errors_encountered: bool = false
	world_dir_names.assign(DirAccess.get_directories_at(FileManager.PATH_WORLDS))
	# Set up the dir names to world names dictionary:
	dir_name_to_world_name.clear()
	for dir_name in world_dir_names:
		dir_name_to_world_name[dir_name] = FileManager.read_cfg_keyval(FileManager.PATH_WORLDS + "/" + dir_name + "/world_data.cfg", "meta_data", "world_name")
		if dir_name_to_world_name[dir_name] == null:
			dir_name_to_world_name[dir_name] = "<error: reading cfg keyval returned null>"
			any_errors_encountered = true
	if any_errors_encountered:
		return FAILED
	else:
		return OK
func update_worlds_list() -> void:
	sync_worlds()
	worlds_list_node.clear()
	for world_name in dir_name_to_world_name.values():
		worlds_list_node.add_item(world_name)
	return

func start_world_by_index(list_index: int = -1) -> Error:
	if list_index == -1:
		if worlds_list_node.get_selected_items().is_empty():
			push_warning("No list index was specified.")
			return FAILED
		else:
			list_index = worlds_list_node.get_selected_items()[0]
	start_world_by_specifics(FileManager.PATH_WORLDS + "/" + world_dir_names[list_index], $WorldsScreenUI/Toggles/AllowJoining.button_pressed, $WorldsScreenUI/Toggles/HostWithoutPlaying.button_pressed)
	return OK
func start_world_by_specifics(world_dir_path: String, 
allow_multiplayer_joining: bool = $WorldsScreenUI/Toggles/AllowJoining.button_pressed, 
host_without_playing: bool = $WorldsScreenUI/Toggles/HostWithoutPlaying.button_pressed) -> Error:
	print("Although technically not using it yet, use world files when loading a world later. ", world_dir_path)
	if NetworkManager.start_game(not host_without_playing, true, allow_multiplayer_joining) != OK:
		return FAILED
	else:
		return OK


func open_new_world_popup() -> void:
	hide_all_worlds_menu_popups()
	$NewWorldPopup/WorldNameInput.clear()
	$NewWorldPopup/WorldSeedInput.clear()
	$NewWorldPopup.show()
	$NewWorldPopup/WorldNameInput.grab_focus()
	return
func confirm_new_world() -> Error:
	var popup: Node = $NewWorldPopup
	var world_name: String = popup.get_node("WorldNameInput").text
	var world_seed: String = popup.get_node("WorldSeedInput").text
	var err: Error = FileManager.create_world(world_name, world_seed)
	update_worlds_list()
	popup.hide()
	if err != OK:
		return FAILED
	else:
		return OK

func open_edit_world_popup():
	hide_all_worlds_menu_popups()
	
	var displayed_worlds_itemlist: Node = worlds_list_node
	if displayed_worlds_itemlist.get_selected_items().is_empty():
		push_warning("Attempted to open the edit world popup despite no displayed world items being selected. (Aborted popup.)")
		return
	var selected_world_index: int = displayed_worlds_itemlist.get_selected_items()[0]
	var worlds_list_lines: Array[String] = FileManager.read_file_lines(worlds_list_txtfile_location)
	var world_info_file_path: String = "user://storage/worlds/" + worlds_list_lines[(selected_world_index*2)+2] + "/world_info.txt"
	var popup: Node = $EditWorldPopup
	var world_name: String = worlds_list_lines[(selected_world_index*2)+1]
	var world_seed: String = FileManager.read_txtfile_remaining_of_line_starting_with(world_info_file_path, "world_seed: ")[1]
	
	popup.get_node("PopupTitleText").text = "[center]Edit world: \"" + world_name + "\""
	popup.get_node("WorldNameInput").text = world_name
	popup.get_node("WorldSeedInput").text = world_seed
	popup.show()
	popup.get_node("WorldNameInput").grab_focus()
	return

func confirm_edit_world():
	var displayed_worlds_itemlist: Node = worlds_list_node
	if displayed_worlds_itemlist.get_selected_items().is_empty():
		push_warning("Attempted to finilize editing a saved world whilst none of the displayed worlds items were selected. (Did nothing.)")
		return
	var selected_server_index: int = displayed_worlds_itemlist.get_selected_items()[0]
	var file_contents: Array[String] = FileManager.read_file_lines(worlds_list_txtfile_location)
	
	var popup: Node = $EditWorldPopup
	var edited_name: String = popup.get_node("WorldNameInput").text
	var edited_seed: String = ""
	if popup.get_node("WorldSeedInput").text != "":
		edited_seed = str(int(popup.get_node("WorldSeedInput").text))
	else:
		edited_seed = str(GeneralGlobals.random_worldgen_seed())
	var original_world_dir: String = "user://storage/worlds/" + file_contents[(selected_server_index*2)+2]
	var new_world_dir_name: String = FileManager.first_unused_dir_alt("user://storage/worlds/", edited_name)
	var new_world_dir: String = "user://storage/worlds/" + new_world_dir_name
	
	# Determine what the contents of the worlds list text file should be after editing and replace its old contents.
	file_contents[(selected_server_index*2)+1] = edited_name
	file_contents[(selected_server_index*2)+2] = new_world_dir_name
	FileManager.write_txtfile_from_array_of_lines(worlds_list_txtfile_location, file_contents)
	
	
	# Update the world's world_info text file.
	FileManager.write_txtfile_replace_end_of_line_starting_with(original_world_dir + "/world_info.txt", "world_name: ", edited_name)
	FileManager.write_txtfile_replace_end_of_line_starting_with(original_world_dir + "/world_info.txt", "world_seed: ", edited_seed)
	
	if original_world_dir != new_world_dir:
		DirAccess.rename_absolute(original_world_dir, new_world_dir)
	
	update_worlds_list()
	popup.hide()
	return

func open_delete_world_popup():
	hide_all_worlds_menu_popups()
	
	var displayed_worlds_itemlist: Node = worlds_list_node
	if displayed_worlds_itemlist.get_selected_items().is_empty():
		push_warning("Attempted to open the delete world popup despite no displayed world items being selected. (Did nothing.)")
		return
	var name_of_world_to_delete: String = FileManager.read_file_lines(worlds_list_txtfile_location)[(displayed_worlds_itemlist.get_selected_items()[0]*2)+1]
	
	$DeleteWorldPopup/PopupTitleText.text = "[center]Are you sure you want to delete world:\n\"" + name_of_world_to_delete +"\"?\n(This action cannot be undone.)[/center]"
	$DeleteWorldPopup.show()
	return

func confirm_delete_world():
	var displayed_worlds_itemlist: Node = worlds_list_node
	if displayed_worlds_itemlist.get_selected_items().is_empty():
		push_warning("Attempted to finilize deleting a world, but none of the displayed items were selected. (Aborted deletion.)")
		return
	var world_index: int = (displayed_worlds_itemlist.get_selected_items()[0]*2)+1
	var worlds_list_lines: Array[String] = FileManager.read_file_lines(worlds_list_txtfile_location)
	var dir_to_delete: String = "user://storage/worlds/" + worlds_list_lines[(displayed_worlds_itemlist.get_selected_items()[0]*2)+2]
	if not DirAccess.dir_exists_absolute(dir_to_delete):
		push_warning("Attempted to finilize deleting a world, but its directory could not be found: ", dir_to_delete, " (Aborting deletion.)")
		return 
	
	# Delete the world's directory/folder and then edit the worlds list txtfile (second then first line due to array resizing.)
	if FileManager.delete_dir(dir_to_delete, false):
		push_warning("An error was encountered deleting a world's directory: ", dir_to_delete)
	worlds_list_lines.remove_at(world_index+1)
	worlds_list_lines.remove_at(world_index)
	FileManager.write_txtfile_from_array_of_lines(worlds_list_txtfile_location, worlds_list_lines)
	
	$DeleteWorldPopup.hide()
	disable_world_selected_requiring_buttons()
	update_worlds_list()
	return

func _on_duplicate_world_pressed():
	var displayed_worlds_itemlist: Node = worlds_list_node
	if displayed_worlds_itemlist.get_selected_items().is_empty():
		push_warning("Attempted to duplicate a world, but none of the displayed items were selected. (Did nothing.)")
		return
	var selected_world_index: int = displayed_worlds_itemlist.get_selected_items()[0]
	var worlds_list_lines: Array[String] = FileManager.read_file_lines(worlds_list_txtfile_location)
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
	FileManager.copy_dir_to_path(originals_dir_path, copys_dir_path, false)
	
	disable_world_selected_requiring_buttons()
	update_worlds_list()
	return


func toggle_visibility_of_host_without_playing_toggle (button_value: bool) -> void:
	$WorldsScreenUI/Toggles/HostWithoutPlaying.disabled = not button_value
	if not button_value:
		$WorldsScreenUI/Toggles/HostWithoutPlaying.button_pressed = false

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
