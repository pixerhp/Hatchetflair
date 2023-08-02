extends Control

@onready var worlds_list_text = get_node("WorldsScreenUI/SavedWorldsList")
var worlds_list = ["test a", "test b", "test c", "test d", "test e", "test f", "test g", "test h"]


# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect popups and their buttons to functions.
	var new_world_button = get_node("WorldsScreenUI/WorldButtons/NewWorld")
	new_world_button.pressed.connect(self.open_new_world_popup)
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
	update_worlds_list_text()


# Start playing/hosting one of your worlds.
func start_world(world_index: int = 0):#world_file_name: String, allow_multiplayer: bool, host_without_playing: bool):
	var allow_multiplayer_joining_toggle: CheckButton = $WorldsScreenUI/Toggles/AllowJoining
	var host_without_playing_toggle: CheckButton = $WorldsScreenUI/Toggles/HostWithoutPlay
	NetworkManager.start_game(not host_without_playing_toggle.button_pressed, true, allow_multiplayer_joining_toggle.button_pressed)


func open_new_world_popup():
	hide_all_worlds_menu_popups()
	var new_world_popup = get_node("NewWorldPopup")
	new_world_popup.get_node("WorldNameInput").clear()
	new_world_popup.get_node("SeedInput").clear()
	new_world_popup.show()

func confirm_new_world():
	var new_world_popup = get_node("NewWorldPopup")
	worlds_list.append(new_world_popup.get_node("WorldNameInput").text)
	update_worlds_list_text()
	new_world_popup.hide()

func open_delete_world_popup():
	hide_all_worlds_menu_popups()
	if not worlds_list_text.get_selected_items().is_empty(): # Don't do anything if no worlds are selected.
		var delete_world_popup = get_node("DeleteWorldPopup")
		delete_world_popup.get_node("PopupTitleText").text = "[center]Are you sure you want to delete \"" + worlds_list[worlds_list_text.get_selected_items()[0]] +"\"?\n(This action cannot be undone.)[/center]"
		delete_world_popup.show()

func confirm_delete_world():
	if not worlds_list_text.get_selected_items().is_empty(): # Crash prevention for if no world is selected.
		var delete_world_popup = get_node("DeleteWorldPopup")
		worlds_list.erase(worlds_list[worlds_list_text.get_selected_items()[0]])
		delete_world_popup.hide()
		update_worlds_list_text()
		disable_world_selected_requiring_buttons()

func open_edit_world_popup():
	hide_all_worlds_menu_popups()
	if not worlds_list_text.get_selected_items().is_empty(): # Don't do anything if no worlds are selected.
		var edit_world_popup = get_node("EditWorldPopup")
		edit_world_popup.get_node("PopupTitleText").text = "[center]What will you rename world \"" + worlds_list[worlds_list_text.get_selected_items()[0]] +"\" to?[/center]"
		edit_world_popup.get_node("WorldNameInput").text = worlds_list[worlds_list_text.get_selected_items()[0]]
		edit_world_popup.get_node("SeedInput").clear()
		edit_world_popup.show()

func confirm_edit_world():
	if not worlds_list_text.get_selected_items().is_empty(): # Crash prevention for if no world is selected.
		var edit_world_popup = get_node("EditWorldPopup")
		worlds_list[worlds_list_text.get_selected_items()[0]] = edit_world_popup.get_node("WorldNameInput").text
		update_worlds_list_text()
		edit_world_popup.hide()

func _on_duplicate_world_pressed():
	if not worlds_list_text.get_selected_items().is_empty(): # Crash prevention for if no world is selected.
		worlds_list.append("Copy of " + worlds_list[worlds_list_text.get_selected_items()[0]])
		update_worlds_list_text()
		disable_world_selected_requiring_buttons()

func _on_play_button_pressed():
	if not worlds_list_text.get_selected_items().is_empty(): # Don't do anything if no worlds are selected.
		start_world()


# Update the text of the visible worlds-list for the player.
func update_worlds_list_text():
	worlds_list_text.clear()
	for world in worlds_list:
		worlds_list_text.add_item(world)


# Disables the host_without_playing_toggle if multiplayer joining is turned off.
func toggle_disabling_the_host_without_playing_toggle (button_value: bool) -> void:
	var host_without_playing_toggle: CheckButton = $WorldsScreenUI/Toggles/HostWithoutPlay
	host_without_playing_toggle.disabled = not button_value
	if not button_value:
		host_without_playing_toggle.button_pressed = false

func _on_worlds_list_item_selected():
	hide_all_worlds_menu_popups()
	var delete_world_button: Button = $WorldsScreenUI/WorldButtons/DeleteWorld
	delete_world_button.disabled = false
	var edit_world_button: Button = $WorldsScreenUI/WorldButtons/EditWorld
	edit_world_button.disabled = false
	var duplicate_world_button: Button = $WorldsScreenUI/WorldButtons/DuplicateWorld
	duplicate_world_button.disabled = false
	var play_world_button: Button = $WorldsScreenUI/WorldButtons/PlayWorld
	play_world_button.disabled = false

func hide_all_worlds_menu_popups():
	get_node("NewWorldPopup").hide()
	get_node("EditWorldPopup").hide()
	get_node("DeleteWorldPopup").hide()

func disable_world_selected_requiring_buttons():
	var delete_world_button: Button = $WorldsScreenUI/WorldButtons/DeleteWorld
	delete_world_button.disabled = true
	var edit_world_button: Button = $WorldsScreenUI/WorldButtons/EditWorld
	edit_world_button.disabled = true
	var duplicate_world_button: Button = $WorldsScreenUI/WorldButtons/DuplicateWorld
	duplicate_world_button.disabled = true
	var play_world_button: Button = $WorldsScreenUI/WorldButtons/PlayWorld
	play_world_button.disabled = true
