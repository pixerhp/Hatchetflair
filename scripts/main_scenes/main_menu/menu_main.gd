extends Control


func switch_to_game_scene():
	get_tree().change_scene_to_file("res://scenes/main_scenes/game_scene.tscn")


# Makes visible one main menu screen after hiding all others.
func switch_to_menu(menu_name: String) -> void:
	for child_menu in $Menus.get_children():
		child_menu.visible = false
	var menu_to_make_visible = get_node("Menus/" + menu_name)
	if not menu_to_make_visible == null: # (Crash prevention.)
		menu_to_make_visible.visible = true
	else:
		push_error("Attempted to make visible a screen/menu child node which couldn't be found.")
	return

func _on_quit_button_pressed() -> void:
	Globals.quit_game()
	return

func _on_game_title_clicked() -> void:
	Globals._set_window_title(true)
	return

func _on_network_info_overlay_back_button_pressed(message: String, should_display: bool, show_back_button: bool) -> void:
	NetworkManager.network_status_update(message, should_display, show_back_button)
	return

func _on_close_settings_menu():
	switch_to_menu("TitleMenu")
	pass # Replace with function body.
