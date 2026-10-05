extends CollisionShape3D
class_name Building_Block_V2

var max_armor_points: int = 40
var armor_points: int = 40

signal got_destroyed(building_block: Building_Block_V2, type: Block_Types)

var render: MeshInstance3D = null

var id: int = 0

var is_being_destroyed: bool = false

enum Block_Types {STREET, INNER, CORNER, SIDE, ROOF}
var block_type: Block_Types = Block_Types.INNER

var block_visual_rotation: float = 0.0

var effects_manager: Effects_Manager = null

var destruction_point: Vector3 = Vector3.ZERO
var settings_manager: SettingsManager = null

func initialize() -> void:
	effects_manager = Effects_Manager.INSTANCE
	settings_manager = Settings_Manager.INSTANCE
	destruction_point = global_position
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
	if is_being_destroyed:
		return
	
	armor_points -= damage
	armor_points = clamp(armor_points,0,max_armor_points)
	
	#print(armor_points)
	
	if armor_points <= 0:
		if source:
			source.get_score(max_armor_points * 4)
			
		#if is_player:
			#self.get_parent().get_parent().death_screen.visible = true
		destroy_now()
		#got_destroyed.emit(self)
		#deactivate() 
		
func destroy_now(point: Vector3 = global_position) -> void:
	if is_being_destroyed:
		return
	is_being_destroyed = true
	armor_points = 0
	
	var destruction_point: Vector3 = point
	
	got_destroyed.emit(self, block_type)
	
	if effects_manager and settings_manager:
		if settings_manager.destruction_effects_mode == settings_manager.Destruction_Effects_Mode.Always or settings_manager.destruction_effects_mode == settings_manager.Destruction_Effects_Mode.On_Block_Only:
			effects_manager.debris_from_pool(destruction_point)
	
	queue_free()
	
func deactivate() -> void:
	
	
	if effects_manager and settings_manager:
		if settings_manager.destruction_effects_mode == settings_manager.Destruction_Effects_Mode.Always or settings_manager.destruction_effects_mode == settings_manager.Destruction_Effects_Mode.On_Building_Only:
			effects_manager.debris_from_pool(global_position)
	queue_free()
	return
	visible = false
	
	return
	
	for c in get_children():
		if c.has_method("deactivate"):
			c.deactivate()
	
