extends Control

func open_screen(screen_name: String):
	for child in $Menus.get_children():
		child.visible = false
	get_node("Menus/" + screen_name).visible = true

func quit():
	get_tree().quit()
