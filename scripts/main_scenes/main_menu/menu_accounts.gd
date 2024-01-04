extends Control

# !!! make meta not an allowed username for file reasons.
# !!! Remember to add/have serveral failsafes to prevent errors/attemtps to modify/delete the GUEST account.
# !!! Make it so that if a username is renamed, edit all files that use it for saving things accordingly.

var accounts: Dictionary = {}
var selector_index_to_username: Dictionary = {}


func _ready():
	_update_everything()
	# !!! make a specific account be chosen upon startup (the last saved one as stored in the program_meta file.)
	_on_account_option_button_item_selected(0)
	
	# !!! Reset all nodes to how they should be when you open the accounts menu.
	return
func _on_visibility_changed():
	if not is_node_ready():
		await ready
	
	# !!! Reset all nodes to how they should be when you open the accounts menu.
	return

func _update_everything():
	_update_accounts_from_file()
	_update_account_selector()
	_update_account_info_text()

func _update_accounts_from_file():
	accounts.clear()
	accounts = FileManager.read_cfg(FileManager.PATH_ACCOUNTS, ["meta"])
	return


### GENERAL SCREEN:

func _update_account_selector():
	var opening_texts: Array[String] = ["GUEST ACCOUNT", ""]
	var selector_texts: Array[String] = []
	for username in accounts.keys():
		selector_texts.append(str(username))
	Globals.sort_alphabetically(selector_texts)
	selector_texts = opening_texts + selector_texts
	selector_index_to_username.clear()
	for index in range(2,selector_texts.size()):
		selector_index_to_username[index] = selector_texts[index]
		selector_texts[index] = (
			"@" + selector_texts[index] + " - " + 
			Globals.dict_safeget(accounts, [selector_texts[index], "displayname"], FileManager.ERRMSG_CFG)
		)
	var selector_node: OptionButton = $GeneralScreen/VBoxContainer/HBoxContainer/MajorityVContainer/SelectButtonsHContainer/VBoxContainer/AccountSelector
	if selector_node == null:
		push_error("Account selector node not found.")
		return
	selector_node.clear()
	selector_node.add_item(selector_texts[0])
	selector_node.add_separator(selector_texts[1])
	for index in range(2,selector_texts.size()):
		selector_node.add_item(selector_texts[index])
	return
func _update_account_info_text():
	var account_info_text_node: RichTextLabel = $GeneralScreen/VBoxContainer/HBoxContainer/MajorityVContainer/VBoxContainer/TextAndButtonHContainer/AccountText
	if account_info_text_node == null:
		push_error("Account username and displayname text node not found.")
		return
	account_info_text_node.text = (
		"@username: " + Globals.player_username + "\n" +
		"displayname: " + Globals.player_displayname + "\n" +
		"creation date UTC: [date-time]" + "\n" +
		"last played UTC: [date-time]"
	)
	return

func _on_account_option_button_item_selected(index: int):
	if index < 2:
		Globals.player_username = "guest"
		Globals.player_displayname = "Guest"
	else:
		Globals.player_username = Globals.normalize_username_str(selector_index_to_username[index])
		Globals.player_displayname = Globals.dict_safeget(
			accounts, 
			[selector_index_to_username[index], "displayname"], 
			selector_index_to_username[index]
		)
	_update_account_info_text()
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
