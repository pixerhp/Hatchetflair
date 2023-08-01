extends Control

@onready var add_server_button: Button = $JoinScreenUI/ServerButtons/AddServer
@onready var remove_server_button: Button = $JoinScreenUI/ServerButtons/RemoveServer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


# Attempts to join the selected server.
func join_server():
	# UPDATE THIS TO WORK WITH THE SELECTED SERVER IP LATER.
	NetworkManager.start_game(true, false, true, "127.0.0.1")
	pass
