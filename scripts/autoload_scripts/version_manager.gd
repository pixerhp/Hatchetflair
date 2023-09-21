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

func transversion_file(path: String, target_v: String = Globals.V_ENTIRE) -> Error:
	var any_errors_occured: bool = false
	match path:
		FileManager.PATH_SERVERS:
			match compare_v_to_v(FileManager.read_cfg_keyval(path, "meta_info", "version"), target_v):
				-2:
					return FAILED
				-1:
					pass
				0:
					return OK
				1:
					pass
		FileManager.PATH_USERS:
			match compare_v_to_v(FileManager.read_file_first_line(path), target_v):
				-2:
					return FAILED
				-1:
					pass
				0:
					return OK
				1:
					pass
		var unrecognized_path:
			any_errors_occured = true
			push_error("Did not have code to transversion file at path: ", path)
	
	if any_errors_occured:
		return FAILED
	return OK
func transversion_files(paths: Array[String], target_v: String = Globals.V_ENTIRE) -> Error:
	var any_errors_occured: bool = false
	for path in paths:
		if transversion_file(path, target_v) != OK:
			any_errors_occured = true
	if any_errors_occured:
		return FAILED
	return OK

func transversion_chunk():
	pass
