extends Control

var worlds = ["bojler", "eladó"]
@onready var worlds_text = get_node("WorldSelect/Worlds")
@onready var new_world = get_node("WorldSelect/Buttons/NewWorld")
@onready var new_world_popup = get_node("NewWorldPopup")

# Called when the node enters the scene tree for the first time.
func _ready():
	new_world.pressed.connect(self.open_make_world_popup)
	new_world_popup.get_node("Okay").pressed.connect(self.confirm_make_world)
	new_world_popup.get_node("Cancel").pressed.connect(new_world_popup.hide)
	update_worlds_list()

# Open the new world popup.
func open_make_world_popup():
	new_world_popup.get_node("TextEdit").clear()
	new_world_popup.show()

# Actually add the world to the internal array and hide the make world popup.
func confirm_make_world():
	worlds.append(new_world_popup.get_node("TextEdit").text)
	update_worlds_list()
	new_world_popup.hide()

# Update the visible list for the player.
func update_worlds_list():
	worlds_text.clear()
	for world in worlds:
		worlds_text.add_item(world)
