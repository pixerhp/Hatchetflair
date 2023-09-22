extends Control

@onready var settings_list_node: Node = $SettingsUI/SettingsList


func _ready():
	settings_list_node.clear()
	var item_text: String
	for action in InputMap.get_actions():
		if not action.substr(0, 3) == "ui_":
			item_text = action + "   <-->   "
			for event in InputMap.action_get_events(action):
				item_text += event.as_text() + ", "
			settings_list_node.add_item(item_text)
