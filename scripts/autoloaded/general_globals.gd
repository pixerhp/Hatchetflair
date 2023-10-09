extends Node

#-=-=-=-# TABLE OF CONTENTS:

# [contents]:
# ~ global constants
# ~ initialization
# ~ basic functionality
# ~ hotkeys
# ~ convenience functions


#-=-=-=-# GLOBAL CONSTANTS:

const GAME_NAME: String = "Hatchetflair"
const GAME_PHASE: String = "pre-alpha"
const V_MODEL: String = "1"
const V_MAJOR: String = "1"
const V_MINOR: String = "0"
const V_PATCH: String = "0"
const V_ENTIRE: String = V_MODEL + "." + V_MAJOR + "." + V_MINOR + "." + V_PATCH
var TITLE_ENTIRE: String = ""

const IS_MODDED: bool = false
const IS_INDEV: bool = true

# !!! replace with a signal/coroutine and places having the "await" keyword?
var globals_ready: bool = false

#-=-=-=-# INITIALIZATION:

func _enter_tree() -> void:
	randomize() # Randomizes global rng.
	_initialize_title_entire()
	_set_window_title()
	FileManager.ensure_required_dirs()
	FileManager.ensure_required_files()
	
	
	
	
#	# TEMPORARY CODE FOR TESTING OUTPUT
#	var rhombdo_table_indices: Array[PackedByteArray] = ChunkUtilities.gen_unit_rhombdo_indices_table()
#	FileManager.write_file_apba("user://rhombdo_apba_test.apba", rhombdo_table_indices, true)
#	FileManager.write_file_var("user://rhombdo_store_var_test.data", rhombdo_table_indices, true)
#	var text_lines: PackedStringArray = []
#	for indices in rhombdo_table_indices:
#		text_lines.append(str(indices))
#	FileManager.write_file_lines("user://rhombdo_text_text.txt", text_lines)
	
	
	
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


#-=-=-=-# BASIC FUNCTIONALITY:

# Closes the game's program & window.
func quit_game() -> void:
	get_tree().quit()  


#-=-=-=-# HOTKEYS:

func _process(_delta):
	# Global hotkeys.
	if Input.is_action_just_pressed("Fullscreen Toggle"):
		if (DisplayServer.window_get_mode() == 0):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


#-=-=-=-# CONVENIENCE FUNCTIONS:

func rand_int() -> int:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.randomize()
	return(random.randi() - 4294967296 + random.randi())

func normalize_name(name_str: String, default: String) -> String:
	name_str = name_str.replace("\n", "")
	name_str = name_str.replace("\r", "")
	name_str = name_str.replace("\t", "")
	if name_str.is_empty():
		name_str = default
	return name_str
func normalize_seed(seed_str: String) -> String:
	seed_str = seed_str.replace("\n", "")
	seed_str = seed_str.replace("\r", "")
	seed_str = seed_str.replace("\t", "")
	if seed_str.is_empty():
		seed_str = str(rand_int())
	else:
		seed_str = str(int(seed_str))
	return seed_str
func normalize_ip(ip: String) -> String:
	ip = ip.replace("\n", "")
	ip = ip.replace("\r", "")
	ip = ip.replace("\t", "")
	return ip

# Used to swap between the xyz and hx1x2 coordinate systems.
func swap_xyz_hxx_i(coords: Vector3i) -> Vector3i:
	return Vector3i(coords[1], coords[0], coords[2])
func swap_xyz_hxx_f(coords: Vector3) -> Vector3:
	return Vector3(coords[1], coords[0], coords[2])

# Allows you to get a value from a dictionary even if you're not sure its key exists,
# including easily getting something like dict[key1][key2][key3] without having to manually use .has() repeatedly.
# If the value is not found, it returns the default value.
func dict_safeget(dict: Dictionary, keys: Array, default: Variant) -> Variant:
	var subdict: Dictionary = dict
	for key in keys:
		if subdict.has(key):
			if typeof(subdict[key]) == TYPE_DICTIONARY:
				subdict = subdict[key]
			else:
				return subdict[key]
		else:
			return default
	return subdict

# Because arrays are passed in by reference, it directly sorts the original array, no return required.
func sort_alphabetically(arr: Array, ascending: bool = true) -> void:
	if ascending:
		arr.sort_custom(func(a, b) -> bool: return a.naturalnocasecmp_to(b) < 0)
	else:
		arr.sort_custom(func(a, b) -> bool: return a.naturalnocasecmp_to(b) > 0)
	return


#-=-=-=-# <~
