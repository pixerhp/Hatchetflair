extends Node

# Ordered from oldest to newest, you should support transversioning between all released versions.
const supported_versions: PackedStringArray = [
	"1.1.0.0", # NOT YET TRANSVERSIONING SUPPORTED
	"1.2.0.0", # NOT YET TRANSVERSIONING SUPPORTED
]

func _ready():
	# (Reminder to implement proper transversioning support for each latest version.)
	assert(supported_versions.has(Globals.GameInfo.VERSION))

# "program files" refering to things like accounts, saved servers, meta information, etc.
func transversion_program_files(start_v: String, end_v: String) -> Error:
	
	
	return OK

func transversion_world(world_path: String, start_v: String, end_v: String) -> Error:
	
	
	return OK

func transversion_character(something, start_v: String, end_v: String) -> Error:
	
	
	return OK


# !!! revise pretty much all of this, have a const array of supported versions for transversioning.


## v stands for version.
## cv stands for "current version"/similar. (It is also sometimes used like "current version of/for".)
## to separate a v_entire into it's components, use `v_entire.split('.')`.
#
## Returns -1 if v1 < v2, 0 if v1 == v2, and 1 if v1 > v2.
#func compare_v_to_v(v1: String, v2: String) -> int:
	#var v1_components: PackedStringArray = v1.split('.')
	#var v2_components: PackedStringArray = v2.split('.')
	#if v1_components.size() > v2_components.size():
		#v2_components.resize(v1_components.size())
	#if v2_components.size() > v1_components.size():
		#v1_components.resize(v2_components.size())
	#
	#for i in v1_components.size():
		#if int(v1_components[i]) < int(v2_components[i]):
			#return -1
		#if int(v1_components[i]) > int(v2_components[i]):
			#return 1
	#return 0
#func compare_v_to_cv(version: String) -> int:
	#return compare_v_to_v(version, Globals.V_ENTIRE)
#
#func transversion_file(path: String, target_v: String = Globals.V_ENTIRE) -> Error:
	#match path:
		#FileManager.PATH_SERVERS:
			#match compare_v_to_v(FileManager.read_cfg_keyval(path, "meta", "version"), target_v):
				#-2:
					#return FAILED
				#-1:
					#if upversion_servers(target_v) != OK:
						#return FAILED
					#return OK
				#0:
					#return OK
				#1:
					#if downversion_servers(target_v) != OK:
						#return FAILED
					#return OK
		#FileManager.PATH_USERS:
			#match compare_v_to_v(FileManager.read_file_first_line(path), target_v):
				#-2:
					#return FAILED
				#-1:
					#if upversion_users(target_v) != OK:
						#return FAILED
					#return OK
				#0:
					#return OK
				#1:
					#if downversion_users(target_v) != OK:
						#return FAILED
					#return OK
		#var unrecognized_path:
			#push_error("Did not have code to transversion file at path: ", unrecognized_path)
			#return FAILED
	#return FAILED
#func transversion_files(paths: Array[String], target_v: String = Globals.V_ENTIRE) -> Error:
	#var any_errors_occured: bool = false
	#for path in paths:
		#if transversion_file(path, target_v) != OK:
			#any_errors_occured = true
	#if any_errors_occured:
		#return FAILED
	#return OK
#
#func upversion_servers(target_v: String) -> Error:
	#print("\"the parameter is not used\" Godot warning avoidance: ", target_v)
	#return OK
#func downversion_servers(target_v: String) -> Error:
	#print("\"the parameter is not used\" Godot warning avoidance: ", target_v)
	#return OK
#
#func upversion_users(target_v: String) -> Error:
	#print("\"the parameter is not used\" Godot warning avoidance: ", target_v)
	#return OK
#func downversion_users(target_v: String) -> Error:
	#print("\"the parameter is not used\" Godot warning avoidance: ", target_v)
	#return OK
#
#
#func transversion_chunk():
	#pass
