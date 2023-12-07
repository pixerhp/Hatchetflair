extends Control

# Add/Edit account popup nodes:
@onready var general_menu_nodes_container: Control = $VBoxContainer
@onready var account_popup_node: Control = $AccountPopup
@onready var account_popup_contents: Control = $AccountPopup/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer
@onready var account_popup_titletext_node: Control = account_popup_contents.get_node("PopupTitleText")
@onready var account_popup_usernameinput_node: Control = account_popup_contents.get_node("UsernameInput")
@onready var account_popup_cancelbutton_node: Control = account_popup_contents.get_node("Buttons/Cancel")
@onready var account_popup_confirmbutton_node: Control = account_popup_contents.get_node("Buttons/Confirm")


func _ready():
	_update_account_names_text()
	_update_edit_account_button_disabledness()
	general_menu_nodes_container.visible = true
	account_popup_node.visible = false
	return

func _update_account_names_text():
	var account_names_text_node: RichTextLabel = $VBoxContainer/AccountNamesText
	if account_names_text_node == null:
		push_error("Account username and displayname text node not found.")
		return
	account_names_text_node.text = (
		"[center]" +
		"Account username: " + Globals.player_username + "\n" +
		"Account displayname: " + Globals.player_displayname +
		"[/center]" )
	return
func _update_edit_account_button_disabledness():
	var edit_account_button_node: Button = $VBoxContainer/AccountButtonsContainer/EditAccount
	var account_select_node: OptionButton = $VBoxContainer/AccountSelectContainer/AccountSelect
	if (edit_account_button_node == null) or (account_select_node == null):
		push_error("At least one of two nodes not found.")
		return
	return


func _on_account_option_button_item_selected(index_of_selected: int):
	_update_edit_account_button_disabledness()
	
	var account_select_node: OptionButton = $VBoxContainer/AccountSelectContainer/AccountSelect
	if account_select_node == null:
		push_error("Account select option-button node not found.")
		return
	Globals.player_username = account_select_node.get_item_text(index_of_selected)
	Globals.player_displayname = "[" + Globals.player_username + "'s displayname]"
	_update_account_names_text()
	return

func _on_add_account_pressed():
	account_popup_titletext_node.text = "[center]Enter new account username and displayname.[/center]"
	account_popup_contents.get_node("UsernameInput").text = ""
	account_popup_contents.get_node("DisplaynameInput").text = ""
	account_popup_contents.get_node("UsernameInput").visible = true
	account_popup_node.visible = true
	general_menu_nodes_container.visible = false
func _on_edit_account_pressed():
	var account_select_node: OptionButton = $VBoxContainer/AccountSelectContainer/AccountSelect
	if account_select_node == null:
		push_error("Account select option-button node not found.")
		return
	account_popup_contents.get_node("UsernameInput").text = ""
	account_popup_contents.get_node("DisplaynameInput").text = ""
	if account_select_node.selected == 0:
		account_popup_titletext_node.text = "[center]Edit current guest displayname.[/center]"
		account_popup_contents.get_node("UsernameInput").visible = false
	else:
		account_popup_titletext_node.text = "[center]Edit account username and displayname.[/center]"
		account_popup_contents.get_node("UsernameInput").visible = true
	
	account_popup_node.visible = true
	general_menu_nodes_container.visible = false

func _on_account_popup_usernameinput_text_changed():
	var formatted_username: String = Globals.normalize_username_str(
		account_popup_contents.get_node("UsernameInput").text)
	account_popup_contents.get_node("UsernameInput").text = formatted_username
	account_popup_contents.get_node("UsernameInput").set_caret_column(formatted_username.length())
	return
func _on_account_popup_cancel_button():
	account_popup_node.visible = false
	general_menu_nodes_container.visible = true
	return
# !!! IMPORTANT: in the future, if username is different make everything local using it be updated.
func _on_account_popup_confirm_button():
	var formatted_username: String = Globals.normalize_username_str(
		account_popup_contents.get_node("UsernameInput").text)
	return
