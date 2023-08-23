extends Node

const game_name: String = "Hatchetflair"
const game_version_phase: String = "pre-game"
const game_version_engine: String = "1"
const game_version_major: String = "8"
const game_version_minor: String = "0"
const game_version_entire: String = game_version_phase + " v" + game_version_engine + "." + game_version_major + "." + game_version_minor
var all_global_stuff_initialized: bool = false


func _enter_tree() -> void:
	randomize() # Randomizes the global rng as it's a good place to do it.
	setup_game_window_title()
	if FileManager.ensure_essential_game_dirs_and_files_exist():
		push_error("GlobalStuff encountered error(s) while attempting to ensure some or all essential dirs/files.")
		get_tree().quit()
	
	all_global_stuff_initialized = true


func setup_game_window_title(attempt_to_include_a_splash_text: bool = true):
	DisplayServer.window_set_title(game_name+"   "+game_version_entire)
	if attempt_to_include_a_splash_text == false:
		return
	
	# Get the contents of the splash texts txtfile.
	var splashes_file_contents: Array[String] = FileManager.read_txtfile_lines_as_array("res://assets/text_files/window_splash_texts.txt")
	if splashes_file_contents == []:
		push_warning("Either an issue accessing the splash_texts file occured, or the file was completely empty. (Leaving window title splashless.)")
		return
	
	# Usable splashes don't include the lines from the txtfile that are blank or start with an indent.
	var splashes: Array[String] = []
	for line in splashes_file_contents:
		if (line != "") and (not line.begins_with("\t")):
			splashes.append(line)
	
	if splashes.is_empty():
		push_warning("The window splashes txtfile was accessed successfully, but contained no usable splashes. (Leaving window title splashless.)")
		return
	else:
		DisplayServer.window_set_title(game_name+"   "+game_version_entire+"   ---   "+splashes.pick_random())
		return


func _process(_delta):
	# Global hotkeys.
	if Input.is_action_just_pressed("Fullscreen Toggle"):
		if (DisplayServer.window_get_mode() == 0):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if Input.is_action_just_pressed("Screenshot"):
		pass
