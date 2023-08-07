extends Node

const game_version_phase: String = "1"
const game_version_major: String = "pregame"
const game_version_minor: String = "6"

func version_entire_string() -> String:
	return(game_version_phase + "." + game_version_major + "." + game_version_minor)


func _ready() -> void:
	# Ensure the global random number generator isn't the same every program execution.
	randomize()


func set_window_title():
	# Preemptively set the window's title, just in case something goes wrong with splash texts.
	DisplayServer.window_set_title("Hatchetflare - " + version_entire_string())
	# Attempt to open the splash texts file.
	var splash_texts_file = FileAccess
	if splash_texts_file.file_exists("res://assets/text_files/window_splash_texts.txt"):
		# Create an array of usable splash texts.
		splash_texts_file = FileAccess.open("res://assets/text_files/window_splash_texts.txt", FileAccess.READ)
		var line_number: int = 0
		var line_contents: String = ""
		var usable_splash_texts: Array[String] = []
		while (splash_texts_file.eof_reached() == false) :
			line_number += 1
			line_contents = splash_texts_file.get_line()
			if (not line_contents.begins_with("\t")) and (line_contents != ""):
				usable_splash_texts.append(line_contents)
		splash_texts_file.close()
		# Set the title to include a splash text, if the usable splash texts array has at least one item.
		if usable_splash_texts.is_empty():
			push_warning("The splash texts file was successfully accessed, but the resulting list of splashes is empty, so no splash text was used.")
		else:
			DisplayServer.window_set_title("Hatchetflare - " + version_entire_string() + " - " + usable_splash_texts[randi() % usable_splash_texts.size()])
	else:
		push_warning("The file for window splash texts was not found in the menu_main script, so no splash text was used.")

# Called every frame.
func _process(_delta):
	if Input.is_action_just_pressed("Fullscreen Toggle") :
		if (DisplayServer.window_get_mode() == 0):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
