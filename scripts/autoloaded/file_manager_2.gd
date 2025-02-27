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
	
	const CFG_READ: String = ERRMSG_START + "cfg file read error" + ERRMSG_END

# ----------------------------------------------------------------

# Recursively delete (or only empty) a directory and all of it's contents.
func erase_dir(path: String, only_contents: bool, to_recycle_bin: bool) -> Error:
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

# ----------------------------------------------------------------

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
func get_region_from_cc(cc: Vector3i) -> Vector3i:
	return Vector3i(
		(cc[0] / 16) if (cc[0] >= 0) else (((cc[0] + 1) / 16) - 1),
		(cc[1] / 16) if (cc[1] >= 0) else (((cc[1] + 1) / 16) - 1),
		(cc[2] / 16) if (cc[2] >= 0) else (((cc[2] + 1) / 16) - 1),
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
