extends Node

class PATH:
	# Full paths:
	class RES:
		const ROOT: String = "res://"
		const ASSETS: String = ROOT + "assets"
		const SPLASHES: String = ASSETS + "/splash_texts"
	class USER:
		const ROOT: String = "user://"
		const STORAGE: String = ROOT + "storage"
		const WORLDS: String = STORAGE + "/worlds"
	
	# Partial paths:
	class PARTIAL:
		const SC: String = "sc" # for static chunks related data.
		const MCG: String = "mcg" # for mobile chunks groups related data.

class ERRMSG:
	const ERRMSG_START: String = "<< "
	const ERRMSG_END: String = " >>"
	static func form(message: String, start: String = "", end: String = "") -> String:
		return ERRMSG_START + start + message + end + ERRMSG_END
	static func form_colon(message: String, attach: String) -> String:
		return ERRMSG_START + message + ": " + attach + ERRMSG_END
	
	const CFG_READ: String = "cfg file read error"
	const DIR_NOT_FOUND: String = "directory wasn't found or doesn't exist"
	const FILE_NOT_FOUND: String = "file wasn't found or doesn't exist"
	const FILE_ACCESS_ERROR: String = "file access error"

## ----------------------------------------------------------------

# Recursively delete (or only empty) a directory and all of it's contents.
func erase_dir(path: String, only_contents: bool, to_recycle_bin: bool) -> Error:
	if not DirAccess.dir_exists_absolute(path):
		push_error(FM.ERRMSG.form_colon(FM.ERRMSG.DIR_NOT_FOUND, path))
		return FAILED
	if to_recycle_bin:
		if not only_contents:
			return OS.move_to_trash(ProjectSettings.globalize_path(path))
		else:
			var err: Error = OK
			for dir in DirAccess.get_directories_at(path):
				if OS.move_to_trash(ProjectSettings.globalize_path(path.path_join(dir))) != OK:
					err = FAILED
			for file in DirAccess.get_files_at(path):
				if OS.move_to_trash(ProjectSettings.globalize_path(path.path_join(file))) != OK:
					err = FAILED
			return err
	else:
		var err: Error = OK
		for dir in DirAccess.get_directories_at(path):
			if erase_dir(path.path_join(dir), false, false) != OK:
				err = FAILED
		for file in DirAccess.get_files_at(path):
			if DirAccess.remove_absolute(path.path_join(file)) != OK:
				err = FAILED
		if not only_contents:
			if DirAccess.remove_absolute(path) != OK:
				err = FAILED
		return err

# Use DirAccess.rename() for simply renaming/moving a directory rather than copying it.
func copy_dir_into_dir(
	source: String, # Path of the directory to be copied.
	target: String, # Path of the directory to be copied into, will be created if it doesn't exist.
	insert_source_dir_name: bool, # Copy the source dir itself into target, instead of just its contents.
	empty_target: bool, # If the target (including insertion) already exists, empty its contents first.
	to_recycle_bin: bool, # If any directories/files get deleted, send them to the recycle bin.
) -> Error:
	if not DirAccess.dir_exists_absolute(source):
		push_error(FM.ERRMSG.form_colon(FM.ERRMSG.DIR_NOT_FOUND, source))
		return FAILED
	# If the source directory folder itself needs to be copied, alter the target path accordingly.
	if insert_source_dir_name:
		target = target.path_join(source.erase(0, source.rfind("/") + 1))
	# Ensure that the target directory exists, and be empty if requested.
	if DirAccess.dir_exists_absolute(target):
		if empty_target:
			# (The copy is attempted regardless of whether this fails.)
			erase_dir(target, true, to_recycle_bin)
	else:
		if DirAccess.make_dir_recursive_absolute(target) != OK:
			return FAILED
	# Do the file/directory copying.
	var err: Error = OK
	for file in DirAccess.get_files_at(source):
		if DirAccess.copy_absolute(source.path_join(file), target.path_join(file)) != OK:
			err = FAILED
	for dir in DirAccess.get_directories_at(source):
		if copy_dir_into_dir(
			source.path_join(dir), target.path_join(dir), false, false, to_recycle_bin,
		) != OK:
			err = FAILED
	return err

func get_dir_size(path: String, attempt_os_ask: bool = true) -> int:
	if not DirAccess.dir_exists_absolute(path):
		push_error(FM.ERRMSG.form_colon(FM.ERRMSG.DIR_NOT_FOUND, path))
		return 0
	
	# Try getting the filesize quickly using the OS.
	if attempt_os_ask:
		match OS.get_name():
			"Windows":
				var output: Array = []
				var err: int = OS.execute("powershell.exe", [
					"/C", "\"ls -r " + ProjectSettings.globalize_path(path) + "|measure -sum length\""
				], output, false, false)
				if (err == 0) and (not (output.is_empty() or (output == [""]))):
					return output[0].split("Sum")[1].split("\n")[0].to_int()
			"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
				var output: Array = []
				var err: int = OS.execute("du", [
					"-csb", ProjectSettings.globalize_path(path)
				], output, false, true)
				if (err == 0) and (not output.is_empty()):
					return output[0].split("\t")[0].to_int()
	
	# Fallback method which opens and checks the length of each file one-by-one.
	var total: int = 0
	for file in DirAccess.get_files_at(path):
		total += get_file_size(path.path_join(file))
	for dir in DirAccess.get_directories_at(path):
		total += get_dir_size(path.path_join(dir), false)
	return total

func get_file_size(path: String) -> int:
	if not FileAccess.file_exists(path):
		push_error(FM.ERRMSG.form_colon(FM.ERRMSG.FILE_NOT_FOUND, path))
		return FAILED
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if FileAccess.get_open_error() != OK:
		push_error(FM.ERRMSG.form_colon(FM.ERRMSG.FILE_ACCESS_ERROR, str(FileAccess.get_open_error())))
		return 0
	return file.get_length()

## ----------------------------------------------------------------

func get_region_from_cc(cc: Vector3i) -> Vector3i:
	return Vector3i(
		(cc[0] / 16) if (cc[0] >= 0) else (((cc[0] + 1) / 16) - 1),
		(cc[1] / 16) if (cc[1] >= 0) else (((cc[1] + 1) / 16) - 1),
		(cc[2] / 16) if (cc[2] >= 0) else (((cc[2] + 1) / 16) - 1),
	)
func get_filepath_for_chunkdata(
	cc: Vector3i,
	is_mobile: bool,
	group_id: String = "",
	world_name: String = WorldUtils.world_name,
) -> String:
	var region: Vector3i = get_region_from_cc(cc)
	return (
		FM.PATH.USER.WORLDS + "/" + world_name.validate_filename() + "/" + ((
			FM.PATH.PARTIAL.MCG + "/" + group_id.validate_filename()
		) if is_mobile else (
			FM.PATH.PARTIAL.SC
		)) + "/" + str(region[0]) + "_" + str(region[1]) + "_" + str(region[2]) + ".hfcr"
	)

# NOTE: In general, use the static/mobile chunk group functions which call this one instead.
func save_chunk(
	chunk: WorldUtils.Chunk,
	is_mobile: bool,
	group_id: String = "",
) -> Error:
	if not group_id.is_valid_filename():
		push_warning("Group identifier contained disallowed filename characters, ",
		"chunk will be saved under altered group id.")
	var region_filepath: String = get_filepath_for_chunkdata(chunk.cc, is_mobile, group_id)
	
	# !!!
	
	return OK

#func load_chunk(
	#
#)
