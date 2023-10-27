extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("Pause Menu"):
		var pause_menu_node: Node = $PauseMenu
		if pause_menu_node.visible:
			pause_menu_node.visible = false
		else:
			pause_menu_node.visible = true
