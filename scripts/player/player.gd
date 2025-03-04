class_name Player 
extends CharacterBody3D

@export_category("Player")
@export_range(1, 35, 1) var speed : float = 10 # m/s
@export_range(10, 400, 1) var acceleration : float = 100 # m/s^2

@export_range(0.1, 3.0, 0.1, "or_greater") var camera_sens: float = 1

var mouse_captured: bool = false

var move_dir: Vector2 # Input direction for movement
var look_dir: Vector2 # Input direction for look/aim
var vert_dir: int # Input direction for moving up/down
var walk_vel: Vector3 # Walking velocity 
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
	if is_on_floor():
		velocity = _walk(delta)
	else:
		velocity = swim(delta)
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
func swim(delta: float) -> Vector3:
	move_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards") # get input direction
	vert_dir = Input.get_axis("up","down")
	var _forward: Vector3 = camera.global_transform.basis * Vector3(move_dir.x, -vert_dir, move_dir.y) # get a vector for the direction you're facing
	var walk_dir: Vector3 = _forward.normalized() # normalize vector and get move direction
	#print(move_dir)
	walk_vel = walk_vel.move_toward(walk_dir * speed * Vector3(move_dir.x, -vert_dir, move_dir.y).length(), acceleration * delta) # calculate walking velocity
	return walk_vel
