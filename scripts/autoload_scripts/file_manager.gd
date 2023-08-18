extends Node

func recursively_delete_all_files_inside_directory(dir: String) -> bool:
	if not DirAccess.dir_exists_absolute(dir):
		push_warning("The \"recursively_delete_all_files_inside_directory()\" func couldn't find the directory specified: " + dir)
		return true
	
	# Delete the contents of all deeper nested directories and their files first.
	for deeper_nested_dir in DirAccess.get_directories_at(dir):
		if recursively_delete_all_files_inside_directory(dir + "/" + deeper_nested_dir):
			push_warning("The \"recursively_delete_all_files_inside_directory()\" func encountered an error deleting directory: " + dir + "/" + deeper_nested_dir)
			return true
		DirAccess.remove_absolute(dir + "/" + deeper_nested_dir)
	
	# Delete all of the (non-directory) files in the current directory.
	for file in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir + "/" + file)
	
	return false
