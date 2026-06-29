extends PanelContainer

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_controls"):
		visible = not visible
