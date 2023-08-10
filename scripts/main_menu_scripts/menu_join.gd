extends Control

const servers_list_file_location: String = "user://storage/servers_list.txt"

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect join menu popups and their buttons to functions.
	var add_server_popup = get_node("AddServerPopup")
	add_server_popup.get_node("Okay").pressed.connect(self.confirm_add_server)
	add_server_popup.get_node("Cancel").pressed.connect(add_server_popup.hide)
	var edit_server_popup = get_node("EditServerPopup")
	edit_server_popup.get_node("Okay").pressed.connect(self.confirm_edit_server)
	edit_server_popup.get_node("Cancel").pressed.connect(edit_server_popup.hide)
	var remove_server_popup = get_node("RemoveServerPopup")
	remove_server_popup.get_node("Confirm").pressed.connect(self.confirm_remove_server)
	remove_server_popup.get_node("Cancel").pressed.connect(remove_server_popup.hide)
	
	disable_server_selected_requiring_buttons()
	hide_all_servers_menu_popups()


# Attempts to join the selected server.
func join_server(server_list_index: int = 0):
	print("Chosen server list index: " + str(server_list_index))
	print("Chosen server nickname: " + get_array_of_servers_list_file_contents()[server_list_index * 2])
	print("Chosen server IP: " + get_array_of_servers_list_file_contents()[(server_list_index * 2) + 1])
	NetworkManager.start_game(true, false, true, get_array_of_servers_list_file_contents()[(server_list_index * 2) + 1])


func _on_join_button_pressed():
	var displayed_servers_list_text = get_node("JoinScreenUI/SavedServersList")
	if not displayed_servers_list_text.get_selected_items().is_empty(): # Don't do anything if no worlds are selected.
		join_server(displayed_servers_list_text.get_selected_items()[0])


func open_add_server_popup():
	hide_all_servers_menu_popups()
	var add_server_popup = get_node("AddServerPopup")
	add_server_popup.get_node("ServerIPInput").clear()
	add_server_popup.get_node("ServerNicknameInput").clear()
	add_server_popup.show()

func confirm_add_server():
	# Figure out what the new servers list items (including IPs) should look like.
	var add_server_popup = get_node("AddServerPopup")
	var servers_text_file_contents = get_array_of_servers_list_file_contents()
	servers_text_file_contents.append(add_server_popup.get_node("ServerNicknameInput").text)
	servers_text_file_contents.append(add_server_popup.get_node("ServerIPInput").text)
	
	# Replace the current servers list file contents with newer updated contents.
	replace_servers_list_file_contents(servers_text_file_contents)
	
	update_servers_list_text()
	add_server_popup.hide()

func open_edit_server_popup():
	hide_all_servers_menu_popups()
	var displayed_servers_list_text = get_node("JoinScreenUI/SavedServersList")
	if not displayed_servers_list_text.get_selected_items().is_empty(): # Don't do anything if no worlds are selected.
		var edit_server_popup = get_node("EditServerPopup")
		edit_server_popup.get_node("PopupTitleText").text = "[center]Edit server: \"" + get_array_of_servers_list_file_contents()[displayed_servers_list_text.get_selected_items()[0] * 2] +"\""
		edit_server_popup.get_node("ServerIPInput").text = get_array_of_servers_list_file_contents()[(displayed_servers_list_text.get_selected_items()[0] * 2) + 1]
		edit_server_popup.get_node("ServerNicknameInput").text = get_array_of_servers_list_file_contents()[displayed_servers_list_text.get_selected_items()[0] * 2]
		edit_server_popup.show()

func confirm_edit_server():
	var displayed_servers_list_text = get_node("JoinScreenUI/SavedServersList")
	if not displayed_servers_list_text.get_selected_items().is_empty(): # Crash prevention for if no world is selected.
		
		# Figure out what the new servers list items (including IPs) should look like.
		var edit_server_popup = get_node("EditServerPopup")
		var servers_text_file_contents = get_array_of_servers_list_file_contents()
		servers_text_file_contents[displayed_servers_list_text.get_selected_items()[0] * 2] = edit_server_popup.get_node("ServerNicknameInput").text
		servers_text_file_contents[(displayed_servers_list_text.get_selected_items()[0] * 2) + 1] = edit_server_popup.get_node("ServerIPInput").text
		
		# Replace the current servers list file contents with newer updated contents.
		replace_servers_list_file_contents(servers_text_file_contents)
		
		update_servers_list_text()
		edit_server_popup.hide()

