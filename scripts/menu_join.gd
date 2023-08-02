extends Control

@onready var servers_list_text = get_node("JoinScreenUI/SavedServersList")
var servers_names = []
var servers_ips = []


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Attempts to join the selected server.
func join_server(server_index: int = 0):
	# UPDATE THIS TO WORK WITH THE SELECTED SERVER IP LATER.
	NetworkManager.start_game(true, false, true, "127.0.0.1")
	pass


func _on_join_button_pressed():
	if not servers_list_text.get_selected_items().is_empty(): # Don't do anything if no worlds are selected.
		join_server()


func _on_servers_list_item_selected():
	hide_all_servers_menu_popups()
	var remove_server_button: Button = $JoinScreenUI/ServerButtons/RemoveServer
	remove_server_button.disabled = false
	var edit_server_button: Button = $JoinScreenUI/ServerButtons/EditServer
	edit_server_button.disabled = false
	var join_server_button: Button = $JoinScreenUI/ServerButtons/JoinServer
	join_server_button.disabled = false

func hide_all_servers_menu_popups():
	get_node("NewServerPopup").hide()
	get_node("EditServerPopup").hide()
	get_node("RemoveServerPopup").hide()

func disable_server_selected_requiring_buttons():
	var remove_server_button: Button = $JoinScreenUI/ServerButtons/RemoveServer
	remove_server_button.disabled = true
	var edit_server_button: Button = $JoinScreenUI/ServerButtons/EditServer
	edit_server_button.disabled = true
	var join_server_button: Button = $JoinScreenUI/ServerButtons/JoinServer
	join_server_button.disabled = true
