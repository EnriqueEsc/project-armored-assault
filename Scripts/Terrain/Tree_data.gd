extends RefCounted
class_name Tree_data

var max_hp: int = 5
var hp: int = 5
var id: int = 0
var position: Vector3 = Vector3.ZERO
var matrix_index: Vector2i = Vector2i.ZERO
var is_burning: bool = false

signal got_destroyed(id: int)
signal got_burnt(damage:int, matrix_index: Vector2i)

func _init(hp: int, id: int, position: Vector3, matrix_index: Vector2i) -> void:
	self.max_hp = hp
	self.hp = self.max_hp
	self.id = id
	self.position = position
	self.matrix_index = matrix_index
	#print(hp,id,position,matrix_index)

func distance_to(pos: Vector3) -> float:
	return position.distance_to(pos)

func take_damage(damage: int, is_burning: bool) -> void:
	hp -= damage
	
	#damage *= (hp/max_hp)
	
	damage /= 2
	
	if hp > 0:
		return
	
	if self.is_burning:
		return
	
	self.is_burning = is_burning
	
	if is_burning:
		got_burnt.emit(damage, matrix_index)
		
	got_destroyed.emit(id)
