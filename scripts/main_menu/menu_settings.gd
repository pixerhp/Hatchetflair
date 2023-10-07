extends Control

@onready var settings_list_node: Node = $SettingsUI/SettingsList


func _ready():
	settings_list_node.clear()
	var events_text: String
	for action in InputMap.get_actions():
		if not action.substr(0, 3) == "ui_":
			events_text = ""
			for event in InputMap.action_get_events(action):
				events_text += event.as_text() + ";  "
			if not events_text.is_empty():
				events_text = events_text.erase(events_text.length() - 3, 2)
			settings_list_node.add_item(action + "   <-->   " + events_text)
