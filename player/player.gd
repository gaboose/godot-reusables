extends CharacterBody3D

const SPEED = 5.0
const ACCELERATION = 50.0
const JUMP_ACCELERATION = 10.0
const JUMP_VELOCITY = 4.5

# Converts mouse movement (pixels) to rotation (radians).
const MOUSE_SENSITIVITY = 0.002

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY
		get_viewport().set_input_as_handled()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		rotate_object_local(Vector3(-1, 0, 0), event.relative.y * MOUSE_SENSITIVITY)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		var acceleration = (ACCELERATION if is_on_floor() else JUMP_ACCELERATION) * delta * direction
		velocity.x += acceleration.x
		velocity.z += acceleration.z
		velocity = velocity.limit_length(SPEED)
	elif is_on_floor():
		var acceleration = ACCELERATION * delta;
		velocity.x = move_toward(velocity.x, 0, acceleration)
		velocity.z = move_toward(velocity.z, 0, acceleration)

	move_and_slide()
