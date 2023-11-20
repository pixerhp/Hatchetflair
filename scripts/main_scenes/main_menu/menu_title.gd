extends Control


func _ready():
	_refresh_texts()
	return
func _refresh_texts():
	_update_corner_version_text()
	_update_welcome_message()
	return

func _update_corner_version_text():
	var corner_version_text_node: RichTextLabel = $TitleUI/HBoxContainer/VersionText
	if corner_version_text_node == null:
		push_error("Corner version text node not found.")
		return
	corner_version_text_node.text = "v" + Globals.V_ENTIRE
	return
func _update_welcome_message():
	var welcome_message_node: RichTextLabel = $TitleUI/WelcomeMessage
	if welcome_message_node == null:
		push_error("Welcome message text node not found.")
		return
	if not Globals.player_username == "GUEST":
		welcome_message_node.text = (
			"[center][wave]" +
			"Welcome, " + 
			Globals.player_displayname + " (@" + Globals.player_username + ")" +
			"[/wave][/center]" )
	else:
		welcome_message_node.text = (
			"[center][wave]" +
			"Welcome, " + 
			Globals.player_displayname + " (@" + Globals.player_username + ")" +
			"\n(you are playing as a GUEST account.)" +
			"[/wave][/center]" )
	return


func _on_game_title_clicked() -> void:
	Globals._set_window_title(true)
	return
