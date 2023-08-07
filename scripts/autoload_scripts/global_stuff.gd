extends Node

const game_version_phase: String = "1"
const game_version_major: String = "pre-game"
const game_version_minor: String = "6"
const game_version_entire: String = game_version_phase + "." + game_version_major + "." + game_version_minor


func _ready() -> void:
	# Ensure the global random number generator isn't the same every program execution.
	randomize()
	
	# Set the windows title to include the game's name, the version, and a fun splash text if it loads right.
	set_window_title()


func set_window_title(optional_specified_title: String = ""):
	if not (optional_specified_title == ""):
		DisplayServer.window_set_title(optional_specified_title)
		return
	# Preemptively set the window's title, just in case something goes wrong with splash texts.
	DisplayServer.window_set_title("Hatchetflare   v" + game_version_entire)
	# Attempt to open the splash texts file.
	var splash_texts_file = FileAccess
	if splash_texts_file.file_exists("res://assets/text_files/window_splash_texts.txt"):
		# Create an array of usable splash texts.
		splash_texts_file = FileAccess.open("res://assets/text_files/window_splash_texts.txt", FileAccess.READ)
		var line_contents: String = ""
		var usable_splash_texts: Array[String] = []
		while (splash_texts_file.eof_reached() == false) :
			line_contents = splash_texts_file.get_line()
			if (not line_contents.begins_with("\t")) and (line_contents != ""):
				usable_splash_texts.append(line_contents)
		splash_texts_file.close()
		# Set the title to include a splash text, if the usable splash texts array has at least one item.
		if usable_splash_texts.is_empty():
			push_warning("The window title splash texts file was accessed successfully, but no useable splashes were found, so no splash text was used.")
		else:
			DisplayServer.window_set_title("Hatchetflare   v" + game_version_entire + "   ---   " + usable_splash_texts[randi() % usable_splash_texts.size()])
	else:
		push_warning("The file for window title splash texts was not found, so no splash text was used.")



# Called every frame.
func _process(_delta):
	if Input.is_action_just_pressed("Fullscreen Toggle") :
		if (DisplayServer.window_get_mode() == 0):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
