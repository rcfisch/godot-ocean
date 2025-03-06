class_name FloatingBox
extends CharacterBody3D

var buoyancy : float = 10
var surface : float

static var instance = self

static func get_wave_height(height: float):
	instance.surface = height
	

func _physics_process(delta):
	if position.y < surface:
		velocity.y += buoyancy
	
