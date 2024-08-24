extends Node3D
class_name VideoNode

const VIDEO_FILE_EXTS = ["avi", "flv", "h264", "m4v", "mkv", "mod", "mov", "mp4", "mpeg", "mpg", "ogv", "webm", "wmv"]
const IMAGE_FILE_EXTS = ["png", "bmp", "tga", "webp", "jpg", "jpeg", "mpo"]
const FILE_EXTS = VIDEO_FILE_EXTS + IMAGE_FILE_EXTS

enum PLAYBACK_STATE {STOPPED, PLAYING, PAUSED}
signal playback_state_changed(state: PLAYBACK_STATE)

var is_loop = true

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
var _is_stereo = false #: set = set_stereo

var _plane_position = Vector3(0, 1.8, -500)

@onready var player = $VideoViewport/VideoPlayer


# quick file navigation
var _file_list
var _current_dir
var _current_file_idx
var current_file # for file dialog

var _volume_db: float = 0.0
var volume_db: float:
	set(val):
		_volume_db = val
		if player && !is_muted():
			player.volume_db = val
	get:
		return _volume_db


# Called when the node enters the scene tree for the first time.
func _ready():
	
	# initialize materials
	stereo_materials = []
	for res in ["res://material/stereo_shader.tres", "res://material/stereo_shader360.tres", "res://material/stereo_shader360eac.tres"]:
		var m = load(res)
		m.set_shader_parameter("stereo_img", $VideoViewport.get_texture())
		m.set_shader_parameter("cross_eyes", 0)
		stereo_materials.push_back(m)
	stereo_materials.push_front(stereo_materials[0])
		
	mono_material = StandardMaterial3D.new()
	mono_material.albedo_texture = $VideoViewport.get_texture()
	mono_material.flags_unshaded = true
	
	
	# initialize surfaces
	for i in range(SURFACES.size()):
		surfaces.append(MeshInstance3D.new())
		surfaces[i].scale = Vector3(1000, 1000, 1000)
		surfaces[i].material_override = mono_material

	surfaces[SURFACES.PLANE].mesh = load("res://geometry/plane.obj")
	surfaces[SURFACES.PLANE].position = _plane_position

	surfaces[SURFACES.HALF_SPHERE].mesh = load("res://geometry/half_sphere.obj")
	surfaces[SURFACES.EAC_SPHERE].mesh = load("res://geometry/eac_sphere.obj")
	surfaces[SURFACES.SPHERE].mesh = load("res://geometry/sphere.obj")
	
	load_surface(SURFACES.PLANE)


func _adjust_plane_size():
	var texture = player.get_video_texture()
	if _view_mode == VIEW_MODE.IMAGE:
		texture = mono_material.albedo_texture
	if _surface_id == SURFACES.PLANE and texture:
		var tex = texture.get_size()
		video_surface.scale.x = video_surface.scale.y * tex.x/tex.y / (1 + float(_is_stereo and not _texture2))


func recenter_view():
	var surface_transform = get_viewport().get_camera_3d().transform
	var surface_rotation = surface_transform.basis.get_euler()
	surface_rotation.z = 0
	var _surface_basis = Basis.from_euler(surface_rotation).scaled(video_surface.scale)
	for surface in surfaces:
		surface.transform.basis = _surface_basis
		surface.position = surface_transform.origin
	surfaces[SURFACES.PLANE].position += surface_transform.basis * (_plane_position)

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

	var tex_file = FileAccess.open(path, FileAccess.READ)
	var bytes = tex_file.get_buffer(tex_file.get_length())
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
	var imgtex = ImageTexture.create_from_image(img)
	tex_file.close()
	return imgtex

func load_media_file(path):
	# try to load video
	var texture
	_texture2 = null # mpo support
		# try to load image
	texture = _load_external_tex(path)
	if texture:
		_view_mode = VIEW_MODE.IMAGE
		player.stop()

	elif _load_video(path):
		texture = $VideoViewport.get_texture()
		_view_mode = VIEW_MODE.VIDEO
	else:
		print("ERROR: Couldn't _recognize file: %s" % path)
		return
	
	if path.get_base_dir() != _current_dir:
		_current_dir = path.get_base_dir()
		_file_list = _get_file_list(_current_dir)
		_current_file_idx = _file_list.find(path)
	current_file = path.get_file()

	mono_material.albedo_texture = texture
	for m in stereo_materials:
		m.set_shader_parameter("stereo_img", texture)
	if _texture2:
		stereo_2img_material.set_shader_parameter("stereo_img", texture)
		stereo_2img_material.set_shader_parameter("stereo_img2", _texture2)

	_adjust_plane_size()
	set_stereo(_is_stereo)


