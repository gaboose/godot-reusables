extends CharacterBody3D

const ACCELERATION = 40.0
const FRICTION = 15.0
const SPRINT = 2.0
const JUMP_ACCELERATION = 3.0
const JUMP_IMPULSE = 4.5
const JUMP_FRICTION = 0.01

const SPEED = ACCELERATION / FRICTION
const SPRINT_SPEED = SPEED * SPRINT

const MOUSE_SENSITIVITY = 0.002
const RIGHT_JOYSTICK_SENSITIVITY = 3.5;

var smoothed_look_input := Vector2.ZERO
const SMOOTHING := 16.0

var sprint_jump := false
var double_jump := true

func _action_add_key_event(action, keycode):
	var event = InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)

func _action_add_joypad_motion_event(action, axis, axis_value):
	var event = InputEventJoypadMotion.new()
	event.device = -1
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action, event)

func _action_add_joypad_button_event(action, button):
	var event = InputEventJoypadButton.new()
	event.device = -1
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
	
	InputMap.add_action("move_sprint")
	_action_add_key_event("move_sprint", KEY_SHIFT)
	_action_add_joypad_button_event("move_sprint", JOY_BUTTON_RIGHT_SHOULDER)
	
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
		if double_jump:
			velocity.y = JUMP_IMPULSE
			if is_on_floor():
				sprint_jump = Input.is_action_pressed("move_sprint")
			else:
				double_jump = false
		get_viewport().set_input_as_handled()
				

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		rotate_object_local(Vector3(-1, 0, 0), event.relative.y * MOUSE_SENSITIVITY)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		double_jump = true
	
	var look_input = Vector2(
		Input.get_action_strength("look_right") - Input.get_action_strength("look_left"),
		Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	)

	smoothed_look_input = smoothed_look_input.lerp(look_input, SMOOTHING * delta)

	rotate_y(-smoothed_look_input.x * RIGHT_JOYSTICK_SENSITIVITY * delta)
	rotate_object_local(Vector3(-1, 0, 0), smoothed_look_input.y * RIGHT_JOYSTICK_SENSITIVITY * delta)

	var move_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_size = move_input.length()
	var move_direction := transform.basis * Vector3(move_input.x, 0, move_input.y)
	move_direction.y = 0.0
	move_direction = move_direction.normalized() * move_size
	
	var hvel = Vector2(velocity.x, velocity.z)
	var friction = (FRICTION if is_on_floor() else JUMP_FRICTION)
	hvel.x = move_toward(hvel.x, 0, abs(hvel.x) * friction * delta)
	hvel.y = move_toward(hvel.y, 0, abs(hvel.y) * friction * delta)
	
	if move_direction:
		var acceleration = (ACCELERATION if is_on_floor() else JUMP_ACCELERATION)
		if Input.is_action_pressed("move_sprint"):
			acceleration *= SPRINT
		
		var acceleration_vector = acceleration * move_direction
		hvel.x += acceleration_vector.x * delta
		hvel.y += acceleration_vector.z * delta
	
	if !is_on_floor():
		hvel = hvel.limit_length(SPRINT_SPEED if sprint_jump else SPEED)
	
	velocity.x = hvel.x
	velocity.z = hvel.y

	move_and_slide()
