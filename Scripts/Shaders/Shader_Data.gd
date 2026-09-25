extends Node

var player: Vehicle_Rigid = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not player:
		for c in get_tree().get_nodes_in_group("Player"):
			if c is Tank_player_controller:
				player = c.tank_rigid
				return
	if is_instance_valid(player) and player.is_inside_tree():
		RenderingServer.global_shader_parameter_set("player_pos", player.global_position)
		#var aim_direction = -player.tank_turret.global_transform.basis.x.normalized()
		#RenderingServer.global_shader_parameter_set("player_aim_dir", aim_direction)
	
	#print("FPS: ",Engine.get_frames_per_second())
