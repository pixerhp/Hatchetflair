extends Node

var draw_debug_chunkborders: bool = true

func _ready():
	_initialize_window_title()
	var wcm: WorldChunksManager = WorldChunksManager.new()
	wcm.test_function()

func _initialize_window_title():
	await get_tree().process_frame
	DisplayServer.window_set_title(
		ProjectSettings.get_setting("application/config/name")#.to_upper()
		+ " v" + ProjectSettings.get_setting("application/config/version")
		+ (" (indev)" if OS.is_debug_build() else "")
	)

var _pre_fullscreen_window_mode: int = ProjectSettings.get_setting("display/window/size/mode")
func _process(_delta):
	# Inputs processed regardless of game state:
	if Input.is_action_just_pressed("escape"):
		get_tree().quit()
	if Input.is_action_just_pressed("fullscreen_toggle"):
		if not DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			_pre_fullscreen_window_mode = DisplayServer.window_get_mode()
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			if _pre_fullscreen_window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
				_pre_fullscreen_window_mode = DisplayServer.WINDOW_MODE_WINDOWED
			DisplayServer.window_set_mode(_pre_fullscreen_window_mode)
	# !!! Can later implement Screenshot, toggle Console window, etc...

func byte_as_string(num: int) -> String:
	return ("%08s" % String.num_int64(num, 2)).replace(" ", "0")
