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
