extends Control

var world_dir_names: Array[String] = []
var dir_name_to_world_name: Dictionary = {}
@onready var worlds_list_node: Node = $WorldsUI/SavedWorldsList


func _ready():
	# Connect popup buttons to their associated functions.
	$NewWorldPopup/Confirm.pressed.connect(self.confirm_new_world)
	$NewWorldPopup/Cancel.pressed.connect($NewWorldPopup.hide)
	$EditWorldPopup/Confirm.pressed.connect(self.confirm_edit_world)
	$EditWorldPopup/Cancel.pressed.connect($EditWorldPopup.hide)
	$DeleteWorldPopup/Confirm.pressed.connect(self.confirm_delete_world)
	$DeleteWorldPopup/Cancel.pressed.connect($DeleteWorldPopup.hide)
	
	disable_item_selected_buttons()
	hide_worlds_menu_popups()
	return


func sync_worlds():
	world_dir_names.assign(DirAccess.get_directories_at(FileManager.PATH_WORLDS))
	dir_name_to_world_name.clear()
	for dir_name in world_dir_names:
		dir_name_to_world_name[dir_name] = FileManager.read_cfg_keyval(FileManager.PATH_WORLDS + "/" + 
		dir_name + "/world.cfg", "meta", "world_name", FileManager.ERRMSG_CFG + "   (dirname: " + dir_name + ")")
	return
func sort_worlds():
	Globals.sort_alphabetically(world_dir_names, true)
	return
func update_worlds_list():
	sync_worlds()
	sort_worlds()
	worlds_list_node.clear()
	for dir_name in world_dir_names:
		worlds_list_node.add_item(dir_name_to_world_name[dir_name])
	return

func start_world_by_index(index: int = -1) -> Error:
	if index == -1:
		if worlds_list_node.get_selected_items().is_empty():
			push_warning("No list index was specified.")
			return FAILED
		else:
			index = worlds_list_node.get_selected_items()[0]
	start_world_by_specifics(FileManager.PATH_WORLDS + "/" + world_dir_names[index], 
	$WorldsUI/Toggles/AllowJoining.button_pressed, 
	$WorldsUI/Toggles/HostWithoutPlaying.button_pressed)
	return OK
func start_world_by_specifics(world_dir_path: String, 
allow_multiplayer_joining: bool = $WorldsUI/Toggles/AllowJoining.button_pressed, 
host_without_playing: bool = $WorldsUI/Toggles/HostWithoutPlaying.button_pressed) -> Error:
	print("Although technically not using it yet, use world files when loading a world later. ", world_dir_path)
	if NetworkManager.host_game(allow_multiplayer_joining, host_without_playing) != OK:
		return FAILED
	else:
		return OK


func open_new_world_popup() -> void:
	hide_worlds_menu_popups()
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
	return OK

func open_edit_world_popup() -> Error:
	hide_worlds_menu_popups()
	if worlds_list_node.get_selected_items().is_empty():
		push_warning("No world index is selected.")
		return FAILED
	var dir_name: String = world_dir_names[worlds_list_node.get_selected_items()[0]]
	var dict: Dictionary = FileManager.read_cfg(FileManager.PATH_WORLDS + "/" + dir_name + "/world.cfg")
	var world_name: String = Globals.dict_safeget(dict, ["meta", "world_name"], FileManager.ERRMSG_CFG)
	var world_seed: String = Globals.dict_safeget(dict, ["generation", "seed"], FileManager.ERRMSG_CFG)
	var popup: Node = $EditWorldPopup
	popup.get_node("PopupTitleText").text = "[center]Edit world: \"" + world_name + "\""
	popup.get_node("WorldNameInput").text = world_name
	popup.get_node("WorldSeedInput").text = world_seed
	popup.show()
	popup.get_node("WorldNameInput").grab_focus()
	return OK
func confirm_edit_world() -> Error:
	if worlds_list_node.get_selected_items().is_empty():
		push_warning("No world index is selected.")
		return FAILED
	var dir_name: String = world_dir_names[worlds_list_node.get_selected_items()[0]]
	var popup: Node = $EditWorldPopup
	var edited_name: String = popup.get_node("WorldNameInput").text
	var edited_seed: String = popup.get_node("WorldSeedInput").text
	var err: Error = FileManager.edit_world(dir_name, edited_name, edited_seed)
	
	update_worlds_list()
	popup.hide()
	if err != OK:
		return FAILED
	return OK

func open_delete_world_popup() -> Error:
	hide_worlds_menu_popups()
	if worlds_list_node.get_selected_items().is_empty():
		push_warning("No world index is selected.")
		return FAILED
	var dir_name: String = world_dir_names[worlds_list_node.get_selected_items()[0]]
	var world_name: String = FileManager.read_cfg_keyval(FileManager.PATH_WORLDS + "/" + dir_name + "/world.cfg", "meta", "world_name", FileManager.ERRMSG_CFG)
	var popup: Node = $DeleteWorldPopup
	popup.get_node("PopupTitleText").text = ("[center]Are you sure you want to delete world:\n" + world_name 
	+ "\n(It will be deleted to your OS's recycling bin.)[/center]")
	popup.show()
	return OK
func confirm_delete_world() -> Error:
	hide_worlds_menu_popups()
	if worlds_list_node.get_selected_items().is_empty():
		push_warning("No world index is selected.")
		return FAILED
	var dir_name: String = world_dir_names[worlds_list_node.get_selected_items()[0]]
	var err: Error = FileManager.delete_world(dir_name)
	
	$DeleteWorldPopup.hide()
	disable_item_selected_buttons()
	update_worlds_list()
	if err != OK:
		return FAILED
	return OK

func _on_duplicate_world_pressed() -> Error:
	if worlds_list_node.get_selected_items().is_empty():
		push_warning("No world index is selected.")
		return FAILED
	var dir_name: String = world_dir_names[worlds_list_node.get_selected_items()[0]]
	var err: Error = FileManager.duplicate_world(dir_name)
	disable_item_selected_buttons()
	update_worlds_list()
	if err != OK:
		return FAILED
	return OK


func toggle_host_without_playing_visibility (button_value: bool):
	$WorldsUI/Toggles/HostWithoutPlaying.disabled = not button_value
	if button_value == false:
		$WorldsUI/Toggles/HostWithoutPlaying.button_pressed = false

func _on_worlds_list_item_selected():
	hide_worlds_menu_popups()
	$WorldsUI/WorldButtons/DeleteWorld.disabled = false
	$WorldsUI/WorldButtons/EditWorld.disabled = false
	$WorldsUI/WorldButtons/DuplicateWorld.disabled = false
	$WorldsUI/WorldButtons/PlayWorld.disabled = false

func disable_item_selected_buttons():
	$WorldsUI/WorldButtons/DeleteWorld.disabled = true
	$WorldsUI/WorldButtons/EditWorld.disabled = true
	$WorldsUI/WorldButtons/DuplicateWorld.disabled = true
	$WorldsUI/WorldButtons/PlayWorld.disabled = true

func hide_worlds_menu_popups():
	$NewWorldPopup.hide()
	$EditWorldPopup.hide()
	$DeleteWorldPopup.hide()