func _load_video(video):
	var stream = FFmpegVideoStream.new()
	stream.file = video
	player.stream = stream
	#var stream = VideoStreamGDNative.new()
	#stream.set_file(video)
	#player.stream = stream
	
	if(!player.get_video_texture()):
		# fallback option
		player.stream = load(video)
	if(!player.get_video_texture()):
		print("ERROR: Couldn't load video")
		return false
	
	$VideoViewport.size = player.get_video_texture().get_size()
	player.play()
	playback_state_changed.emit(PLAYBACK_STATE.PLAYING)
	player.paused = false
	return true
	
# p in percent
func set_video_position(p):
	p = max(p, 0)
	print("try to set video position: %f -> %f" % [player.stream_position, p])
	if abs(player.stream_position - p) > 1.0:
		print("actually setting stream position...")
		player.stream_position = p
		
		# seek next frame while paused (from godot-videodecoder.c)
		if player.paused:
			player.paused = false
			# yes, it seems like 5 idle frames _is_ the magic number.
			# VideoPlayer gets notified to do NOTIFICATION_INTERNAL_PROCESS on idle frames
			# so this should always work?
			#for i in range(5): # TODO: seeking sucks right now
			#	await get_tree().process_frame
			#await get_tree().create_timer(0.3).timeout
			player.paused = true


func set_stereo(is_stereo):
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


func load_surface(surface_id):
	if surface_id == _surface_id:
		return
	
	if video_surface:
		remove_child(video_surface)
	video_surface = surfaces[surface_id]
	add_child(video_surface)
	_surface_id = surface_id
	_adjust_plane_size()
	set_stereo(_is_stereo) # refresh material

func toggle_pause():
	if player.is_playing():
		if player.paused:
			player.paused = false
			playback_state_changed.emit(PLAYBACK_STATE.PLAYING)

		else:
			player.paused = true
			playback_state_changed.emit(PLAYBACK_STATE.PAUSED)
	else:
		player.play()
		#set_video_position(0)
		playback_state_changed.emit(PLAYBACK_STATE.PLAYING)


func zoom_in():
	if _surface_id == SURFACES.PLANE:
		video_surface.scale.x *= 1.125
		video_surface.scale.y *= 1.125
func zoom_out():
	if _surface_id == SURFACES.PLANE:
		video_surface.scale.x /= 1.125
		video_surface.scale.y /= 1.125



func _on_video_player_finished():
	if is_loop:
		set_video_position(0)
		player.play()
		print("start again")
	else:
		playback_state_changed.emit(PLAYBACK_STATE.STOPPED)

func set_swap_eyes(swap_eyes):
	for m in stereo_materials:
		m.set_shader_parameter("cross_eyes", int(swap_eyes))
	stereo_2img_material.set_shader_parameter("cross_eyes", int(swap_eyes))

## STATIC UTILITY FUNCTION
func _get_file_list(dir_path):
	var files = []
	var dir = DirAccess.open(dir_path)
	dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547
	while true:
		var file = dir.get_next() 
		if file.get_extension() in FILE_EXTS:
			files.push_back(file)
		elif file == "":
			return files

func load_next_file():
	if not _file_list:
		return
	if _current_file_idx + 1 < _file_list.size():
		_current_file_idx += 1
	else:
		_current_file_idx = 0
	load_media_file(_current_dir + '/' + _file_list[_current_file_idx])
func load_prev_file():
	if not _file_list:
		return
	if _current_file_idx > 0:
		_current_file_idx -= 1
	else:
		_current_file_idx = _file_list.size() - 1
	load_media_file(_current_dir + '/' + _file_list[_current_file_idx])


func skip_forward():
	print("skip forward")
	set_video_position(player.stream_position + 10)
	
func skip_backward():
	set_video_position(player.stream_position - 10)

func press_left():
	if _view_mode == VIEW_MODE.VIDEO:
		skip_backward()
	else:
		load_prev_file()
func press_right():
	if _view_mode == VIEW_MODE.VIDEO:
		skip_forward()
	else:
		load_next_file()


func set_mute(val: bool):
	if val:
		player.volume = 0
	else:
		player.volume_db = volume_db
func is_muted():
	return player && player.volume == 0

func raise_volume():
	volume_db += 5
func lower_volume():
	volume_db -= 5
