extends Node


# Called every frame.
func _process(_delta):
	if Input.is_action_just_pressed("Fullscreen Toggle") :
		if (DisplayServer.window_get_mode() == 0):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
