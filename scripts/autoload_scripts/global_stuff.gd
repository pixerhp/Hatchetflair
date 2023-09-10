extends Node

const GAME_NAME: String = "Hatchetflair"
const V_ENGINE: String = "1"
const V_MAJOR: String = "0"
const V_MINOR: String = "9"
const V_PATCH: String = "0"
const V_COUNT: String = "9" # n, where the current version is the nth version to exist.
const V_ENTIRE: String = V_ENGINE + "_" + V_MAJOR + "_" + V_MINOR + "_" + V_PATCH + "_" + V_COUNT
var TITLE_ENTIRE: String = ""

# Alter the game's title.
const IS_MODDED: bool = false
const IS_INDEV: bool = true

var globals_ready: bool = false

# =-= =-= =-= =-= =-= =-= =-= <~

func _enter_tree() -> void:
	randomize() # Randomizes the global rng as it's a good place to do it.
	_initialize_title_entire()
	_set_window_title()
	
#	if FileManager.ensure_essential_game_dirs_and_files_exist() == FAILED:
#		push_error("GlobalStuff encountered error(s) while attempting to ensure some or all essential dirs/files.")
#		get_tree().quit()
#	if VersionManager.ensure_cv_essential_files():
#		push_error("Ensuring that the game's essential files are (or transversioned to) the correct version failed, this may lead to crashes or other unintended behavior.
#		If you decide to play anyways, you should create a personal backup of your worlds and any other files you care about first.")
	
	globals_ready = true


func _initialize_title_entire() -> void:
	var name_exts: String = ""
	if IS_MODDED:
		name_exts += "*"
	var v_exts: String = ""
	if IS_INDEV:
		v_exts += " [INDEV]"
	TITLE_ENTIRE = (
		GAME_NAME + name_exts + " v" + V_ENGINE + "." + V_MAJOR + "." + V_MINOR + "." + V_PATCH + v_exts
	)
	return

func _set_window_title(include_splash: bool = true) -> Error:
	if not include_splash:
		DisplayServer.window_set_title(TITLE_ENTIRE)
		return OK
	
	var splashes_file_lines: PackedStringArray = FileManager.read_file_lines(FileManager.PATH_SPLASHES)
	var usable_splashes: Array = []
	# Resize the usable splashes array so that it's not resized repeatedly for each splash added.
	# Since we don't know the number of usable splashes yet, we make it the same size for now and remove the excess later.
	usable_splashes.resize(splashes_file_lines.size())
	# Determine which lines from the array are usable splashes (not a comment, or blank line, etc.)
	var index: int = 0
	for item in splashes_file_lines:
		if (item != "") and (not item.begins_with('#')) and (not item.begins_with("\t")) and (not item.begins_with(" ")):
			usable_splashes[index] = item
			index += 1
	# Resize the array to snuggly fit just the elements we wanted.
	if usable_splashes.find(null) != -1:
		usable_splashes.resize(usable_splashes.find(null))
	
	if usable_splashes.is_empty():
		push_warning("No usable splash texts. (Leaving window-title splashless.)")
		DisplayServer.window_set_title(TITLE_ENTIRE)
		return OK
	else:
		DisplayServer.window_set_title(TITLE_ENTIRE + "   ~   " + usable_splashes.pick_random())
		return OK

func _process(_delta):
	# Global hotkeys.
	if Input.is_action_just_pressed("Fullscreen Toggle"):
		if (DisplayServer.window_get_mode() == 0):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if Input.is_action_just_pressed("Screenshot"):
		pass

# Closes the game's program & window.
func quit_game() -> void:
	get_tree().quit()  


func get_rand() -> int:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.randomize()
	return(random.randi() - 4294967296 + random.randi())
