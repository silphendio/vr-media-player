extends Control


enum PROJECTION {
	FLAT,
	VR180,
	VR360
	VR360_EAC
}
var projection = PROJECTION.FLAT
var is_stereo = false
var is_loop = false

signal video_loaded(file)

signal is_stereo_changed(is_stereo)
signal projection_changed(projection)
signal is_loop_changed(is_loop)

signal volume_changed(vol)

signal progress_changed(p)

signal start_pressed
signal recenter_pressed

signal zoom_in_pressed
signal zoom_out_pressed
signal swap_eyes_changed(swap_eyes)

signal prev_pressed
signal next_pressed
signal skip_forward_pressed
signal skip_back_pressed

var volume = 100 setget set_volume

var is_playing setget set_is_playing

var _pause_icon
var _start_icon

var volume_icon = preload("res://thirdparty/tabler-icons/volume.svg")
var volume_icon2 = preload("res://thirdparty/tabler-icons/volume-2.svg")
var volume_icon3 = preload("res://thirdparty/tabler-icons/volume-3.svg")

# for video progress
var _duration = 0
var _progress = 0
onready var _progress_slider = $VBoxContainer/ProgressSlider
var _is_progress_dragging = false

func set_is_playing(p):
	is_playing = p
	if is_playing:
		$VBoxContainer/HBoxContainer/StartButton.icon = _pause_icon
	else:
		$VBoxContainer/HBoxContainer/StartButton.icon = _start_icon

func set_volume(vol):
	volume = clamp(vol, 0, 100)
	$VBoxContainer/HBoxContainer3/VolumeSlider.value = volume

func set_progress(pos, duration):
	if (_duration == duration and _progress == pos):
		return

	_progress = pos
	_duration = duration
	var value
	if duration == 0:
		value = 0
		pos = 0
	else:
		value = int(_progress_slider.max_value * pos / duration)
	if _progress_slider.value != value:
		_progress_slider.value = value
		$VBoxContainer/HBoxContainer2/ProgressLabel.text = _sec_to_str(pos) + " / " + _sec_to_str(duration)

func _sec_to_str(seconds):
	var text = ""
	var hours = int(seconds/3600)
	var minutes = int(seconds/60) % 60
	if hours > 0:
		text += "%d:" % hours
		text += "%02d:" % minutes
	else:
		text += "%d:" % minutes
	text += "%02d:" % (int(seconds) % 60)
	return text
# Called when the node enters the scene tree for the first time.
func _ready():
	var btn = $VBoxContainer/GridContainer/ProjectionOption
	btn.add_item("Flat")
	btn.add_item("180°")
	btn.add_item("360°")
	btn.add_item("360° EAC")
	
	$VBoxContainer/GridContainer/StereoOption.add_item("Mono")
	$VBoxContainer/GridContainer/StereoOption.add_item("Stereo")

	_start_icon = load("res://thirdparty/tabler-icons/player-play.svg")
	_pause_icon = load("res://thirdparty/tabler-icons/player-pause.svg")

func _on_LoadButton_pressed():
	$FileDialog.popup()

func _on_ProjectionOption_item_selected(index):
	projection = index
	emit_signal("projection_changed", index)

func _on_StereoOption_item_selected(index):
	is_stereo = bool(index)
	emit_signal("is_stereo_changed", is_stereo)

func _on_LoopCheckButton_toggled(button_pressed):
	is_loop = button_pressed
	emit_signal("is_loop_changed", is_loop)

func _on_VolumeSlider_value_changed(value):
	volume = value
	var icon = $VBoxContainer/HBoxContainer3/VolumeIcon
	if value > 50:
		icon.texture = volume_icon
	elif value > 0:
		icon.texture = volume_icon2
	else:
		icon.texture = volume_icon3
	emit_signal("volume_changed", volume)

func _on_ProgressSlider_value_changed(value):
	var p = _duration * value / _progress_slider.max_value
	emit_signal("progress_changed",  p)

func _on_ExitDialog_confirmed():
	get_tree().quit()

func _on_ExitButton_pressed():
	$ExitDialog.show()


func _on_ProgressSlider_drag_started():
	_is_progress_dragging = true

func _on_ProgressSlider_drag_ended(_value_changed):
	_is_progress_dragging = false

# simple signal forwarding

func _on_FileDialog_file_selected(path):
	emit_signal("video_loaded", path)

func _on_StartButton_pressed():
	emit_signal("start_pressed")

func _on_PrevButton_pressed():
	emit_signal("prev_pressed")

func _on_SkipBackButton_pressed():
	emit_signal("skip_back_pressed")

func _on_Skip_forwardButton_pressed():
	emit_signal("skip_forward_pressed")

func _on_NextButton_pressed():
	emit_signal("next_pressed")

func _on_RecenterButton_pressed():
	emit_signal("recenter_pressed")

func _on_ZoomOutButton_pressed():
	emit_signal("zoom_out_pressed")

func _on_ZoomInButton_pressed():
	emit_signal("zoom_in_pressed")

func _on_SwapEyesCheckButton_toggled(button_pressed):
	emit_signal("swap_eyes_changed", button_pressed)
