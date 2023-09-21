extends Node
# v stands for version.
# cv stands for "current version"/similar. (It is also sometimes used like "current version of/for".)
# to separate a v_entire into it's components, use `v_entire.split('.')`.

# Returns -1 if v1 < v2, 0 if v1 == v2, and 1 if v1 > v2.
func compare_v_to_v(v1: String, v2: String) -> int:
	var v1_components: PackedStringArray = v1.split('.')
	var v2_components: PackedStringArray = v2.split('.')
	if v1_components.size() > v2_components.size():
		v2_components.resize(v1_components.size())
	if v2_components.size() > v1_components.size():
		v1_components.resize(v2_components.size())
	
	for i in v1_components.size():
		if int(v1_components[i]) < int(v2_components[i]):
			return -1
		if int(v1_components[i]) > int(v2_components[i]):
			return 1
	return 0
func compare_v_to_cv(version: String) -> int:
	return compare_v_to_v(version, Globals.V_ENTIRE)

# Returns true only if one or more essential files failed to be (or be transversioned to) the correct version.
func ensure_cv_essential_files() -> bool: 
	var any_failures_encountered: bool = false
	
	var files_to_ensure: Array[Array] = [
		["user://storage/user_info.txt", "user_info",],
		["user://storage/worlds_list.txt", "worlds_or_servers_list",],
		["user://storage/servers_list.txt", "worlds_or_servers_list",],
	]
	for item in files_to_ensure:
		if transversion_file(item[0], item[1]):
			push_error("Failure to transversion an essential game file to the current version: ", item)
			any_failures_encountered = true
	
	return(any_failures_encountered)

# Returns whether or not the file failed to be successfully brought to the target version.
func transversion_file(file_path: String, file_style: String, target_version: String = Globals.game_version_entire) -> bool:
	match file_style:
		"user_info":
			match compare_v_to_cv(FileManager.read_file_first_line(file_path)):
				-1:
					# NOTE: will contain actual file converting (returning false) later when other supported versions exist.
					return(true)
				0:
					return(false)
				1:
					# NOTE: will contain actual file converting (returning false) later when other supported versions exist.
					return(true)
				128:
					push_transversion_v_comparison_error(file_path, file_style, FileManager.read_file_first_line(file_path), target_version)
					return(true)
		"worlds_or_servers_list":
			match compare_v_to_cv(FileManager.read_file_first_line(file_path)):
				-1:
					# NOTE: will contain actual file converting (returning false) later when other supported versions exist.
					return(true)
				0:
					return(false)
				1:
					# NOTE: will contain actual file converting (returning false) later when other supported versions exist.
					return(true)
				128:
					push_transversion_v_comparison_error(file_path, file_style, FileManager.read_file_first_line(file_path), target_version)
					return(true)
	
	push_error("File contents style not currently supported for transversioning: ", file_style)
	return(true)

func push_transversion_v_comparison_error(file_path: String, file_style: String, current_version: String, target_version: String):
	push_error("Failed to transversion file: ", file_path, " with style: ", file_style, 
	" due to an error having occured attempting to compare its current version: ", 
	current_version, " to its target version: ", target_version)
	return
