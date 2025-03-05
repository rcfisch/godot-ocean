class_name Player 
extends CharacterBody3D

@export_category("Player")
@export_range(1, 35, 1) var speed : float = 10 # m/s
@export_range(10, 400, 1) var acceleration : float = 100 # m/s^2

@export_range(0.1, 3.0, 0.1, "or_greater") var camera_sens: float = 1
@export var drag : float = 0.3 # Lerp value: 0 = no drag, 1 = instant stop
@export var gravity : float = 5
@export var max_fall_speed : float = 200

var mouse_captured: bool = false

var entered_water_cooldown : float = 0
var move_dir: Vector2 # Input direction for movement
var look_dir: Vector2 # Input direction for look/aim
var vert_dir: int # Input direction for moving up/down
var walk_vel: Vector3 # Walking velocity 
var grav_vel: float # Gravity velocity 
var started_falling : bool = false
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
	if GlobalVar.player_is_surfaced and !is_on_floor():
		if grav_vel < max_fall_speed:
			grav_vel -= gravity
	else: grav_vel = 0
	#print(GlobalVar.player_is_surfaced)
	if Input.is_action_pressed("sprint"):
		speed = 350
		acceleration = 1000
		drag = 1
	else: 
		speed = 35
		acceleration = 100
		drag = 0.3
	if is_on_floor():
		velocity = _walk(delta)
	else:
		if GlobalVar.player_is_surfaced:
			velocity = lerp(velocity, air_control(delta) + apply_gravity(delta), 0.1)
			entered_water_cooldown = 40
			swim(delta)
		else:
			entered_water_cooldown = max(0, entered_water_cooldown - 1)
			if entered_water_cooldown > 20:
				velocity = lerp(velocity, swim(delta) + apply_gravity(delta), 0.1)
			elif entered_water_cooldown > 0:
				velocity = lerp(velocity, air_control(delta) + apply_gravity(delta), 0.1)
			else:
				if Input.is_action_pressed("down") or Input.is_action_pressed("up") or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") or Input.is_action_pressed("move_backwards") or Input.is_action_pressed("move_forward"):
					velocity = lerp(velocity, swim(delta) + apply_gravity(delta), 0.7)
				else:
					velocity = lerp(velocity, swim(delta) + apply_gravity(delta), 0.1)
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
	walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration * delta) # calculate walking velocity
	return walk_vel
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
	#print(move_dir)
	walk_vel = walk_vel.move_toward(walk_dir * speed * Vector3(move_dir.x, -vert_dir, move_dir.y).length(), acceleration * delta) # calculate walking velocity
	if GlobalVar.player_is_surfaced and velocity.y < 0:
		if !started_falling:
			grav_vel = gravity
			started_falling = true
		walk_vel = Vector3(walk_vel.x, 0, walk_vel.z)
	if !GlobalVar.player_is_surfaced:
		started_falling = false
	return walk_vel
func apply_gravity(delta: float) -> Vector3:
	return Vector3(0, grav_vel, 0)
