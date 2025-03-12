extends Node3D


func switch_to_main_menu():
	get_tree().change_scene_to_file("res://scenes/main_scenes/main_menu.tscn")

@onready var chunk_manager_node: Object = $ChunksManager

@onready var temporary_cam: Camera3D = $REMOVE_LATER_cam
var cam_speed = 20

var previous_mouse_position: Vector2 = Vector2(0, 0)
var fast_cam_flying_held_duration: float = 0
func _process(delta):
	# Toggle the pause menu if its associated key is pressed.
	# !!! [in the future, esc should also be able to close out of other things WITHOUT opening this menu.]
	if Input.is_action_just_pressed("escape_pausemenu") and not $SettingsMenu.visible:
		$PauseMenu.visible = not $PauseMenu.visible
	
	if Input.is_action_just_pressed("spec_hud"):
		print("(Toggling/altering your HUD is not yet implemented.)")
	if Input.is_action_just_pressed("spec_perspective"):
		print("(Changing/modifying your view perspective is not yet implemented.)")
	
	# Temporary controls for flying the testing camera around:
	if Input.is_action_pressed("speed_up"):
		fast_cam_flying_held_duration += delta
		cam_speed = 120 + pow((fast_cam_flying_held_duration * 4) + 1, 2)
	elif Input.is_action_pressed("speed_down"):
		fast_cam_flying_held_duration = 0
		cam_speed = 0.5
	else:
		fast_cam_flying_held_duration = 0
		cam_speed = 15
	
	
	if Input.is_action_pressed("move_forwards"):
		temporary_cam.position += (cam_speed * delta * -1) * temporary_cam.global_transform.basis.z
	if Input.is_action_pressed("move_backwards"):
		temporary_cam.position += (cam_speed * delta) * temporary_cam.global_transform.basis.z
	if Input.is_action_pressed("move_left"):
		temporary_cam.position += (cam_speed * delta * -1) * temporary_cam.global_transform.basis.x
	if Input.is_action_pressed("move_right"):
		temporary_cam.position += (cam_speed * delta) * temporary_cam.global_transform.basis.x
	if Input.is_action_pressed("move_relative_down"):
		temporary_cam.position += (cam_speed * delta * -1) * temporary_cam.global_transform.basis.y
	if Input.is_action_pressed("move_relative_up"):
		temporary_cam.position += (cam_speed * delta) * temporary_cam.global_transform.basis.y
	if Input.is_action_pressed("move_jump_up"):
		temporary_cam.position += (cam_speed * delta) * Vector3(0,1,0)
	if Input.is_action_pressed("move_crouch_down"):
		temporary_cam.position += (cam_speed * delta) * Vector3(0,-1,0)
	
	if Input.is_action_just_pressed("debug_lag_spike"):
		var prev_fps := Engine.max_fps
		Engine.max_fps = 1
		await get_tree().create_timer(0.9, true, true, true).timeout
		Engine.max_fps = prev_fps
	
	# debug toggles:
	if Input.is_action_just_pressed("debug_info"):
		Globals.draw_debug_info_text = not Globals.draw_debug_info_text
		print("draw debug text toggled: ", "ON" if Globals.draw_debug_info_text else "OFF")
	if Input.is_action_just_pressed("debug_borders"):
		Globals.draw_debug_chunk_borders = not Globals.draw_debug_chunk_borders
		print("draw debug chunk borders toggled: ", "ON" if Globals.draw_debug_chunk_borders else "OFF")
	 
	# Coordinates text:
	if Input.is_action_pressed("speed_up"):
		DebugDraw.add_text("coords (h,z₁,z₂): " +
			"(" + str(Globals.get_coords3d_string(Globals.swap_xyz_hzz_f($REMOVE_LATER_cam.position), -1)) + ")")
	elif Input.is_action_pressed("speed_down"):
		DebugDraw.add_text("coords (h,z₁,z₂): " + 
			"(" + str(Globals.get_coords3d_string(Globals.swap_xyz_hzz_f($REMOVE_LATER_cam.position), 6)) + ")")
	else:
		DebugDraw.add_text("coords (h,z₁,z₂): " + 
			"(" + str(Globals.get_coords3d_string(Globals.swap_xyz_hzz_f($REMOVE_LATER_cam.position), 2)) + ")")
	
	if Input.is_action_pressed("speed_up"):
		DebugDraw.add_text("coords (x, y, z): " +
			"(" + str(Globals.get_coords3d_string($REMOVE_LATER_cam.position, -1)) + ")")
	elif Input.is_action_pressed("speed_down"):
		DebugDraw.add_text("coords (x, y, z): " + 
			"(" + str(Globals.get_coords3d_string($REMOVE_LATER_cam.position, 6)) + ")")
	else:
		DebugDraw.add_text("coords (x, y, z): " + 
			"(" + str(Globals.get_coords3d_string($REMOVE_LATER_cam.position, 2)) + ")")
	
	if Globals.draw_debug_info_text:
		DebugDraw.add_text("(counted) fps: " + str(Performance.get_monitor(Performance.TIME_FPS)))
		DebugDraw.add_text("")
		DebugDraw.add_text("draw calls: " + str(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		DebugDraw.add_text("total primatives: " + str(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
		DebugDraw.add_text("render buffer mem used: " + String.humanize_size(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)))
		DebugDraw.add_text("render texture mem used: " + String.humanize_size(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)))
		DebugDraw.add_text("")
		DebugDraw.add_text("object count: " + str(Performance.get_monitor(Performance.OBJECT_COUNT)))
		DebugDraw.add_text("object resource count: " + str(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)))
		DebugDraw.add_text("object node count: " + str(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		DebugDraw.add_text("object orphan node count: " + str(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)))
		DebugDraw.add_text("")
		DebugDraw.add_text("static memory used: " + String.humanize_size(Performance.get_monitor(Performance.MEMORY_STATIC)))
		DebugDraw.add_text("max static memory: " + String.humanize_size(Performance.get_monitor(Performance.MEMORY_STATIC_MAX)))
	
	 
	if Globals.draw_debug_chunk_borders:
		DebugDraw.draw_axes(Transform3D(Basis(), 
			temporary_cam.global_position + Vector3(0, 0.75, 0) - 4 * temporary_cam.global_transform.basis.z), 1, true)
		DebugDraw.draw_axes(Transform3D(Basis(), 
			temporary_cam.global_position + Vector3(0, -0.75, 0) - 4 * temporary_cam.global_transform.basis.z), 1, false)
		DebugDraw.player_position_for_chunk_borders = temporary_cam.global_position

func _input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
				previous_mouse_position = get_viewport().get_mouse_position()
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				Input.warp_mouse(previous_mouse_position)
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			# !!! research *why* these need to be multiplied by such a small number,
			# potentially allowing a proper/known conversion like "angle per mouse unit" (or similar.)
			temporary_cam.rotation.y += event.relative.x * -0.005
			temporary_cam.rotation.x += event.relative.y * -0.005

func _on_pausemenu_resumegameplay_pressed():
	# !!! Later, the game world may be actually paused by the pause-menu in singleplayer, unpause it here.
	$PauseMenu.visible = false
func _on_pausemenu_settings_pressed():
	$PauseMenu.visible = false
	$SettingsMenu.visible = true
	pass
func _on_pausemenu_toggleafk_pressed():
	pass
func _on_resetcharacter_pressed():
	pass
func _on_pausemenu_saveandquit_pressed():
	# Wait for the chunks manager to finish up its work, such as saving currently loaded chunks.
	await chunk_manager_node.chunks_manager_thread_ended
	
	switch_to_main_menu()


func _on_close_settings_menu():
	$SettingsMenu.visible = false
	$PauseMenu.visible = true
	pass # Replace with function body.
