extends Node

# Contents:
# - Global constants
# - Basic dirs & files interactions
# - File reading and writing
# - File creating and ensurance


# GLOBAL CONSTANTS:

const PATH_ASSETS: String = "res://assets"
const PATH_SPLASHES: String = PATH_ASSETS + "/text_files/window_splash_texts.txt"

const PATH_STORAGE: String = "user://storage"
const PATH_WORLDS: String = PATH_STORAGE + "/worlds"
const PATH_SCREENSHOTS: String = PATH_STORAGE + "/screenshots"
const PATH_SERVERS: String = PATH_STORAGE + "/servers_list.cfg"


# BASIC DIRS & FILES INTERACTIONS:

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


# FILE READING AND WRITING:

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

func read_cfg(file_path: String, skip_section: String = "") -> Dictionary:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(file_path)
	if err != OK:
		push_error("Failed to open cfgfile at: ", file_path, " (Error val:) ", err)
		return {}
	var dictionary: Dictionary = {}
	var section_data: Dictionary = {}
	for section in cfg.get_sections():
		section_data = {}
		for key in cfg.get_section_keys(section):
			section_data[key] = cfg.get_value(section, key)
		dictionary[section] = section_data
	return dictionary
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
func read_cfg_sections_list(file_path: String) -> PackedStringArray:
	return []
func read_cfg_keyval_to_section(file_path: String, key: Variant, sect: String) -> Dictionary:
	return {}
func read_cfg_section_to_keyval(file_path: String, sect: String, key: Variant) -> Dictionary:
	return {}
func read_cfg_keyval_to_keyval(file_path: String, key1: Variant, key2: Variant) -> Dictionary:
	return {}

func write_cfg_from_dict(file_path: String, dict: Dictionary) -> Error:
	var cfg: ConfigFile = ConfigFile.new()
	var any_errors_occured: bool = false
	
	for section in dict.keys():
		if typeof(dict[section]) == TYPE_DICTIONARY:
			for key in dict[section].keys():
				cfg.set_value(section, key, dict[section][key])
		else:
			push_error("Dictionary key ", section, " did not have a dictionary as its value.")
			any_errors_occured = true
	
	var err: Error = cfg.save(file_path)
	if err != OK:
		push_error("Failed to save cfgfile to ", file_path, " (Error val:) ", err)
		any_errors_occured = true
	if any_errors_occured:
		return FAILED
	else:
		return OK




func sort_txtfile_contents_alphabetically(file_path: String, skipped_lines: int, num_of_lines_in_group: int = 1) -> void:
	var file_contents: Array[String] = read_file_lines(file_path)
	if file_contents.size() == 0:
		push_warning("Attempted to alphabetically sort the contents of \"" + file_path + "\", but it had no contents. (Aborting sort.)")
		return
	if (file_contents.size() == skipped_lines) or (file_contents.size() == skipped_lines + num_of_lines_in_group):
		# The file has very few lines, such that attempting to sort it wouldn't change anything, wasting time.
		# This is a common and intended situation, so there's no need for a warning/error message.
		return
	if ((file_contents.size() - skipped_lines) % num_of_lines_in_group != 0):
		push_error("Attempted to alphabetically sort the content lines of \"", file_path, "\", but it had the wrong number of lines. (Aborting sort.) ",
		"(The sort expected [", str(num_of_lines_in_group), "k + ", str(skipped_lines), "] lines, but the file contained ", str(file_contents.size()), " lines instead.)")
		return
	
	if num_of_lines_in_group < 2:
		# (A zero or negative group size is simply treated as a group size of 1.)
		# No concatenation is needed, so simply sort the section of items after the skipped lines.
		var content_of_skipped_lines: Array[String] = file_contents.slice(0, skipped_lines)
		var lines_to_be_sorted: Array[String] = file_contents.slice(skipped_lines)
		lines_to_be_sorted.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0) # (Custom func ensures 1 < 2 < 10)
		file_contents = content_of_skipped_lines + lines_to_be_sorted
	else:
		# Concatenate together all lines in each "group" (with item-length keys at the end,) so that they stay together after the sort is finished.
		# [str1, str2, str3] -> [str1str2str3:{length of str2}:{length of str1}];   [a, bb, ccc, dddd] -> [abbcccdddd:3:2:1]
		var content_of_skipped_lines: Array[String] = file_contents.slice(0, skipped_lines)
		var concatenated_lines: Array[String] = []
		for index_of_last_group_item in range(file_contents.size()-1, skipped_lines-1, -1 * num_of_lines_in_group):
			var current_concatenation_item: String
			for index in range(index_of_last_group_item, index_of_last_group_item - num_of_lines_in_group, -1):
				current_concatenation_item = file_contents[index] + current_concatenation_item
				if index != index_of_last_group_item:
					current_concatenation_item = current_concatenation_item + ":" + str(file_contents[index].length())
			concatenated_lines.append(current_concatenation_item)
		
		# Sort the concatenated items alphabetically (a to z.) (The custom function is so that 1 < 2 < 10.)
		concatenated_lines.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)
		
		# Determine the final results of the sort, unconcatenating grouped lines back apart.
		file_contents = content_of_skipped_lines
		var index_of_seperator: int = 0
		for current_concatenation in concatenated_lines:
			for item_num in range(1, num_of_lines_in_group + 1):
				if item_num != num_of_lines_in_group:
					# Find the rightmost instance of ":" in the current state of current_concatenation.
					index_of_seperator = current_concatenation.rfind(":")
					file_contents.append(current_concatenation.substr(0, int(current_concatenation.substr(index_of_seperator+1))))
					current_concatenation = current_concatenation.substr(int(current_concatenation.substr(index_of_seperator+1)), index_of_seperator - int(current_concatenation.substr(index_of_seperator+1)))
				else: # The last bit of concatenated info with nothing else surrounding it.
					file_contents.append(current_concatenation)
	
	write_file_from_lines(file_path, file_contents)
	return


# FILE CREATING AND ENSURANCE:

func ensure_essential_game_dirs_and_files_exist() -> Error:
	var err: Error = OK
	
	var directories_to_ensure: Array[String] = [
		"user://storage",
		"user://storage/worlds",
	]
	for dir in directories_to_ensure:
		DirAccess.make_dir_recursive_absolute(dir)
		if not DirAccess.dir_exists_absolute(dir):
			push_error("Essential game directory: \"", dir, "\" could not be found/created.")
			err = FAILED
	
	# If an essential file doesn't already exist, creates it blank except for version_entire in its first text line.
	var file_paths_to_ensure: Array[String] = [
		"user://storage/user_info.txt",
		"user://storage/worlds_list.txt",
		"user://storage/servers_list.txt",
	]
	for file_path in file_paths_to_ensure:
		if not FileAccess.file_exists(file_path):
			write_file_from_lines(file_path, [GeneralGlobals.game_version_entire])
			if not FileAccess.file_exists(file_path):
				push_error("Essential game file: \"", file_path, "\" could not be found/created.")
				err = FAILED
	
	return(err)

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
