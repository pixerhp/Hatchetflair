extends PanelContainer

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("controls_toggle"):
		visible = not visible
