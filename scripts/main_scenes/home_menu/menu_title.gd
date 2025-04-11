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
	var node: RichTextLabel = %TitlescreenVersionText
	if node == null:
		push_error("Node for displaying titlescreen version text was not found.")
		return
	if Globals.GameInfo.VERSION == "-1":
		node.text = "version unspecified"
	else:
		node.text = "version " + Globals.GameInfo.VERSION
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

func _on_open_files_button_pressed():
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path(FM.PATH.USER.ROOT))
	return
