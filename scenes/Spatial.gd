extends Spatial

const VIDEO_FILE_EXTS = ["avi", "flv", "h264", "m4v", "mkv", "mod", "mov", "mp4", "mpeg", "mpg", "ogv", "webm", "wmv"]
const IMAGE_FILE_EXTS = ["png", "bmp", "tga", "webp", "jpg", "jpeg", "mpo"]
const FILE_EXTS = VIDEO_FILE_EXTS + IMAGE_FILE_EXTS

var _menu_scene = null
var menu = null

enum VIEW_MODE {VIDEO, IMAGE}
var _view_mode = VIEW_MODE.VIDEO

var mono_material
var stereo_materials = []
# mpo image support
var _texture2 = null
var stereo_2img_material = preload("res://material/stereo_shader_2img.tres")


var video_surface = null
enum SURFACES {PLANE, HALF_SPHERE, SPHERE, EAC_SPHERE}

var surfaces = []
var _surface_id = -1
var _is_stereo = false #setget _set_stereo

var _plane_position = Vector3(0, 1.8, -10)

# to open menu with laser active
enum CONTROLLER {NONE, LEFT, RIGHT}
var _last_controller = CONTROLLER.NONE

var _video_duration = -1

onready var _player = $VideoViewport/VideoPlayer

# flat screen controls
var flatscreen_fps_mode_enabled = false

var _laser_right
var _laser_left

var _menu_transform_base = null

var _current_path = null

# quick file navigation
var _file_list
var _current_dir
var _current_file_idx

# for analog vr buttons
enum VR_CTRL { TRIGGER, RIGHT, LEFT, UP, DOWN }
var _vr_ctrl_map = [0, 0, 0, 0, 0]


# Called when the node enters the scene tree for the first time.
func _ready():
	
	# initialize materials
	stereo_materials = []
	for res in ["res://material/stereo_shader.tres", "res://material/stereo_shader360.tres", "res://material/stereo_shader360eac.tres"]:
		var m = load(res)
		m.set_shader_param("stereo_img", $VideoViewport.get_texture())
		m.set_shader_param("cross_eyes", 0)
		stereo_materials.push_back(m)
	stereo_materials.push_front(stereo_materials[0])
		
	mono_material = SpatialMaterial.new()
	mono_material.albedo_texture = $VideoViewport.get_texture()
	mono_material.flags_albedo_tex_force_srgb = true
	mono_material.flags_unshaded = true
	
	
	# initialize surfaces
	for i in range(SURFACES.size()):
		surfaces.append(MeshInstance.new())
		surfaces[i].scale = Vector3(10, 10, 10)
		surfaces[i].material_override = mono_material

	surfaces[SURFACES.PLANE].mesh = load("res://geometry/plane.obj")
	surfaces[SURFACES.PLANE].translation = _plane_position

	surfaces[SURFACES.HALF_SPHERE].mesh = load("res://geometry/half_sphere.obj")
	surfaces[SURFACES.EAC_SPHERE].mesh = load("res://geometry/eac_sphere.obj")
	surfaces[SURFACES.SPHERE].mesh = load("res://geometry/sphere.obj")
	
	_load_surface(SURFACES.PLANE)
	
	# setup ui
	menu = $MenuPlane
	_menu_scene = $MenuPlane/Viewport/Menu
	_menu_transform_base = menu.transform
	# hack to get the menu to the right coordinates
	_toggle_menu()
	_toggle_menu()

	_menu_scene.connect("video_loaded", self, "_load_media_file")
	_menu_scene.connect("projection_changed", self, "_load_surface")
	_menu_scene.connect("is_stereo_changed", self, "_set_stereo")
	_menu_scene.connect("is_loop_changed", self, "_set_loop")
	_menu_scene.connect("volume_changed", self, "_change_volume")
	_menu_scene.connect("progress_changed", self, "_set_video_position")

	_menu_scene.connect("start_pressed", self, "_toggle_pause")
	_menu_scene.connect("recenter_pressed", self, "_recenter_view")

	_menu_scene.connect("zoom_in_pressed", self, "_zoom_in")
	_menu_scene.connect("zoom_out_pressed", self, "_zoom_out")
	
	_menu_scene.connect("swap_eyes_changed", self, "_set_swap_eyes")

	_menu_scene.connect("next_pressed", self, "_load_next_file")
	_menu_scene.connect("prev_pressed", self, "_load_prev_file")
	_menu_scene.connect("skip_forward_pressed", self, "_skip_forward")
	_menu_scene.connect("skip_back_pressed", self, "_skip_backward")
	
	# laser
	_laser_left = $FPController/LeftHandController/RayCast
	_laser_left.controller = $FPController/LeftHandController
	_laser_left.target = $MenuPlane
	_laser_left.viewport = $MenuPlane/Viewport
	_laser_right = $FPController/RightHandController/RayCast
	_laser_right.controller = $FPController/RightHandController
	_laser_right.target = $MenuPlane
	_laser_right.viewport = $MenuPlane/Viewport
	$FPController/LeftHandController.remove_child(_laser_left)
	$FPController/RightHandController.remove_child(_laser_right)

