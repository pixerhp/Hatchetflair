extends Node

var draw_debug_chunkborders: bool = true

func byte_as_string(num: int) -> String:
	return ("%08s" % String.num_int64(num, 2)).replace(" ", "0")

func _process(_delta):
	# Process inputs that should work regardless of game state:
	if Input.is_action_just_pressed("escape"):
		get_tree().quit()
	if Input.is_action_just_pressed("fullscreen_toggle"):
		if not DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	# !!! Can later implement Screenshot, toggle Console window, etc...


func _ready():
	var test: ExampleClass = ExampleClass.new()
	test.print_type("wowza")
