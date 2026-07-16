extends PanelContainer

func _ready():
	%F1HelpLabel.text += (
		"\n\nversion " + 
		ProjectSettings.get_setting("application/config/version")
	)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_controls"):
		visible = not visible
