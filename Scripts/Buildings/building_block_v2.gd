extends CollisionShape3D
class_name Building_Block_V2

var max_armor_points: int = 40
var armor_points: int = 40

signal got_destroyed(building_block: Building_Block_V2)

var render: MeshInstance3D = null

var id: int = 0

func initialize() -> void:
	return
	# 1. Verificamos que este nodo realmente tenga una forma tipo caja asignada
	if shape is BoxShape3D:
		# 2. Creamos el nodo visual (MeshInstance3D)
		var r: MeshInstance3D = MeshInstance3D.new()
		
		# 3. Creamos el recurso visual de la caja (BoxMesh)
		var box_mesh: BoxMesh = BoxMesh.new()
		
		# 4. Le copiamos el tamaño exacto del CollisionShape3D
		box_mesh.size = shape.size
		
		# 5. Asignamos la malla al nodo visual
		r.mesh = box_mesh
		
		# 6. Añadimos el nodo visual como hijo para que aparezca en el mundo
		add_child(r)

func take_damage(damage: int, source: Vehicle_Rigid, impact_point: Vector3) -> void:
	armor_points -= damage
	armor_points = clamp(armor_points,0,max_armor_points)
	
	#print(armor_points)
	
	if armor_points <= 0:
		if source:
			source.get_score(max_armor_points * 4)
			
		#if is_player:
			#self.get_parent().get_parent().death_screen.visible = true
		got_destroyed.emit(self)
		deactivate() 

func deactivate() -> void:
	
	queue_free()
	return
	visible = false
	
	return
	
	for c in get_children():
		if c.has_method("deactivate"):
			c.deactivate()
	
