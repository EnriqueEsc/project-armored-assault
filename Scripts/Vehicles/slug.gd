extends Projectile
class_name Slug

var slugs: Array[Projectile] = []
@export var slug_pref: PackedScene = preload("res://Prefabs/Test/slug.tscn")
@export var slug_num: int = 10
@export var recursivity: int = 1
@export var horizontal_disp: Vector2 = Vector2.ZERO
@export var vertical_disp: Vector2 = Vector2.ZERO
var fixated_ignore: Array = []

func _additional_setup() -> void:
	if recursivity < 1:
		return
	
	if slug_num < 1:
		return
	
	slugs = []
	for i in slug_num:
		var pref = slug_pref.instantiate() as Slug
		pref.damage = damage
		pref.blast_rad = blast_rad
		pref.base_speed = base_speed
		pref.blast_damage = blast_damage
		pref.blast_det_max_entities = blast_det_max_entities
		pref.recursivity = recursivity - 1
		get_tree().current_scene.call_deferred("add_child",pref)
		slugs.append(pref)
	
	for s in slugs:
		s.ignore = (fixated_ignore)
		s.ignore.append_array(ignore)

	
func _additional_shoot_process() -> void:
	if slugs.is_empty():
		return
		
	for s in slugs:
		s.ignore = (fixated_ignore)
		s.ignore.append_array(ignore)
		
		s.shoot(global_position + (global_basis.z),Vector2(rotation.x + deg_to_rad(randf_range(vertical_disp.x,vertical_disp.y)),rotation.y + deg_to_rad(randf_range(horizontal_disp.x,horizontal_disp.y))))

func set_origin(vehicle: Vehicle_Rigid) -> void:
	origin = vehicle
	hits_enemy.connect(origin.send_hit_signal)
	is_player = origin.is_player
	fixated_ignore = [origin]
