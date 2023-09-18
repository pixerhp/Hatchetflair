extends Node

#-=-=-=-# TABLE OF CONTENTS:

# [contents]:
# ~ global constants
# ~ dir & file interactions
# ~ reading & writing
# ~ file organizing
# ~ game-specific


#-=-=-=-# GLOBAL CONSTANTS:

const PATH_ASSETS: String = "res://assets"
const PATH_SPLASHES: String = PATH_ASSETS + "/text_files/splash_texts.txt"

const PATH_STORAGE: String = "user://storage"
const PATH_REMEMBERED_SERVERS: String = PATH_STORAGE + "/remembered_servers.cfg"
const PATH_WORLDS: String = PATH_STORAGE + "/worlds"
const PATH_SCREENSHOTS: String = PATH_STORAGE + "/screenshots"


#-=-=-=-# DIR & FILE INTERACTIONS:

func delete_dir(dir_path: String, to_recycle_bin: bool) -> Error:
	if to_recycle_bin:
		var err: Error = OS.move_to_trash(ProjectSettings.globalize_path(dir_path))
		if err != OK:
			push_error("Failed to move dir into OS trash: ", dir_path, " (Error val:) ", err)
			return err
		return OK
	else:
		delete_dir_contents(dir_path, false)
		var err: Error = DirAccess.remove_absolute(dir_path)
		if err != OK:
			push_error("Failed to remove dir at path: ", dir_path, " (Error val:) ", err)
			return FAILED
		return OK
func delete_dirs(dir_paths: Array[String], to_recycle_bin: bool) -> Error:
	var any_errors_occured: bool = false
	for path in dir_paths:
		if delete_dir(path, to_recycle_bin) != OK:
			any_errors_occured = true
	if any_errors_occured:
		return FAILED
	return OK
func delete_dir_contents(dir_path: String, to_recycle_bin: bool) -> Error:
	var err: Error
	var any_errors_occured: bool = false
	if to_recycle_bin:
		for nested_dir_name in DirAccess.get_directories_at(dir_path):
			err = OS.move_to_trash(ProjectSettings.globalize_path(dir_path))
			if err != OK:
				push_error("Failed to move dir into OS trash: ", dir_path + "/" + nested_dir_name, " (Error val:) ", err)
				any_errors_occured = true
		for file_name in DirAccess.get_files_at(dir_path):
			err = OS.move_to_trash(ProjectSettings.globalize_path(dir_path + "/" + file_name))
			if err != OK:
				push_error("Failed to move file into OS trash: ", dir_path + "/" + file_name, " (Error val:) ", err)
				any_errors_occured = true
		if any_errors_occured:
			return FAILED
		return OK
	else:
		for nested_dir_name in DirAccess.get_directories_at(dir_path):
			if delete_dir(dir_path + "/" + nested_dir_name, false) != OK:
				any_errors_occured = true
		for file_name in DirAccess.get_files_at(dir_path):
			err = DirAccess.remove_absolute(dir_path + "/" + file_name)
			if err != OK:
				push_error("Failed to delete file at path: ", dir_path + "/" + file_name, " (Error val:) ", err)
				any_errors_occured = true
		if any_errors_occured:
			return FAILED
		return OK
func delete_dirs_contents(dir_paths: Array[String], to_recycle_bin: bool) -> Error:
	var any_errors_occured: bool = false
	for path in dir_paths:
		if delete_dir_contents(path, to_recycle_bin) != OK:
			any_errors_occured = true
	if any_errors_occured:
		return FAILED
	return OK

func copy_dir(from_path: String, to_path: String, empty_target: bool) -> Error:
	# Ensure that the "to" file path directory exists.
	if DirAccess.dir_exists_absolute(to_path):
		if empty_target:
			delete_dir_contents(to_path, false)
	else:
		var err: Error = DirAccess.make_dir_recursive_absolute(to_path)
		if err != OK:
			push_error("Failed to create dir at path: ", to_path, " (Error val:) ", err)
			return FAILED
	if copy_dir_contents(from_path, to_path, false) != OK:
		return FAILED
	return OK
