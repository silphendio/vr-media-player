extends MeshInstance3D
class_name MenuView
# TODO? scaling CollisionShape isn't properly supported
# if it breaks, add a size property instead
# that way size won't be registered by the editor though

@onready var viewport = $SubViewport

var _mouse_position: Vector2i = Vector2i(-1, -1)

## Viewport resolution in px
@export
var resolution: Vector2i:
	set(res):
		resolution = res
		if not is_inside_tree():
			await ready
		viewport.size = resolution


## Raycast that acts as laser pointer / mouse
@export var pointer: RayCast3D

## Track mouse buttons? TODO: implement
@export var track_mouse: bool = false

## Track keyboard input TODO: implement
@export var use_keyboard: bool = false

var _mouse_mask = 0
var _last_click = 0 # for double click

## inject (left) mouse click
func press(pressed = true):
	if !viewport.is_inside_tree():
		return
	
	_mouse_mask = int(pressed) # MOUSE_BUTTON_MASK_LEFT == 1
	if _mouse_position.x < 0: # can't click on nothing
		print("mouse out of range: ", _mouse_position)
		return
	var event = InputEventMouseButton.new()
	event.position = _mouse_position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.button_mask = _mouse_mask
	
	# double click
	var click_time = Time.get_ticks_msec()
	if click_time - _last_click < 500:
		event.double_click = true
	_last_click = click_time

	# TODO: find out why this throws pointless errors (Condition "!is_inside_tree()" is true.)
	viewport.push_input(event, true)
	#print("event: ", event)


## inject mouse scroll_down event
func scroll_down():
	var event = InputEventMouseButton.new()
	event.position = _mouse_position
	event.button_index = MOUSE_BUTTON_WHEEL_DOWN
	event.pressed = true
	event.button_mask = MOUSE_BUTTON_WHEEL_DOWN
	viewport.push_input(event, true)
	event.pressed = false
	viewport.push_input(event, true)

## inject mouse scroll_up event
func scroll_up():
	var event = InputEventMouseButton.new()
	event.position = _mouse_position
	event.button_index = MOUSE_BUTTON_WHEEL_UP
	event.pressed = true
	event.button_mask = MOUSE_BUTTON_WHEEL_UP
	viewport.push_input(event, true)
	event.pressed = false
	viewport.push_input(event, true)


# Called when the node enters the scene tree for the first time.
func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	#viewport.set_process_input(true)

var _mouse_pressed_tmp = false

func _process(delta):
	# workaround for mouse events not working for popup windows in menu
	var m = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if m != _mouse_pressed_tmp:
		press(m)
		_mouse_pressed_tmp = m
	
	# track raycast & change mouse position, inject events
	var _mouse_position_prev = _mouse_position
	var pos3d = null

	# find mouse position
	if pointer:
		if pointer.get_collider_rid() == $Area3D.get_rid():
			pos3d = pointer.get_collision_point()
	else:
		# fallback to PC mouse mouse
		var cam = get_viewport().get_camera_3d()
		var mousepos = get_viewport().get_mouse_position()
		var from = cam.project_ray_origin(mousepos)
		var to = from + cam.project_ray_normal(mousepos) * 100
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_areas = true
		var result = get_world_3d().direct_space_state.intersect_ray(query)
		
		if result.has("position"):
			pos3d = result.position

	if pos3d:
		pos3d = global_transform.affine_inverse() * pos3d
		var p = Vector2(pos3d.x, -pos3d.y)
		p.x = (p.x + 0.5) * resolution.x
		p.y = (p.y + 0.5) * resolution.y
		_mouse_position = p
		#print("mouse position: ", p)
	else:
		_mouse_position = Vector2i(-1, -1)

	# mouse moved
	if _mouse_position != _mouse_position_prev:
		var event = InputEventMouseMotion.new()
		event.position = _mouse_position
		event.global_position = _mouse_position
		event.relative = _mouse_position - _mouse_position_prev
		event.velocity = event.relative / delta
		event.button_mask = _mouse_mask
		event.pressure =  _mouse_mask
		viewport.push_input(event, true)
		#print("mouse move simulated! %s -> %s" % [_mouse_position_prev, _mouse_position])

func _unhandled_key_input(event):
	if event is InputEventKey:
		#print(event)
		viewport.push_input(event)
		pass

