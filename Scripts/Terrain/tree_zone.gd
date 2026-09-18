extends Area3D
class_name Tree_Zone

@export var tree_mesh: Mesh
@export var tree_spacing: float = 1.0
@export var tree_prefab: MeshInstance3D = null


@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var multimesh_instance: MultiMeshInstance3D = $MultiMeshInstance3D

var tree_grid: Array = []
var multimesh: MultiMesh

var col_size_x: int = 0
var col_size_z: int = 0

var vehicles_within: Array[Vehicle_Rigid] = []

var active_count: int = 0

func _ready() -> void:
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exit)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exit)
	init_grid()


func init_grid() -> void:
	var box = collision.shape as BoxShape3D

	col_size_x = int(box.size.x / tree_spacing)
	col_size_z = int(box.size.z / tree_spacing)

	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	
	if tree_prefab:
		multimesh.mesh = tree_prefab.mesh
	else:
		multimesh.mesh = tree_mesh
	multimesh.instance_count = col_size_x * col_size_z

	tree_grid.resize(col_size_x)

	var start_x = -box.size.x * 0.5 + tree_spacing * 0.5
	var start_z = -box.size.z * 0.5 + tree_spacing * 0.5

	var counter := 0

	for x in col_size_x:
		tree_grid[x] = []
		tree_grid[x].resize(col_size_z)

		for z in col_size_z:
			var pos = Vector3(start_x + x * tree_spacing,0.0,start_z + z * tree_spacing)

			var transform = Transform3D.IDENTITY

			transform = transform.rotated(Vector3.UP,randf_range(0.0, TAU))

			transform.origin = pos

			multimesh.set_instance_transform(counter, transform)
			var tree: Tree_data = Tree_data.new(1,counter, multimesh_instance.to_global(transform.origin) ,Vector2i(x,z))
			tree.got_destroyed.connect(destroy_tree)
			tree.got_burnt.connect(burn_tree)
			tree_grid[x][z] = tree
			#print("[",x,"][",z,"]"," ",tree_grid[x][z])

			counter += 1
	
	active_count = counter
	multimesh_instance.multimesh = multimesh


func _on_body_entered(body):
	if not body is Vehicle_Rigid:
		return
	
	if body is Vehicle_Rigid:
		vehicles_within.append(body)
	if body is Drone_Rigid:
		if body.explodes.is_connected(take_explosion):
			body.explodes.disconnect(take_explosion)
		body.explodes.connect(take_explosion)

func _on_body_exit(body):
	if not body is Vehicle_Rigid:
		return
	
	if vehicles_within.has(body):
		vehicles_within.erase(body)

func _on_area_entered(body):
	#print(body.collider.get_parent.name)
	
	#print(body == origin)
	
	#print(body)
	
	#print(body)
	if body is Projectile:
		if body.explodes.is_connected(take_explosion):
			body.explodes.disconnect(take_explosion)
		body.explodes.connect(take_explosion)


func _on_area_exit(body):
	#print(body.collider.get_parent.name)
	
	#print(body == origin)
	
	#print(body)
	
	#print(body)
	if body is Projectile:
		if body.explodes.is_connected(take_explosion):
			body.explodes.disconnect(take_explosion)
		#body.explodes.connect(take_explosion)

func take_explosion(pos: Vector3, blast_rad: float, blast_damage: float) -> void:
	var closest_tree: Tree_data = null
	var min_distance: float = INF
	for x in tree_grid:
		for z in x:
			if z.hp > 0 and z.distance_to(pos) < min_distance:
				closest_tree = z
				min_distance = z.distance_to(pos)
	if closest_tree:
		#print( pos," | ",closest_tree.position)
		#closest_tree.got_destroyed.emit(closest_tree.id)
		blast_damage = 10
		closest_tree.take_damage(int(blast_damage),true)

func destroy_tree(id: int) -> void:
	var mm: MultiMesh = multimesh_instance.multimesh
	var t: Transform3D = mm.get_instance_transform(id)
	t.basis = Basis.from_scale(Vector3.ZERO)
	mm.set_instance_transform(id,t)
	active_count -= 1
	if active_count <= 0:
		queue_free()

func burn_tree(damage: int, pos: Vector2i) -> void:
	
	if damage <= 0:
		return
	
	var trees_affected: Array[Tree_data] = []
	var piv_x: int = pos.x
	var piv_z: int = pos.y
	#trees_affected.append(tree_grid[piv_x][piv_z])
	if piv_x + 1 < col_size_x and tree_grid[piv_x + 1][piv_z].hp > 0:
		trees_affected.append(tree_grid[piv_x + 1][piv_z])
	if piv_x - 1 >= 0 and tree_grid[piv_x - 1][piv_z].hp > 0:
		trees_affected.append(tree_grid[piv_x - 1][piv_z])
	if piv_z + 1 < col_size_z and tree_grid[piv_x][piv_z + 1].hp > 0:
		trees_affected.append(tree_grid[piv_x][piv_z + 1])
	if piv_z - 1 >= 0 and tree_grid[piv_x][piv_z - 1].hp > 0:
		trees_affected.append(tree_grid[piv_x][piv_z - 1])
	
	var fire = null
	fire = Effects_Manager.INSTANCE.fire_from_pool(tree_grid[piv_x][piv_z].position)
	if fire:
		await get_tree().create_timer(fire.lifetime / 2.0).timeout
		pass
		#fire.finished.connect(t.take_damage.bind(1,true))
	else:
		await get_tree().create_timer(1.5).timeout
		pass
	var vehicles_affected: Array[Vehicle_Rigid] = []
	for t in trees_affected:
		for v in vehicles_within:
			if not vehicles_affected.has(v) and t.distance_to(v.global_position) < 3.0:
				vehicles_affected.append(v)
		t.take_damage(damage,true)
	
	for v in vehicles_affected:
		v.take_damage(damage,v,v.global_position)
	
	pass