func copy_dir_contents(from_path: String, into_path: String, empty_target: bool) -> Error:
	if empty_target:
		delete_dir_contents(into_path, false)
	var err: Error
	var any_errors_occured: bool = false
	for file_name in DirAccess.get_files_at(from_path):
		err = DirAccess.copy_absolute(from_path + "/" + file_name, into_path + "/" + file_name)
		if err != OK:
			push_error("Failed to copy file: ", from_path + "/" + file_name, 
			" to: ", into_path + "/" + file_name, " (Error val:) ", err)
			any_errors_occured = true
	for subdir_name in DirAccess.get_directories_at(from_path):
		if copy_dir(from_path + "/" + subdir_name, into_path + "/" + subdir_name, false) != OK:
			any_errors_occured = true
	if any_errors_occured:
		return FAILED
	return OK

func move_dir(from_path: String, to_path: String, empty_target: bool) -> Error:
	# ! DirAccess.rename_absolute does exist and can move directories if certain conditions are met,
	# so this function may be revised in the future using it. For now though, it doesn't use it because you
	# have to worry about the stuff in the dir before the to_path a lot.
	if copy_dir(from_path, to_path, empty_target) != OK:
		# Abort deleting the original dir if any failures occured copying contents, to avoid permanently losing any data.
		return FAILED
	if delete_dir(from_path, false) != OK:
		return FAILED
	return OK

func get_available_dirname(path_opening: String, dir_name: String, start_with_alt0: bool) -> String:
	var list_of_dir_names: PackedStringArray = DirAccess.get_directories_at(path_opening)
	var alt_num: int = list_of_dir_names.size()
	if start_with_alt0:
		for index in list_of_dir_names.size():
			if not list_of_dir_names.has(dir_name + " alt" + str(index)):
				alt_num = index
				break
	else:
		for index in list_of_dir_names.size():
			if index == 0:
				if not list_of_dir_names.has(dir_name):
					alt_num = index
					break
			else:
				if not list_of_dir_names.has(dir_name + " alt" + str(index)):
					alt_num = index
					break
	if (not start_with_alt0) and (alt_num == 0):
		return dir_name
	else:
		return dir_name + " alt" + str(alt_num)
func get_available_dirpath(dir_path: String, start_with_alt0: bool) -> String:
	var sep_index: int = dir_path.rfind('/')
	var path_opening: String = dir_path.substr(0, sep_index + 1)
	var dir_name: String = dir_path.substr(sep_index + 1)
	return path_opening + get_available_dirname(path_opening, dir_name, start_with_alt0)
func get_available_filename(path_opening: String, file_name: String, start_with_alt0: bool) -> String:
	var list_of_file_names: PackedStringArray = DirAccess.get_files_at(path_opening)
	var period_index: int = file_name.rfind('.')
	var name_without_extension: String = file_name.substr(0, period_index)
	var name_extension: String = file_name.substr(period_index)
	var alt_num: int = list_of_file_names.size()
	if start_with_alt0:
		for index in list_of_file_names.size():
			if not list_of_file_names.has(name_without_extension + " alt" + str(index) + name_extension):
				alt_num = index
				break
	else:
		for index in list_of_file_names.size():
			if index == 0:
				if not list_of_file_names.has(file_name):
					alt_num = index
					break
			else:
				if not list_of_file_names.has(name_without_extension + " alt" + str(index) + name_extension):
					alt_num = index
					break
	if (not start_with_alt0) and (alt_num == 0):
		return file_name
	else:
		return name_without_extension + " alt" + str(alt_num) + name_extension
func get_available_filepath(file_path: String, start_with_alt0: bool) -> String:
	var sep_index: int = file_path.rfind('/')
	var path_opening: String = file_path.substr(0, sep_index + 1)
	var file_name: String = file_path.substr(sep_index + 1)
	return path_opening + get_available_filename(path_opening, file_name, start_with_alt0)

