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
const PATH_SERVERS: String = PATH_STORAGE + "/servers_list.cfg"
const PATH_WORLDS: String = PATH_STORAGE + "/worlds"
const PATH_SCREENSHOTS: String = PATH_STORAGE + "/screenshots"


#-=-=-=-# DIR & FILE INTERACTIONS:

func delete_dir(dir_path: String, move_to_os_trash: bool) -> Error:
	if move_to_os_trash:
		var err: Error = OS.move_to_trash(ProjectSettings.globalize_path(dir_path))
		push_error("Failed to move dir into OS trash: ", dir_path, " (Error val:) ", err)
		return err
	else:
		delete_dir_contents(dir_path, false)
		var err: Error = DirAccess.remove_absolute(dir_path)
		if err != OK:
			push_error("Failed to remove dir at path: ", dir_path, " (Error val:) ", err)
			return FAILED
		return OK
func delete_dirs(dir_paths: Array[String], move_to_os_trash: bool) -> Error:
	var any_errors_occured: bool = false
	for path in dir_paths:
		if delete_dir(path, move_to_os_trash) != OK:
			any_errors_occured = true
	if any_errors_occured:
		return FAILED
	else:
		return OK
func delete_dir_contents(dir_path: String, move_to_os_trash: bool) -> Error:
	var err: Error
	var any_errors_occured: bool = false
	if move_to_os_trash:
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
		else:
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
		else:
			return OK
func delete_dirs_contents(dir_paths: Array[String], move_to_os_trash: bool) -> Error:
	var any_errors_occured: bool = false
	for path in dir_paths:
		if delete_dir_contents(path, move_to_os_trash) != OK:
			any_errors_occured = true
	if any_errors_occured:
		return FAILED
	else:
		return OK

func copy_dir_to_path(from_dir: String, target_dir: String, empty_target_dir_first_if_exists: bool) -> Error:
	var err: Error
	if DirAccess.dir_exists_absolute(target_dir):
		if empty_target_dir_first_if_exists:
			delete_dir_contents(target_dir, false)
	else:
		err = DirAccess.make_dir_recursive_absolute(target_dir)
		if err != OK:
			push_error("Failed to create dir at path: ", target_dir, " (Error val:) ", err)
			return FAILED
	if copy_dir_contents_into_dir(from_dir, target_dir, false) != OK:
		return FAILED
	else:
		return OK
func copy_dir_contents_into_dir(from_dir_path: String, target_dir_path: String, empty_target_dir_first: bool) -> Error:
	if empty_target_dir_first:
		if delete_dir_contents(target_dir_path, false) != OK:
			return FAILED
	var err: Error
	var any_errors_occured: bool = false
	for file_name in DirAccess.get_files_at(from_dir_path):
		err = DirAccess.copy_absolute(from_dir_path + "/" + file_name, target_dir_path + "/" + file_name)
		if err != OK:
			push_error("Failed to copy file: ", from_dir_path + "/" + file_name, 
			" to: ", target_dir_path + "/" + file_name, " (Error val:) ", err)
			any_errors_occured = true
	for nested_dir_name in DirAccess.get_directories_at(from_dir_path):
		if copy_dir_to_path(from_dir_path + "/" + nested_dir_name, target_dir_path + "/" + nested_dir_name, false) != OK:
			any_errors_occured = true
	if any_errors_occured:
		return FAILED
	else:
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
	else:
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
	# Note2: Would also rather be Array[String] than Array, but I can't get PackedStringArray -> Array[Strings] to work.
	var lines: Array = Array(read_file_lines(file_path))
	if lines.is_empty():
		push_warning("File contained no lines to sort.")
		return OK # Returning OK because this could be a normal situation.
	var skipped: Array = lines.slice(0, skip)
	var to_sort: Array = lines.slice(skip)
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
	# Note2: Would also rather be Array[String] than Array, but I can't get PackedStringArray -> Array[Strings] to work.
	var lines: Array = read_file_lines(file_path)
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
	
	var skipped_lines: Array = lines.slice(0, skip)
	# Convert the array of lines to sort into an array (each element is a group) of arrays (the lines in each group.)
	var lines_to_group: Array = lines.slice(skip)
	var line_groups: Array[Array] = []
	line_groups.resize(int(float(lines_to_group.size()) / float(group_size)))
	var group_of_lines: Array = []
	group_of_lines.resize(group_size)
	for group_index in range(0, int(float(lines_to_group.size()) / float(group_size))):
		for line_index in range(0, group_size):
			group_of_lines[line_index] = lines_to_group[(group_index * group_size) + line_index]
		line_groups[group_index] = group_of_lines.duplicate()
	
	# Sort the array of line groups by the value their first line.
	if ascending:
		print(line_groups)
		line_groups.sort_custom(func(a: Array, b: Array) -> bool: return a[0].naturalnocasecmp_to(b[0]) < 0)
		print(line_groups)
	else:
		line_groups.sort_custom(func(a: Array, b: Array) -> bool: return a[0].naturalnocasecmp_to(b[0]) > 0)
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


