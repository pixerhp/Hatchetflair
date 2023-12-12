extends Control

# Add/Edit account popup nodes:
@onready var general_menu_nodes_container: Control = $VBoxContainer
@onready var account_popup_node: Control = $AccountPopup
@onready var account_popup_contents: Control = $AccountPopup/HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer
@onready var account_popup_titletext_node: Control = account_popup_contents.get_node("PopupTitleText")
@onready var account_popup_usernameinput_node: Control = account_popup_contents.get_node("UsernameInput")
@onready var account_popup_cancelbutton_node: Control = account_popup_contents.get_node("Buttons/Cancel")
@onready var account_popup_confirmbutton_node: Control = account_popup_contents.get_node("Buttons/Confirm")
@onready var account_select_node: OptionButton = $VBoxContainer/AccountSelectContainer/AccountSelect
var account_popup_mode_is_edit: bool = true


func _ready():
	_update_account_names_text()
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


func _on_account_option_button_item_selected(index_of_selected: int):
	Globals.player_username = account_select_node.get_item_text(index_of_selected)
	Globals.player_displayname = "[" + Globals.player_username + "'s displayname]"
	_update_account_names_text()
	return

func _on_add_account_pressed():
	account_popup_mode_is_edit = false
	account_popup_titletext_node.text = "[center]Enter new account username and displayname.[/center]"
	account_popup_contents.get_node("UsernameInput").text = ""
	account_popup_contents.get_node("DisplaynameInput").text = ""
	account_popup_contents.get_node("UsernameInput").visible = true
	account_popup_node.visible = true
	general_menu_nodes_container.visible = false

func _on_manage_account_button_pressed():
	# Find the popup for choosing which way you want to manage your account.
	var popup: PopupMenu = $VBoxContainer/HBoxContainer/VBoxContainermore/AccountSelectContainer/VBoxContainer/AccountButtonsContainer/ManageAccount/PopupMenu
	if popup == null:
		push_error("Could not find manage-account managing-type-selection popup.")
		return
	popup.position = popup.get_parent().global_position
	popup.visible = true
	return

func _on_change_displayname_button_pressed():
	var thing: HBoxContainer = $VBoxContainer/HBoxContainer/VBoxContainermore/VBoxContainer/HBoxContainer2
	if thing == null:
		push_error("Could not find the container node of new displayname entry nodes.")
		return
	thing.visible = !thing.visible
	return


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
# !!! vv IMPORTANT vv: in the future, if username is different make everything local using it be updated.
func _on_account_popup_confirm_button():
	if account_popup_mode_is_edit:
		Globals.player_displayname = account_popup_contents.get_node("DisplaynameInput").text
		if not account_select_node.selected == 0:
			var formatted_username: String = Globals.normalize_username_str(
				account_popup_contents.get_node("UsernameInput").text)
			Globals.player_username = formatted_username
			account_select_node.set_item_text(account_select_node.selected, Globals.player_username)
	else: # (Adding a new account.)
		var formatted_username: String = Globals.normalize_username_str(
			account_popup_contents.get_node("UsernameInput").text)
		if formatted_username.is_empty():
			return
		account_select_node.add_item(formatted_username)
		_on_account_option_button_item_selected(account_select_node.get_selectable_item(true))
		Globals.player_displayname = account_popup_contents.get_node("DisplaynameInput").text
	
	account_popup_node.visible = false
	general_menu_nodes_container.visible = true
	_update_account_names_text()
	return
