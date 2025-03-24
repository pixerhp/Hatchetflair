extends CharacterBody3D

# *Paige*: Hello!




# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _process(delta: float):
	# Draw coordinates debug text.
	DebugDraw.add_text("player origin offset: " + str(Globals.this_player.origin_offset))
	DebugDraw.add_text("player coordinates: ")
	if Input.is_action_pressed("speed_up"): # low precision
		DebugDraw.add_text("  →  (h,z₁,z₂): (" +
			str(Globals.get_coords3d_string(self.position, true, -1)) + ")")
		DebugDraw.add_text("  →  (x, y, z): (" +
			str(Globals.get_coords3d_string(self.position, false, -1)) + ")")
	elif Input.is_action_pressed("speed_down"): # high precision
		DebugDraw.add_text("  →  (h,z₁,z₂): (" + 
			str(Globals.get_coords3d_string(self.position, true, 6)) + ")")
		DebugDraw.add_text("  →  (x, y, z): (" + 
			str(Globals.get_coords3d_string(self.position, false, 6)) + ")")
	else: # normal precision
		DebugDraw.add_text("  →  (h,z₁,z₂): (" + 
			str(Globals.get_coords3d_string(self.position, true, 2)) + ")")
		DebugDraw.add_text("  →  (x, y, z): (" + 
			str(Globals.get_coords3d_string(self.position, false, 2)) + ")")
	
	return

func _physics_process(delta: float):
	if Input.is_action_just_pressed("spec_perspective"):
		print("(Changing/modifying your view perspective is not yet implemented.)")
	
	# Process playmode-dependant controls/animations. 
	match Globals.my_playmode:
		Globals.PLAYMODE.SPECTATOR:
			process_spectator(delta)
		Globals.PLAYMODE.SURVIVOR:
			pass
	
	if Globals.draw_debug_chunk_borders:
		DebugDraw.draw_axes(Transform3D(Basis(), 
			self.global_position + Vector3(0, 0.75, 0) - 4 * self.global_transform.basis.z), 1, true)
		DebugDraw.draw_axes(Transform3D(Basis(), 
			self.global_position + Vector3(0, -0.75, 0) - 4 * self.global_transform.basis.z), 1, false)
		# For drawing chunk-borders.
		DebugDraw.player_position_for_chunk_borders = self.global_position
	
	return


var speed_flying_held_duration: float = 0
var flying_speed: float = 0

func process_spectator(delta: float):
	if Input.is_action_pressed("speed_up"):
		speed_flying_held_duration += delta
		flying_speed = 120 + pow((speed_flying_held_duration * 4) + 1, 2)
	elif Input.is_action_pressed("speed_down"):
		speed_flying_held_duration = 0
		flying_speed = 0.5
	else:
		speed_flying_held_duration = 0
		flying_speed = 15
	
	if Input.is_action_pressed("move_forwards"):
		self.position += (flying_speed * delta * -1) * self.global_transform.basis.z
	if Input.is_action_pressed("move_backwards"):
		self.position += (flying_speed * delta) * self.global_transform.basis.z
	if Input.is_action_pressed("move_left"):
		self.position += (flying_speed * delta * -1) * self.global_transform.basis.x
	if Input.is_action_pressed("move_right"):
		self.position += (flying_speed * delta) * self.global_transform.basis.x
	if Input.is_action_pressed("move_relative_down"):
		self.position += (flying_speed * delta * -1) * self.global_transform.basis.y
	if Input.is_action_pressed("move_relative_up"):
		self.position += (flying_speed * delta) * self.global_transform.basis.y
	if Input.is_action_pressed("move_jump_up"):
		self.position += (flying_speed * delta) * Vector3(0,1,0)
	if Input.is_action_pressed("move_crouch_down"):
		self.position += (flying_speed * delta) * Vector3(0,-1,0)
	
	return


var previous_mouse_position: Vector2 = Vector2(0, 0)
func _input(event) -> void:
	if Globals.my_playmode == Globals.PLAYMODE.SPECTATOR:
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
				self.rotation.y += event.relative.x * -0.005
				self.rotation.x += event.relative.y * -0.005
	return
