extends Node



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		RenderingServer.global_shader_parameter_set("player_pos", player.global_position)
