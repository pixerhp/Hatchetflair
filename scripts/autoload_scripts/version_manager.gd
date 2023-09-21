extends Node
# v stands for version.
# cv stands for "current version"/similar. (It is also sometimes used like "current version of/for".)
# to separate a v_entire into it's components, use `v_entire.split('.')`.

# Compares whether the input version_entire comes before (-1), is the same as (0) or probably comes after (1) the cv.
func compare_v_to_cv(in_v_entire: String) -> int:
	if in_v_entire == "":
		push_warning()
		return(127)
	# If the input version is obviously the same as the current one then we don't need to do any special comparing.
	if in_v_entire == Globals.game_version_entire:
		return(0)
	
	var in_v_components: PackedStringArray = in_v_entire.split('.')
	
	if (in_v_components[0] != "pre-game"):
		# NOTE: in the future (specifically when the phase changes for the first time,)
		# phase comparisons will need to be manually defined here.
		return(1)
	else:
		# If the phases are equal, compare the engine versions.
		if (int(in_v_components[1]) < int(Globals.game_version_engine)):
			return(-1)
		elif (int(in_v_components[1]) > int(Globals.game_version_engine)):
			return(1)
		else:
			# If the engine versions are equal, compare the major versions.
			if (int(in_v_components[2]) < int(Globals.game_version_major)):
				return(-1)
			elif (int(in_v_components[2]) > int(Globals.game_version_major)):
				return(1)
			else:
				# If the major versions are equal, compare the minor versions.
				if (int(in_v_components[3]) < int(Globals.game_version_minor)):
					return(-1)
				elif (int(in_v_components[3]) > int(Globals.game_version_minor)):
					return(1)
				else:
					# Despite the two version strings not being strictly equal, 
					# the two versions are similar enough to be considered fully compatable.
					return(0)

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
