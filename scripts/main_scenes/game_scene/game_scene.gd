extends Node3D


func switch_to_main_menu():
	get_tree().change_scene_to_file("res://scenes/main_scenes/main_menu.tscn")


@onready var temporary_cam: Camera3D = $REMOVE_LATER_cam
var cam_speed = 20

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Toggle the pause menu if its associated key is pressed.
	# !!! [in the future, esc should also be able to close out of other things WITHOUT opening this menu.]
	if Input.is_action_just_pressed("game_special_pause_menu"):
		$PauseMenu.visible = not $PauseMenu.visible
	
	# Temporary controls for flying the camera around:
	
	if Input.is_action_pressed("game_play_speed_fast"):
		cam_speed = 100
	elif Input.is_action_pressed("game_play_speed_slow"):
		cam_speed = 2
	else:
		cam_speed = 20
	
	if Input.is_action_pressed("game_play_move_forwards"):
		temporary_cam.position += (cam_speed * delta * -1) * temporary_cam.global_transform.basis.z
	if Input.is_action_pressed("game_play_move_backwards"):
		temporary_cam.position += (cam_speed * delta) * temporary_cam.global_transform.basis.z
	if Input.is_action_pressed("game_play_move_strafeleft"):
		temporary_cam.position += (cam_speed * delta * -1) * temporary_cam.global_transform.basis.x
	if Input.is_action_pressed("game_play_move_straferight"):
		temporary_cam.position += (cam_speed * delta) * temporary_cam.global_transform.basis.x
	if Input.is_action_pressed("game_play_drop_throw_letgo"):
		temporary_cam.position += (cam_speed * delta * -1) * temporary_cam.global_transform.basis.y
	if Input.is_action_pressed("game_play_interact_act"):
		temporary_cam.position += (cam_speed * delta) * temporary_cam.global_transform.basis.y
	if Input.is_action_pressed("game_play_jump"):
		temporary_cam.position += (cam_speed * delta) * Vector3(0,1,0)
	if Input.is_action_pressed("game_play_crouch_slide_crawl"):
		temporary_cam.position += (cam_speed * delta) * Vector3(0,-1,0)
	
	if (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED) and not (Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event) -> void:
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			# !!! research *why* these need to be multiplied by such a small number,
			# potentially allowing a proper/known conversion like "angle per mouse pixel" (or similar.)
			temporary_cam.rotation.y += event.relative.x * -0.005
			temporary_cam.rotation.x += event.relative.y * -0.005
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_pausemenu_resumegameplay_pressed():
	# !!! Later, the game world may be actually paused by the pause-menu in singleplayer, unpause it here.
	$PauseMenu.visible = false
func _on_pausemenu_toggleplaying_pressed():
	pass
func _on_pausemenu_settings_pressed():
	$PauseMenu.visible = false
	$SettingsMenu.visible = true
	pass
func _on_pausemenu_saveandquit_pressed():
	# !!! Remember to SAVE and quit later.
	switch_to_main_menu()


func _on_close_settings_menu():
	$SettingsMenu.visible = false
	$PauseMenu.visible = true
	pass # Replace with function body.
