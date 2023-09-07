extends Node


# GENERAL FILE INTERACTION FUNCTIONS:

func read_txtfile_lines_as_array(file_path: String) -> Array[String]:
	if not FileAccess.file_exists(file_path):
		push_error("A text file: \"", file_path, "\" couldn't be found to have its lines read. (Returning [].)")
		return([])
	
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if not file.is_open():
		push_error("A text file: \"", file_path, "\" which was successfully found couldn't be opened to have its lines read. ",
		"(FileAccess open error:) ", str(FileAccess.get_open_error()), " (Returning [].)")
		return([])
	
	# Get all of the lines of the text file.
	var text_lines: Array[String] = []
	while file.eof_reached() == false:
		text_lines.append(file.get_line())
	file.close()
	
	if (text_lines.size() > 0) and (text_lines[text_lines.size()-1] == ""):
		text_lines.pop_back()
	
	return(text_lines)

func read_txtfile_firstline(file_path: String) -> String:
	if not FileAccess.file_exists(file_path):
		push_error("A text file: \"", file_path, "\" couldn't be found to have its first line read. (Returning \"\".)")
		return("")
	
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if not file.is_open():
		push_error("A text file: \"", file_path, "\" which was successfully found couldn't be opened to have its first line read. ",
		"(FileAccess open error:) ", str(FileAccess.get_open_error()), " (Returning \"\".)")
		return("")
	
	var line = file.get_line()
	file.close()
	return(line)

func read_txtfile_remaining_of_line_starting_with(file_path: String, substring: String) -> Array:
	if not FileAccess.file_exists(file_path):
		push_error("A text file: \"", file_path, "\" couldn't be found to have its lines read. (Returning \"\".)")
		return(["", -1])
	
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if not file.is_open():
		push_error("A text file: \"", file_path, "\" which was successfully found couldn't be opened to have its lines read. ",
		"(FileAccess open error:) ", str(FileAccess.get_open_error()), " (Returning \"\".)")
		return(["", -1])
	
	var line: String = ""
	var line_number: int = 0
	while file.eof_reached() == false:
		line = file.get_line()
		line_number += 1
		if line.substr(0, substring.length()) == substring:
			# A line beginning with the substring was found.
			file.close()
			return([line_number, line.substr(substring.length())])
	
	# A line which begins with the substring was not found.
	file.close()
	return(["", -1])

func write_txtfile_from_array_of_lines(file_path: String, text_lines: Array[String]) -> bool:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if not file.is_open():
		push_error("A text file: \"", file_path, "\" to be written-to or created could not be opened. (FileAccess open error:) ", str(FileAccess.get_open_error()))
		return(true)
	
	for line in text_lines:
		file.store_line(line)
	file.close()
	return(false)

func write_txtfile_replace_end_of_line_starting_with(file_path: String, substring: String, replacement: String) -> bool:
	if not FileAccess.file_exists(file_path):
		push_error("A text file: \"", file_path, "\" couldn't be found to be read and written to. (Aborting.)")
		return(true)
	
	var line_to_replace: int = read_txtfile_remaining_of_line_starting_with(file_path, substring)[0]
	if line_to_replace == -1:
		push_error("The line_starting substring: \"", substring, "\" could not be found in: ", file_path, " (Aborting.)")
		return(true)
	
	var txtfile_lines: Array[String] = read_txtfile_lines_as_array(file_path)
	txtfile_lines[line_to_replace - 1] = substring + replacement
	write_txtfile_from_array_of_lines(file_path, txtfile_lines)
	
	return(false)

func sort_txtfile_contents_alphabetically(file_path: String, skipped_lines: int, num_of_lines_in_group: int = 1) -> void:
	var file_contents: Array[String] = read_txtfile_lines_as_array(file_path)
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
	
	write_txtfile_from_array_of_lines(file_path, file_contents)
	return

func delete_dir(dir: String) -> bool:
	if not DirAccess.dir_exists_absolute(dir):
		push_error("The \"delete_dir()\" func found that the directory specified didn't exist: ", dir)
		return true
	
	if delete_dir_contents(dir):
		push_error("An error was enountered by deeper nested \"delete_dir_contents()\" whilst deleting the contents of: ", dir, " (Abandoning deletion.)")
		return true
	
	DirAccess.remove_absolute(dir)
	if DirAccess.dir_exists_absolute(dir):
		push_error("The contents of: ", dir, " were successfully removed, but said directory itself persisted through attempted deletion.")
		return true
	
	return false

