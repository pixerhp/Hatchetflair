extends Control

var current_button : Button
var buttons : Array 
@onready var info_panel : Panel = $InfoPanel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for key in $SettingsScreenUI/Hotkeys/VBoxContainer.get_children():
		buttons.push_back(key.get_child(1))
	# Connect the buttons pressed signal:
	for button in buttons:
		button.pressed.connect(_on_button_pressed.bind(button))
	
	_update_labels() # called to refresh the labels
	
	info_panel.hide() # hide the PanelContainer
	
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
		InputMap.action_erase_events(current_button.name)
		# And assign the new event to it
		InputMap.action_add_event(current_button.name, event)
		
		# After a key is assigned, set current_button back to null
		current_button = null
		info_panel.hide() # hide the info panel again
		
		_update_labels() # refresh the labels
		
func _update_labels() -> void:
	# This is just a quick way to update the labels:
	for button in buttons:
		var eb : Array[InputEvent] = InputMap.action_get_events(button.name)
		if !eb.is_empty():
			button.set_text(eb[0].as_text())
		else:
			button.set_text("")
