extends Control


func _ready():
	get_node("TitleUI/GameNameTitle/RefreshSplashButton").pressed.connect(Globals.refresh_window_title.bind(true))
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
		 " " + Globals.GameInfo.NAME +
		"[/wave][/rainbow]" + 
		"[/center]"
	)
	return

func _update_corner_version_text():
	var corner_version_text_node: RichTextLabel = $TitleUI/HBoxContainer/VersionText
	if corner_version_text_node == null:
		push_error("Corner version text node not found.")
		return
	if Globals.GameInfo.VERSION == "-1":
		corner_version_text_node.text = "version unspecified"
	else:
		corner_version_text_node.text = "version " + Globals.GameInfo.VERSION
	return

func _update_welcome_message():
	var welcome_message_node: RichTextLabel = $TitleUI/WelcomeMessage
	if welcome_message_node == null:
		push_error("Welcome message text node reference was null.")
		return
	
	welcome_message_node.text = "[center]"
	welcome_message_node.text += "Welcome, " + Globals.this_player.displayname
	if Globals.this_player.username == "":
		welcome_message_node.text += "!\n(you are playing as a guest account.)"
	else:
		welcome_message_node.text += " (@" + Globals.this_player.username + ")"
	welcome_message_node.text += "[/center]"
	
	return