func get_available_dict_key_string(dict: Dictionary, key: String, start_with_alt0: bool) -> String:
	var keys_list: Array[String] = []
	keys_list.assign(dict.keys())
	if start_with_alt0:
		for index in keys_list.size():
			if not keys_list.has(key + " alt" + str(index)):
				return (key + " alt" + str(index))
		return (key + " alt" + str(keys_list.size()))
	else:
		for index in keys_list.size():
			if index == 0:
				if not keys_list.has(key):
					return key
			else:
				if not keys_list.has(key + " alt" + str(index)):
					return(key + " alt" + str(index))
		return (key + " alt" + str(keys_list.size()))


#-=-=-=-# READING & WRITING:

func read_file_lines(file_path: String) -> PackedStringArray:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	var err: Error = FileAccess.get_open_error()
	if err != OK:
		push_error("Failed to open file: ", file_path, " (Error val:) ", err)
		return []
	return file.get_as_text().split("\n", false)
func read_file_first_line(file_path: String) -> String:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	var err: Error = FileAccess.get_open_error()
	if err != OK:
		push_error("Failed to open file: ", file_path, " (Error val:) ", err)
		return ""
	return(file.get_line())

func write_file_from_lines(file_path: String, lines: PackedStringArray) -> Error:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	var err: Error = FileAccess.get_open_error()
	if err != OK:
		push_error("Failed to open file: ", file_path, " (Error val:) ", err)
		return err
	file.store_string("\n".join(lines))
	return OK
func write_file_from_string(file_path: String, text: String) -> Error:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	var err: Error = FileAccess.get_open_error()
	if err != OK:
		push_error("Failed to open file: ", file_path, " (Error val:) ", err)
		return err
	file.store_string(text)
	return OK

func read_cfg(file_path: String, skip_sections: PackedStringArray = []) -> Dictionary:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(file_path)
	if err != OK:
		push_error("Failed to open cfgfile at: ", file_path, " (Error val:) ", err)
		return {}
	var dictionary: Dictionary = {}
	var section_data: Dictionary = {}
	for section in cfg.get_sections():
		if not skip_sections.has(section):
			section_data = {}
			for key in cfg.get_section_keys(section):
				section_data[key] = cfg.get_value(section, key)
			dictionary[section] = section_data
	return dictionary
func read_cfg_keyval(file_path: String, section: String, key: String) -> Variant:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(file_path)
	if err != OK:
		push_error("Failed to open cfgfile at: ", file_path, " (Error val:) ", err)
		return null
	return cfg.get_value(section, key)
func read_cfg_section(file_path: String, section: String) -> Dictionary:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(file_path)
	if err != OK:
		push_error("Failed to open cfgfile at: ", file_path, " (Error val:) ", err)
		return {}
	if not cfg.has_section(section):
		push_warning("Config file at: ", file_path, " did not contain section: ", section)
		return {}
	var section_data: Dictionary = {}
	for key in cfg.get_section_keys(section):
		section_data[key] = cfg.get_value(section, key)
	return section_data
func read_cfg_list_sections(file_path: String) -> PackedStringArray:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(file_path)
	if err != OK:
		push_error("Failed to open cfgfile at: ", file_path, " (Error val:) ", err)
		return []
	return cfg.get_sections()
func read_cfg_section_to_keyval(file_path: String, key: String) -> Dictionary:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(file_path)
	if err != OK:
		push_error("Failed to open cfgfile at: ", file_path, " (Error val:) ", err)
		return {}
	var dictionary: Dictionary = {}
	for section in cfg.get_sections():
		if cfg.has_section_key(section, key):
			dictionary[section] = cfg.get_value(section, key)
	return dictionary
