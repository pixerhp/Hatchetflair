extends Node

var INPUTMAP_DEFAULTS: Dictionary[StringName, Array] = get_inputmap_dict(true)

class GameInfo:
	static var NAME: String = ProjectSettings.get_setting("application/config/name")
	const PHASE: String = "pre-alpha"
	static var VERSION: String = ProjectSettings.get_setting("application/config/version", "-1")
		# Ex. stable: model.major.minor.patch ; unstable: ?
	static var IS_MODDED: bool = false
	
	static var FULL_TITLE: String = (
		NAME + ("* " if IS_MODDED else " ") + PHASE + " version " + VERSION
	)

var this_player: PlayerData = PlayerData.new()
class PlayerData:
	var username: String = "" # !!! change standard everywhere in code that no username is "" rather than "guest"
	var displayname: String = "Guest"
	var origin_offset: Vector3i = Vector3i(0, 0, 0)
		# chunk coords offset of your floating point coords in the world. For example, if your 
		# origin offset is 100000 chunks out, then terrain 100000 chunks out will be loaded at 
		# what is internally/functionally (0,0,0).
		# The point of this is to solve not being able to live/be far out due to rounding errors.

# !!! the below are not yet used, but should serve as future reference for stuff that should be.
enum PLAYMODE {
	SPECTATOR,
		# Spectate the world passively without colliding or interacting with it.
	SURVIVOR, 
		# Live vulnerably in the world as a player character.
	BUILDER, 
		# Build, destroy, and terraform anything easily with unlimited resources and ability.
		# Has catalog access, invulnerability, flying, toggleable collision, associated commands access, etc.
	DESIGNER, 
		# More powerful than builder mode, specialized for creating datapacks/mods that alter game content.
		# Create/modify/remove substances/etc, entities and behaviors, etc.
	DIRECTOR,
		# Like builder mode, but specialized for creating photo/video renders, inspired by gmod animations.
		# Entities and objects can told exactly what to do/say as actors of an animation script.
}
var my_playmode = PLAYMODE.SPECTATOR

var draw_debug_info_text: bool = true
var draw_debug_chunk_borders: bool = false


## ----------------------------------------------------------------

func _enter_tree() -> void:
	randomize()
	FileManager.ensure_required_dirs()
	FileManager.ensure_required_files()
	initialize_account()
	return

func _ready() -> void:
	refresh_window_title(true)
	return

func _process(_delta):
	# Process inputs that should work globally.
	if Input.is_action_just_pressed("fullscreen_toggle"):
		if (DisplayServer.window_get_mode() == 0):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if Input.is_action_just_pressed("spec_screenshot"):
		print("(Screenshotting is not yet implemented.)")
	if Input.is_action_just_pressed("console_log"):
		print("(Toggling opening/viewing the game's console/log output is not yet implemented.)")

func quit_game() -> void:
	get_tree().quit() 
	return

## ----------------------------------------------------------------

func initialize_account():
	# !!! change type to Dictionary[String, Dictionary] after creating and using FM cfg funcs.
	var accounts: Dictionary = FileManager.read_cfg(
		FM.PATH.USER.ACCOUNTS, ["meta"])
	var last_selected_username: String = FileManager.read_cfg_keyval(
		FM.PATH.USER.ACCOUNTS, "meta", "last_selected_account_username", "")
	if accounts.has(last_selected_username):
		this_player.username = last_selected_username
		this_player.displayname = accounts[last_selected_username].get("displayname", "David")
	else:
		this_player.username = ""
		this_player.displayname = "Guest"
	return

func refresh_window_title(include_rand_splash: bool):
	DisplayServer.window_set_title(
		GameInfo.FULL_TITLE + 
		(("    ~    " + random_splashtext()) if include_rand_splash else (""))
	)

func random_splashtext() -> String:
	var splashes: PackedStringArray = FM.read_txt_as_commented_lines(
		FM.PATH.RES.SPLASHES, 
		PackedStringArray(["#", "\t"]), 
		true,
	)
	if splashes.size() == 0:
		push_warning("No splash texts.")
		return "Splashless?"
	return splashes[randi_range(0, splashes.size() - 1)]

func get_inputmap_dict(include_not_hf_unique: bool) -> Dictionary[StringName, Array]: 
	var dict: Dictionary[StringName, Array]
	if include_not_hf_unique:
		for action in InputMap.get_actions():
			dict[action] = InputMap.action_get_events(action)
	else:
		for action in InputMap.get_actions():
			if not action.begins_with("ui_"):
				dict[action] = InputMap.action_get_events(action)
	return dict

## ----------------------------------------------------------------

# !!! revise or disimplement these later.
func normalize_name(name_str: String, default: String) -> String:
	name_str = name_str.replace("\n", "")
	name_str = name_str.replace("\r", "")
	name_str = name_str.replace("\t", "")
	if name_str.is_empty():
		name_str = default
	return name_str
func normalize_ip(ip: String) -> String:
	ip = ip.replace("\n", "")
	ip = ip.replace("\r", "")
	ip = ip.replace("\t", "")
	return ip

func normalize_username(string: String) -> String:
	var regex = RegEx.new()
	if regex.compile("[\\w\\d]+") != OK:
		push_error("Invalid RegEx pattern.")
		return ""
	var result = ""
	for part in regex.search_all(string.to_lower().replace(" ", "_")):
		result += part.get_string()
	return result

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

# Used to swap between the (x,y,z) and (h,z₁,z₂) coordinate systems. (Notably flips handedness.)
func swap_xyz_hzz_i(coords: Vector3i) -> Vector3i:
	return Vector3i(coords[1], coords[0], -coords[2])
func swap_xyz_hzz_f(coords: Vector3) -> Vector3:
	return Vector3(coords[1], coords[0], -coords[2])

# Like Dictionary get(), but for a value in a dictionary in a dictionary in a ...
func dict_get_recursive(dict: Dictionary, keys: Array, default: Variant) -> Variant:
	if keys.size() == 0:
		return default
	var subdir: Dictionary = dict
	for i in keys.size():
		if i >= (keys.size() - 1):
			return subdir.get(keys[i], default)
		if not subdir.has(keys[i]):
			return default
		if not typeof(subdir[keys[i]]) == TYPE_DICTIONARY:
			return default
		subdir = subdir[keys[i]]
	return default # (This is logically impossible to get to, but Godot wants me to add it.)

# Directly sorts the original array that's passed in.
func sort_alphabetically(arr: Array, ascending: bool = true) -> void:
	if ascending:
		arr.sort_custom(func(a, b) -> bool: return a.naturalnocasecmp_to(b) < 0)
	else:
		arr.sort_custom(func(a, b) -> bool: return a.naturalnocasecmp_to(b) > 0)
	return
