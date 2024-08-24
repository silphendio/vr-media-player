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

var vr_push_left = Switch.new()
var vr_push_right = Switch.new()


@onready var volume_indicator = $VolumeIndicator3D



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

		# pointer switching
		menu_hand = vr_stuff.right_hand
		menu_hand.add_child(menu_pointer)
		
		vr_stuff.left_hand.button_pressed.connect(_on_left_btn_pressed)
		vr_stuff.right_hand.button_pressed.connect(_on_right_btn_pressed)
	else:
		print("no OpenXR found: proceeding with flatscreen mode")
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	
	_menu_transform_base = menu_view.transform
	show_menu()
	print("root ready")

func _on_left_btn_pressed(btn):
	on_vr_button_pressed(vr_stuff.left_hand, btn)
func _on_right_btn_pressed(btn):
	on_vr_button_pressed(vr_stuff.right_hand, btn)

func on_vr_button_pressed(hand, button):
	if button == "by_button":
		switch_hand(hand)
		toggle_menu()
	
	if button == "ax_button":
		if is_menu_open():
			# TODO: register down&up press separately
			menu_view.press(true)
			menu_view.press(false)
		else:
			video_node.toggle_pause()

func show_menu_pointer(active = true):
	print("show menu pointer: ", active)
	if !vr_stuff:
		return
	if active && !menu_pointer in menu_hand.get_children():
		menu_hand.add_child(menu_pointer)
	elif !active && menu_pointer in menu_hand.get_children():
		menu_hand.remove_child(menu_pointer)

func switch_hand(new_hand):
	if menu_hand != new_hand && menu_pointer.is_inside_tree():
		menu_hand.remove_child(menu_pointer)
		new_hand.add_child(menu_pointer)
	menu_hand = new_hand

func _process(delta):
	if vr_stuff:
		var ts = 0.1
		var left_joystick = vr_stuff.left_hand.get_vector2("primary")
		var right_joystick = vr_stuff.right_hand.get_vector2("primary")

		vr_left_trigger.update(vr_stuff.left_hand.get_float("trigger") > ts)
		vr_right_trigger.update(vr_stuff.right_hand.get_float("trigger") > ts)
		vr_menu_trigger.update(menu_hand.get_float("trigger") > ts)
		vr_scroll_up.update(left_joystick.y > 0.5 || right_joystick.y > 0.5, delta)
		vr_scroll_down.update(left_joystick.y < -0.5 || right_joystick.y < -0.5, delta)
		
		vr_push_left.update(left_joystick.x < -0.5 || right_joystick.x < -0.5)
		vr_push_right.update(left_joystick.x > 0.5 || right_joystick.x > 0.5)
		
		# in-menu stuff:
		if is_menu_open():
			if vr_menu_trigger.event != Switch.IDLE:
				menu_view.press(vr_menu_trigger.state)
				#keyboard_view.press(vr_menu_trigger.state)
			if vr_scroll_down.event == ScrollSwitch.PRESSED:
				menu_view.scroll_down()
			if vr_scroll_up.event == ScrollSwitch.PRESSED:
				menu_view.scroll_up()
		
			# maybe switch menu hand
			if vr_left_trigger.event == Switch.PRESSED:
				switch_hand(vr_stuff.left_hand)
			if vr_right_trigger.event == Switch.PRESSED:
				switch_hand(vr_stuff.right_hand)
		else:
			# navigation

			if vr_push_left.event == Switch.PRESSED:
				video_node.press_left()
			if vr_push_right.event == Switch.PRESSED:
				video_node.press_right()
			
			# audio
			# volume_indicator
			if abs(left_joystick.y) > 0.1:
				add_volume_db(left_joystick.y * 20 * delta, vr_stuff.left_hand)
			if abs(right_joystick.y) > 0.1:
				add_volume_db(right_joystick.y * 20 * delta, vr_stuff.right_hand)
			
			# pause
			if (vr_left_trigger.event == Switch.PRESSED) || (vr_right_trigger.event == Switch.PRESSED):
				video_node.toggle_pause()


func add_volume_db(delta: float, indicator_parent = null):
	video_node.volume_db += delta
	if indicator_parent:
		volume_indicator.volume_db = video_node.volume_db
		volume_indicator.time_left = 100.0
		if volume_indicator.is_inside_tree():
			#volume_indicator.reparent(indicator_parent)
			volume_indicator.get_parent().remove_child(volume_indicator)
			#print("ind rep")
		indicator_parent.add_child(volume_indicator)
		#print("ind add")
		volume_indicator.visible = true
	print("new vol:", video_node.volume_db)


func _unhandled_input(event):
	# flat screen controls
	
	if event is InputEventKey and event.pressed:
		if event.key_label == KEY_ESCAPE:
			toggle_menu()
		if event.keycode == KEY_SPACE:
			video_node.toggle_pause()

		if event.keycode == KEY_LEFT:
			video_node.press_left()
		if event.keycode == KEY_RIGHT:
			video_node.press_right()
		if event.keycode == KEY_UP:
			video_node.raise_volume()
		if event.keycode == KEY_DOWN:
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
		
		# this doesn't work for the file dialog...
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN && is_menu_open():
			menu_view.scroll_down()	
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP && is_menu_open():
			menu_view.scroll_up()


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