func _adjust_plane_size():
	var texture = _player.get_video_texture()
	if _view_mode == VIEW_MODE.IMAGE:
		texture = mono_material.albedo_texture
	if _surface_id == SURFACES.PLANE and texture:
		var tex = texture.get_size()
		video_surface.scale.x = video_surface.scale.y * tex.x/tex.y / (1 + float(_is_stereo and not _texture2))


func _recenter_view():
	var _surface_transform = $FPController/ARVRCamera.transform
	for surface in surfaces:
		var scale = video_surface.scale
		surface.transform.basis = _surface_transform.basis * Basis(Vector3.ZERO).scaled(scale)
		surface.translation = _surface_transform.origin
	surfaces[SURFACES.PLANE].translation += _surface_transform.basis.xform(_plane_position)

func _load_mpo(buffer):
	# TODO
	# first image
	var img = Image.new()
	img.load_jpg_from_buffer(buffer)
	
	
	var img2 = Image.new()
	var buffer2 = null
	
	for i in range(3, buffer.size() - 4):
		if buffer.subarray(i,i+3).hex_encode() == "ffd8ffe1":
			buffer2 = buffer.subarray(i, -1)
	if buffer2:
		img2.load_jpg_from_buffer(buffer2)
		_texture2 = ImageTexture.new()
		_texture2.create_from_image(img2)
	
	return img

# stupid workaround
func _load_external_tex(path):
	if not path.get_extension() in IMAGE_FILE_EXTS:
		return null

	var tex_file = File.new()
	tex_file.open(path, File.READ)
	var bytes = tex_file.get_buffer(tex_file.get_len())
	var img = Image.new()
	if path.ends_with(".png"):
		img.load_png_from_buffer(bytes)
	if path.ends_with(".bmp"):
		img.load_bmp_from_buffer(bytes)
	if path.ends_with(".tga"):
		img.load_tga_from_buffer(bytes)
	if path.ends_with(".webp"):
		img.load_webp_from_buffer(bytes)
	if path.ends_with(".jpg") or path.ends_with(".jpeg"):
		img.load_jpg_from_buffer(bytes)
	if path.ends_with(".mpo"):
		img = _load_mpo(bytes)
	var imgtex = ImageTexture.new()
	imgtex.create_from_image(img)
	tex_file.close()
	return imgtex

func _load_media_file(path):
	# try to load video
	var texture
	_texture2 = null # mpo support
	var is_video = false
		# try to load image
	texture = _load_external_tex(path)
	if texture:
		_view_mode = VIEW_MODE.IMAGE
		_player.stop()

	elif _load_video(path):
		is_video = true
		texture = $VideoViewport.get_texture()
		_view_mode = VIEW_MODE.VIDEO
	else:
		print("ERROR: Couldn't recognize file: %s" % path)
		return
	
	if path.get_base_dir() != _current_dir:
		_current_dir = path.get_base_dir()
		_file_list = _get_file_list(_current_dir)
		_current_file_idx = _file_list.find(path)


	mono_material.albedo_texture = texture
	mono_material.flags_albedo_tex_force_srgb = is_video # no idea why
	for m in stereo_materials:
		m.set_shader_param("stereo_img", texture)
	if _texture2:
		stereo_2img_material.set_shader_param("stereo_img", texture)
		stereo_2img_material.set_shader_param("stereo_img2", _texture2)

	_adjust_plane_size()
	_set_stereo(_is_stereo)


func _load_video(video):
	# _player.stream = load(video)
	var stream = VideoStreamGDNative.new()
	stream.set_file(video)
	_player.stream = stream
	
	if(!_player.get_video_texture()):
		# fallback option
		_player.stream = load(video)
	if(!_player.get_video_texture()):
		print("ERROR: Couldn't load video")
		return false
	
	var sp = _player.stream_position
	_player.stream_position = -1
	_video_duration = _player.stream_position
	_player.stream_position = sp
	_menu_scene.set_progress(sp, _video_duration)
	
	$VideoViewport.size = _player.get_video_texture().get_size()
	_player.play()
	_menu_scene.is_playing = true
	_player.paused = false
	return true
	
