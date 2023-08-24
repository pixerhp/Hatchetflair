extends Node


# FILE INTERACTION FUNCTIONS:

func read_txtfile_lines_as_array(file_location: String) -> Array[String]:
	if not FileAccess.file_exists(file_location):
		push_error("A text file: \"", file_location, "\" couldn't be found to have its lines read. (Returning [].)")
		return([])
	
	var file: FileAccess = FileAccess.open(file_location, FileAccess.READ)
	if not file.is_open():
		push_error("A text file: \"", file_location, "\" which was successfully found couldn't be opened to have its lines read. ",
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

func write_txtfile_from_array_of_lines(file_location: String, text_lines: Array[String]) -> void:
	var file: FileAccess = FileAccess.open(file_location, FileAccess.WRITE)
	if not file.is_open():
		push_error("A text file: \"", file_location, "\" to be written-to or created could not be opened. (FileAccess open error:) ", str(FileAccess.get_open_error()))
		return
	
	for line in text_lines:
		file.store_line(line)
	file.close()
	return

func sort_txtfile_contents_alphabetically(file_location: String, skipped_lines: int, num_of_lines_in_group: int = 1) -> void:
	var file_contents: Array[String] = read_txtfile_lines_as_array(file_location)
	if file_contents.size() == 0:
		push_warning("Attempted to alphabetically sort the contents of \"" + file_location + "\", but it had no contents. (Aborting sort.)")
		return
	if (file_contents.size() == skipped_lines) or (file_contents.size() == skipped_lines + num_of_lines_in_group):
		# The file has very few lines, such that attempting to sort it wouldn't change anything, wasting time.
		# This is a common and intended situation, so there's no need for a warning/error message.
		return
	if ((file_contents.size() - skipped_lines) % num_of_lines_in_group != 0):
		push_error("Attempted to alphabetically sort the content lines of \"", file_location, "\", but it had the wrong number of lines. (Aborting sort.) ",
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
	
	write_txtfile_from_array_of_lines(file_location, file_contents)
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

func copy_dir_to_dir(from_dir: String, to_dir: String, replace_if_already_exists: bool) -> bool:
	if not DirAccess.dir_exists_absolute(from_dir):
		push_error("The \"copy_dir_to_dir()\" func found that the \"from\" directory specified doesn't exist: ", from_dir)
		return true
	
	if replace_if_already_exists:
		# Empty out the destination directory for replacement.
		if DirAccess.dir_exists_absolute(to_dir):
			delete_dir_contents(to_dir)
	else:
		# Find an available destination directory name and create the directory.
		to_dir = first_unused_dir_alt(to_dir)
		DirAccess.make_dir_recursive_absolute(to_dir)
		if not DirAccess.dir_exists_absolute(to_dir):
			push_error("The \"copy_dir_to_dir()\" func failed to create or find dir: \"", to_dir, " (Abandoning copying.)")
			return(true)
	
	# Copy all of the contents into the destination directory.
	if copy_dir_contents_into_dir(from_dir, to_dir, false):
		push_warning("A deeper nested layer of \"copy_dir_contents_into_dir()\" used by \"copy_dir_to_dir()\" encountered an error. (Returning error.")
		return(true)
	
	return(false)

func copy_dir_contents_into_dir(from_dir: String, to_dir: String, replace_if_already_exists: bool) -> bool:
	if not DirAccess.dir_exists_absolute(from_dir):
		push_error("The \"copy_dir_contents_into_dir()\" func found that the \"from\" directory specified doesn't exist: ", from_dir)
		return true
	if not DirAccess.dir_exists_absolute(to_dir):
		push_error("The \"copy_dir_contents_into_dir()\" func found that the \"to\" directory specified doesn't exist: ", to_dir)
		return true
	
	if replace_if_already_exists:
		delete_dir_contents(to_dir)
	
	# Copy all of the (non-directory) files.
	for file in DirAccess.get_files_at(from_dir):
		DirAccess.copy_absolute(from_dir + "/" + file, to_dir + "/" + file)
	
	# Copy all of the directories and their files.
	for sub_dir in DirAccess.get_directories_at(from_dir):
		if copy_dir_to_dir(from_dir + "/" + sub_dir, to_dir + "/" + sub_dir, false):
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


# FILE ENSURANCE/CREATION FUNCTIONS:

func ensure_essential_game_dirs_and_files_exist() -> bool:
	var errors_were_encountered: bool = false
	
	var directories_to_ensure: Array[String] = [
		"user://storage",
		"user://storage/worlds",
	]
	for dir in directories_to_ensure:
		DirAccess.make_dir_recursive_absolute(dir)
		if not DirAccess.dir_exists_absolute(dir):
			errors_were_encountered = true
			push_error("Essential game directory: \""+dir+"\" could not be created/found.")
	
	# If an essential file doesn't already exist, creates it blank except for version_entire in its first text line.
	var file_locations_to_ensure: Array[String] = [
		"user://storage/user_info.txt",
		"user://storage/worlds_list.txt",
		"user://storage/servers_list.txt",
	]
	for file_location in file_locations_to_ensure:
		if not FileAccess.file_exists(file_location):
			write_txtfile_from_array_of_lines(file_location, [GlobalStuff.game_version_entire])
			if not FileAccess.file_exists(file_location):
				errors_were_encountered = true
				push_error("Essential game file: \""+file_location+"\" could not be created/found.")
	
	if errors_were_encountered:
		return(true)
	else:
		return(false)
