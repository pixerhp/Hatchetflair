extends Control


# Opens one of the titlescreen menus and hides all of the others.
func switch_to_menu(menu_name: String) -> void:
	for child_menu in $Menus.get_children():
		child_menu.visible = false
	get_node("Menus/" + menu_name).visible = true
	return

func _on_quit_button_pressed() -> void:
	GlobalStuff.quit_game()
	return

func _on_network_info_overlay_back_button_pressed(message: String, should_display: bool, show_back_button: bool) -> void:
	NetworkManager.network_status_update(message, should_display, show_back_button)
	return
