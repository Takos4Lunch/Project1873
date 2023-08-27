extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003

#bob variables
const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

# fov changes
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var crosshair = $Head/Camera3D/crosshair
@onready var pivot = $Pivot
@onready var shoulder_camera = $Pivot/ShoulderCamera

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	crosshair.position.x = get_viewport().size.x/2-32
	crosshair.position.y = get_viewport().size.y/2-32
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
		
		pivot.rotate_y(-event.relative.x * SENSITIVITY)
		shoulder_camera.rotate_x(-event.relative.y * SENSITIVITY)
		shoulder_camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	#Handle sprint
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
	#Handle camera
	if Input.is_action_just_pressed("camera"):
		_switch_camera()
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
		
	#head bobbing
	if input_dir.x>0 && Input.is_action_pressed("sprint"):
		head.rotation.z = lerp_angle(head.rotation.z, deg_to_rad(-5), 0.05)
	elif input_dir.x<0 && Input.is_action_pressed("sprint"):
		head.rotation.z = lerp_angle(head.rotation.z, deg_to_rad(5), 0.05)
	else:
		head.rotation.z = lerp_angle(head.rotation.z, deg_to_rad(0), 0.05)
	if input_dir.y>0:
		$Head/AnimationPlayer.play("bob")
	elif input_dir.y<0:
		$Head/AnimationPlayer.play("bob")
	else:
		$Head/AnimationPlayer.stop()
	#FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED *2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()

func _switch_camera():
	if camera.is_current():
		camera.set_current(false)
		shoulder_camera.set_current(true)
	else:
		camera.set_current(true)
		shoulder_camera.set_current(false)
