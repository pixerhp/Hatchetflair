extends Control


func _ready():
	pass

func _on_account_option_button_item_selected(selected_index: int):
	# !!! since a new account was selected from the dropdown, 
	# refresh everything that that should affect accordingly.
	print("selected account with index: ", selected_index)
	pass

func _on_add_account_pressed():
	pass
func _on_edit_account_pressed():
	pass

func _on_edit_displayname_pressed():
	pass
