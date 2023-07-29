extends Control

@onready var allow_multiplayer_joining_toggle: CheckButton = $WorldsScreenUI/Toggles/AllowJoining
@onready var host_without_playing_toggle: CheckButton = $WorldsScreenUI/Toggles/HostWithoutPlay

var worlds_list = ["bojler", "eladó"]
@onready var worlds_text = get_node("WorldsScreenUI/Worlds")
@onready var new_world = get_node("WorldsScreenUI/WorldButtons/NewWorld")
@onready var new_world_popup = get_node("NewWorldPopup")

# Called when the node enters the scene tree for the first time.
func _ready():
	new_world.pressed.connect(self.open_new_world_popup)
	new_world_popup.get_node("Okay").pressed.connect(self.confirm_new_world)
	new_world_popup.get_node("Cancel").pressed.connect(new_world_popup.hide)
	update_worlds_list()

# Disables the host_without_playing_toggle if multiplaer joining is turned off.
func toggle_multiplayer_joining(button_value: bool) -> void:
	host_without_playing_toggle.disabled = not button_value
	if not button_value:
		host_without_playing_toggle.button_pressed = false

# Open the new world popup.
func open_new_world_popup():
	new_world_popup.get_node("TextEdit").clear()
	new_world_popup.show()

# Actually add the world to the internal array and hide the new world popup.
func confirm_new_world():
	worlds_list.append(new_world_popup.get_node("TextEdit").text)
	update_worlds_list()
	new_world_popup.hide()

func delete_world():
	worlds_list.pop_back()
	update_worlds_list()

# Update the visible list for the player.
func update_worlds_list():
	worlds_text.clear()
	for world in worlds_list:
		worlds_text.add_item(world)
