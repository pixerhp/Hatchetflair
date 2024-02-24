extends Node

# !!! the game menu appearing to the player before global preparations may be a problem in the future,
# consider preventing that later with singals or the await keyword.

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

var INPUTMAP_DEFAULTS: Dictionary = {}

var player_username: String = "guest"
var player_displayname: String = "Guest"


#-=-=-=-# INITIALIZATION:

func _enter_tree() -> void:
	randomize() # Randomizes global rng.
	FileManager.ensure_required_dirs()
	FileManager.ensure_required_files()
	_initialize_title_entire()
	_set_window_title()
	_initialize_inputmap_defaults()
	
	
	
	
	# TEMPORARY TESTING 2!
	# !!! (add polyhedron faces to the function input)
	ChunkUtils.get_marched_polyhedron_tri_indices_table(
		ChunkUtils.unit_cube.verts, 
		ChunkUtils.unit_cube.edges, 
		ChunkUtils.unit_cube.faces, 
		true)
	
	print()
	print()
	print()
	
	var a: PackedByteArray = [1,5]
	var b: PackedByteArray = [4,6]
	var c: PackedByteArray = [4,6]
	print(a, " duplicated is: ", a.duplicate())
	print(b, " duplicated is: ", b.duplicate())
	print(c, " duplicated is: ", c.duplicate())
	print("does ", a, " equal ", b, "?: ", (a==b))
	print("does ", a, " equal ", c, "?: ", (a==c))
	print("does ", b, " equal ", c, "?: ", (b==c))
	
	
#	# TEMPORARY CODE FOR TESTING OUTPUT
#	var rhombdo_table_indices: Array[PackedByteArray] = ChunkUtilities.gen_unit_rhombdo_indices_table()
#	FileManager.write_file_apba("user://rhombdo_apba_test.apba", rhombdo_table_indices, true)
#	FileManager.write_file_var("user://rhombdo_store_var_test.data", rhombdo_table_indices, true)
#	var text_lines: PackedStringArray = []
#	for indices in rhombdo_table_indices:
#		text_lines.append(str(indices))
#	FileManager.write_file_lines("user://rhombdo_text_text.txt", text_lines)
	
	
	
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

func _initialize_inputmap_defaults():
	INPUTMAP_DEFAULTS.clear()
	for action in InputMap.get_actions():
		INPUTMAP_DEFAULTS[action] = InputMap.action_get_events(action)
	return

#-=-=-=-# BASIC FUNCTIONALITY:

# Closes the game's program & window.
func quit_game() -> void:
	get_tree().quit()  


#-=-=-=-# HOTKEYS:

func _process(_delta):
	# Global hotkeys.
	if Input.is_action_just_pressed("game_special_fullscreen_toggle"):
		if (DisplayServer.window_get_mode() == 0):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


#-=-=-=-# CONVENIENCE FUNCTIONS:

func random_int() -> int:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	return(rng.randi() - 4294967296 + rng.randi())

# Takes in an equally distributed random value between 0 (inclusive) and 1 (exclusive).
# An output 1 larger than another is `r` times rarer than another.
# ((rate - 1) / rate) is the probability that the output will lie between 0 and 1.
func prob_to_raritytier_val(rate: float, prob: float) -> float:
	return -1 * (log(1 - prob) / log(rate))
func random_raritytier_val(rate: float) -> float:
	randomize()
	var rng_float: float = 1
	while rng_float == 1:
		rng_float = randf()
	return prob_to_raritytier_val(rate, rng_float)
func prob_to_raritytier_val_natural(prob: float) -> float:
	return -1 * log(1 - prob)
func random_raritytier_val_natural() -> float:
	randomize()
	var rng_float: float = 1
	while rng_float == 1:
		rng_float = randf()
	return prob_to_raritytier_val_natural(rng_float)
# Combines raritytier values together into a larger one.
# For example, if the rate is 3, combining 3 of the same value together outputs said value + 1.
func raritytier_val_combine(rate: float, values: Array[float]) -> float:
	if values.size() == 0:
		return 0
	var combined_pows: float = 0 
	for val in values:
		combined_pows += pow(rate, val)
	return log(combined_pows)/log(rate)
func raritytier_val_combine_natural(values: Array[float]) -> float:
	if values.size() == 0:
		return 0
	var combined_pows: float = 0 
	for val in values:
		combined_pows += exp(val)
	return log(combined_pows)

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
		seed_str = str(random_int())
	else:
		seed_str = str(int(seed_str))
	return seed_str
func normalize_ip(ip: String) -> String:
	ip = ip.replace("\n", "")
	ip = ip.replace("\r", "")
	ip = ip.replace("\t", "")
	return ip

func normalize_username_str(string: String) -> String:
	var semi_formatted_str: String = string.to_lower().replace(" ", "_")
	var regex = RegEx.new() # RegEx is used for the removal of all unwanted characters.
	if regex.compile("[\\w\\d]+") != OK:
		push_error("RegEx invalid pattern.")
		return ""
	var formatted_str = ""
	for acceptable_segment in regex.search_all(semi_formatted_str):
		formatted_str += acceptable_segment.get_string()
	return formatted_str

# Used to swap between the zyx and hz1z2 coordinate systems.
func swap_zyx_hzz_i(coords: Vector3i) -> Vector3i:
	return Vector3i(coords[1], coords[0], coords[2])
func swap_zyx_hzz_f(coords: Vector3) -> Vector3:
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
