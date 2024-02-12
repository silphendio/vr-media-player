extends Label3D

@export var time_left: float = 1.0

@export var volume_db: int = 0:
	get:
		return volume_db
	set(v):
		volume_db = v
		text = str(v) + " dB"
		if v > 0:
			modulate = Color.RED
		else:
			modulate = Color.WHITE

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_left -= delta
	if time_left < 0:
		get_parent().remove_child(self)
