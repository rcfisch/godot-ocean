class_name Player 
extends CharacterBody3D

@export_category("Player")
@export_range(1, 35, 1) var speed : float = 10 # m/s
@export_range(10, 400, 1) var acceleration : float = 100 # m/s^2

@export_range(0.1, 3.0, 0.1, "or_greater") var camera_sens: float = 1

var mouse_captured: bool = false

var move_dir: Vector2 # Input direction for movement
var look_dir: Vector2 # Input direction for look/aim
var walk_vel: Vector3 # Walking velocity 
@onready var camera : Camera3D = $Camera

func _ready() -> void:
	camera.make_current()
	capture_mouse()
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		look_dir = event.relative * 0.001
		if mouse_captured: _rotate_camera()
	
func _physics_process(delta: float) -> void:
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
