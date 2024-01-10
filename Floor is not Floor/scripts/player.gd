extends CharacterBody3D

@onready var camera_mount = $camera_mount
@onready var animation = $visuals/mixamo_base/AnimationPlayer

@export var SPEED = 10
@export var JUMP_VELOCITY = 5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var horizontal_sens := 0.1
var vertical_sens := 0.1

var time: float = 0
var score := 0
var resetPosition: Vector3 = Vector3.ZERO

func _ready():
	resetPosition = global_transform.origin

func handle_jump():
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		if animation.current_animation != "kick":
			animation.play("kick")
		velocity.y = JUMP_VELOCITY * 5

func handle_collisions():
	for index in get_slide_collision_count():
		var collision = get_slide_collision(index)
		if collision.get_collider().is_in_group("wall"):
			score += fmod(time, 60)
		elif not is_on_floor():
			score += fmod(time, 60)
		else:
			score = 0
		if collision.get_collider().is_in_group("wall"):
			if Input.is_action_just_pressed("ui_accept"):
				velocity.y = JUMP_VELOCITY * 5
				velocity.x = velocity.x * -1
				velocity.z = velocity.z * -1

func handle_camera(event: InputEvent):
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			rotate_y(deg_to_rad(-event.relative.x * horizontal_sens))
			$visuals.rotate_y(deg_to_rad(event.relative.x * horizontal_sens))
			if camera_mount.rotation.x < -1:
				camera_mount.rotation.x = -1
			elif camera_mount.rotation.x > 1:
				camera_mount.rotation.x = 1
			else:
				camera_mount.rotate_x(deg_to_rad(-event.relative.y * vertical_sens))

func handle_movements():
	var input_dir = Input.get_vector("LEFT", "RIGHT", "UP", "DOWN")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var isJumping = animation.current_animation != "kick"
	var extraVel := Vector3.ZERO
	
	if Input.is_action_just_pressed("ESCAPE"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		$CanvasLayer/menu.visible = true
	if Input.is_action_just_pressed("RESET"):
		position = resetPosition
	if direction:
		if Input.is_action_just_pressed("DASH"):
			global_transform.origin = global_transform.origin - $camera_mount/Camera3D.global_transform.origin
		if Input.is_action_pressed("RUNNING") :
			if animation.current_animation != "running" and isJumping:
				animation.play("running")

			velocity.x = direction.x * (SPEED * 2)
			velocity.z = direction.z * (SPEED * 2)
		else:
			if animation.current_animation != "walking" and isJumping:
				animation.play("walking")

			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			
		$visuals.look_at(position + direction)
	else:
		if animation.current_animation != "idle" and isJumping:
			animation.play("idle")

		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	handle_camera(event)

func _physics_process(delta):
	time += delta
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta * 4

	# Handle jump.
	handle_jump()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	handle_movements()
	handle_collisions()
	
func _process(delta):
	$CanvasLayer/score/Button/Label.text = str(score)