# p in percent
func _set_video_position(p):
	if abs(_player.stream_position - p) > 0.5:
		_player.stream_position = p
		
		# seek next frame while paused (from godot-videodecoder.c)
		if _player.paused:
			_player.paused = false
			# yes, it seems like 5 idle frames _is_ the magic number.
			# VideoPlayer gets notified to do NOTIFICATION_INTERNAL_PROCESS on idle frames
			# so this should always work?
			for i in range(5):
				yield(get_tree(), 'idle_frame')
			_player.paused = true


func _set_loop(_is_loop):
	pass # not needed

func _set_stereo(is_stereo):
	if !is_stereo:
		video_surface.material_override = mono_material
		_is_stereo = false
	else:
		video_surface.material_override = stereo_materials[_surface_id]
		_is_stereo = true
		
		# mpo support
		if _texture2:
			video_surface.material_override = stereo_2img_material
	_adjust_plane_size()


func _load_surface(surface_id):
	if surface_id == _surface_id:
		return
	
	if video_surface:
		remove_child(video_surface)
	video_surface = surfaces[surface_id]
	add_child(video_surface)
	_surface_id = surface_id
	_adjust_plane_size()
	_set_stereo(_is_stereo) # refresh material

func _toggle_pause():
	if _player.is_playing():
		if _player.paused:
			_menu_scene.is_playing = true
			_player.paused = false
		else:
			_menu_scene.is_playing = false
			_player.paused = true
	else:
		_player.play()
		#_set_video_position(0)
		_menu_scene.is_playing = true



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Called every frame. 'delta' is the elapsed time since the previous frame.
	var camera = $FPController/ARVRCamera
	if not menu in get_children():
		if Input.is_key_pressed(KEY_W):
			camera.translation.y += delta*10
		if Input.is_key_pressed(KEY_A):
			camera.translation.x -= delta*10
		if Input.is_key_pressed(KEY_S):
			camera.translation.y -= delta*10
		if Input.is_key_pressed(KEY_D):
			camera.translation.x += delta*10

		# for pseudo-buttons on vr controllers
		update_vr_controls()


	if video_surface != surfaces[SURFACES.PLANE]:
		video_surface.translation = camera.translation
	
			
	# update video position

	if menu in get_children():
		_menu_scene.set_progress(_player.stream_position, _video_duration)

func _toggle_menu():
	if menu in get_children():
		remove_child(menu)
		if _laser_left in $FPController/LeftHandController.get_children():
			$FPController/LeftHandController.remove_child(_laser_left)
		if _laser_right in $FPController/RightHandController.get_children():
			$FPController/RightHandController.remove_child(_laser_right)
	else:
		add_child(menu)
		flatscreen_fps_mode_enabled = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		# show in front of controller or, failing that, camera
		var t
		if _laser_left in $FPController/LeftHandController.get_children():
			t = $FPController/LeftHandController.global_transform
		elif _laser_right in $FPController/RightHandController.get_children():
			t = $FPController/RightHandController.global_transform
		else:
			t = get_viewport().get_camera().transform
		menu.transform = t * _menu_transform_base

# flat screen controls
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_ESCAPE:
			_toggle_menu()

		if event.pressed and event.scancode == KEY_SPACE:
			_toggle_pause()

		if event.pressed and event.scancode == KEY_LEFT:
			_on_left_pressed()
		if event.pressed and event.scancode == KEY_RIGHT:
			_on_right_pressed()
		if event.pressed and event.scancode == KEY_UP:
			raise_volume()
		if event.pressed and event.scancode == KEY_DOWN:
			lower_volume()
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_MIDDLE:
			flatscreen_fps_mode_enabled = not flatscreen_fps_mode_enabled
			if flatscreen_fps_mode_enabled:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if event.button_index == BUTTON_RIGHT:
			_toggle_menu()

	var cam = $FPController/ARVRCamera
	# mouse move
	if (flatscreen_fps_mode_enabled or (Input.is_mouse_button_pressed(BUTTON_LEFT) and not menu in get_children())) and event is InputEventMouseMotion:
		var r = event.relative / 200

		cam.rotation.y += r.x
		cam.rotation.x = clamp(cam.rotation.x + r.y, -TAU/4, TAU/4)

	# mouse plane zoom # and 
	if event is InputEventMouseButton and event.is_pressed() and not menu in get_children():
		if event.button_index == BUTTON_WHEEL_DOWN:
			lower_volume()
		if event.button_index == BUTTON_WHEEL_UP:
			raise_volume()

func _zoom_in():
	if _surface_id == SURFACES.PLANE:
		video_surface.scale.x *= 1.125
		video_surface.scale.y *= 1.125
func _zoom_out():
	if _surface_id == SURFACES.PLANE:
		video_surface.scale.x /= 1.125
		video_surface.scale.y /= 1.125

