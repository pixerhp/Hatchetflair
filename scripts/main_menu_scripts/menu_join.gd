extends Control

const servers_list_txtfile_location: String = "user://storage/servers_list.txt"


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


func join_server(servers_list_index: int = 0):
	var servers_txtfile_lines: Array[String] = FileManager.read_txtfile_lines_as_array(servers_list_txtfile_location)
	print("Chosen server's list-index: " + str(servers_list_index))
	print("Chosen server's nickname: " + servers_txtfile_lines[(servers_list_index*2)+1])
	print("Chosen server's IP: " + servers_txtfile_lines[(servers_list_index*2)+2])
	NetworkManager.start_game(true, false, true, servers_txtfile_lines[(servers_list_index*2)+2])

func _on_join_button_pressed():
	var displayed_servers_list_text = $JoinScreenUI/SavedServersList
	if not displayed_servers_list_text.get_selected_items().is_empty(): # Don't do anything if no worlds are selected.
		join_server(displayed_servers_list_text.get_selected_items()[0])


func open_add_server_popup():
	hide_all_servers_menu_popups()
	$AddServerPopup/ServerIPInput.clear()
	$AddServerPopup/ServerNicknameInput.clear()
	$AddServerPopup.show()

func confirm_add_server():
	var popup = $AddServerPopup
	
	# Figure out what the new contents for the servers-list text file should be and replace the old contents.
	var file_contents = FileManager.read_txtfile_lines_as_array(servers_list_txtfile_location)
	file_contents.append(popup.get_node("ServerNicknameInput").text)
	file_contents.append(popup.get_node("ServerIPInput").text)
	FileManager.write_txtfile_from_array_of_lines(servers_list_txtfile_location, file_contents)
	
	update_the_displayed_servers_list()
	popup.hide()

func open_edit_server_popup():
	hide_all_servers_menu_popups()
	
	var displayed_servers_itemlist = $JoinScreenUI/SavedServersList
	if displayed_servers_itemlist.get_selected_items().is_empty():
		push_warning("Attempted to open the EditServer popup despite no displayed server item being selected. (Did nothing.)")
		return
	
	var txtfile_lines: Array[String] = FileManager.read_txtfile_lines_as_array(servers_list_txtfile_location)
	var selected_server_index: int = displayed_servers_itemlist.get_selected_items()[0]
	var popup = $EditServerPopup
	popup.get_node("PopupTitleText").text = "[center]Edit server: \"" + txtfile_lines[(selected_server_index*2)+1] +"\""
	popup.get_node("ServerIPInput").text = txtfile_lines[(selected_server_index*2)+2]
	popup.get_node("ServerNicknameInput").text = txtfile_lines[(selected_server_index*2)+1]
	popup.show()
	return

func confirm_edit_server():
	var displayed_servers_itemlist = $JoinScreenUI/SavedServersList
	if displayed_servers_itemlist.get_selected_items().is_empty():
		push_warning("Attempted to finilize editing a saved server whilst none of the displayed items were selected. (Did nothing.)")
		return
	
	# Determine what the contents of the servers list text file should be after editing and replace the old contents.
	var file_contents: Array[String] = FileManager.read_txtfile_lines_as_array(servers_list_txtfile_location)
	var selected_server_index: int = displayed_servers_itemlist.get_selected_items()[0]
	var popup = $EditServerPopup
	file_contents[(selected_server_index*2)+1] = popup.get_node("ServerNicknameInput").text
	file_contents[(selected_server_index*2)+2] = popup.get_node("ServerIPInput").text
	FileManager.write_txtfile_from_array_of_lines(servers_list_txtfile_location, file_contents)
	
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
	var name_of_removable_server: String = FileManager.read_txtfile_lines_as_array(servers_list_txtfile_location)[(displayed_servers_itemlist.get_selected_items()[0]*2)+1]
	popup.get_node("PopupTitleText").text = "[center]Are you sure you want to remove\n\"" + name_of_removable_server +"\"?\n(This action CANNOT be undone!)[/center]"
	popup.show()
	return

func confirm_remove_server():
	var displayed_servers_itemlist = $JoinScreenUI/SavedServersList
	if displayed_servers_itemlist.get_selected_items().is_empty():
		push_warning("Attempted to finilize removing a saved server whilst none of the displayed items were selected. (Did nothing.)")
		return
	
	# Determine what the contents of the servers list text file should be after the removal and replace the old contents.
	var file_contents: Array[String] = FileManager.read_txtfile_lines_as_array(servers_list_txtfile_location)
	var selected_server_index: int = displayed_servers_itemlist.get_selected_items()[0]
	file_contents.remove_at((selected_server_index*2)+2)
	file_contents.remove_at((selected_server_index*2)+1)
	FileManager.write_txtfile_from_array_of_lines(servers_list_txtfile_location, file_contents)
	
	update_the_displayed_servers_list()
	disable_server_selected_requiring_buttons()
	$RemoveServerPopup.hide()
	return


func update_the_displayed_servers_list():
	FileManager.sort_txtfile_contents_alphabetically(servers_list_txtfile_location, 1, 2)
	$JoinScreenUI/SavedServersList.clear()
	
	# Add each server nickname from the text file to the displayed servers list text you see in the menu.
	var servers_list_txtfile_lines: Array[String] = FileManager.read_txtfile_lines_as_array(servers_list_txtfile_location)
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
