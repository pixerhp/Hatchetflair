extends CharacterBody3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var character: CharacterBody3D = self

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

const WALK_SPEED = 5.0

func _ready():
	animation_player.set_assigned_animation("walk")

var action_timer: int = 180
enum actions_enums {IDLE, WALK}
var action_type: int = actions_enums.IDLE
var walk_direction: Vector2 = Vector2.ZERO
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	action_timer -= 1
	if action_timer <= 0:
		action_timer = randi_range(30, 480)
		if action_type == actions_enums.IDLE:
			action_type = actions_enums.WALK
		else:
			action_type = actions_enums.IDLE
		
		match action_type:
			actions_enums.IDLE:
				animation_player.set_assigned_animation("walk")
				animation_player.stop()
				walk_direction = Vector2.ZERO
			actions_enums.WALK:
				animation_player.set_assigned_animation("walk")
				animation_player.play()
				character.rotation.y = randf_range((-PI), (PI))
				walk_direction = Vector2.UP
	
	
	var direction = (transform.basis * Vector3(walk_direction.x, 0, walk_direction.y)).normalized()
	velocity.x = direction.x * WALK_SPEED
	velocity.z = direction.z * WALK_SPEED
	
	move_and_slide()
