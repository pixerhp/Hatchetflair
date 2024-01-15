extends Control

# !!! make meta and guest not allowed usernames for file reasons.
# !!! Remember to add/have serveral failsafes to prevent errors/attemtps to modify/delete the GUEST account.
# !!! Make it so that if a username is renamed, edit all files that use it for saving things accordingly.

var accounts: Dictionary = {}
var selector_index_to_username: Dictionary = {}


func _switch_to_screen(screen_node_name: String):
	var node_to_make_visible: Node = get_node(screen_node_name)
	if node_to_make_visible == null:
		push_error("Child node named \"", screen_node_name, "\" not found.")
		return
	
	_reset_node_visibilities()
	for child_node in self.get_children():
		child_node.visible = false
	node_to_make_visible.visible = true
	return

func _ready():
	_update_everything()
	_select_remembered_last_selected_account()
	_reset_node_visibilities()
	_switch_to_screen("GeneralScreen")
	return

func _on_visibility_changed():
	if not is_node_ready():
		await ready
	_reset_node_visibilities()
	_switch_to_screen("GeneralScreen")
	return

func _update_everything():
	_update_accounts_from_file()
	_update_account_selector()
	_update_account_info_text()
	_update_manage_account_button_disabledness()

func _reset_node_visibilities():
	_update_account_info_text() # If the account info text should be reset when the change displayname stuff is hidden.
	account_info_right_spacer_node.visible = true
	change_displayname_button.visible = true
	change_displayname_container.visible = false

func _update_accounts_from_file():
	accounts.clear()
	accounts = FileManager.read_cfg(FileManager.PATH_ACCOUNTS, ["meta"])
	return

func _select_remembered_last_selected_account():
	var last_selected_account_username = FileManager.read_cfg_keyval(
		FileManager.PATH_ACCOUNTS,
		"meta",
		"last_selected_account_username",
		"guest",
	)
	var index_of_last_selected_username = selector_index_to_username.find_key(last_selected_account_username)
	if index_of_last_selected_username == null:
		_on_account_option_button_item_selected(0)
	else:
		_on_account_option_button_item_selected(index_of_last_selected_username)



### GENERAL SCREEN:
@onready var account_selector_node: OptionButton = $GeneralScreen/VBoxContainer/HBoxContainer/MajorityVContainer/SelectButtonsHContainer/VBoxContainer/AccountSelector
@onready var account_info_text_node: RichTextLabel = $GeneralScreen/VBoxContainer/HBoxContainer/MajorityVContainer/VBoxContainer/TextAndButtonHContainer/AccountText
@onready var account_info_right_spacer_node: Node = $GeneralScreen/VBoxContainer/HBoxContainer/MajorityVContainer/VBoxContainer/TextAndButtonHContainer/SpacerMiddle
@onready var manage_account_button_node: Button = $GeneralScreen/VBoxContainer/HBoxContainer/MajorityVContainer/SelectButtonsHContainer/VBoxContainer/ButtonsHContainer/ManageAccountButton
@onready var manage_account_choice_popup: PopupMenu = $GeneralScreen/VBoxContainer/HBoxContainer/MajorityVContainer/SelectButtonsHContainer/VBoxContainer/ButtonsHContainer/ManageAccountButton/ManageAccountPopup
@onready var change_displayname_button: Button = $GeneralScreen/VBoxContainer/HBoxContainer/MajorityVContainer/VBoxContainer/TextAndButtonHContainer/ChangeDisplaynameButton
@onready var change_displayname_container: HBoxContainer = $GeneralScreen/VBoxContainer/HBoxContainer/MajorityVContainer/VBoxContainer/ChangeDisplaynameNodes

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
	if account_selector_node == null:
		push_error("Account selector node not found.")
		return
	account_selector_node.clear()
	account_selector_node.add_item(selector_texts[0])
	account_selector_node.add_separator(selector_texts[1])
	for index in range(2,selector_texts.size()):
		account_selector_node.add_item(selector_texts[index])
	return
func _update_account_info_text():
	if account_info_text_node == null:
		push_error("Account username and displayname text node not found.")
		return
	account_info_text_node.text = (
		"@username: " + Globals.player_username + "\n" +
		"displayname: " + Globals.player_displayname
	)
	return
func _update_manage_account_button_disabledness():
	if account_selector_node.selected < 2:
		manage_account_button_node.disabled = true
	else:
		manage_account_button_node.disabled = false
	return

func _on_account_option_button_item_selected(index: int):
	account_selector_node.select(index)
	if index < 2:
		Globals.player_username = "guest"
		Globals.player_displayname = FileManager.read_cfg_keyval(
			FileManager.PATH_ACCOUNTS, 
			"meta", 
			"guest_displayname", 
			"Guest"
		)
		FileManager.write_cfg_keyval(
			FileManager.PATH_ACCOUNTS, 
			"meta", 
			"last_selected_account_username", 
			"guest",
		)
	else:
		Globals.player_username = Globals.normalize_username_str(selector_index_to_username[index])
		Globals.player_displayname = Globals.dict_safeget(
			accounts, 
			[selector_index_to_username[index], "displayname"], 
			selector_index_to_username[index]
		)
		FileManager.write_cfg_keyval(
			FileManager.PATH_ACCOUNTS, 
			"meta", 
			"last_selected_account_username", 
			selector_index_to_username[index],
		)
	_update_account_info_text()
	_update_manage_account_button_disabledness()
	_reset_node_visibilities()
	return

