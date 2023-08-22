extends Node


func read_txtfile_lines_as_array(file_location: String, include_potential_blank_last_line: bool) -> Array[String]:
	if not FileAccess.file_exists(file_location):
		push_error("A text file couldn't be found to have its lines read: " + file_location)
		return([])
	
	var file: FileAccess = FileAccess.open(file_location, FileAccess.READ)
	if not file.is_open():
		push_error("A text file which was successfully found couldn't be opened to have its lines read: " + file_location + " with FileAccess open error: " + str(FileAccess.get_open_error()))
		return([])
	
	# Get all of the lines of the text file.
	var text_lines: Array[String] = []
	while (file.eof_reached() == false):
		text_lines.append(file.get_line())
	file.close()
	
	if not include_potential_blank_last_line:
		if (text_lines.size() > 0) and (text_lines[text_lines.size()-1] == ""):
			text_lines.pop_back()
	
	return(text_lines)

func write_txtfile_from_array_of_lines(file_location: String, text_lines: Array[String]) -> void:
	var file: FileAccess = FileAccess.open(file_location, FileAccess.WRITE)
	if not file.is_open():
		push_error("A text file to be written-to/created could not be opened: " + file_location + " with FileAccess open error: " + str(FileAccess.get_open_error()))
		return
	
	for line in text_lines:
		file.store_line(line)
	file.close()
	return

func sort_txtfile_contents_alphabetically(file_location: String, skipped_lines: int, num_of_lines_in_group: int = 1) -> void:
	var file_contents: Array[String] = read_txtfile_lines_as_array(file_location, false)
	if file_contents.size() == 0:
		push_warning("Attempted to alphabetically sort a text file's contents, but it had no contents. (Aborting sort.) File location: " + file_location)
		return
	elif (file_contents.size() == skipped_lines) or (file_contents.size() == skipped_lines + num_of_lines_in_group):
		# The file has very few lines, such that attempting to sort it wouldn't change anything, wasting time.
		# This is a common and intended situation, so there's no need for a warning/error message.
		return
	elif ((file_contents.size() - skipped_lines) % num_of_lines_in_group != 0):
		push_error("Attempted to alphabetically sort a text files contents, but it had the wrong number of lines. (Aborting sort.) File location: " + file_location)
		push_error("(The sort expected [" + str(num_of_lines_in_group) + "k + " + str(skipped_lines) + "] lines, but the file contained " + str(file_contents.size()) + " lines instead.)")
		return
	
	# {U} Concatenate together all lines in each "group" (with item-length keys at the end,) so that they stay together after the sort is finished.
	
	
	# Sort the concatenated items alphabetically (a to z.) (The custom function is so that 1 < 2 < 10.)
	#concatenated_lines.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)
	
	# {U} Unconcatenate the lines apart, so that 

func recursively_delete_all_files_inside_directory(dir: String) -> bool:
	if not DirAccess.dir_exists_absolute(dir):
		push_warning("The \"recursively_delete_all_files_inside_directory()\" func couldn't find the directory specified: " + dir)
		return true
	
	# Delete the contents of all deeper nested directories and all of their files first.
	for deeper_nested_dir in DirAccess.get_directories_at(dir):
		if recursively_delete_all_files_inside_directory(dir + "/" + deeper_nested_dir):
			push_warning("The \"recursively_delete_all_files_inside_directory()\" func encountered an error deleting directory: " + dir + "/" + deeper_nested_dir)
			return true
		DirAccess.remove_absolute(dir + "/" + deeper_nested_dir)
	
	# Delete all of the (non-directory) files in the current directory.
	for file in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir + "/" + file)
	
	return false


# VERSION UPDATING FUNCTIONS ARE BELOW HERE.