func read_cfg_keyval_to_section(file_path: String, key: String) -> Dictionary:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(file_path)
	if err != OK:
		push_error("Failed to open cfgfile at: ", file_path, " (Error val:) ", err)
		return {}
	var dictionary: Dictionary = {}
	for section in cfg.get_sections():
		if cfg.has_section_key(section, key):
			dictionary[cfg.get_value(section, key)] = section
	return dictionary
func read_cfg_keyval_to_keyval(file_path: String, key1: String, key2: String) -> Dictionary:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(file_path)
	if err != OK:
		push_error("Failed to open cfgfile at: ", file_path, " (Error val:) ", err)
		return {}
	var dictionary: Dictionary = {}
	for section in cfg.get_sections():
		if cfg.has_section_key(section, key1) and cfg.has_section_key(section, key2):
			dictionary[cfg.get_value(section, key1)] = cfg.get_value(section, key2)
	return dictionary

func write_cfg(file_path: String, dict: Dictionary) -> Error:
	var cfg: ConfigFile = ConfigFile.new()
	var any_errors_encountered: bool = false
	
	for section in dict.keys():
		if typeof(dict[section]) == TYPE_DICTIONARY:
			for key in dict[section].keys():
				cfg.set_value(section, key, dict[section][key])
		else:
			push_error("Dictionary key ", section, " did not have a dictionary as its value.")
			any_errors_encountered = true
	
	var err: Error = cfg.save(file_path)
	if err != OK:
		push_error("Failed to save cfgfile to ", file_path, " (Error val:) ", err)
		any_errors_encountered = true
	if any_errors_encountered:
		return FAILED
	return OK
func write_cfg_keyval(file_path: String, section: String, key: String, value: Variant) -> Error:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(file_path)
	if err != OK:
		push_error("Failed to open cfgfile at: ", file_path, " (Error val:) ", err)
		return err
	cfg.set_value(section, key, value)
	err = cfg.save(file_path)
	if err != OK:
		push_error("Failed to save cfgfile to ", file_path, " (Error val:) ", err)
		return(err)
	return OK


#-=-=-=-# FILE ORGANIZING:

func sort_file_lines_alphabetically(file_path: String, skip: int = 0, ascending: bool = true) -> Error:
	# Note: Would be a PackedStringArray, but as of typing it doesn't support direct custom sorts.
	var lines: Array[String] = []
	lines.assign(read_file_lines(file_path))
	if lines.is_empty():
		push_warning("File contained no lines to sort.")
		return OK # Returning OK because this could be a normal situation.
	var skipped: Array[String] = lines.slice(0, skip)
	var to_sort: Array[String] = lines.slice(skip)
	if ascending:
		to_sort.sort_custom(func(a, b) -> bool: return a.naturalnocasecmp_to(b) < 0)
	else:
		to_sort.sort_custom(func(a, b) -> bool: return a.naturalnocasecmp_to(b) > 0)
	if write_file_from_lines(file_path, skipped + to_sort) != OK:
		return FAILED
	return OK
