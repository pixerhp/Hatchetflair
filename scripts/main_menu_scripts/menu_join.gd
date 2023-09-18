extends Control


func _ready():
	# Connect popup buttons to their associated functions.
	$AddServerPopup/Confirm.pressed.connect(self.confirm_add_server)
	$AddServerPopup/Cancel.pressed.connect($AddServerPopup.hide)
	$EditServerPopup/Confirm.pressed.connect(self.confirm_edit_server)
	$EditServerPopup/Cancel.pressed.connect($EditServerPopup.hide)
	$RemoveServerPopup/Confirm.pressed.connect(self.confirm_remove_server)
	$RemoveServerPopup/Cancel.pressed.connect($RemoveServerPopup.hide)
	
	disable_server_selected_requiring_buttons()
	hide_all_servers_menu_popups()
	return


func join_server_by_index(servers_list_index: int = -1) -> void:
	if servers_list_index == -1:
		if not $JoinScreenUI/SavedServersList.get_selected_items().is_empty():
			servers_list_index = $JoinScreenUI/SavedServersList.get_selected_items()[0]
		else:
			push_error("No servers list index was specified for joining a server's world. (Aborting joining server.)")
			return
	var servers_list_lines: Array[String] = FileManager.read_file_lines(FileManager.PATH_SERVERS)
	var server_ip: String = servers_list_lines[(servers_list_index * 2) + 2]
	
	join_server_by_ip(server_ip)
	return

func join_server_by_ip(server_ip: String):
	if server_ip == "":
		push_warning("Attempted to join server by ip, but the ip was a blank string.")
		return
	NetworkManager.start_game(true, false, true, server_ip)
	return


func open_add_server_popup():
	hide_all_servers_menu_popups()
	$AddServerPopup/ServerIPInput.clear()
	$AddServerPopup/ServerNicknameInput.clear()
	$AddServerPopup.show()
	return

func confirm_add_server():
	var popup: Node = $AddServerPopup
	var server_nickname: String = popup.get_node("ServerNicknameInput").text
	if server_nickname == "":
		server_nickname = "new remembered server"
	var server_ip: String = popup.get_node("ServerIPInput").text
	
	# Determine the updated servers-list txtfile contents and replace the old contents.
	var file_contents: Array[String] = FileManager.read_file_lines(FileManager.PATH_SERVERS)
	file_contents.append(server_nickname)
	file_contents.append(server_ip)
	FileManager.write_txtfile_from_array_of_lines(FileManager.PATH_SERVERS, file_contents)
	
	update_the_displayed_servers_list()
	popup.hide()
	return

func open_edit_server_popup():
	hide_all_servers_menu_popups()
	
	var displayed_servers_itemlist = $JoinScreenUI/SavedServersList
	if displayed_servers_itemlist.get_selected_items().is_empty():
		push_warning("Attempted to open the EditServer popup despite no displayed server item being selected. (Did nothing.)")
		return
	
	var txtfile_lines: Array[String] = FileManager.read_file_lines(FileManager.PATH_SERVERS)
	var selected_server_index: int = displayed_servers_itemlist.get_selected_items()[0]
	var popup = $EditServerPopup
	popup.get_node("PopupTitleText").text = "[center]Edit server: \"" + txtfile_lines[(selected_server_index*2)+1] + "\""
	popup.get_node("ServerIPInput").text = txtfile_lines[(selected_server_index*2)+2]
	popup.get_node("ServerNicknameInput").text = txtfile_lines[(selected_server_index*2)+1]
	popup.show()
	return

func confirm_edit_server():
	var displayed_servers_itemlist = $JoinScreenUI/SavedServersList
	if displayed_servers_itemlist.get_selected_items().is_empty():
		push_warning("Attempted to finilize editing a saved server whilst none of the displayed servers items were selected. (Did nothing.)")
		return
	
	# Determine what the contents of the servers list text file should be after editing and replace its old contents.
	var file_contents: Array[String] = FileManager.read_file_lines(FileManager.PATH_SERVERS)
	var selected_server_index: int = displayed_servers_itemlist.get_selected_items()[0]
	var popup = $EditServerPopup
	file_contents[(selected_server_index*2)+1] = popup.get_node("ServerNicknameInput").text
	file_contents[(selected_server_index*2)+2] = popup.get_node("ServerIPInput").text
	FileManager.write_txtfile_from_array_of_lines(FileManager.PATH_SERVERS, file_contents)
	
	update_the_displayed_servers_list()
	popup.hide()
	return

func open_remove_server_popup():
	hide_all_servers_menu_popups()
	
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
	
	update_the_displayed_servers_list()
	disable_server_selected_requiring_buttons()
	$RemoveServerPopup.hide()
	return


func update_the_displayed_servers_list():
	FileManager.sort_file_line_groups_alphabetically(FileManager.PATH_SERVERS, 2, 1)
	$JoinScreenUI/SavedServersList.clear()
	
	# Add each server nickname from the text file to the displayed servers list text you see in the menu.
	var servers_list_txtfile_lines: PackedStringArray = FileManager.read_file_lines(FileManager.PATH_SERVERS)
	for index in range(1, servers_list_txtfile_lines.size()-1, 2):
		$JoinScreenUI/SavedServersList.add_item(servers_list_txtfile_lines[index])
	return


func _on_servers_list_item_selected():
	hide_all_servers_menu_popups()
	$JoinScreenUI/ServerButtons/RemoveServer.disabled = false
	$JoinScreenUI/ServerButtons/EditServer.disabled = false
	$JoinScreenUI/ServerButtons/JoinServer.disabled = false

func disable_server_selected_requiring_buttons():
	$JoinScreenUI/ServerButtons/RemoveServer.disabled = true
	$JoinScreenUI/ServerButtons/EditServer.disabled = true
	$JoinScreenUI/ServerButtons/JoinServer.disabled = true

func hide_all_servers_menu_popups():
	$AddServerPopup.hide()
	$EditServerPopup.hide()
	$RemoveServerPopup.hide()
