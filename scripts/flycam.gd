extends Node

func _process(_delta):
	DebugDraw.texts_to_draw.append("cam x: " + str(self.position.x))
	DebugDraw.texts_to_draw.append("cam y: " + str(self.position.y))
	DebugDraw.texts_to_draw.append("cam z: " + str(self.position.z))
	#DebugDraw.lines_to_draw.append([Vector3(-5,-5,-5),Vector3(-5,-5,50),Color(0,1,0.5)])

var fly_speed: float = 0
var fly_direction_vector: Vector3 = Vector3()
func _physics_process(delta):
	# Determine fly speed:
	if Input.is_action_pressed("speed_faster"):
		fly_speed = 32 if fly_speed < 32 else (fly_speed * (1 + delta/4))
	elif Input.is_action_pressed("speed_slower"):
		fly_speed = 0.25
	else:
		fly_speed = 8
	
	# Determine fly direction:
	fly_direction_vector = Vector3(0, 0, 0)
	if Input.is_action_pressed("move_backwards"):
		fly_direction_vector += self.global_transform.basis.z
	if Input.is_action_pressed("move_forwards"):
		fly_direction_vector += -1 * self.global_transform.basis.z
	if Input.is_action_pressed("move_left"):
		fly_direction_vector += -1 * self.global_transform.basis.x
	if Input.is_action_pressed("move_right"):
		fly_direction_vector += self.global_transform.basis.x
	if Input.is_action_pressed("move_jump_up"):
		fly_direction_vector += Vector3(0,1,0)
	if Input.is_action_pressed("move_crouch_down"):
		fly_direction_vector += Vector3(0,-1,0)
	if Input.is_action_pressed("move_relative_down"):
		fly_direction_vector += -1 * self.global_transform.basis.y
	if Input.is_action_pressed("move_relative_up"):
		fly_direction_vector += self.global_transform.basis.y
	
	# Handle fly movement:
	fly_direction_vector = fly_direction_vector.normalized()
	self.position += fly_speed * delta * fly_direction_vector

# Handle mouse grabbing and rotation controls for fly cam:
var previous_mouse_pos: Vector2 = Vector2(0, 0)
func _input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
				previous_mouse_pos = get_viewport().get_mouse_position()
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				Input.warp_mouse(previous_mouse_pos)
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			# presumably, mouse movement is in pixels (and rotation is in radians).
			self.rotation.y += event.relative.x * -0.005
			self.rotation.x += event.relative.y * -0.005
	return
