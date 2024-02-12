extends Node3D

## helper class to make vr inputs easier to use
class Switch:
	enum {IDLE, PRESSED, RELEASED}
	var event
	var state: bool = false
	func update(b: bool):
		if state && !b:
			event = RELEASED
		elif !state && b:
			event = PRESSED
		else:
			event = IDLE
		state = b
# to emulate mouse wheel with joystick
class ScrollSwitch:
	enum {IDLE, PRESSED}
	var event
	var time_to_trigger : float = 0.1
	var state: bool = false
	func update(b: bool, t = 0.0):
		event = IDLE
		if !state && b:
			event = PRESSED
			time_to_trigger = 0.1
		elif state && b:
			time_to_trigger -= t
			if time_to_trigger <= 0:
				event = PRESSED
				time_to_trigger = 0.1
		state = b

## nodes
@onready var menu_pointer = $FlatView/RayCast3D
@onready var menu_view = $MenuView
# @onready var keyboard_view = $Keyboard
@onready var video_node = $VideoNode

## other vars

var _use_vr = false
var vr_stuff = null

var menu_hand
# flat screen controls
var flatscreen_fps_mode_enabled = false
var _menu_transform_base = null


var vr_menu_trigger = Switch.new()
var vr_left_trigger = Switch.new()
var vr_right_trigger = Switch.new()
var vr_scroll_up = ScrollSwitch.new()
var vr_scroll_down = ScrollSwitch.new()

var vr_pause_button = Switch.new()

var test_switch = Switch.new()


func show_menu():
	# show in front of controller or, failing that, camera
	var t
	if vr_stuff && menu_pointer in vr_stuff.left_hand.get_children():
		t = vr_stuff.left_hand.global_transform
	elif vr_stuff && menu_pointer in vr_stuff.right_hand.get_children():
		t = vr_stuff.right_hand.global_transform
	else:
		t = get_viewport().get_camera_3d().transform
	menu_view.transform = t * _menu_transform_base
	if !menu_view in get_children():

		add_child(menu_view)
	menu_pointer.visible = true
	flatscreen_fps_mode_enabled = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func hide_menu():
	if menu_view in get_children():
		remove_child(menu_view)
	menu_pointer.visible = false


func is_menu_open():
	return menu_view in get_children()
func toggle_menu():
	if is_menu_open():
		hide_menu()
	else:
		show_menu()


# Called when the node enters the scene tree for the first time.
func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	# debug

	# VR stuff
	print("XR interfaces: ", XRServer.get_interfaces())
	var interface = XRServer.find_interface("OpenXR")
	if interface and interface.is_initialized(): ## DEBUG TODO
		print("OpenXR found")
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
		
		menu_pointer.visible = true
		menu_view.pointer = menu_pointer
		# keyboard_view.pointer = menu_pointer
		$FlatView.remove_child(menu_pointer)
		remove_child($FlatView)
		vr_stuff = load("res://scenes/vr_stuff.tscn").instantiate()
		add_child(vr_stuff)
		_use_vr = true
		print("vr initialized")
		
		
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		# TODO: implement pointer switching
		menu_hand = vr_stuff.right_hand
		menu_hand.add_child(menu_pointer)
	else:
		print("no OpenXR found: proceeding with flatscreen mode")
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	
	_menu_transform_base = menu_view.transform
	show_menu()
	print("root ready")



func show_menu_pointer(active = true):
	print("show menu pointer: ", active)
	if !vr_stuff:
		return
	if active && !menu_pointer in menu_hand.get_children():
		menu_hand.add_child(menu_pointer)
	elif !active && menu_pointer in menu_hand.get_children():
		menu_hand.remove_child(menu_pointer)

func _process(delta):
	if vr_stuff:
		var ts = 0.1

		vr_left_trigger.update(vr_stuff.left_hand.get_float("trigger") > ts)
		vr_right_trigger.update(vr_stuff.right_hand.get_float("trigger") > ts)
		
		vr_pause_button.update(menu_hand.is_button_pressed("by_button"))		
		
		# menu button
		if vr_pause_button.event == Switch.PRESSED:
			toggle_menu()

		# in-menu stuff:
		if is_menu_open():
			vr_menu_trigger.update(menu_hand.get_float("trigger") > ts)
			vr_scroll_up.update(menu_hand.get_vector2("primary").y > 0.5, delta)
			vr_scroll_down.update(menu_hand.get_vector2("primary").y < -0.5, delta)

			if vr_menu_trigger.event != Switch.IDLE:
				menu_view.press(vr_menu_trigger.state)
				#keyboard_view.press(vr_menu_trigger.state)
			if vr_scroll_down.event == ScrollSwitch.PRESSED:
				menu_view.scroll_down()
			if vr_scroll_up.event == ScrollSwitch.PRESSED:
				menu_view.scroll_up()
		
			# maybe switch menu hand
			if vr_left_trigger.event == Switch.PRESSED && menu_hand != vr_stuff.left_hand:
				menu_hand.remove_child(menu_pointer)
				menu_hand = vr_stuff.left_hand
				menu_hand.add_child(menu_pointer)
				print("switched menu hand to left")
			if vr_right_trigger.event == Switch.PRESSED && menu_hand != vr_stuff.right_hand:
				menu_hand.remove_child(menu_pointer)			
				menu_hand = vr_stuff.right_hand
				menu_hand.add_child(menu_pointer)
				print("switched menu hand to right")


func _unhandled_input(event):
	# flat screen controls
	
	if event is InputEventKey:
		if event.key_label == KEY_ESCAPE:
			print("esc pressed")
			toggle_menu()
		if event.pressed and event.keycode == KEY_SPACE:
			video_node.toggle_pause()

		if event.pressed and event.keycode == KEY_LEFT:
			video_node.press_left()
		if event.pressed and event.keycode == KEY_RIGHT:
			video_node.press_right()
		if event.pressed and event.keycode == KEY_UP:
			video_node.raise_volume()
		if event.pressed and event.keycode == KEY_DOWN:
			video_node.lower_volume()

	if vr_stuff:
		return

	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_MIDDLE && !is_menu_open():
			flatscreen_fps_mode_enabled = not flatscreen_fps_mode_enabled
			if flatscreen_fps_mode_enabled:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if event.button_index == MOUSE_BUTTON_RIGHT:
			toggle_menu()


	# mouse move
	var cam = get_viewport().get_camera_3d()
	if (flatscreen_fps_mode_enabled or (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
			and not menu_view in get_children())) and event is InputEventMouseMotion:
		var r = event.relative / 200
		cam.rotation.y += r.x
		cam.rotation.x = clamp(cam.rotation.x + r.y, -TAU/4, TAU/4)

	# mouse plane zoom # and 
	if event is InputEventMouseButton and event.is_pressed() and not menu_view in get_children():
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			video_node.lower_volume()
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			video_node.raise_volume()

