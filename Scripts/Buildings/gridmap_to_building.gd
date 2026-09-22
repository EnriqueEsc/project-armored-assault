extends GridMap

var blocks = null
var blocks_ordered = []
var building: Building_V3 = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	blocks = get_used_cells()
	print(blocks)
	
	await get_tree().physics_frame
	
	order_positions()
	generate_collisions()

func order_positions() -> void:
	blocks_ordered.clear()
	
	var order: Dictionary = {}
	
	for b in blocks:
		if not order.has(b.y):
			order[b.y] = []
		order[b.y].append(b)
	
	var heights = order.keys()
	heights.sort()
	
	for height in heights:
		blocks_ordered.append(order[height])

func generate_collisions() -> void:
	if blocks_ordered.is_empty():
		return
	
	var parent_node = get_parent() as Node3D
	
	if parent_node == null:
		return
	
	building = Building_V3.new()
	building.name = "Building"
	
	building.grid_map = self
	building.transform = transform
	
	building.position += Vector3(1,1.0,1)
	
	for bo in blocks_ordered:
		if bo.is_empty():
			continue
			
		var height: int = bo[0].y
		var chunk = Building_Chunk.new()
		chunk.name = "Chunk_" + str(height)
		print(bo[0].y)
		chunk.position.y = (Vector3i(0, height, 0)).y
		building.add_child(chunk)
		
		for b in bo:
			var col = CollisionShape3D.new()
			var shape = BoxShape3D.new()
			shape.size = cell_size
			col.shape = shape
			
			chunk.add_child(col)
			building.grid_offset = Vector3i(cell_size.x,1.0,cell_size.z)
			col.position = Vector3(b) * Vector3(building.grid_offset)
			print(Vector3(col.position.x,col.position.y,col.position.z))
	collision_layer = 0
	collision_mask = 0
	
	parent_node.add_child(building)
	reparent(building)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
