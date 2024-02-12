class_name VolumeControl
extends Control

signal value_changed

@export var value = 0:
	set(v):
		label.text = str(v) + suffix
		value = v
	get:
		return value

@export var suffix: String = " dB"
@export var small_step: int = 2
@export var big_step: int = 12

@onready var label = $HBoxContainer/Label

func _on_button_lower_much_pressed():
	value -= big_step
func _on_button_lower_pressed():
	value -= small_step
func _on_button_raise_pressed():
	value += small_step
func _on_button_raise_much_pressed():
	value += big_step