func open_remove_server_popup():
	hide_all_servers_menu_popups()
	var displayed_servers_list_text = get_node("JoinScreenUI/SavedServersList")
	if not displayed_servers_list_text.get_selected_items().is_empty(): # Don't do anything if no server is selected.
		var remove_server_popup = get_node("RemoveServerPopup")
		remove_server_popup.get_node("PopupTitleText").text = "[center]Are you sure you want to remove\n\"" + get_array_of_servers_list_file_contents()[displayed_servers_list_text.get_selected_items()[0] * 2] +"\"?\n(This action cannot be undone.)[/center]"
		remove_server_popup.show()

func confirm_remove_server():
	var displayed_servers_list_text = get_node("JoinScreenUI/SavedServersList")
	if not displayed_servers_list_text.get_selected_items().is_empty(): # Crash prevention for if no server nickname is selected.
		
		# Figure out what the new servers list items (including IPs) should look like.
		var servers_text_file_contents = get_array_of_servers_list_file_contents()
		servers_text_file_contents.remove_at((displayed_servers_list_text.get_selected_items()[0] * 2) + 1)
		servers_text_file_contents.remove_at(displayed_servers_list_text.get_selected_items()[0] * 2)
		
		# Replace the current servers list file contents with newer updated contents.
		replace_servers_list_file_contents(servers_text_file_contents)
		
		update_servers_list_text()
		disable_server_selected_requiring_buttons()
		get_node("RemoveServerPopup").hide()


# Update the servers list text which is shown to players in the join menu.
func update_servers_list_text():
	var displayed_servers_list_text = get_node("JoinScreenUI/SavedServersList")
	displayed_servers_list_text.clear()
	var servers_text_file_contents = get_array_of_servers_list_file_contents()
	# Only use every other item in the file contents (nicknames,) since the servers list file also stores server ips.
	for index in range(0, servers_text_file_contents.size()-1, 2):
		displayed_servers_list_text.add_item(servers_text_file_contents[index])

# Outputs an array of strings, of every* line from the servers list text file.
# *Doesn't include the line 1 version number, or the last line either if it's blank or the number of content lines is odd.
func get_array_of_servers_list_file_contents() -> Array[String]:
	# If the servers list text file is able to be found/accessed:
	if (FileAccess.file_exists(servers_list_file_location)):
		var servers_list_txt_file: FileAccess
		servers_list_txt_file = FileAccess.open(servers_list_file_location, FileAccess.READ)
		# If the version of the file is correct:
		if (servers_list_txt_file.get_line() == GlobalStuff.game_version_entire):
			var text_lines: Array[String] = []
			while (servers_list_txt_file.eof_reached() == false):
				text_lines.append(servers_list_txt_file.get_line())
			servers_list_txt_file.close()
			if (text_lines.size() % 2 == 1):
				text_lines.pop_back()
			return(text_lines)
		else:
			push_error("The text file for the servers list, when accessed by the join menu, was found to have an outdated version.")
	else:
		push_error("The text file for the servers list could not be found or accessed by the join menu.")
	return([])

func replace_servers_list_file_contents(new_servers_list_contents: Array[String]):
	# Make sure you can actually access the file.
	if (FileAccess.file_exists(servers_list_file_location)):
		var servers_text_file: FileAccess
		servers_text_file = FileAccess.open(servers_list_file_location, FileAccess.WRITE)
		servers_text_file.store_line(GlobalStuff.game_version_entire)
		for line in new_servers_list_contents:
			servers_text_file.store_line(line)
		servers_text_file.close()
	else:
		push_error("The servers list text file could not be accessed whilst trying to update it's contents.")


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
