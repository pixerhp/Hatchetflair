extends Control

@onready var allow_multiplayer_joining_toggle: CheckButton = $WorldsScreenUI/Toggles/AllowJoining
@onready var host_without_playing_toggle: CheckButton = $WorldsScreenUI/Toggles/HostWithoutPlay

var worlds_list = ["bojler", "eladó"]
@onready var worlds_text = get_node("WorldsScreenUI/Worlds")
@onready var new_world_button = get_node("WorldsScreenUI/WorldButtons/NewWorld")
@onready var new_world_popup = get_node("NewWorldPopup")
@onready var delete_world_popup = get_node("DeleteWorldPopup")

# Called when the node enters the scene tree for the first time.
func _ready():
	new_world_button.pressed.connect(self.open_new_world_popup)
	new_world_popup.get_node("Okay").pressed.connect(self.confirm_new_world)
	new_world_popup.get_node("Cancel").pressed.connect(new_world_popup.hide)
	delete_world_popup.get_node("Confirm").pressed.connect(self.confirm_delete_world)
	delete_world_popup.get_node("Cancel").pressed.connect(delete_world_popup.hide)
	update_worlds_list()

# Disables the host_without_playing_toggle if multiplaer joining is turned off.
func toggle_multiplayer_joining(button_value: bool) -> void:
	host_without_playing_toggle.disabled = not button_value
	if not button_value:
		host_without_playing_toggle.button_pressed = false

# Open the new world popup.
func open_new_world_popup():
	delete_world_popup.hide()
	new_world_popup.get_node("TextEdit").clear()
	new_world_popup.show()

# Actually add the world to the internal array and hide the new world popup.
func confirm_new_world():
	worlds_list.append(new_world_popup.get_node("TextEdit").text)
	update_worlds_list()
	new_world_popup.hide()

func open_delete_world_popup():
	new_world_popup.hide()
	if not worlds_text.get_selected_items().is_empty(): # Don't do anything if no worlds are selected.
		delete_world_popup.get_node("RichTextLabel").text = "[center]Are you sure you want to delete \"" + worlds_list[worlds_text.get_selected_items()[0]] +"\"?\n(This action cannot be undone.)[/center]"
		delete_world_popup.show()

func confirm_delete_world():
	if not worlds_text.get_selected_items().is_empty(): # Crash prevention for if no world is selected.
		worlds_list.erase(worlds_list[worlds_text.get_selected_items()[0]])
		delete_world_popup.hide()
	update_worlds_list()

# This is done to prevent changing which item you're deleting after the deletion popup already named a world.
func world_list_item_clicked():
	delete_world_popup.hide()

# Update the visible list for the player.
func update_worlds_list():
	worlds_text.clear()
	for world in worlds_list:
		worlds_text.add_item(world)
