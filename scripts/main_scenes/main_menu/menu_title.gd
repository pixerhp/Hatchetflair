extends Control


func _ready():
	_refresh_texts()
	return
func _refresh_texts():
	_update_title_text()
	_update_corner_version_text()
	_update_welcome_message()
	return

func _update_title_text():
	var node: RichTextLabel = $TitleUI/GameNameTitle
	if node == null:
		push_error("Game title text node not found.")
		return
	node.text = (
		"[center]" + 
		"[img=center,center]" + "res://assets/icons/hatchetflair/v2/hf_v2.png" + "[/img]" +
		"[rainbow freq=0.01 sat=0.8 val=1.0 speed=-1.2][wave freq=-2 amp=60]" +
		 " " + Globals.GAME_NAME +
		"[/wave][/rainbow]" + 
		"[/center]"
	)
	return

func _update_corner_version_text():
	var corner_version_text_node: RichTextLabel = $TitleUI/HBoxContainer/VersionText
	if corner_version_text_node == null:
		push_error("Corner version text node not found.")
		return
	corner_version_text_node.text = "v" + Globals.V_ENTIRE + (" [v_indev]" if Globals.IS_VERSION_INDEV else "")
	return

func _update_welcome_message():
	var welcome_message_node: RichTextLabel = $TitleUI/WelcomeMessage
	if welcome_message_node == null:
		push_error("Welcome message text node not found.")
		return
	
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
	Globals._refresh_window_title(true)
	return
