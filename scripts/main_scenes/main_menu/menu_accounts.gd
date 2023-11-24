extends Control

@onready var general_menu_nodes_container: Control = $VBoxContainer
@onready var account_popup_node: Control = $AccountPopup


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
	if account_select_node.selected == 0:
		edit_account_button_node.disabled = true
	else:
		edit_account_button_node.disabled = false
	return


func _on_account_option_button_item_selected(index_of_selected: int):
	_update_edit_account_button_disabledness()
	
	var account_select_node: OptionButton = $VBoxContainer/AccountSelectContainer/AccountSelect
	if account_select_node == null:
		push_error("Account select option-button node not found.")
		return
	Globals.player_username = account_select_node.get_item_text(index_of_selected)
	if not Globals.player_username == "GUEST":
		Globals.player_displayname = "[" + Globals.player_username + "'s displayname]"
	else:
		Globals.player_displayname = "Guest"
	_update_account_names_text()
	return

func _on_add_account_pressed():
	account_popup_node.get_node("PopupTitleText").text = "[center]Enter new account username and displayname.[/center]"
	
	account_popup_node.visible = true
	general_menu_nodes_container.visible = false
func _on_edit_account_pressed():
	account_popup_node.get_node("PopupTitleText").text = "[center]Edit account username and displayname.[/center]"
	
	account_popup_node.visible = true
	general_menu_nodes_container.visible = false
