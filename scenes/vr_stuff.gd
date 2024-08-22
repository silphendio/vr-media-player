extends Node3D

@onready var left_hand = $XROrigin3D/LeftHand
@onready var right_hand = $XROrigin3D/RightHand

@onready var camera = $XROrigin3D/XRCamera3D

@onready var left_hand_mesh = $XROrigin3D/LeftHand/MeshInstance3D
@onready var right_hand_mesh = $XROrigin3D/RightHand/MeshInstance3D



func _on_left_hand_tracking_changed(tracking):
	left_hand.visible = tracking


func _on_right_hand_tracking_changed(tracking):
	right_hand.visible = tracking