func _on_vr_button_pressed(button_index):
	if button_index == JOY_OPENVR_MENU:
		_toggle_menu()

func _on_RightHandController_button_pressed(button):
	if menu in get_children() or button==JOY_OPENVR_MENU:
		if _laser_left in $FPController/LeftHandController.get_children():
			$FPController/LeftHandController.remove_child(_laser_left)
		if not _laser_right in $FPController/RightHandController.get_children():
			$FPController/RightHandController.add_child(_laser_right)
			if button!=JOY_OPENVR_MENU:
				return # prevent surprise clicks
	_on_vr_button_pressed(button)

func _on_LeftHandController_button_pressed(button):
	if menu in get_children() or button==JOY_OPENVR_MENU:
		if _laser_right in $FPController/RightHandController.get_children():
			$FPController/RightHandController.remove_child(_laser_right)
		if not _laser_left in $FPController/LeftHandController.get_children():
			$FPController/LeftHandController.add_child(_laser_left)
			if button!=JOY_OPENVR_MENU:
				return # prevent surprise clicks
	_on_vr_button_pressed(button)


func _on_VideoPlayer_finished():
	if _menu_scene.is_loop:
		_set_video_position(0)
		_player.play()
	else:
		_menu_scene.is_playing = false

func _change_volume(vol):
	if(vol==0):
		_player.volume = 0
	else:
		_player.volume_db = (vol-100)*0.6

func _set_swap_eyes(swap_eyes):
	for m in stereo_materials:
		m.set_shader_param("cross_eyes", int(swap_eyes))
	stereo_2img_material.set_shader_param("cross_eyes", int(swap_eyes))

## STATIC UTILITY FUNCTION
func _get_file_list(dir_path):
	var files = []
	var dir = Directory.new()
	dir.open(dir_path)
	dir.list_dir_begin(true, true)
	while true:
		var file = dir.get_next() 
		if file.get_extension() in FILE_EXTS:
			files.push_back(file)
		elif file == "":
			return files

func _load_next_file():
	if not _file_list:
		return
	if _current_file_idx + 1 < _file_list.size():
		_current_file_idx += 1
	else:
		_current_file_idx = 0
	_load_media_file(_current_dir + '/' + _file_list[_current_file_idx])
func _load_prev_file():
	if not _file_list:
		return
	if _current_file_idx > 0:
		_current_file_idx -= 1
	else:
		_current_file_idx = _file_list.size() - 1
	_load_media_file(_current_dir + '/' + _file_list[_current_file_idx])


func _skip_forward():
	_set_video_position(_player.stream_position + 10)
	
func _skip_backward():
	_set_video_position(_player.stream_position - 10)

func _on_left_pressed():
	if _view_mode == VIEW_MODE.VIDEO:
		_skip_backward()
	else:
		_load_prev_file()
func _on_right_pressed():
	if _view_mode == VIEW_MODE.VIDEO:
		_skip_forward()
	else:
		_load_next_file()

func raise_volume():
	_menu_scene.volume += 5
	_change_volume(_menu_scene.volume)
func lower_volume():
	_menu_scene.volume -= 5
	_change_volume(_menu_scene.volume)


func update_vr_controls():
	var _vr_ctrl_map_new = [0, 0, 0, 0, 0]
	for c in [$FPController/LeftHandController, $FPController/RightHandController]:
		_vr_ctrl_map_new[VR_CTRL.TRIGGER] |= int(c.get_joystick_axis(JOY_VR_ANALOG_TRIGGER) > 0.2)
		_vr_ctrl_map_new[VR_CTRL.RIGHT] |= int(c.get_joystick_axis(JOY_OPENVR_TOUCHPADX) > 0.5)
		_vr_ctrl_map_new[VR_CTRL.LEFT] |= int(c.get_joystick_axis(JOY_OPENVR_TOUCHPADX) < -0.5)
		_vr_ctrl_map_new[VR_CTRL.UP] |= int(c.get_joystick_axis(JOY_OPENVR_TOUCHPADY) > 0.5)
		_vr_ctrl_map_new[VR_CTRL.DOWN] |= int(c.get_joystick_axis(JOY_OPENVR_TOUCHPADY) < -0.5)
	for i in range(5):
		if _vr_ctrl_map_new[i] > _vr_ctrl_map[i]:
			# do stuff here
			if i == VR_CTRL.TRIGGER:
				_toggle_pause()
			elif i == VR_CTRL.LEFT:
				_on_left_pressed()
			elif i == VR_CTRL.RIGHT:
				_on_right_pressed()
			elif i == VR_CTRL.UP:
				raise_volume()
			elif i == VR_CTRL.DOWN:
				lower_volume()
				
	_vr_ctrl_map = _vr_ctrl_map_new
  
