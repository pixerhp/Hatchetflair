extends Control


func _ready():
	_refresh_texts()
	return
func _refresh_texts():
	_update_corner_version_text()
	_update_welcome_message()
	return

func _update_corner_version_text():
	# Find the text node.
	var corner_version_text_node: RichTextLabel = $TitleUI/HBoxContainer/VersionText
	if corner_version_text_node == null:
		push_error("Corner version text node not found.")
		return
	
	corner_version_text_node.text = "v" + Globals.V_ENTIRE
	return

func _update_welcome_message():
	# Find the text node that displays the welcome message.
	var welcome_message_node: RichTextLabel = $TitleUI/WelcomeMessage
	if welcome_message_node == null:
		push_error("Welcome message text node not found.")
		return
	
	# Set up the titlescreen's user welcome message.
	welcome_message_node.text = (
		"[center]" +
		"Welcome, " + 
		Globals.player_displayname + " (@" + Globals.player_username + ")"
	)
	if Globals.player_username == "guest":
		welcome_message_node.text += "\n(you are playing on a guest account.)"
	welcome_message_node.text += "[/center]"
	
	return


func _on_game_title_clicked() -> void:
	Globals._set_window_title(true)
	return
