extends Control

@onready var servers_list_text = get_node("JoinScreenUI/SavedServersList")
var servers_nicknames = ["localhost 127.0.0.1", "bad ip address A", "bad ip address B"]
var servers_ips = ["127.0.0.1", "3256.23532.456.1241356", "definitely an ip address ;^)"]


# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect popups and their buttons to functions.
	var add_server_popup = get_node("AddServerPopup")
	add_server_popup.get_node("Okay").pressed.connect(self.confirm_add_server)
	add_server_popup.get_node("Cancel").pressed.connect(add_server_popup.hide)
	
	disable_server_selected_requiring_buttons()
	hide_all_servers_menu_popups()
	update_servers_list_text()


# Attempts to join the selected server.
func join_server(server_index: int = 0):
	# UPDATE THIS TO WORK WITH THE SELECTED SERVER IP LATER.
	NetworkManager.start_game(true, false, true, "127.0.0.1")
	pass


func _on_join_button_pressed():
	if not servers_list_text.get_selected_items().is_empty(): # Don't do anything if no worlds are selected.
		join_server()


func open_add_server_popup():
	hide_all_servers_menu_popups()
	var add_server_popup = get_node("AddServerPopup")
	add_server_popup.get_node("ServerIPInput").clear()
	add_server_popup.get_node("ServerNicknameInput").clear()
	add_server_popup.show()

func confirm_add_server():
	var add_server_popup = get_node("AddServerPopup")
	servers_ips.append(add_server_popup.get_node("ServerIPInput").text)
	servers_nicknames.append(add_server_popup.get_node("ServerNicknameInput").text)
	update_servers_list_text()
	add_server_popup.hide()


# Update the text of the visible servers-list for the player.
func update_servers_list_text():
	servers_list_text.clear()
	for nickname in servers_nicknames:
		servers_list_text.add_item(nickname)


func _on_servers_list_item_selected():
	hide_all_servers_menu_popups()
	var remove_server_button: Button = $JoinScreenUI/ServerButtons/RemoveServer
	remove_server_button.disabled = false
	var edit_server_button: Button = $JoinScreenUI/ServerButtons/EditServer
	edit_server_button.disabled = false
	var join_server_button: Button = $JoinScreenUI/ServerButtons/JoinServer
	join_server_button.disabled = false

func hide_all_servers_menu_popups():
	get_node("AddServerPopup").hide()
	get_node("EditServerPopup").hide()
	get_node("RemoveServerPopup").hide()

func disable_server_selected_requiring_buttons():
	var remove_server_button: Button = $JoinScreenUI/ServerButtons/RemoveServer
	remove_server_button.disabled = true
	var edit_server_button: Button = $JoinScreenUI/ServerButtons/EditServer
	edit_server_button.disabled = true
	var join_server_button: Button = $JoinScreenUI/ServerButtons/JoinServer
	join_server_button.disabled = true
