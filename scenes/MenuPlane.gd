extends MeshInstance


func get_2d_position(point3d):
	var p = $Area.global_transform.affine_inverse() * point3d
	p = Vector2(p.x, p.z)
	p.x = (p.x+1)/2
	p.y = (p.y+1)/2
	p *= $Viewport.size
	return p

func _unhandled_input(event):
	if event is InputEventMouse:
		# find ray intersection
		var camera = get_viewport().get_camera()
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * 100
		var result = get_world().direct_space_state \
		.intersect_ray(from, to, [], $Area.collision_layer,false,true)
		
		# calculate 2d position
		if result.size() > 0 and result.collider == $Area:
			event.position = get_2d_position(result.position)
			$Viewport.input(event)

	if event is InputEventKey:
		$Viewport.input(event)
