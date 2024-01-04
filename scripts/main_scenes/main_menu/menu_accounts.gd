extends Control

# !!! Remember to add/have serveral failsafes to prevent errors/attemtps to modify/delete the GUEST account.
# !!! Make it so that if a username is renamed, edit all files that use it for saving things accordingly.

func _ready():
	# !!! Reset all nodes to how they should be when you open the accounts menu.
	return

func _on_visibility_changed():
	# check if the node isn't ready yet, this will circumstantially fire before _ready() causing issues.
	# !!! Reset all nodes to how they should be when you open the accounts menu.
	return


func _update_account_info_text():
	var account_info_text_node: RichTextLabel #= $VBoxContainer/AccountNamesText
	if account_info_text_node == null:
		push_error("Account username and displayname text node not found.")
		return
	account_info_text_node.text = (
		"[center]" +
		"Account username: " + Globals.player_username + "\n" +
		"Account displayname: " + Globals.player_displayname + "\n" +
		"Account creation date UTC: [date]" +
		"[/center]" )
	return


func _on_account_option_button_item_selected(index: int):
#	Globals.player_username = account_selector_node.get_item_text(index)
#	Globals.player_displayname = "[" + Globals.player_username + "'s displayname]"
#	_update_account_info_text()
	return

func _on_create_account_button_pressed():
	return

func _on_manage_account_button_pressed():
	# Get the setup the popuop node used for choosing which way you want to manage the account.
	var choice_popup: PopupMenu = $VBoxContainer/HBoxContainer/VBoxContainermore/AccountSelectContainer/VBoxContainer/AccountButtonsContainer/ManageAccount/PopupMenu
	if choice_popup == null:
		push_error("Could not find manage-account managing-type-selection popup.")
		return
	choice_popup.position = choice_popup.get_parent().global_position
	choice_popup.visible = true
	return

func _on_change_displayname_button_pressed():
	var change_display_container: HBoxContainer #= $VBoxContainer/HBoxContainer/VBoxContainermore/VBoxContainer/HBoxContainer2
	if change_display_container == null:
		push_error("Could not find the container node of new displayname entry nodes.")
		return
	change_display_container.visible = not change_display_container.visible
	return



#	var formatted_username: String = Globals.normalize_username_str(
#		account_popup_contents.get_node("UsernameInput").text)
#	account_popup_contents.get_node("UsernameInput").text = formatted_username
#	account_popup_contents.get_node("UsernameInput").set_caret_column(formatted_username.length())
