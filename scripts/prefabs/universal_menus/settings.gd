extends Control

# !!! to-do: replace instances of the word "hotkeys" with the more appopriate: "keybinds".

signal close_settings_menu
func _on_close_settings_pressed():
	close_settings_menu.emit()

@onready var hotkeys_container: Node = $HBoxContainer/VBoxContainer/SettingsPanel/VBoxContainer/HotkeysList/VBoxContainer
@onready var input_listener_screen: Node = $InputListenerScreen

var listen_for_inputs: bool = false
var input_listener_context: Array = [] # Hotkey-set example: [HOTKEY_SET, hotkey_item_node_ref]
enum {HOTKEY_SET = 0, HOTKEY_ADD = 1}


# !!! Rememeber that when adding an event usign the add button not to add the input if it's already attached to that action.

func _ready():
	# References to template nodes used to set up the list of hotkeys nodes.
	var hotkey_node_template: Node = $HBoxContainer/VBoxContainer/SettingsPanel/VBoxContainer/HotkeysList/VBoxContainer/HotkeyItem
	var hotkey_spacer_template: Node = $HBoxContainer/VBoxContainer/SettingsPanel/VBoxContainer/HotkeysList/VBoxContainer/Spacer
	
	# This block generates the list of hotkey nodes based on the HF-specific actions that exist.
	var new_hotkey_item_node: Node
	for action in InputMap.get_actions():
		if action.substr(0, 3) == "ui_":
			continue
		hotkeys_container.add_child(hotkey_spacer_template.duplicate(DUPLICATE_USE_INSTANTIATION))
		new_hotkey_item_node = hotkey_node_template.duplicate(DUPLICATE_USE_INSTANTIATION)
		new_hotkey_item_node.set_name(action)
		new_hotkey_item_node.get_node("ActionTitle").set_text("[center]" + action + "[/center]")
		hotkeys_container.add_child(new_hotkey_item_node)
	_update_hotkey_events_texts()
	
	# Removes the template nodes.
	hotkey_node_template.queue_free()
	hotkey_spacer_template.queue_free()
	
	# Connects hotkey buttons to signals to give them function.
	var button: Button
	for hotkey_item in hotkeys_container.get_children():
		# (Skip spacers.)
		if not hotkey_item is HSplitContainer:
			continue
		
		# The 'set' button:
		button = hotkey_item.get_node("VBoxContainer").get_node("PanelContainer").get_node("SetButton")
		button.pressed.connect(_hotkey_set.bind(button))
		# The 'reset' button:
		button = hotkey_item.get_node("VBoxContainer").get_node("HBoxContainer").get_node("ResetButton")
		button.pressed.connect(_hotkey_reset.bind(button))
		# The 'clear' button:
		button = hotkey_item.get_node("VBoxContainer").get_node("HBoxContainer").get_node("ClearButton")
		button.pressed.connect(_hotkey_clear.bind(button))
		# The 'remove' button:
		button = hotkey_item.get_node("VBoxContainer").get_node("HBoxContainer").get_node("RemoveButton")
		button.pressed.connect(_hotkey_remove_last.bind(button))
		# The 'add' button:
		button = hotkey_item.get_node("VBoxContainer").get_node("HBoxContainer").get_node("AddButton")
		button.pressed.connect(_hotkey_add.bind(button))
	
	return

func _update_hotkey_events_texts() -> void:
	# Count how many times each event (input) is used for actions.
	var event_counts: Dictionary = {}
	for action in InputMap.get_actions():
		if action.substr(0, 3) == "ui_":
			continue
		for event in InputMap.action_get_events(action):
			if event_counts.has(event.as_text()):
				event_counts[event.as_text()] += 1
			else:
				event_counts[event.as_text()] = 1
	
	# Update the hotkey events texts.
	var event_title_node: RichTextLabel
	var button_events: Array[InputEvent] = []
	var events_text: String = ""
	for keymap_item in hotkeys_container.get_children():
		# (Skip the spacer nodes:)
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
				if event_counts[event.as_text()] > 1:
					events_text += "[color=yellow]" +  event.as_text() + "[/color];   "
				else:
					events_text += event.as_text() + ";   "
			if not events_text.is_empty():
				events_text = events_text.erase(events_text.length() - 4, 4)
			events_text = "[center]" + events_text + "[/center]"
			event_title_node.set_text(events_text)
			continue
	return


func _reset_all_hotkeys():
	for action in Globals.INPUTMAP_DEFAULTS:
		InputMap.action_erase_events(action)
		for event in Globals.INPUTMAP_DEFAULTS[action]:
			InputMap.action_add_event(action, event)
	_update_hotkey_events_texts()

func _hotkey_set(button_pressed: Button) -> void:
	input_listener_context = [HOTKEY_SET, button_pressed]
	listen_for_inputs = true
	input_listener_screen.show()
	return
func _hotkey_reset(button_pressed: Button) -> void:
	var action = button_pressed.get_parent().get_parent().get_parent().name
	InputMap.action_erase_events(action)
	for event in Globals.INPUTMAP_DEFAULTS[action]:
			InputMap.action_add_event(action, event)
	_update_hotkey_events_texts()
	return
func _hotkey_clear(button_pressed: Button) -> void:
	InputMap.action_erase_events(button_pressed.get_parent().get_parent().get_parent().name)
	_update_hotkey_events_texts()
	return
func _hotkey_remove_last(button_pressed: Button) -> void:
	var action = button_pressed.get_parent().get_parent().get_parent().name
	var events = InputMap.action_get_events(action)
	if not events.is_empty():
		events.resize(events.size() - 1)
		InputMap.action_erase_events(action)
		for event in events:
			InputMap.action_add_event(action, event)
		_update_hotkey_events_texts()
	return
func _hotkey_add(button_pressed: Button) -> void:
	input_listener_context = [HOTKEY_ADD, button_pressed]
	listen_for_inputs = true
	input_listener_screen.show()
	return


func _input(event: InputEvent) -> void:
	if listen_for_inputs == false:
		return
	# Specifies which input types get used.
	if not ((event is InputEventKey) or (event is InputEventMouseButton) 
	or (event is InputEventJoypadButton) or (event is InputEventJoypadMotion)):
		return
	
	if input_listener_context.size() > 0:
		match input_listener_context[0]:
			HOTKEY_SET:
				InputMap.action_erase_events(input_listener_context[1].get_parent().get_parent().get_parent().name)
				InputMap.action_add_event(input_listener_context[1].get_parent().get_parent().get_parent().name, event)
				_update_hotkey_events_texts()
				input_listener_context.clear()
			HOTKEY_ADD:
				InputMap.action_add_event(input_listener_context[1].get_parent().get_parent().get_parent().name, event)
				_update_hotkey_events_texts()
				input_listener_context.clear()
	
	listen_for_inputs = false
	input_listener_screen.hide()
	return
