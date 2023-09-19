extends Control

# The servers list is stored in a cfg file, where each section (except for meta_info) is for a different server.
# The section title texts are for a server's altname, and under it are the keys and values for its nickname, ip (etc.)
# Altnames need to be unique, so for 3 servers nicknamed "a", their altnames would be "a", "a alt1", and "a alt2".

var server_altnames: Array[String] = []
var altname_to_nickname: Dictionary = {}
@onready var servers_list_node: Node = $JoinScreenUI/SavedServersList


func _ready():
	# Connect popup buttons to their associated functions.
	$AddServerPopup/Confirm.pressed.connect(self.confirm_add_server)
	$AddServerPopup/Cancel.pressed.connect($AddServerPopup.hide)
	$EditServerPopup/Confirm.pressed.connect(self.confirm_edit_server)
	$EditServerPopup/Cancel.pressed.connect($EditServerPopup.hide)
	$RemoveServerPopup/Confirm.pressed.connect(self.confirm_remove_server)
	$RemoveServerPopup/Cancel.pressed.connect($RemoveServerPopup.hide)
	
	disable_item_selected_buttons()
	hide_join_menu_popups()
	return


func sync_servers():
	var servers_dict: Dictionary = FileManager.read_cfg(FileManager.PATH_SERVERS, ["meta_info"])
	server_altnames.clear()
	altname_to_nickname.clear()
	for altname in servers_dict:
		server_altnames.append(altname)
		altname_to_nickname[altname] = servers_dict[altname]["nickname"]
func update_servers_list():
	sync_servers()
	servers_list_node.clear()
	for server_nickname in altname_to_nickname.values():
		servers_list_node.add_item(server_nickname)
	return

func join_server_by_index(index: int = -1) -> Error:
	if index == -1:
		if not $JoinScreenUI/SavedServersList.get_selected_items().is_empty():
			index = $JoinScreenUI/SavedServersList.get_selected_items()[0]
		else:
			push_warning("No list index was specified.")
			return FAILED
	var ip: String = FileManager.read_cfg_keyval(FileManager.PATH_SERVERS, server_altnames[index], "ip")
	join_server_by_ip(ip)
	return OK
func join_server_by_ip(ip: String) -> Error:
	if NetworkManager.start_game(true, false, true, ip) != OK:
		return FAILED
	return OK


func open_add_server_popup() -> void:
	hide_join_menu_popups()
	$AddServerPopup/ServerIPInput.clear()
	$AddServerPopup/ServerNicknameInput.clear()
	$AddServerPopup.show()
	return
func confirm_add_server() -> Error:
	var popup: Node = $AddServerPopup
	var nickname: String = popup.get_node("ServerNicknameInput").text
	var ip: String = popup.get_node("ServerIPInput").text
	var err: Error = FileManager.add_remembered_server(nickname, ip)
	update_servers_list()
	popup.hide()
	if err != OK:
		return FAILED
	return OK

func open_edit_server_popup() -> Error:
	hide_join_menu_popups()
	if servers_list_node.get_selected_items().is_empty():
		push_warning("No world index is selected.")
		return FAILED
	var altname: String = server_altnames[servers_list_node.get_selected_items()[0]]
	var nickname: String = altname_to_nickname[altname]
	var ip: String = FileManager.read_cfg_keyval(FileManager.PATH_SERVERS, altname, "ip")
	var popup: Node = $EditServerPopup
	popup.get_node("PopupTitleText").text = "[center]Edit remembered server: \"" + nickname + "\""
	popup.get_node("ServerIPInput").text = ip
	popup.get_node("ServerNicknameInput").text = nickname
	popup.show()
	return OK
func confirm_edit_server() -> Error:
	if servers_list_node.get_selected_items().is_empty():
		push_warning("No world index is selected.")
		return FAILED
	var altname: String = server_altnames[servers_list_node.get_selected_items()[0]]
	var popup = $EditServerPopup
	var new_nickname: String = popup.get_node("ServerNicknameInput").text
	var new_ip: String = popup.get_node("ServerIPInput").text
	var err: Error = FileManager.edit_remembered_server(altname, new_nickname, new_ip)
	update_servers_list()
	popup.hide()
	if err != OK:
		return FAILED
	return OK

func open_remove_server_popup():
	hide_join_menu_popups()
	
	var displayed_servers_itemlist = $JoinScreenUI/SavedServersList
	if displayed_servers_itemlist.get_selected_items().is_empty():
		push_warning("Attempted to open the RemoveServer popup despite no displayed server item being selected. (Did nothing.)")
		return
	
	var popup = $RemoveServerPopup
	var name_of_removable_server: String = FileManager.read_file_lines(FileManager.PATH_SERVERS)[(displayed_servers_itemlist.get_selected_items()[0]*2)+1]
	popup.get_node("PopupTitleText").text = "[center]Are you sure you want to remove\n\"" + name_of_removable_server +"\"?\n(This action cannot be undone.)[/center]"
	popup.show()
	return

func confirm_remove_server():
	var displayed_servers_itemlist = $JoinScreenUI/SavedServersList
	if displayed_servers_itemlist.get_selected_items().is_empty():
		push_warning("Attempted to finilize removing a saved server, but none of the displayed items were selected. (Did nothing.)")
		return
	
	# Determine what the contents of the servers list text file should be after the removal and replace the old contents.
	var file_contents: Array[String] = FileManager.read_file_lines(FileManager.PATH_SERVERS)
	var selected_server_index: int = displayed_servers_itemlist.get_selected_items()[0]
	file_contents.remove_at((selected_server_index*2)+2)
	file_contents.remove_at((selected_server_index*2)+1)
	FileManager.write_txtfile_from_array_of_lines(FileManager.PATH_SERVERS, file_contents)
	
	update_servers_list()
	disable_item_selected_buttons()
	$RemoveServerPopup.hide()
	return


func _on_servers_list_item_selected():
	hide_join_menu_popups()
	$JoinScreenUI/ServerButtons/RemoveServer.disabled = false
	$JoinScreenUI/ServerButtons/EditServer.disabled = false
	$JoinScreenUI/ServerButtons/JoinServer.disabled = false

func disable_item_selected_buttons():
	$JoinScreenUI/ServerButtons/RemoveServer.disabled = true
	$JoinScreenUI/ServerButtons/EditServer.disabled = true
	$JoinScreenUI/ServerButtons/JoinServer.disabled = true

func hide_join_menu_popups():
	$AddServerPopup.hide()
	$EditServerPopup.hide()
	$RemoveServerPopup.hide()