# Possible future/alt stuff: 2 bools/funcs, one for whether groups should be sorted against eachother using first item,
# & one for whether items within a group should be sorted.
func sort_file_line_groups_alphabetically(file_path: String, group_size: int, skip: int, ascending: bool = true) -> Error:
	if group_size < 1:
			group_size = 1
	if group_size == 1:
		sort_file_lines_alphabetically(file_path, skip, ascending)
	# Note: Would be a PackedStringArray, but as of typing it doesn't support direct custom sorts.
	var lines: Array[String] = []
	lines.assign(read_file_lines(file_path))
	if lines.is_empty():
		if (skip == 0):
			push_warning("File ", file_path, " contained no lines to sort.")
			return OK # Returning OK because this could be a normal situation.
		else:
			push_error("File ", file_path, " contained no lines despite intention to skip ", skip, " lines.")
			return FAILED
	if (lines.size() == skip) or (lines.size() == skip + group_size):
		# The file is already sorted due to having minimum content.
		return OK
	if ((lines.size() - skip) % group_size != 0):
		push_error("File ", file_path, " contained the wrong number of lines.", 
		" Expected ", str(group_size), "k+", str(skip), ", but found ", str(lines.size()), ".")
		return FAILED
	
	var skipped_lines: Array[String] = lines.slice(0, skip)
	# Convert the array of lines to sort into an array (each element is a group) of arrays (the lines in each group.)
	var lines_to_group: Array[String] = lines.slice(skip)
	var line_groups: Array[Array] = []
	line_groups.resize(int(float(lines_to_group.size()) / float(group_size)))
	var group_of_lines: Array[String] = []
	group_of_lines.resize(group_size)
	for group_index in range(0, int(float(lines_to_group.size()) / float(group_size))):
		for line_index in range(0, group_size):
			group_of_lines[line_index] = lines_to_group[(group_index * group_size) + line_index]
		line_groups[group_index] = group_of_lines.duplicate()
	
	# Sort the array of line groups by the value their first line.
	if ascending:
		print(line_groups)
		line_groups.sort_custom(func(a: Array[String], b: Array[String]) -> bool: return a[0].naturalnocasecmp_to(b[0]) < 0)
		print(line_groups)
	else:
		line_groups.sort_custom(func(a: Array[String], b: Array[String]) -> bool: return a[0].naturalnocasecmp_to(b[0]) > 0)
	# Concatenate the groups of lines back into a single array of all of the lines.
	for group_index in range(0, line_groups.size()):
		for line_index in range(0, line_groups[group_index].size()):
			lines_to_group[(group_index * group_size) + line_index] = line_groups[group_index][line_index]
	# Overwrite the file with the new sorted lines.
	if write_file_from_lines(file_path, skipped_lines + lines_to_group) != OK:
		return FAILED
	return OK
#func sort_file_lines_and_comments_alphabetically (Think of something like sorting the splash texts file.)
#func sort_cfg ?


#-=-=-=-# SAFE CHECKING:

#func check_dict_key(dict_to_check: Dictionary, keys_to_check) -> bool:
#
#
#
#
#
#	return true


#-=-=-=-# GAME-SPECIFIC:

func ensure_required_dirs() -> Error:
	var any_errors_encountered: bool = false
	var err: Error
	var directories_to_ensure_exist: Array[String] = [
		PATH_STORAGE,
		PATH_REMEMBERED_SERVERS,
		PATH_WORLDS,
		PATH_SCREENSHOTS,
	]
	for dir in directories_to_ensure_exist:
		if not DirAccess.dir_exists_absolute(dir):
			err = DirAccess.make_dir_recursive_absolute(dir)
			if err != OK:
				push_error("Failed to find or create directory: ", dir, " (Error val:) ", err)
				any_errors_encountered = true
	if any_errors_encountered:
		return FAILED
	return OK
func ensure_required_files():
	pass
func ensure_world():
	pass

#func create_world(cfg_data: Dictionary) -> Error:
func create_world(world_name: String, world_seed: String) -> Error:
	# Normalize the world name.
	world_name = world_name.replace("\n", "")
	world_name = world_name.replace("\r", "")
	world_name = world_name.replace("\t", "")
	if world_name == "":
		world_name = "new world"
	# Normalize the world seed.
	if world_seed != "":
		world_seed = str(int(world_seed))
	else:
		world_seed = str(GeneralGlobals.get_rand_int())
	
	# Create the world's directory and subdirectories.
	var dir_name: String = get_available_dirname(PATH_WORLDS, world_name, false)
	var dir_path = PATH_WORLDS + "/" + dir_name
	var err: Error
	err = DirAccess.make_dir_absolute(dir_path)
	if err != OK:
		push_error("Failed to create directory: ", dir_path, " (Error val:) ", err)
		return err
	err = DirAccess.make_dir_absolute(dir_path + "/chunks")
	if err != OK:
		push_error("Failed to create directory: ", dir_path + "/chunks", " (Error val:) ", err)
		return err
	
	# Set up the dictionary that will be used to create the world info cfg file.
	var cfg_data: Dictionary = {
		"meta_info": {
			"version": GeneralGlobals.V_ENTIRE,
			"world_name": world_name,
			"favorited": false,
			"creation_date_utc": Time.get_datetime_string_from_system(true, true),
			"last_played_date_utc": "unplayed",
			"launch_count": 0,
		},
		"generation": {
			"seed": world_seed,
		},
		"world_data": {
			"placeholder": "314"
		},
		"players_data": {
			"placeholder": "314"
		},
	}
	
	# Write the world info cfg file and return.
	if write_cfg(dir_path + "/world.cfg", cfg_data) != OK:
		return FAILED
	return OK
