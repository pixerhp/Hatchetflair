extends Node

var all_global_stuff_initialized: bool = false
var is_modded: bool = false # "true" currently only adds a `*` to the end of the games name in the window title.
const game_name: String = "Hatchetflair"
const game_version_phase: String = "pre-game"
const game_version_engine: String = "1"
const game_version_major: String = "8"
const game_version_minor: String = "0"
const game_version_entire: String = game_version_phase + " v" + game_version_engine + "." + game_version_major + "." + game_version_minor

# Useful for getting and using certain parts of a version_entire from a file/other.
func unconcat_ver_entire(version_entire: String) -> Array[String]:
	# No need to do anything if the input is blank.
	if version_entire == "":
		return([])
	
	var version_components: Array[String] = []
	var remaining_version_string: String = version_entire
	
	# Get the phase and then remove it (and also " v") from what's left to search through.
	version_components.append(remaining_version_string.substr(0, remaining_version_string.find(" ")))
	remaining_version_string = remaining_version_string.erase(0, remaining_version_string.find(" ") + 2)
	
	# Get every number preceeded by a period, and then the remaining string if there's anything past the last period.
	while remaining_version_string.find(".") != -1:
		version_components.append(remaining_version_string.substr(0, remaining_version_string.find(".")))
		remaining_version_string = remaining_version_string.erase(0, remaining_version_string.find(".") + 1)
	if remaining_version_string != "":
		version_components.append(remaining_version_string)
	
	return(version_components)


func _enter_tree() -> void:
	randomize() # Randomizes the global rng as it's a good place to do it.
	setup_game_window_title()
	if FileManager.ensure_essential_game_dirs_and_files_exist():
		push_error("GlobalStuff encountered error(s) while attempting to ensure some or all essential dirs/files.")
		get_tree().quit()
	
	if VersionManager.ensure_cv_essential_files():
		push_error("Ensuring that the game's essential files are (or transversioned to) the correct version failed, this may lead to crashes or other unintended behavior.
		If you decide to play anyways, you should create a personal backup of your worlds and any other files you care about first.")
	
	all_global_stuff_initialized = true


func setup_game_window_title(include_a_splashtext: bool = true):
	if is_modded:
		DisplayServer.window_set_title(game_name + "*   " + game_version_entire)
	else:
		DisplayServer.window_set_title(game_name + "   " + game_version_entire)
	if include_a_splashtext == false:
		return
	
	# Get the contents of the splash texts txtfile and exclude all lines which are blank or start with a tab indent.
	var splashes_txtfile_contents: Array[String] = FileManager.read_txtfile_lines_as_array("res://assets/text_files/window_splash_texts.txt")
	if splashes_txtfile_contents == []:
		push_warning("Either an issue accessing the splash_texts file occured, or the file was completely empty. (Leaving window title splashless.)")
		return
	var splashes: Array[String] = []
	for line in splashes_txtfile_contents:
		if (line != "") and (not line.begins_with("\t")):
			splashes.append(line)
	
	if splashes.is_empty():
		push_warning("The window splashes txtfile was accessed successfully, but contained no usable splashes. (Leaving window title splashless.)")
		return
	else:
		if is_modded:
			DisplayServer.window_set_title(game_name+"*   "+game_version_entire+"   ---   "+splashes.pick_random())
		else:
			DisplayServer.window_set_title(game_name+"   "+game_version_entire+"   ---   "+splashes.pick_random())
		return

# Closes the game's program & window.
func quit_game() -> void:
	get_tree().quit()  

func random_worldgen_seed() -> int:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.randomize()
	return(random.randi() - 4294967296 + random.randi())


func _process(_delta):
	# Global hotkeys.
	if Input.is_action_just_pressed("Fullscreen Toggle"):
		if (DisplayServer.window_get_mode() == 0):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if Input.is_action_just_pressed("Screenshot"):
		pass
