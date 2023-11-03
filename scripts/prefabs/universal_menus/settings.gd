extends Control

signal close_settings_menu

@onready var hotkeys_list_vbox_node: Node = $HBoxContainer/VBoxContainer/SettingsUI/VBoxContainer/HotkeysList/VBoxContainer
@onready var keymap_item_node: Node = $HBoxContainer/VBoxContainer/SettingsUI/VBoxContainer/HotkeysList/VBoxContainer/KeyMapItem
@onready var input_listener_screen: Node = $InputListenerScreen

var active_hotkey_remap_button: Button


func _ready():
	# This block creates KeyMapItem nodes for each HF-specific action.
	var input_map_actions := InputMap.get_actions()
	var action_title_text: String = ""
	var new_keymap_item_node: Node
	for action in input_map_actions:
		if action.substr(0, 3) == "ui_":
			continue
		action_title_text = "[center]" + action + "[/center]"
		new_keymap_item_node = keymap_item_node.duplicate(DUPLICATE_USE_INSTANTIATION)
		new_keymap_item_node.set_name(action)
		new_keymap_item_node.get_node("ActionTitle").set_text(action_title_text)
		hotkeys_list_vbox_node.add_child(new_keymap_item_node)
	_update_hotkey_remap_buttons_text()
	
	# Removes the dummy KeyMapItem which was used to create the others.
	#hotkeys_list_vbox_node.get_child(1).queue_free()
	keymap_item_node.queue_free()
	
	# Connects the hotkey buttons with signals to give them function.
	var hotkey_remap_button: Button
	for keymap_item in hotkeys_list_vbox_node.get_children():
		hotkey_remap_button = keymap_item.get_node("RemapButton")
		hotkey_remap_button.pressed.connect(_on_hotkey_remap_button_pressed.bind(hotkey_remap_button))
	return

func _update_hotkey_remap_buttons_text() -> void:
	var hotkey_remap_button: Button
	var button_events: Array[InputEvent] = []
	var remap_button_text: String = ""
	# !!! Add functionality where a button's text is yellow if it's hotkey is used for multiple buttons.
	for keymap_item in hotkeys_list_vbox_node.get_children():
		hotkey_remap_button = keymap_item.get_node("RemapButton")
		button_events = InputMap.action_get_events(hotkey_remap_button.get_parent().name)
		if button_events.is_empty():
			hotkey_remap_button.set_text("unbound")
			hotkey_remap_button.add_theme_color_override("font_color", Color(1, 0.25, 0))
			continue
		else:
			remap_button_text = ""
			for event in button_events:
				remap_button_text += event.as_text() + ";  "
			if not remap_button_text.is_empty():
				remap_button_text = remap_button_text.erase(remap_button_text.length() - 3, 3)
			hotkey_remap_button.set_text(remap_button_text)
			hotkey_remap_button.remove_theme_color_override("font_color")
			continue
	return

func _on_hotkey_remap_button_pressed(hotkey_remap_button: Button) -> void:
	active_hotkey_remap_button = hotkey_remap_button
	input_listener_screen.show()
	return

# _input is called every time the player makes an input, including mouse and keyboard.
# This specific instance is used for input listening after you click a remap button.
func _input(event: InputEvent) -> void:
	if active_hotkey_remap_button == null:
		return
	# Makes it so that only keyboard keys, mouse buttons, and controller stuff can be used for hotkeys.
	if not ((event is InputEventKey) or (event is InputEventMouseButton) 
	or (event is InputEventJoypadButton) or (event is InputEventJoypadMotion)):
		return
	
	InputMap.action_erase_events(active_hotkey_remap_button.get_parent().name)
	InputMap.action_add_event(active_hotkey_remap_button.get_parent().name, event)
	active_hotkey_remap_button = null
	input_listener_screen.hide()
	_update_hotkey_remap_buttons_text()
	return

func _on_reset_hotkeys_pressed():
	for action in Globals.INPUTMAP_DEFAULTS:
		InputMap.action_erase_events(action)
		for event in Globals.INPUTMAP_DEFAULTS[action]:
			InputMap.action_add_event(action, event)
	_update_hotkey_remap_buttons_text()
	return


func _on_close_settings_pressed():
	close_settings_menu.emit()
	return
