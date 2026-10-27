class_name Player
extends CharacterBody3D

signal started_moving

const SPEED := 3.8
const TURN_SPEED := 2.2
const ACCEL := 24.0
const SNAP_SPEED := 8.0

var touch_input := Vector2.ZERO
var started := false
var bob_time := 0.0
var base_camera_y := 0.0

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	base_camera_y = camera.position.y
	var headlamp := $Camera3D/Headlamp as SpotLight3D
	var projector := GradientTexture2D.new()
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(0.55, 0.55, 0.55, 1), Color(0, 0, 0, 1)])
	projector.gradient = gradient
	projector.fill = GradientTexture2D.FILL_RADIAL
	projector.fill_from = Vector2(0.5, 0.5)
	projector.fill_to = Vector2(0.5, 0.0)
	projector.width = 128
	projector.height = 128
	headlamp.light_projector = projector

func set_move_input(value: Vector2) -> void:
	touch_input = value

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	var input_vec := touch_input
	if input_vec.length() < 0.01:
		var keyboard := Vector2.ZERO
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			keyboard.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			keyboard.x += 1.0
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			keyboard.y -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			keyboard.y += 1.0
		input_vec = keyboard.normalized() if keyboard.length() > 1.0 else keyboard
	var forward := -input_vec.y
	var turn := input_vec.x
	if abs(turn) > 0.05:
		rotate_y(-turn * TURN_SPEED * delta)
	elif abs(forward) > 0.05:
		var snapped := snappedf(rotation.y, PI * 0.5)
		rotation.y = lerp_angle(rotation.y, snapped, min(1.0, SNAP_SPEED * delta))
	var target_velocity := -transform.basis.z * forward * SPEED
	if forward < 0.0:
		target_velocity *= 0.65
	velocity.x = move_toward(velocity.x, target_velocity.x, ACCEL * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, ACCEL * delta)
	move_and_slide()
	var speed_ratio := clampf(Vector2(velocity.x, velocity.z).length() / SPEED, 0.0, 1.0)
	bob_time += delta * (6.0 + speed_ratio * 6.0)
	camera.position.y = base_camera_y + sin(bob_time) * 0.025 * speed_ratio
	camera.rotation.z = lerpf(camera.rotation.z, -turn * 0.035, min(1.0, 10.0 * delta))
	if not started and input_vec.length() > 0.1:
		started = true
		started_moving.emit()