func _on_manage_account_button_pressed():
	if account_selector_node.selected < 2:
		return
	# Get the setup the popuop node used for choosing which way you want to manage the account.
	if manage_account_choice_popup == null:
		push_error("Couldn't find the manage account choice popup node.")
		return
	manage_account_choice_popup.position = manage_account_choice_popup.get_parent().global_position
	manage_account_choice_popup.visible = true
	return
func _on_manage_account_popup_index_pressed(index):
	match index:
		0:
			_switch_to_screen("ViewMoreAccountInfoScreen")
		1:
			_switch_to_screen("RenameUsernameScreen")
		2:
			_switch_to_screen("DeleteAccountScreen")
		_:
			push_error("Manage account popup had an item with index ", index," pressed which did not have a defined behavior.")
	return

func _on_change_displayname_button_pressed():
	if change_displayname_container == null:
		push_error("Could not find change-displayname nodes container node.")
		return
	change_displayname_container.visible = true
	if change_displayname_button == null:
		push_error("Could not find change-displayname button node.")
		return
	change_displayname_button.visible = false
	
	if account_info_text_node == null:
		push_error("Account username and displayname text node not found.")
		return
	account_info_text_node.text = (
		"[center]" + 
		"current displayname:\n" + 
		Globals.player_displayname + 
		"[/center]"
	)
	if account_info_right_spacer_node == null:
		push_error("Account info spacer node not found.")
		return
	account_info_right_spacer_node.visible = false
	return
func _on_change_displayname_cancel_button():
	if change_displayname_container == null:
		push_error("Could not find change-displayname nodes container node.")
		return
	change_displayname_container.visible = false
	if change_displayname_button ==  null:
		push_error("Could not find change-displayname button node.")
		return
	change_displayname_button.visible = true
	change_displayname_container.get_node("DisplaynameInput").text = ""
	if account_info_right_spacer_node == null:
		push_error("Account info spacer node not found.")
		return
	account_info_right_spacer_node.visible = true
	_update_account_info_text()
	return
func _on_change_displayname_confirm_button():
	var new_displayname_text: String = change_displayname_container.get_node("DisplaynameInput").text
	if new_displayname_text.is_empty():
		return
	Globals.player_displayname = new_displayname_text
	if Globals.player_username == "guest":
		FileManager.write_cfg_keyval(
			FileManager.PATH_ACCOUNTS, 
			"meta",
			"guest_displayname",
			Globals.player_displayname,
		)
	else:
		FileManager.write_cfg_keyval(
			FileManager.PATH_ACCOUNTS, 
			Globals.player_username,
			"displayname",
			Globals.player_displayname,
		)
	_update_everything()
	change_displayname_container.visible = false
	change_displayname_button.visible = true
	change_displayname_container.get_node("DisplaynameInput").text = ""
	return



### VIEW ADVANCED ACCOUNT INFO SCREEN:
@onready var advanced_account_info_text_node: RichTextLabel = $ViewMoreAccountInfoScreen/VBoxContainer/HBoxContainer/PanelContainer/MarginContainer/AboutAccountsText

func _update_advanced_account_info_text():
	if $ViewMoreAccountInfoScreen.visible == false:
		return
	
	_update_accounts_from_file()
	
	advanced_account_info_text_node.text = ""
	
	if not (Globals.player_username == selector_index_to_username[account_selector_node.selected]):
		advanced_account_info_text_node.text += (
			"[color=#ff7373]" +
			"player username currently stored in globals does not match username currently selected by account selector. please report this as a bug to developers." + "\n\n" +
			"for the following advanced account information, the account associated with the globally stored username will be used." + "\n\n" + 
			"[/color]"
		)
	
	advanced_account_info_text_node.text += (
		"[color=lightgray]accounts file location >> [/color]" +
		"[color=greenyellow]" + ProjectSettings.globalize_path(FileManager.PATH_ACCOUNTS) + "[/color]" + "\n" +
		"[color=darkgray](displaying all stored information about account from file:)[/color]" + "\n\n" +
		"[color=lightgray]username >> [/color]" + Globals.player_username + "\n"
	)
	if accounts.has(Globals.player_username):
		for key in accounts[Globals.player_username].keys():
			advanced_account_info_text_node.text += (
				"[color=lightgray]" + str(key) + " >> [/color]" + 
				accounts[Globals.player_username][key] + "\n"
			)
	else:
		advanced_account_info_text_node.text += (
			"[color=#ff7373]account information under this username does not exist in file. showing all file contents:[/color]" + "\n\n\n"
		)
		for username in accounts.keys():
			advanced_account_info_text_node.text += ("[color=lightgray]username >> [/color]" + username + "\n")
			for key in accounts[username].keys():
				advanced_account_info_text_node.text += ("[color=lightgray]" + str(key) + " >> [/color]" + accounts[username][key] + "\n")
			advanced_account_info_text_node.text += "\n"
	return



