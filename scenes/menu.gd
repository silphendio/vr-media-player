extends Control

@export var video_node: Node3D = null

enum PROJECTION {
	FLAT,
	VR180,
	VR360,
	VR360_EAC,
}


var _pause_icon = preload("res://thirdparty/material-symbols/pause_white_24dp.svg")
var _play_icon = preload("res://thirdparty/material-symbols/play_arrow_white_24dp.svg")

var volume_icon = preload("res://thirdparty/material-symbols/volume_up_white_24dp.svg")
var volume_icon_quiet = preload("res://thirdparty/material-symbols/volume_down_white_24dp.svg")
var volume_icon_muted = preload("res://thirdparty/material-symbols/volume_off_white_24dp.svg")

@onready var volume_button = $VBoxContainer/HBoxContainer3/VolumeIcon
@onready var start_button = $VBoxContainer/HBoxContainer/StartButton
@onready var progress_slider = $VBoxContainer/ProgressSlider
@onready var progress_label = $VBoxContainer/HBoxContainer2/ProgressLabel
@onready var volume_control = $VBoxContainer/HBoxContainer3/VolumeSlider

# for video progress
var _duration = 0
var _progress = 0

enum PLAYBACK_STATE {STOPPED, PLAYING, PAUSED}
func set_playstate(p):
	if p == PLAYBACK_STATE.PLAYING:
		start_button.icon = _pause_icon
	else:
		start_button.icon = _play_icon


func update_progress_bar(pos: float, duration: float):
	_progress = pos
	_duration = duration
	var value
	if duration == 0:
		value = 0
		pos = 0
	else:
		value = int(progress_slider.max_value * pos / duration)
	if progress_slider.value != value:
		progress_slider.set_value_no_signal(value)
		progress_label.text = _sec_to_str(int(pos)) + " / " + _sec_to_str(int(duration))

func set_volume(volume_db: float):
	video_node.volume_db = int(volume_db)
	if volume_db > -12:
		volume_button.icon = volume_icon
	else:
		volume_button.icon = volume_icon_quiet
	
	if volume_control.value != volume_db:
		volume_control.value = volume_db

func set_muted(muted: bool = true):
	video_node.set_mute(muted)
	if video_node.is_muted():
		if volume_button.icon != volume_icon_muted:
			volume_button.icon = volume_icon_muted
	else:
		set_volume(video_node.volume_db)

func _sec_to_str(seconds: int):
	var text = ""
	@warning_ignore("integer_division")
	var hours = int(seconds/3600)
	@warning_ignore("integer_division")
	var minutes = int(seconds/60) % 60
	if hours > 0:
		text += "%d:" % hours
		text += "%02d:" % minutes
	else:
		text += "%d:" % minutes
	text += "%02d:" % (int(seconds) % 60)
	return text


func update_ui():
	if(video_node.player):
		update_progress_bar(video_node.player.stream_position, video_node.player.get_stream_length())
		set_muted(video_node.is_muted())
		if !video_node.is_muted():
			set_volume(video_node.volume_db)

func _process(_delta):
	update_ui()

func _on_LoadButton_pressed():
	$FileDialog.popup()


func _on_LoopCheckButton_toggled(button_pressed):
	video_node.is_loop = button_pressed

func _on_VolumeSlider_value_changed(value):
	set_volume(value)

func _on_ProgressSlider_value_changed(value):
	var p = _duration * value / progress_slider.max_value
	video_node.set_video_position(p)

func _on_ExitDialog_confirmed():
	print("QUIT")
	get_tree().quit()

func _on_ExitButton_pressed():
	$ExitDialog.show()


# simple signal forwarding

func _on_FileDialog_file_selected(path):
	video_node.load_media_file(path)

func _on_StartButton_pressed():
	video_node.toggle_pause()

func _on_PrevButton_pressed():
	video_node.load_prev_file()

func _on_SkipBackButton_pressed():
	video_node.skip_backward()

func _on_Skip_forwardButton_pressed():
	video_node.skip_forward()

func _on_NextButton_pressed():
	video_node.load_next_file()

func _on_RecenterButton_pressed():
	video_node.recenter_view()

func _on_ZoomOutButton_pressed():
	video_node.zoom_out()

func _on_ZoomInButton_pressed():
	video_node.zoom_in()

func _on_SwapEyesCheckButton_toggled(button_pressed):
	video_node.set_swap_eyes(button_pressed)


func _on_projection_flat_pressed():
	video_node.load_surface(PROJECTION.FLAT)
func _on_projection_180_pressed():
	video_node.load_surface(PROJECTION.VR180)
func _on_projection_360_pressed():
	video_node.load_surface(PROJECTION.VR360)
func _on_projection_360eac_pressed():
	video_node.load_surface(PROJECTION.VR360_EAC)


func _on_mono_pressed():
	video_node.set_stereo(false)
func _on_stereo_pressed():
	video_node.set_stereo(true)



func _on_volume_icon_pressed():
		set_muted(!video_node.is_muted())