func delete_dir_contents(dir: String) -> bool:
	if not DirAccess.dir_exists_absolute(dir):
		push_error("The \"delete_dir_contents()\" func found that the directory specified didn't exist: ", dir)
		return true
	
	# Delete the contents of all deeper nested directories and all of their files first.
	for deeper_nested_dir in DirAccess.get_directories_at(dir):
		if delete_dir(dir + "/" + deeper_nested_dir):
			push_error("The deeper nested \"delete_dir()\" func encountered an error deleting directory: ", dir, "/", deeper_nested_dir)
			return true
	
	# Delete all of the (non-directory) files in the current directory.
	for file in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir + "/" + file)
	
	return false

func copy_dir_to_dir(from_dir: String, target_dir: String, replace_if_already_exists: bool) -> bool:
	if not DirAccess.dir_exists_absolute(from_dir):
		push_error("The \"copy_dir_to_dir()\" func found that the \"from\" directory specified doesn't exist: ", from_dir)
		return true
	
	if replace_if_already_exists:
		# Empty out the destination directory for replacement.
		if DirAccess.dir_exists_absolute(target_dir):
			delete_dir_contents(target_dir)
	else:
		# Find an available destination directory name and create the directory.
		target_dir = first_unused_dir_alt(target_dir)
		DirAccess.make_dir_recursive_absolute(target_dir)
		if not DirAccess.dir_exists_absolute(target_dir):
			push_error("The \"copy_dir_to_dir()\" func failed to create or find dir: \"", target_dir, " (Abandoning copying.)")
			return(true)
	
	# Copy all of the contents into the destination directory.
	if copy_dir_contents_into_dir(from_dir, target_dir, false):
		push_warning("A deeper nested layer of \"copy_dir_contents_into_dir()\" used by \"copy_dir_to_dir()\" encountered an error. (Returning error.")
		return(true)
	
	return(false)

func copy_dir_contents_into_dir(from_dir: String, target_dir: String, replace_if_already_exists: bool) -> bool:
	if not DirAccess.dir_exists_absolute(from_dir):
		push_error("The \"copy_dir_contents_into_dir()\" func found that the \"from\" directory specified doesn't exist: ", from_dir)
		return true
	if not DirAccess.dir_exists_absolute(target_dir):
		push_error("The \"copy_dir_contents_into_dir()\" func found that the \"to\" directory specified doesn't exist: ", target_dir)
		return true
	
	if replace_if_already_exists:
		delete_dir_contents(target_dir)
	
	# Copy all of the (non-directory) files.
	for file in DirAccess.get_files_at(from_dir):
		DirAccess.copy_absolute(from_dir + "/" + file, target_dir + "/" + file)
	
	# Copy all of the directories and their files.
	for sub_dir in DirAccess.get_directories_at(from_dir):
		if copy_dir_to_dir(from_dir + "/" + sub_dir, target_dir + "/" + sub_dir, false):
			push_warning("A deeper nested layer of \"copy_dir_to_dir()\" used by \"copy_dir_contents_into_dir()\" encountered an error. (Returning error.")
			return(true)
	
	return(false)

# Note: You should *not* include a "/" at the end of the opening path if you input both paths.
func first_unused_dir_alt(dir_opening_path: String, dir_ending_path: String = "") -> String:
	if dir_ending_path == "":
		# Find and output the first usable alt of the full path.
		if not DirAccess.dir_exists_absolute(dir_opening_path):
			return(dir_opening_path)
		else:
			# The simple solution is already used, so find an alternate directory name which isn't taken.
			var attempt_number: int = 1
			while(DirAccess.dir_exists_absolute(dir_opening_path + " alt_" + str(attempt_number))):
					attempt_number += 1
			return(dir_opening_path + " alt_" + str(attempt_number))
	else:
		# Find the first usable alt of the full path, and output only the segment at end of said path.
		if not DirAccess.dir_exists_absolute(dir_opening_path + "/" + dir_ending_path):
			return(dir_ending_path)
		else:
		# The simple solution is already used, so find an alternate directory name which isn't taken.
			var attempt_number: int = 1
			while(DirAccess.dir_exists_absolute(dir_opening_path + "/" + dir_ending_path + " alt_" + str(attempt_number))):
					attempt_number += 1
			return(dir_ending_path + " alt_" + str(attempt_number))



# FILE CREATION AND ENSURANCE FUNCTIONS:

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
			write_txtfile_from_array_of_lines(file_path, [GlobalStuff.game_version_entire])
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
		GlobalStuff.game_version_entire,
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
				GlobalStuff.game_version_entire,
				"creation date-time (utc): " + Time.get_datetime_string_from_system(true, true),
				"last-played date-time (utc): unplayed",
				"world generation seed: " + str(GlobalStuff.random_worldgen_seed()),
			]
		else:
			world_info_lines = world_info_input
		FileManager.write_txtfile_from_array_of_lines(world_dir_path + "/world_info.txt", world_info_lines)
		if not FileAccess.file_exists(world_dir_path + "/world_info.txt"):
			push_error("Failed to create the world_info text file in world directory: ", world_dir_path)
	
	return(false)
