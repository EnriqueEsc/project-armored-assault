extends Node



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		RenderingServer.global_shader_parameter_set("player_pos", player.global_position)
		#var aim_direction = -player.tank_turret.global_transform.basis.x.normalized()
		#RenderingServer.global_shader_parameter_set("player_aim_dir", aim_direction)
	
	#print("FPS: ",Engine.get_frames_per_second())
