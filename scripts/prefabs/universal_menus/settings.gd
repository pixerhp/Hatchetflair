extends Control

signal close_settings_menu

@onready var hotkeys_list_vbox_node: Node = $HBoxContainer/VBoxContainer/SettingsPanel/VBoxContainer/HotkeysList/VBoxContainer
@onready var keymap_item_node: Node = $HBoxContainer/VBoxContainer/SettingsPanel/VBoxContainer/HotkeysList/VBoxContainer/KeyMapItem
@onready var keymap_item_spacer_node: Node = $HBoxContainer/VBoxContainer/SettingsPanel/VBoxContainer/HotkeysList/VBoxContainer/Spacer
@onready var input_listener_screen: Node = $InputListenerScreen

var active_hotkey_remap_button: Button

# !!! Rememeber that when adding an event usign the add button not to add the input if it's already attached to that action.


func _ready():
	# This block creates KeyMapItem nodes for each HF-specific action.
	var input_map_actions := InputMap.get_actions()
	var action_title_text: String = ""
	var new_keymap_item_node: Node
	var new_spacer_node: Control
	for action in input_map_actions:
		if action.substr(0, 3) == "ui_":
			continue
		action_title_text = "[center]" + action + "[/center]"
		new_keymap_item_node = keymap_item_node.duplicate(DUPLICATE_USE_INSTANTIATION)
		new_keymap_item_node.set_name(action)
		new_keymap_item_node.get_node("ActionTitle").set_text(action_title_text)
		hotkeys_list_vbox_node.add_child(new_keymap_item_node)
		new_spacer_node = keymap_item_spacer_node.duplicate(DUPLICATE_USE_INSTANTIATION)
		hotkeys_list_vbox_node.add_child(new_spacer_node)
	_update_hotkey_events_texts()
	
	# Removes the dummy KeyMapItem which was used to create the others.
	#hotkeys_list_vbox_node.get_child(1).queue_free()
	keymap_item_node.queue_free()
	
	# Connects the hotkey buttons with signals to give them function.
	var hotkey_set_button: Button
	for keymap_item in hotkeys_list_vbox_node.get_children():
		# (Skip the spacer nodes:)
		if not keymap_item is HSplitContainer:
			continue
		hotkey_set_button = keymap_item.get_node("VBoxContainer").get_node("PanelContainer").get_node("SetButton")
		hotkey_set_button.pressed.connect(_on_hotkey_remap_button_pressed.bind(hotkey_set_button))
	return

func _update_hotkey_events_texts() -> void:
	# Count how many times each event (input) is used for actions.
	# (This can be used for things like making text yellow if an event is used multiple times.)
	var event_counts: Dictionary = {}
	for action in InputMap.get_actions():
		if action.substr(0, 3) == "ui_":
			continue
		for event in InputMap.action_get_events(action):
			if event_counts.has(event.as_text()):
				event_counts[event.as_text()] += 1
			else:
				event_counts[event.as_text()] = 1
	
	var event_title_node: RichTextLabel
	var button_events: Array[InputEvent] = []
	var events_text: String = ""
	for keymap_item in hotkeys_list_vbox_node.get_children():
		# Skip the spacer nodes:
		if not keymap_item is HSplitContainer:
			continue
		
		event_title_node = keymap_item.get_node("VBoxContainer").get_node("PanelContainer").get_node("EventTitle")
		button_events = InputMap.action_get_events(keymap_item.name)
		
		if button_events.is_empty():
			event_title_node.set_text("[center][color=orangered]unbound[/color][/center]")
			continue
		else:
			events_text = ""
			for event in button_events:
				print("event: ", event, " : ", event_counts[event.as_text()])
				if event_counts[event.as_text()] > 1:
					events_text += "[color=yellow]" +  event.as_text() + "[/color];   "
				else:
					events_text += event.as_text() + ";   "
			if not events_text.is_empty():
				events_text = events_text.erase(events_text.length() - 4, 4)
			events_text = "[center]" + events_text + "[/center]"
			event_title_node.set_text(events_text)
			continue
	print()
	return

func _on_hotkey_remap_button_pressed(hotkey_set_button: Button) -> void:
	active_hotkey_remap_button = hotkey_set_button
	input_listener_screen.show()
	return

# _input is called every time the player makes an input, including mouse and keyboard.
# This specific instance is used for input listening after you click the set button.
func _input(event: InputEvent) -> void:
	if active_hotkey_remap_button == null:
		return
	# Makes it so that only keyboard keys, mouse buttons, and controller stuff can be used for hotkeys.
	if not ((event is InputEventKey) or (event is InputEventMouseButton) 
	or (event is InputEventJoypadButton) or (event is InputEventJoypadMotion)):
		return
	
	InputMap.action_erase_events(active_hotkey_remap_button.get_parent().get_parent().get_parent().name)
	InputMap.action_add_event(active_hotkey_remap_button.get_parent().get_parent().get_parent().name, event)
	active_hotkey_remap_button = null
	input_listener_screen.hide()
	_update_hotkey_events_texts()
	return

func _on_reset_hotkeys_pressed():
	for action in Globals.INPUTMAP_DEFAULTS:
		InputMap.action_erase_events(action)
		for event in Globals.INPUTMAP_DEFAULTS[action]:
			InputMap.action_add_event(action, event)
	_update_hotkey_events_texts()
	return


func _on_close_settings_pressed():
	close_settings_menu.emit()
	return
