extends Control

@onready var servers_list_text = get_node("JoinScreenUI/SavedServersList")
var servers_nicknames = [""]
var servers_ips = [""]


# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect popups and their buttons to functions.
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
	print("Chosen server index: " + str(server_list_index))
	NetworkManager.start_game(true, false, true, servers_ips[servers_list_text.get_selected_items()[0]])


func _on_join_button_pressed():
	if not servers_list_text.get_selected_items().is_empty(): # Don't do anything if no worlds are selected.
		join_server(servers_list_text.get_selected_items()[0])


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

func open_edit_server_popup():
	hide_all_servers_menu_popups()
	if not servers_list_text.get_selected_items().is_empty(): # Don't do anything if no worlds are selected.
		var edit_server_popup = get_node("EditServerPopup")
		edit_server_popup.get_node("PopupTitleText").text = "[center]Edit server: \"" + "[insert server nickname here]" +"\""
		edit_server_popup.get_node("ServerIPInput").text = servers_ips[servers_list_text.get_selected_items()[0]]
		edit_server_popup.get_node("ServerNicknameInput").text = servers_nicknames[servers_list_text.get_selected_items()[0]]
		edit_server_popup.show()

func confirm_edit_server():
	if not servers_list_text.get_selected_items().is_empty(): # Crash prevention for if no world is selected.
		var edit_server_popup = get_node("EditServerPopup")
		servers_ips[servers_list_text.get_selected_items()[0]] = edit_server_popup.get_node("ServerIPInput").text
		servers_nicknames[servers_list_text.get_selected_items()[0]] = edit_server_popup.get_node("ServerNicknameInput").text
		update_servers_list_text()
		edit_server_popup.hide()

func open_remove_server_popup():
	hide_all_servers_menu_popups()
	if not servers_list_text.get_selected_items().is_empty(): # Don't do anything if no server is selected.
		var remove_server_popup = get_node("RemoveServerPopup")
		remove_server_popup.get_node("PopupTitleText").text = "[center]Are you sure you want to remove\n\"" + get_array_of_servers_list_file_contents()[servers_list_text.get_selected_items()[0] * 2] +"\"?\n(This action cannot be undone.)[/center]"
		remove_server_popup.show()

func confirm_remove_server():
	var servers_list_text = get_node("JoinScreenUI/SavedServersList")
	if not servers_list_text.get_selected_items().is_empty(): # Crash prevention for if no server nickname is selected.
		servers_nicknames.remove_at(servers_list_text.get_selected_items()[0])
		servers_ips.remove_at(servers_list_text.get_selected_items()[0])
		
		var servers_text_file_contents = get_array_of_servers_list_file_contents()
		servers_text_file_contents.remove_at((servers_list_text.get_selected_items()[0] * 2) + 1)
		servers_text_file_contents.remove_at(servers_list_text.get_selected_items()[0] * 2)
		
		# Replace the servers list text file contents with updated contents.
		if (FileAccess.file_exists("user://storage/servers_list.txt")):
			var servers_text_file: FileAccess
			servers_text_file = FileAccess.open("user://storage/servers_list.txt", FileAccess.WRITE)
			servers_text_file.store_line(GlobalStuff.game_version_entire)
			for line in servers_text_file_contents:
				servers_text_file.store_line(line)
			servers_text_file.close()
		else:
			push_error("The text file for the servers list could not be found or accessed by the join menu.")
		
		get_node("RemoveServerPopup").hide()
		update_servers_list_text()
		disable_server_selected_requiring_buttons()


# Update the text of the visible servers-list for the player.
func update_servers_list_text():
	var servers_list_text = get_node("JoinScreenUI/SavedServersList")
	servers_list_text.clear()
	var servers_text_file_contents = get_array_of_servers_list_file_contents()
	for index in range(0, servers_text_file_contents.size()-1, 2):
		servers_list_text.add_item(servers_text_file_contents[index])

# Outputs an array of strings, of every* line from the servers list text file.
# *Doesn't include the line 1 version number, or the last line either if it's blank or the number of content lines is odd.
func get_array_of_servers_list_file_contents() -> Array[String]:
	# If the servers list text file is able to be found/accessed:
	if (FileAccess.file_exists("user://storage/servers_list.txt")):
		var servers_list_txt_file: FileAccess
		servers_list_txt_file = FileAccess.open("user://storage/servers_list.txt", FileAccess.READ)
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
