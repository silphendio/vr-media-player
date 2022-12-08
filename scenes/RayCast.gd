extends Spatial
# I couldn't get an actual Raycast node to work
# doesn't check if collision object is target area (there is only one Area)

var target = null
var viewport = null
var controller = null

var _last_click_time = 10000
var _last_position = null
var _is_trigger_pressed = false

var _last_scroll_time = 10000
var _is_wheel_down_pressed = false
var _is_wheel_up_pressed = false


# Called when the node enters the scene tree for the first time.
func _ready():
	get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
	pass



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not (target and viewport and controller):
		print("please hold...")
		return
	
	_last_click_time += delta
	_last_scroll_time += delta

	var from = global_translation
	var to = from + global_transform.basis.xform(Vector3.FORWARD)*100
	var result = get_world().direct_space_state.intersect_ray(from, to, [], 0x7fffffff,false,true)
	
	# calculate 2d position
	if result.size() > 0:
		var position = target.get_2d_position(result.position)
		
		# determine movement
		if not _last_position or (position - _last_position).length_squared() > 1:
			var event = InputEventMouseMotion.new()
			event.position = position
			if _last_position:
				event.relative = position - _last_position
				event.speed = event.relative / delta
			viewport.input(event)
			#print("mouse move simulated! %s -> %s" % [position, _last_position])
			_last_position = position
		
		# trigger
		#var trigger_value = controller.get_joystick_axis(JOY_VR_ANALOG_TRIGGER)
		var triggered = bool(controller.is_button_pressed(JOY_OCULUS_AX) or controller.get_joystick_axis(JOY_VR_ANALOG_TRIGGER) > 0.2)
		if triggered != _is_trigger_pressed:
			_is_trigger_pressed = triggered
			# send click event!
			var event = InputEventMouseButton.new()
			event.position = target.get_2d_position(result.position)
			event.button_index = BUTTON_LEFT
			event.pressed = triggered
			
			# doubleclick
			if triggered:
				if _last_click_time < 0.5:
					event.doubleclick = true
			_last_click_time = 0
			viewport.input(event)
		
		# simulate mouse wheel
		var wheel_up = controller.get_joystick_axis(JOY_OPENVR_TOUCHPADY) > 0.5
		var wheel_down = controller.get_joystick_axis(JOY_OPENVR_TOUCHPADY) < -0.5
		if wheel_up != _is_wheel_up_pressed or (wheel_up and _last_scroll_time > 0.1):
			var event = InputEventMouseButton.new()
			event.position = target.get_2d_position(result.position)
			event.button_index = BUTTON_WHEEL_UP
			event.pressed = wheel_up
			print("synthetic wheel up")
			viewport.input(event)
			_last_scroll_time = 0
			_is_wheel_up_pressed = wheel_up

		if wheel_down != _is_wheel_down_pressed or (wheel_down and _last_scroll_time > 0.1):
			var event = InputEventMouseButton.new()
			event.position = target.get_2d_position(result.position)
			event.button_index = BUTTON_WHEEL_DOWN
			event.pressed = wheel_down
			print("synthetic wheel down")
			viewport.input(event)
			_last_scroll_time = 0
			_is_wheel_down_pressed = wheel_down
		
	else:
		_last_position = null
