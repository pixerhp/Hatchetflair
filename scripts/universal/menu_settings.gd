extends Control

@onready var settings_list_node: Node = $SettingsUI/SettingsList/VBoxContainer
@onready var keymap_node: Node = $SettingsUI/SettingsList/VBoxContainer/KeyMap
@onready var info_panel: Node = $InfoPanel

signal back_to_menu

var current_button: Button
var buttons = []

func _ready():

	
	var events_text: String
	var i=0;
	for action in InputMap.get_actions():
		if not action.substr(0, 3) == "ui_":
			events_text = ""
			for event in InputMap.action_get_events(action):
				events_text += event.as_text() + ";  "
			if not events_text.is_empty():
				events_text = events_text.erase(events_text.length() - 3, 2)
			settings_list_node.add_child(keymap_node.duplicate(8))	
			settings_list_node.get_child(++i).get_child(0).get_child(0).set_text("[center]"+action+"[center]")
			settings_list_node.get_child(i).get_child(0).get_child(1).set_text(events_text)
			settings_list_node.get_child(i).get_child(0).set_name(action)
			
	settings_list_node.get_child(1).queue_free()
	
	for key in settings_list_node.get_children():
		if(!not key):
			buttons.push_back(key.get_child(0).get_child(1))
	# Connect the buttons pressed signal:
	for button in buttons:
		button.pressed.connect(_on_button_pressed.bind(button))

# Whenerver a button is pressed, do:
func _on_button_pressed(button: Button) -> void:
	current_button = button # assign clicked button to current_button
	info_panel.show() # show the panel with the info

func _input(event: InputEvent) -> void:
	if !current_button: # return if current_button is null
		return
	
	if event is InputEventKey || event is InputEventMouseButton:
		
		# This part is for deleting duplicate assignments:
		# Add all assigned keys to a dictionary
		var all_ies : Dictionary = {}
		for ia in InputMap.get_actions():
			for iae in InputMap.action_get_events(ia):
				all_ies[iae.as_text()] = ia
		
		# check if the new key is already in the dict.
		# If yes, delete the old one.
		if all_ies.keys().has(event.as_text()):
			InputMap.action_erase_events(all_ies[event.as_text()])
		
		# This part is where the actual remapping occures:
		# Erase the event in the Input map
		
		InputMap.action_erase_events(current_button.get_parent().name)
		# And assign the new event to it
		InputMap.action_add_event(current_button.get_parent().name, event)
		
		# After a key is assigned, set current_button back to null
		current_button = null
		info_panel.hide() # hide the info panel again
		_update_labels()

func _update_labels() -> void:
	# This is just a quick way to update the labels:
	for button in buttons:
		if(is_instance_valid(button)):
			var eb : Array[InputEvent] = InputMap.action_get_events(button.get_parent().name)
			if !eb.is_empty():
				button.set_text(eb[0].as_text())
			else:
				button.set_text("")

func _on_back_pressed():
	back_to_menu.emit()
	pass # Replace with function body.
