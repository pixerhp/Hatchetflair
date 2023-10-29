extends Control


func switch_to_game_scene():
	get_tree().change_scene_to_file("res://scenes/main_scenes/game_scene.tscn")


# Opens one of the titlescreen menus after hiding all of the others.
func switch_to_menu(menu_name: String) -> void:
	for child_menu in $Menus.get_children():
		child_menu.visible = false
	get_node("Menus/" + menu_name).visible = true
	return

func _on_quit_button_pressed() -> void:
	Globals.quit_game()
	return

func _on_network_info_overlay_back_button_pressed(message: String, should_display: bool, show_back_button: bool) -> void:
	NetworkManager.network_status_update(message, should_display, show_back_button)
	return


func _on_settings_menu_back_to_menu():
	switch_to_menu("TitleMenu")
	pass # Replace with function body.
