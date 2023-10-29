extends Node3D


func switch_to_main_menu():
	get_tree().change_scene_to_file("res://scenes/main_scenes/main_menu.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Toggle the pause menu if its associated key is pressed.
	# !!! [in the future, esc should also be able to close out of other things WITHOUT opening this menu.]
	if Input.is_action_just_pressed("Pause Menu"):
		$PauseMenu.visible = not $PauseMenu.visible

func _on_pausemenu_resumegameplay_pressed():
	# !!! Later, the game world may be actually paused by the pause-menu in singleplayer, unpause it here.
	$PauseMenu.visible = false
func _on_pausemenu_toggleplaying_pressed():
	pass
func _on_pausemenu_settings_pressed():
	$PauseMenu.visible = false
	$SettingsMenu.visible = true
	pass
func _on_pausemenu_saveandquit_pressed():
	# !!! Remember to SAVE and quit later.
	switch_to_main_menu()


func _on_settings_menu_back_to_menu():
	$SettingsMenu.visible = false
	$PauseMenu.visible = true
	pass # Replace with function body.
