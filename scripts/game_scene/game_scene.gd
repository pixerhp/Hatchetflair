extends Node3D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Toggle the pause menu if its associated key is pressed.
	# !!! [in the future, esc should also be able to close out of other things WITHOUT opening this menu.]
	if Input.is_action_just_pressed("Pause Menu"):
		$PauseMenu.visible = not $PauseMenu.visible
