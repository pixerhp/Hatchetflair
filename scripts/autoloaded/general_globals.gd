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
const V_MODEL: String = "1" # (the engine/recoding attempt at making the whole game.)
const V_MAJOR: String = "1" # (big content milestones, resets minor number.)
const V_MINOR: String = "1" # (regular content updates, resets patch number.)
const V_PATCH: String = "0" # (simple bug-fixing/patches.)

const V_ENTIRE: String = V_MODEL + "." + V_MAJOR + "." + V_MINOR + "." + V_PATCH
var TITLE_ENTIRE: String = ""

const IS_MODDED: bool = false
const IS_VERSION_INDEV: bool = true 
	# set to true while this version is being developed, 
	# then set to false once you're finished BEFORE RELEASING IT.

var INPUTMAP_DEFAULTS: Dictionary = {}

var player_username: String = "guest"
var player_displayname: String = "Guest"

# the player's world floating point origin is functionally offset my this value in chunk coordinates.
# if the player is a billion chunks out, but their offset is also at the same place,
# then everything around them should move smoothly like as if they were around (0,0,0).
# it probably can't be set/changed willy-nilly, but instead have everything systematically update properly
# so it will probably only be changed on world load/quit, maybe sleeping or dying, a command, etc.
# "my" because each player's in multiplayer is unique.
var my_origin_offset: Vector3i = Vector3i(0, 0, 0)

# !!! the below are not currently used, but should serve as future reference for stuff that should be.
enum playmode {
	SPECTATOR, # Spectate the world and its happenigs without colliding or interacting with it.
	SURVIVOR, # Live in the world, controlling a player character.
	BUILDER, # Build/destroy anything with conveniences like invincibility, flying, the catalog, commands, etc.
	DESIGNER, # A more advanced builder mode, design the world; add/remove custom content like entities and items.
}
var player_playmode = playmode.SPECTATOR

var draw_debug_info_text: bool = true
var draw_debug_chunk_borders: bool = false


#-=-=-=-# INITIALIZATION:

func _enter_tree() -> void:
	randomize() # Randomizes global rng.
	FileManager.ensure_required_dirs()
	FileManager.ensure_required_files()
	_initialize_title_entire()
	_refresh_window_title()
	_initialize_inputmap_defaults()
	
	
	
	## TEMPORARY TESTING 2!
	## !!! (access edges and faces differently once that godot bug is fixed.)
	#ChunkUtils.get_marched_polyhedron_tri_indices_table(
		#ChunkUtils.unit_cube.verts, 
		#ChunkUtils.unit_cube.new().edges, 
		#ChunkUtils.unit_cube.new().faces, 
		#0)
	
	
	
#	# TEMPORARY CODE FOR TESTING OUTPUT (1st marching rhombdo attempt)
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
	if IS_VERSION_INDEV:
		v_exts += " [v_indev]"
	# Includes phase in the title only if it doesn't indicate completion.
	if (GAME_PHASE != "release") and (GAME_PHASE != "gold") and (GAME_PHASE != "rose-gold"):
		TITLE_ENTIRE = (
			GAME_NAME + name_exts + " " + GAME_PHASE + " v" + V_MODEL + "." + V_MAJOR + "." + V_MINOR + "." + V_PATCH + v_exts
		)
	else:
		TITLE_ENTIRE = (
			GAME_NAME + name_exts + " v" + V_MODEL + "." + V_MAJOR + "." + V_MINOR + "." + V_PATCH + v_exts
		)
	return

func _refresh_window_title(include_random_splash: bool = true):
	if include_random_splash:
		var splash: String = get_random_splash()
		if splash.length() == 0:
			DisplayServer.window_set_title(TITLE_ENTIRE)
			return
		else:
			DisplayServer.window_set_title(TITLE_ENTIRE + "   ~   " + splash)
			return
	else:
		DisplayServer.window_set_title(TITLE_ENTIRE)
		return

func get_random_splash() -> String:
	var splashes: PackedStringArray = FileManager.read_file_commented_lines(FileManager.PATH_SPLASHES, ["#", "\t"], true)
	if splashes.size() > 0:
		return splashes[randi_range(0, splashes.size() - 1)]
	else:
		push_warning("No splash texts found when asked to provide a random splash.")
		return ""

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

func get_coords3d_string(coords: Vector3, length_after_period: int) -> String:
	var finalized_string: String = ""
	var stringified_component: String = ""
	var period_index: int = 0
	if length_after_period < -1:
		length_after_period = -1
	for component in [coords.x, coords.y, coords.z]:
		stringified_component = str(component)
		period_index = stringified_component.find(".")
		if not finalized_string.is_empty():
			finalized_string += ", "
		if (length_after_period != -1) and (period_index == -1):
			finalized_string += stringified_component + "." + "0".repeat(length_after_period)
		else:
			finalized_string += stringified_component.substr(0, period_index + length_after_period + 1)
	return finalized_string

# Used to swap between the zyx and hz1z2 coordinate systems (also flips handedness.)
func swap_zyx_hzz_i(coords: Vector3i) -> Vector3i:
	return Vector3i(coords[1], coords[0], -coords[2])
func swap_zyx_hzz_f(coords: Vector3) -> Vector3:
	return Vector3(coords[1], coords[0], -coords[2])

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