func edit_world(dir_name: String, new_name: String, new_seed: String) -> Error:
	# Normalize the world name.
	new_name = new_name.replace("\n", "")
	new_name = new_name.replace("\r", "")
	new_name = new_name.replace("\t", "")
	if new_name == "":
		new_name = "new world"
	# Normalize the world seed.
	if new_seed != "":
		new_seed = str(int(new_seed))
	else:
		new_seed = str(GeneralGlobals.get_rand_int())
	
	var dict: Dictionary = read_cfg(PATH_WORLDS + "/" + dir_name + "/world.cfg")
	dict["meta_info"]["world_name"] = new_name
	dict["generation"]["seed"] = new_seed
	
	var any_errors_occured: bool = false
	if write_cfg(PATH_WORLDS + "/" + dir_name + "/world.cfg", dict) != OK:
		any_errors_occured = true
	if dir_name.substr(0, new_name.length()) != new_name:
		var new_dir_name: String = get_available_dirname(PATH_WORLDS, new_name, false)
		if move_dir(PATH_WORLDS + "/" + dir_name, PATH_WORLDS + "/" + new_dir_name, true) != OK:
			any_errors_occured = true
	
	if any_errors_occured:
		return FAILED
	return OK
func delete_world(dir_name: String) -> Error:
	if delete_dir(PATH_WORLDS + "/" + dir_name, true) != OK:
		return FAILED
	return OK
func duplicate_world(dir_name: String) -> Error:
	if copy_dir(PATH_WORLDS + "/" + dir_name, PATH_WORLDS + "/" + get_available_dirname(PATH_WORLDS, dir_name, false), true) != OK:
		return FAILED
	return OK

func add_remembered_server(nickname: String, ip: String) -> Error:
	var dict: Dictionary = read_cfg(PATH_REMEMBERED_SERVERS)
	var section_name: String = get_available_dict_key_string(dict, nickname, false)
	dict[section_name] = {
		"nickname": nickname,
		"ip": ip,
		"join_count": 0,
	}
	if write_cfg(PATH_REMEMBERED_SERVERS, dict) != OK:
		return FAILED
	return OK
func edit_remembered_server(section_name: String, nickname: String, ip: String) -> Error:
	var section_data: Dictionary = read_cfg_section(PATH_REMEMBERED_SERVERS, section_name)
	remove_remembered_server(section_name)
	var dict: Dictionary = read_cfg(PATH_REMEMBERED_SERVERS) 
	var replacement_section_name: String = get_available_dict_key_string(dict, nickname, false)
	dict[replacement_section_name] = section_data
	dict[replacement_section_name]["nickname"] = nickname
	dict[replacement_section_name]["ip"] = ip
	print("inputs: ", nickname, ", ", ip)
	print(dict[replacement_section_name]["nickname"])
	print(dict[replacement_section_name]["ip"])
	if write_cfg(PATH_REMEMBERED_SERVERS, dict) != OK:
		return FAILED
	return OK
func remove_remembered_server(section_name: String) -> Error:
	var dict: Dictionary = read_cfg(PATH_REMEMBERED_SERVERS)
	dict.erase(section_name)
	if write_cfg(PATH_REMEMBERED_SERVERS, dict) != OK:
		return FAILED
	return OK


#-=-=-=-#
