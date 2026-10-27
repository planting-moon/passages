class_name Joystick
extends Control

signal value_changed(value: Vector2)

const DEADZONE := 0.15
const KNOB_RADIUS := 42.0

var _raw := Vector2.ZERO
var _value := Vector2.ZERO
var _active := false
var _touch_index := -1
var _mouse_active := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func reset() -> void:
	_release()

func get_value() -> Vector2:
	return _value

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not _active and _is_inside(event.position):
			_active = true
			_touch_index = event.index
			_mouse_active = false
			_update_from_global(event.position)
		elif not event.pressed and _active and event.index == _touch_index:
			_release()
	elif event is InputEventScreenDrag:
		if _active and event.index == _touch_index:
			_update_from_global(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not _active and _is_inside(event.position):
			_active = true
			_mouse_active = true
			_touch_index = -1
			_update_from_global(event.position)
		elif not event.pressed and _active and _mouse_active:
			_release()
	elif event is InputEventMouseMotion and _active and _mouse_active:
		_update_from_global(event.position)

func _is_inside(global_pos: Vector2) -> bool:
	return Rect2(global_position, size).has_point(global_pos)

func _update_from_global(global_pos: Vector2) -> void:
	var center := global_position + size * 0.5
	var radius := _radius()
	_raw = (global_pos - center) / radius
	if _raw.length() > 1.0:
		_raw = _raw.normalized()
	_value = Vector2.ZERO if _raw.length() < DEADZONE else _raw
	value_changed.emit(_value)
	queue_redraw()

func _release() -> void:
	_active = false
	_touch_index = -1
	_mouse_active = false
	_raw = Vector2.ZERO
	_value = Vector2.ZERO
	value_changed.emit(_value)
	queue_redraw()

func _radius() -> float:
	return min(size.x, size.y) * 0.5 - 10.0

func _draw() -> void:
	var center := size * 0.5
	var radius := _radius()
	var knob := center + _raw * radius
	draw_circle(knob, KNOB_RADIUS, Color(0.75, 0.88, 1.0, 0.85))
	draw_arc(knob, KNOB_RADIUS, 0.0, TAU, 32, Color(1, 1, 1, 0.9), 2.0, true)
