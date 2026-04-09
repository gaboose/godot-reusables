extends CharacterBody3D

const SPEED = 5.0
const ACCELERATION = 50.0
const JUMP_ACCELERATION = 10.0
const JUMP_VELOCITY = 4.5

# Converts mouse movement (pixels) to rotation (radians).
const MOUSE_SENSITIVITY = 0.002
const RIGHT_JOYSTICK_SENSITIVITY = 3.5;

var smoothed_look_input := Vector2.ZERO
const SMOOTHING := 16.0

func _action_add_key_event(action, keycode):
	var event = InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)

func _action_add_joypad_motion_event(action, axis, axis_value):
	var event = InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action, event)

func _action_add_joypad_button_event(action, button):
	var event = InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)

func _ready() -> void:
	InputMap.add_action("move_left")
	_action_add_key_event("move_left", KEY_A)
	_action_add_joypad_motion_event("move_left", JOY_AXIS_LEFT_X, -1.0)
	
	InputMap.add_action("move_right")
	_action_add_key_event("move_right", KEY_D)
	_action_add_joypad_motion_event("move_right", JOY_AXIS_LEFT_X, 1.0)
	
	InputMap.add_action("move_forward")
	_action_add_key_event("move_forward", KEY_W)
	_action_add_joypad_motion_event("move_forward", JOY_AXIS_LEFT_Y, -1.0)
	
	InputMap.add_action("move_back")
	_action_add_key_event("move_back", KEY_S)
	_action_add_joypad_motion_event("move_back", JOY_AXIS_LEFT_Y, 1.0)
	
	InputMap.add_action("move_jump")
	_action_add_key_event("move_jump", KEY_SPACE)
	_action_add_joypad_button_event("move_jump", JOY_BUTTON_A)
	
	InputMap.add_action("look_left")
	_action_add_joypad_motion_event("look_left", JOY_AXIS_RIGHT_X, -1.0)
	
	InputMap.add_action("look_right")
	_action_add_joypad_motion_event("look_right", JOY_AXIS_RIGHT_X, 1.0)
	
	InputMap.add_action("look_up")
	_action_add_joypad_motion_event("look_up", JOY_AXIS_RIGHT_Y, -1.0)
	
	InputMap.add_action("look_down")
	_action_add_joypad_motion_event("look_down", JOY_AXIS_RIGHT_Y, 1.0)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("move_jump"):
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
	
	# Rotate based on look actions
	var look_input = Vector2(
		Input.get_action_strength("look_right") - Input.get_action_strength("look_left"),
		Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	)

	smoothed_look_input = smoothed_look_input.lerp(look_input, SMOOTHING * delta)

	rotate_y(-smoothed_look_input.x * RIGHT_JOYSTICK_SENSITIVITY * delta)
	rotate_object_local(Vector3(-1, 0, 0), smoothed_look_input.y * RIGHT_JOYSTICK_SENSITIVITY * delta)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	
	if direction:
		var acceleration = (ACCELERATION if is_on_floor() else JUMP_ACCELERATION) * delta * direction
		velocity.x += acceleration.x
		velocity.z += acceleration.z
		velocity = velocity.limit_length(direction.length()*SPEED)
	elif is_on_floor():
		var acceleration = ACCELERATION * delta;
		velocity.x = move_toward(velocity.x, 0, acceleration)
		velocity.z = move_toward(velocity.z, 0, acceleration)

	move_and_slide()