### CREATE NEW ACCOUNT SCREEN:
@onready var create_account_username_input_node: TextEdit = $CreateNewAccountScreen/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/UsernameInput
@onready var create_account_displayname_input_node: TextEdit = $CreateNewAccountScreen/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/DisplaynameInput
@onready var create_account_warning_text_node: RichTextLabel = $CreateNewAccountScreen/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/WarningMargin/WarningText
@onready var create_account_confirm_button: Button = $CreateNewAccountScreen/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/ButtonsHContainer/ConfirmButton

func _on_create_new_account_screen_visibility_changed():
	if not is_node_ready():
		await ready
	# Clears the typed text whenever you close out or open the account creation screen.
	create_account_username_input_node.text = ""
	create_account_displayname_input_node.text = ""
	_update_create_account_warning_and_confirm_button()
	return

func _update_create_account_warning_and_confirm_button():
	var warning: String = ""
	var username: String = create_account_username_input_node.text
	var displayname: String = create_account_displayname_input_node.text
	
	# Username warnings:
	if username.length() < 1:
		if not warning.is_empty(): warning += "\n"
		warning += "username may not be blank"
	if username.length() > 32:
		if not warning.is_empty(): warning += "\n"
		warning += "username may not exceed 32 characters (" + str(username.length()) + ")"
	if (username == "meta") or (username == "guest"):
		if not warning.is_empty(): warning += "\n"
		warning += "username cannot be \"meta\" or \"guest\""
	if accounts.has(username):
		if not warning.is_empty(): warning += "\n"
		warning += "account with username already exists"
	
	# Displayname warnings:
#	if displayname.length() < 1:
#		if not warning.is_empty(): warning += "\n"
#		warning += "displayname may not be blank"
	if displayname.length() > 64:
		if not warning.is_empty(): warning += "\n"
		warning += "displayname may not exceed 64 characters (" + str(displayname.length()) + ")"
	
	create_account_warning_text_node.text = warning
	create_account_warning_text_node.get_parent().visible = not warning.is_empty()
	create_account_confirm_button.disabled = not warning.is_empty()
	return

func _on_create_account_username_input_text_changed():
	create_account_username_input_node.text = Globals.normalize_username_str(create_account_username_input_node.text)
	create_account_username_input_node.set_caret_column(create_account_username_input_node.text.length())
	_update_create_account_warning_and_confirm_button()
	return
func _on_create_account_displayname_input_text_changed():
	_update_create_account_warning_and_confirm_button()
	return

func _on_create_account_confirm_button_pressed():
	# !!! make safer / more robust against accidentally destroying the file contents if something goes wrong?
	_update_accounts_from_file()
	_update_create_account_warning_and_confirm_button()
	if create_account_confirm_button.disabled == true:
		return
	
	var username: String = Globals.normalize_username_str(create_account_username_input_node.text)
	var displayname: String = create_account_displayname_input_node.text
	FileManager.create_account(username, displayname)
	
	_update_everything()
	_select_remembered_last_selected_account()
	_switch_to_screen("GeneralScreen")
	return



### DELETE ACCOUNT SCREEN:
@onready var delete_account_retype_text_node: RichTextLabel = $DeleteAccountScreen/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/RetypeText
@onready var deletion_retype_string: String = "<NOT YET LOADED>"
@onready var deletion_retype_input_node: TextEdit = $DeleteAccountScreen/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/RetypeInput
@onready var delete_account_warning_text_node: RichTextLabel = $DeleteAccountScreen/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/WarningMargin/WarningText
@onready var delete_account_confirm_button: Button = $DeleteAccountScreen/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/BottomButtons/ConfirmButton

func _on_delete_account_screen_visibility_changed():
	_randomize_delete_account_copy_text()
	_update_delete_account_warning_and_confirm_button()
	return

func _randomize_delete_account_copy_text():
	deletion_retype_string = "%x" % abs(Globals.rand_int())
	delete_account_retype_text_node.text = "[center]" + "retype text: " + deletion_retype_string + "[/center]"
	deletion_retype_input_node.text = ""
	return

func _update_delete_account_warning_and_confirm_button():
	var warning: String = ""
	
	if not deletion_retype_input_node.text == deletion_retype_string:
		if not warning.is_empty(): warning += "\n"
		warning += "input text does not match provided retype string"
	
	delete_account_warning_text_node.text = warning
	delete_account_warning_text_node.get_parent().visible = not warning.is_empty()
	delete_account_confirm_button.disabled = not warning.is_empty()
	pass

func _on_delete_account_confirm_button_pressed():
	if account_selector_node.selected < 2:
		return
	var username: String = selector_index_to_username[account_selector_node.selected]
	if not accounts.has(username):
		push_error("Attempting to delete a username not contained in the accounts dictionary var. (Attempting anyway.)")
	FileManager.delete_account(username)
	_update_everything()
	_select_remembered_last_selected_account()
	_switch_to_screen("GeneralScreen")
	return
