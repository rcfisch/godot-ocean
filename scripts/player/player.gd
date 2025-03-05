class_name Player 
extends CharacterBody3D

@export_category("Player")
@export_range(1, 35, 1) var speed : float = 5 # m/s
@export_range(1, 300, 1) var max_speed : float = 70 # m/s
@export_range(1, 100, 1) var walk_speed : float = 60 # m/s
@export_range(10, 400, 1) var acceleration : float = 100 # m/s^2
@export_range(10, 400, 1) var land_acceleration : float = 300 # m/s^2

@export_range(0.1, 3.0, 0.1, "or_greater") var camera_sens: float = 1
@export var drag : float = 0.3 # Lerp value: 0 = no drag, 1 = instant stop
@export var gravity : float = 8
@export var max_fall_speed : float = 180

var mouse_captured: bool = false

var water_entered = false
var surfaced = false
var move_dir: Vector2 # Input direction for movement
var look_dir: Vector2 # Input direction for look/aim
var vert_dir: int # Input direction for moving up/down
var walk_vel: Vector3 # Walking velocity 
var grav_vel: float # Gravity velocity 
var buoy_vel: float # Buoyancy velocity 
var started_falling : bool = false
var land_friction : float = 10
var water_friction : float = 4
var air_friction : float = 2
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
	swim(delta)
	print(buoy_vel)
	if is_on_floor():
		velocity = _walk(delta)
	else:
			velocity += swim(delta).normalized() * speed
# Ensure velocity doesn't exceed max_speed
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed
	apply_gravity(delta)
	apply_buoyancy(delta)
	apply_friction(delta)
	calculate_y_vel(delta)
	move_and_slide()


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
	walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), land_acceleration * delta) # calculate walking velocity
	if move_dir != Vector2.ZERO:
		return walk_vel
	else: return lerp(velocity, Vector3.ZERO, 0.2)
func air_control(delta: float) -> Vector3:
	move_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards") # get input direction
	var _forward: Vector3 = camera.global_transform.basis * Vector3(move_dir.x, 0, move_dir.y) # get a vector for the direction you're facing
	var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized() # normalize vector and get walk direction
	walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration * delta) # calculate walking velocity
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
	if Input.get_vector("move_left", "move_right", "move_forward", "move_backwards") == Vector2.ZERO and Input.get_axis("up","down") == 0:
		velocity = lerp(velocity, Vector3.ZERO, 0.1)
func apply_gravity(delta):
	if GlobalVar.player_is_surfaced and !surfaced:
		surfaced = true
		grav_vel = 0
	if !GlobalVar.player_is_surfaced and surfaced:
		surfaced = false
		if grav_vel > -60:
			buoy_vel = -grav_vel
	grav_vel = max(-max_fall_speed, grav_vel - gravity)
func apply_buoyancy(delta):
	if !GlobalVar.player_is_surfaced:
		buoy_vel = min(max_fall_speed, buoy_vel + gravity)
	else:
		buoy_vel = 0
func calculate_y_vel(delta):
	velocity.y = velocity.y + grav_vel + buoy_vel
	