#-=-=-=-# GAME-SPECIFIC:

func ensure_required_dirs() -> Error:
	var any_errors_encountered: bool = false
	var err: Error
	var directories_to_ensure_exist: Array[String] = [
		PATH_STORAGE,
		PATH_SERVERS,
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
	else:
		return OK
func ensure_world():
	pass

func create_world(dir_name: String, configuration_data: Dictionary) -> Error:
	if (configuration_data.has("meta_info") and configuration_data.has("generation_settings")):
		push_error("Incorrect configuration data input. Configuration data should be a dictionary of dictionaries, ",
		"in compatable format with the write_cfg function, and consist of required sections like meta_info and others.")
		return FAILED
	
	# Create the world's directory and subdirectories.
	dir_name = get_available_dirname(PATH_WORLDS, dir_name, false)
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
	
	if not configuration_data["meta_info"].has("name"):
		configuration_data["meta_info"]["name"] = dir_name
	
	
	
	
	return OK
func edit_world():
	pass
func delete_world():
	pass
func duplicate_world():
	pass

func add_remembered_server():
	pass
func edit_remembered_server():
	pass
func remove_remembered_server():
	pass


func create_world_dirs_and_files(world_dir_path: String, world_name: String, world_seed: String) -> bool:
	if DirAccess.dir_exists_absolute(world_dir_path):
		push_warning("Attempted to create a world's dirs and files, but the world directory already existed: ", world_dir_path, 
		" (Aborting world creation to prevent messing up whatever's already at/in that directory.)")
		return(true)
	DirAccess.make_dir_absolute(world_dir_path)
	if not DirAccess.dir_exists_absolute(world_dir_path):
		push_error("Failed to create world directory: ", world_dir_path)
		return(true)
	DirAccess.make_dir_absolute(world_dir_path + "/chunks")
	
	var world_info_txtfile_lines: Array[String] = [
		GeneralGlobals.game_version_entire,
		"world_name: " + world_name,
		"favorited?: false",
		"last_played_date_utc: unplayed",
		"creation_date_utc: " + Time.get_datetime_string_from_system(true, true),
		"launch_count: 0",
		"",
		"world_seed: " + world_seed,
	]
	if FileManager.write_txtfile_from_array_of_lines(world_dir_path + "/world_info.txt", world_info_txtfile_lines):
		push_error("Encountered an error attempting to write the world_info file while creating world files for world dir: ", world_dir_path)
		return(true)
	
	return(false)

func ensure_world_dir_has_required_files(world_dir_path: String, world_info_input: Array[String] = []) -> bool:
	if not DirAccess.dir_exists_absolute(world_dir_path):
		push_error("Attempted to ensure that world dir: ", world_dir_path, " had all required files, but that world folder didn't even exist. (Aborting.)")
		return(true)
	DirAccess.make_dir_recursive_absolute(world_dir_path + "/chunks")
	if not DirAccess.dir_exists_absolute(world_dir_path + "/chunks"):
		push_error("Failed to find dirs in world folder, even after attempting to create them: ", world_dir_path)
		return(true)
	if not FileAccess.file_exists(world_dir_path + "/world_info.txt"):
		var world_info_lines: Array[String] = []
		if world_info_input == []:
			world_info_lines = [
				GeneralGlobals.game_version_entire,
				"creation date-time (utc): " + Time.get_datetime_string_from_system(true, true),
				"last-played date-time (utc): unplayed",
				"world generation seed: " + str(GeneralGlobals.random_worldgen_seed()),
			]
		else:
			world_info_lines = world_info_input
		FileManager.write_txtfile_from_array_of_lines(world_dir_path + "/world_info.txt", world_info_lines)
		if not FileAccess.file_exists(world_dir_path + "/world_info.txt"):
			push_error("Failed to create the world_info text file in world directory: ", world_dir_path)
	
	return(false)

#-=-=-=-#
