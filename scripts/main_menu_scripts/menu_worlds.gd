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
		dir_name_to_world_name[dir_name] = FileManager.read_cfg_keyval(FileManager.PATH_WORLDS + "/" + dir_name + "/world.cfg", "meta_info", "world_name")
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

func open_edit_world_popup() -> Error:
	hide_all_worlds_menu_popups()
	if worlds_list_node.get_selected_items().is_empty():
		push_warning("No world index is selected.")
		return FAILED
	var dir_name: String = world_dir_names[worlds_list_node.get_selected_items()[0]]
	# Note: In the future when you can edit much more than just name and seed, 
	# get all world info at once rather than each piece individually to reduce file reads.
	var world_name: String = FileManager.read_cfg_keyval(FileManager.PATH_WORLDS + "/" + dir_name + "/world.cfg", "meta_info", "world_name")
	var world_seed: String = FileManager.read_cfg_keyval(FileManager.PATH_WORLDS + "/" + dir_name + "/world.cfg", "generation", "seed")
	var popup: Node = $EditWorldPopup
	popup.get_node("PopupTitleText").text = "[center]Edit world: \"" + world_name + "\""
	popup.get_node("WorldNameInput").text = world_name
	popup.get_node("WorldSeedInput").text = world_seed
	popup.show()
	popup.get_node("WorldNameInput").grab_focus()
	return OK
func confirm_edit_world():
	if worlds_list_node.get_selected_items().is_empty():
		push_warning("No world index is selected.")
		return
	var dir_name: String = world_dir_names[worlds_list_node.get_selected_items()[0]]
	var popup: Node = $EditWorldPopup
	var edited_name: String = popup.get_node("WorldNameInput").text
	var edited_seed: String = popup.get_node("WorldSeedInput").text
	FileManager.edit_world(dir_name, edited_name, edited_seed)
	
	update_worlds_list()
	popup.hide()
	return

func open_delete_world_popup() -> Error:
	hide_all_worlds_menu_popups()
	if worlds_list_node.get_selected_items().is_empty():
		push_warning("No world index is selected.")
		return FAILED
	var dir_name: String = world_dir_names[worlds_list_node.get_selected_items()[0]]
	var world_name: String = FileManager.read_cfg_keyval(FileManager.PATH_WORLDS + "/" + dir_name + "/world.cfg", "meta_info", "world_name")
	var popup: Node = $DeleteWorldPopup
	popup.get_node("PopupTitleText").text = ("[center]Are you sure you want to delete world:\n" + world_name 
	+ "\n(It will be deleted to your OS's recycling bin.)[/center]")
	popup.show()
	return OK
func confirm_delete_world() -> Error:
	hide_all_worlds_menu_popups()
	if worlds_list_node.get_selected_items().is_empty():
		push_warning("No world index is selected.")
		return FAILED
	var dir_name: String = world_dir_names[worlds_list_node.get_selected_items()[0]]
	var err: Error = FileManager.delete_world(dir_name)
	$DeleteWorldPopup.hide()
	disable_world_selected_requiring_buttons()
	update_worlds_list()
	if err != OK:
		return FAILED
	else:
		return OK

func _on_duplicate_world_pressed() -> Error:
	if worlds_list_node.get_selected_items().is_empty():
		push_warning("No world index is selected.")
		return FAILED
	var dir_name: String = world_dir_names[worlds_list_node.get_selected_items()[0]]
	var err: Error = FileManager.duplicate_world(dir_name)
	disable_world_selected_requiring_buttons()
	update_worlds_list()
	if err != OK:
		return FAILED
	else:
		return OK


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
