class_name Player 
extends CharacterBody3D

@export_category("Player")
@export_range(1, 35, 1) var accel : float = 5 # m/s
@export_range(1, 100, 1) var dash_accel : float = 50 # m/s
var speed : float = 5 # m/s
@export_range(1, 200, 1) var speed_cap : float = 70 # m/s
@export_range(1, 1000, 1) var dash_speed_cap : float = 350 # m/s
var max_speed : float = 70 # m/s
@export_range(1, 100, 1) var walk_speed : float = 60 # m/s
@export_range(10, 400, 1) var acceleration : float = 100 # m/s^2
@export_range(10, 400, 1) var land_acceleration : float = 300 # m/s^2

@export_range(0.1, 3.0, 0.1, "or_greater") var camera_sens: float = 1
@export var drag : float = 0.3 # Lerp value: 0 = no drag, 1 = instant stop
@export var gravity : float = 8
@export var max_fall_speed : float = 180

var mouse_captured: bool = false

var move_dir: Vector2 # Input direction for movement
var look_dir: Vector2 # Input direction for look/aim
var vert_dir: int # Input direction for moving up/down
var walk_vel: Vector3 # Walking velocity 
var grav_vel: float # Gravity velocity 
var falling_grav_vel : float
var started_falling : bool = false
var land_friction : float = 10
var water_friction : float = 4
var air_friction : float = 2
var rv : Vector3 # PLAYER'S RELATIVE VELOCITY
var stored_vel : Vector3
@onready var camera : Camera3D = $Camera

func _ready() -> void:
	camera.make_current()
	capture_mouse()
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		look_dir = event.relative * 0.001
		if mouse_captured: 
			_rotate_camera()
 			
	
func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("sprint"):
		speed = dash_accel
		max_speed = dash_speed_cap
	else:
		speed = accel
		max_speed = speed_cap
	swim(delta)
	air_control(delta)
	_walk(delta)
	if is_on_floor():
		rv += _walk(delta).normalized() * land_acceleration
	elif !GlobalVar.player_is_surfaced:
		rv += swim(delta).normalized() * speed
	else: 
		rv += air_control(delta).normalized() * speed
# Ensure velocity doesn't exceed max_speed
	if !Input.get_vector("move_left", "move_right", "move_forward", "move_backwards") == Vector2.ZERO or !Input.get_axis("up","down") == 0:
		if rv.length() > max_speed:
			rv = rv.normalized() * max_speed
	calculate_y_vel(delta)
	apply_friction(delta)
	stored_vel = rv
	velocity += rv
	print(velocity)
	move_and_slide()
	velocity -= stored_vel


func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true
func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false
func _rotate_camera(sens_mod: float = 1.0) -> void:
	camera.rotation.y -= look_dir.x * camera_sens * sens_mod
	camera.rotation.x = clamp(camera.rotation.x - look_dir.y * camera_sens * sens_mod, -1.5, 1.5)
func _walk(delta: float) -> Vector3:
	move_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards") # get input direction
	var _forward: Vector3 = camera.global_transform.basis * Vector3(move_dir.x, 0, move_dir.y) # get a vector for the direction you're facing
	var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized() # normalize vector and get walk direction
	walk_vel = walk_dir * speed * move_dir.length() # calculate walking velocity
	if move_dir != Vector2.ZERO:
		return walk_vel
	else: return lerp(velocity, Vector3.ZERO, 0.2)
func air_control(delta: float) -> Vector3:
	move_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards") # get input direction
	var _forward: Vector3 = camera.global_transform.basis * Vector3(move_dir.x, 0, move_dir.y) # get a vector for the direction you're facing
	var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized() # normalize vector and get walk direction
	walk_vel = walk_dir * speed * move_dir.length() # calculate walking velocity
	return walk_vel
func swim(delta: float) -> Vector3:
	move_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards") # get input direction
	vert_dir = Input.get_axis("up","down")
	var _forward: Vector3 = camera.global_transform.basis * Vector3(move_dir.x, -vert_dir, move_dir.y) # get a vector for the direction you're facing
	if vert_dir != 0:
		_forward = Vector3(_forward.x, -vert_dir, _forward.z)
	var walk_dir: Vector3 = _forward.normalized() # normalize vector and get move direction
	walk_vel = walk_dir * speed * Vector3(move_dir.x, -vert_dir, move_dir.y).length()
	return walk_vel 
func apply_friction(delta):
	if !GlobalVar.player_is_surfaced:
		velocity = lerp(velocity, Vector3.ZERO, 0.1)
	elif is_on_floor(): velocity = lerp(velocity, Vector3.ZERO, 0.2)
	else: velocity = lerp(velocity, Vector3.ZERO, 0.02)
	if !GlobalVar.player_is_surfaced:
		rv = lerp(rv, Vector3.ZERO, 0.1)
	elif is_on_floor(): rv = lerp(rv, Vector3.ZERO, 0.2)
	else: rv = lerp(rv, Vector3.ZERO, 0.02)
func calculate_y_vel(delta):
	if GlobalVar.player_is_surfaced and !is_on_floor():
		velocity.y = max(-max_fall_speed, velocity.y - gravity)
	if is_on_floor():
		stored_vel.y = 0
		velocity.y = 0
	
