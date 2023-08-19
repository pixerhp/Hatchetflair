extends Node

const game_name: String = "Hatchetflair"
const game_version_phase: String = "pre-game"
const game_version_engine: String = "1"
const game_version_major: String = "8"
const game_version_minor: String = "0"
const game_version_entire: String = game_version_phase + " v" + game_version_engine + "." + game_version_major + "." + game_version_minor
var all_global_stuff_initialized: bool = false

func _init() -> void:
	# Ensure the global random number generator isn't the same every program execution.
	randomize()
	
	# Set the windows title to include the game's name, the version, and a fun splash text if it loads right.
	set_window_title()
	
	# Some essential and example HF user directory content.
	create_essential_files()
	
	all_global_stuff_initialized = true


func set_window_title(optional_specified_title: String = ""):
	if not (optional_specified_title == ""):
		DisplayServer.window_set_title(optional_specified_title)
		return
	# Preemptively set the window's title, just in case something goes wrong with splash texts.
	DisplayServer.window_set_title(game_name + "   " + game_version_entire)
	# Attempt to open the splash texts file.
	if FileAccess.file_exists("res://assets/text_files/window_splash_texts.txt"):
		# Create an array of usable splash texts.
		var splash_texts_file = FileAccess
		splash_texts_file = FileAccess.open("res://assets/text_files/window_splash_texts.txt", FileAccess.READ)
		var line_contents: String = ""
		var usable_splash_texts: Array[String] = []
		while (splash_texts_file.eof_reached() == false):
			line_contents = splash_texts_file.get_line()
			if (not line_contents.begins_with("\t")) and (line_contents != ""):
				usable_splash_texts.append(line_contents)
		splash_texts_file.close()
		# Set the title to include a splash text, if the usable splash texts array has at least one item.
		if usable_splash_texts.is_empty():
			push_warning("The window title splash texts file was accessed successfully, but no useable splashes were found, so no splash text was used.")
		else:
			DisplayServer.window_set_title(game_name + "   " + game_version_entire + "   ---   " + usable_splash_texts[randi() % usable_splash_texts.size()])
	else:
		push_error("The file for window title splash-texts was not found, so no splash text was used.")

func create_essential_files():
	var file
	DirAccess.make_dir_absolute("user://storage")
	if not FileAccess.file_exists("user://storage/user_info.txt"):
		file = FileAccess.open("user://storage/user_info.txt", FileAccess.WRITE)
		file.store_line(game_version_entire)
		file.store_line("Pixer Pinecone")
		file.close()
	if not FileAccess.file_exists("user://storage/servers_list.txt"):
		file = FileAccess.open("user://storage/servers_list.txt", FileAccess.WRITE)
		file.store_line(game_version_entire)
		file.store_line("localhost 127.0.0.1")
		file.store_line("127.0.0.1")
		file.store_line("bad ip example")
		file.store_line("234534534.24653463.34534.547124325")
		file.close()
	DirAccess.make_dir_recursive_absolute("user://storage/worlds/world_1")
	DirAccess.make_dir_absolute("user://storage/worlds/world_1/chunks")
	file = FileAccess.open("user://storage/worlds/world_1/world_info.txt", FileAccess.WRITE)
	file.store_line(game_version_entire)
	file.store_line("date created: 2023-08-07T3:14:00")
	file.store_line("last played: unplayed")
	file.store_line("world generation seed: 314")
	file.close()
	if not FileAccess.file_exists("user://storage/worlds_list.txt"):
		print("(The worlds list was created/overwritten because it wasn't found.)")
		file = FileAccess.open("user://storage/worlds_list.txt", FileAccess.WRITE)
		file.store_line(game_version_entire)
		file.store_line("world_1") # the regular name of the world.
		file.store_line("world_1") # the name of the folder where the world is stored in.
		file.close()



# Called every frame.
func _process(_delta):
	if Input.is_action_just_pressed("Fullscreen Toggle") :
		if (DisplayServer.window_get_mode() == 0):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
