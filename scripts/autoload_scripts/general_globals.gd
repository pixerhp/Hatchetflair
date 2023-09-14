extends Node

const GAME_NAME: String = "Hatchetflair"
const GAME_PHASE: String = "pre-game"
const V_MODEL: String = "1"
const V_MAJOR: String = "0"
const V_MINOR: String = "9"
const V_PATCH: String = "0"
const V_ENTIRE: String = V_MODEL + "." + V_MAJOR + "." + V_MINOR + "." + V_PATCH
var TITLE_ENTIRE: String = ""

# Alter the game's title.
const IS_MODDED: bool = false
const IS_INDEV: bool = true

var globals_ready: bool = false

# =-= =-= =-= =-= =-= =-= =-= # <~

func _enter_tree() -> void:
	randomize() # Randomizes global rng.
	_initialize_title_entire()
	_set_window_title()
	FileManager.ensure_required_dirs()
	FileManager.ensure_required_files()
	
	globals_ready = true
	return


func _initialize_title_entire() -> void:
	var name_exts: String = ""
	if IS_MODDED:
		name_exts += "*"
	var v_exts: String = ""
	if IS_INDEV:
		v_exts += " [INDEV]"
	# Include phase in the title only if the game is not at/past release stage.
	if (GAME_PHASE != "release") and (GAME_PHASE != "gold") and (GAME_PHASE != "rose-gold"):
		TITLE_ENTIRE = (
			GAME_NAME + name_exts + " [" + GAME_PHASE + "] v" + V_MODEL + "." + V_MAJOR + "." + V_MINOR + "." + V_PATCH + v_exts
		)
	else:
		TITLE_ENTIRE = (
			GAME_NAME + name_exts + " v" + V_MODEL + "." + V_MAJOR + "." + V_MINOR + "." + V_PATCH + v_exts
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


func get_rand_int() -> int:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.randomize()
	return(random.randi() - 4294967296 + random.randi())
