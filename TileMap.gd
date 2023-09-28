@tool
extends TileMap

#Laying out basic states the terrain state will be to take account of terrain
#changes whenever they occur might remove later
enum State{ ALLYTURN, MARCH, DESPAWN, SPAWN, ENEMYTURN, DUEL, TERRAIN }
@export var state = State.SPAWN
var _round_count : int = 0
@onready var astar_node = AStar3D.new()
@onready var astar_node2 = AStar3D.new()
var hexes = get_used_cells_by_id( 0, 2, Vector2i( 0, 0 ), 0 )
var water = get_used_cells_by_id( 0, 2, Vector2i( 1, 0 ), 0)
# The Tilemap node doesn't have clear bounds so we're defining the map's limits here.
@export var map_size: Vector2 = Vector2(14, 10)
var obstical = Vector2i(-256, -256)
var _selection
var checked_tiles = {}
#hardcoding this saves us 2 if statements and a search inside a loop
var small_map = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0), Vector2i(8, 0), Vector2i(9, 0), Vector2i(10, 0), Vector2i(11, 0), Vector2i(12, 0), Vector2i(13, 0), Vector2i(14, 0),
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1), Vector2i(7, 1), Vector2i(8, 1), Vector2i(9, 1), Vector2i(10, 1), Vector2i(11, 1), Vector2i(12, 1), Vector2i(13, 1), Vector2i(14, 1),
	Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2), Vector2i(7, 2), Vector2i(8, 2), Vector2i(9, 2), Vector2i(10, 2), Vector2i(11, 2), Vector2i(12, 2), Vector2i(13, 2), Vector2i(14, 2),
	Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 3), Vector2i(8, 3), Vector2i(9, 3), Vector2i(10, 3), Vector2i(11, 3), Vector2i(12, 3), Vector2i(13, 3), Vector2i(14, 3),
	Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4), Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4), Vector2i(7, 4), Vector2i(8, 4), Vector2i(9, 4), Vector2i(10, 4), Vector2i(11, 4), Vector2i(12, 4), Vector2i(13, 4), Vector2i(14, 4),
	Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 5), Vector2i(7, 5), Vector2i(8, 5), Vector2i(9, 5), Vector2i(10, 5), Vector2i(11, 5), Vector2i(12, 5), Vector2i(13, 5), Vector2i(14, 5), 
	Vector2i(0, 6), Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(4, 6), Vector2i(5, 6), Vector2i(6, 6), Vector2i(7, 6), Vector2i(8, 6), Vector2i(9, 6), Vector2i(10, 6), Vector2i(11, 6), Vector2i(12, 6), Vector2i(13, 6), Vector2i(14, 6), 
	Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 7), Vector2i(5, 7), Vector2i(6, 7), Vector2i(7, 7), Vector2i(8, 7), Vector2i(9, 7), Vector2i(10, 7), Vector2i(11, 7), Vector2i(12, 7), Vector2i(13, 7), Vector2i(14, 7), 
	Vector2i(0, 8), Vector2i(1, 8), Vector2i(2, 8), Vector2i(3, 8), Vector2i(4, 8), Vector2i(5, 8), Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8), Vector2i(9, 8), Vector2i(10, 8), Vector2i(11, 8), Vector2i(12, 8), Vector2i(13, 8), Vector2i(14, 8), 
	Vector2i(0, 9), Vector2i(1, 9), Vector2i(2, 9), Vector2i(3, 9), Vector2i(4, 9), Vector2i(5, 9), Vector2i(6, 9), Vector2i(7, 9), Vector2i(8, 9), Vector2i(9, 9), Vector2i(10, 9), Vector2i(11, 9), Vector2i(12, 9), Vector2i(13, 9), Vector2i(14, 9), 
	Vector2i(0, 10), Vector2i(1, 10), Vector2i(2, 10), Vector2i(3, 10), Vector2i(4, 10), Vector2i(5, 10), Vector2i(6, 10), Vector2i(7, 10), Vector2i(8, 10), Vector2i(9, 10), Vector2i(10, 10), Vector2i(11, 10), Vector2i(12, 10), Vector2i(13, 10), Vector2i(14, 10)
]


var _point_path = []

var path_start_position: Vector2: 
	set(value):
		if is_outside_map_bounds(value):
			return
		path_start_position = value
		if path_end_position and path_end_position != path_start_position:
			_recalculate_path()

var path_end_position: Vector2:
	set(value):
		if is_outside_map_bounds(value):
			return
		path_end_position = value
		if path_start_position != value:
			_recalculate_path()
			#not sure why we keep calling ready so much maybe prune this
			#_ready()
		path_end_position = value



# Called when the node enters the scene tree for the first time.
func _ready():
	if state == State.SPAWN:
		spawn()
	var walkable_cells_list = astar_add_walkable_cells(water,hexes)
	astar_connect_walkable_cells(walkable_cells_list)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func spawn():
	state = State.ALLYTURN

func calculate_point_index(point):
	return point.x + map_size.x * point.y


# Loops through all cells within the map's bounds and
# adds all points to the astar_node, except the obstacles.
func astar_add_walkable_cells(obstacle_list = [], hex_list = []):

	var count = 0
	for point in small_map:
		astar_node.add_point(count, Vector3(point.x,point.y,0))
		count += 1
	for point in obstacle_list:
		astar_node.remove_point(calculate_point_index(point))


	return small_map



func clear_previous_path_drawing():
	if not _point_path:
		return
	var point_start = _point_path[0]
	var point_end = _point_path[len(_point_path) - 1]

func _recalculate_path():
	clear_previous_path_drawing()
	var start_point_index = calculate_point_index(path_start_position)
	var end_point_index = calculate_point_index(path_end_position)
	# This method gives us an array of points. Note you need the start and
	# end points' indices as input.

	_point_path = astar_node.get_point_path(start_point_index, end_point_index)
	# Redraw the lines and circles from the start to the end point.
	queue_redraw()


func is_outside_map_bounds(point):
	return point.x < 0 or point.y < 0 or point.x >= map_size.x or point.y >= map_size.y



func _on_timer_timeout(timer) -> void:
	timer.queue_free()

func _input(event):
	#if _phase == Phases.PLAY:
	if event.is_action_pressed("click") or event.is_action_pressed("ui_accept"):
		var pos = event.position
		_selection = local_to_map(pos)
			#_last_click = world_to_map(pos)

#wondering if this function is even used
func _draw():
	if not _point_path:
		return
	var point_start = _point_path[0]
	var point_end = _point_path[len(_point_path) - 1]
	var last_point = map_to_local(Vector2i(point_start.x, point_start.y)) #+ _half_cell_size
	for index in range(1, len(_point_path)):
		var current_point = map_to_local(Vector2(_point_path[index].x, _point_path[index].y)) #+ _half_cell_size
		draw_line(last_point, current_point, Color.WHITE, 4)
		draw_circle(current_point, 4, Color.WHITE)
		last_point = current_point

func _check_cells(point) -> Array:
	checked_tiles[point] = true
	var points_relative
	if point.x as int%2 == 0:
		points_relative = PackedVector2Array([
			point + Vector2.RIGHT,
			point + Vector2.LEFT,
			point + Vector2.DOWN,
			point + Vector2.UP,
			point + Vector2.UP + Vector2.LEFT,
			point + Vector2.DOWN + Vector2.LEFT,
		])
	else:
		points_relative = PackedVector2Array([
			point + Vector2.RIGHT,
			point + Vector2.LEFT,
			point + Vector2.DOWN,
			point + Vector2.UP,
			point + Vector2.DOWN + Vector2.RIGHT,
			point + Vector2.UP + Vector2.RIGHT,
			])
	for point_relative in points_relative:
		if checked_tiles.has(point_relative):
			continue
		if get_cell_tile_data(0,point_relative):
			continue
	return checked_tiles

func _check_balls(point, to_destroy, range):
	if to_destroy.size() >= range +6 : _show_range(to_destroy)
	if to_destroy.size() >= range +6 : return
	checked_tiles[point] = true
	var points_relative
	if point.x as int%2 == 0:
		points_relative = PackedVector2Array([
			point + Vector2.DOWN,
			point + Vector2.UP,
			point + Vector2.RIGHT,
			point + Vector2.UP + Vector2.RIGHT,
			point + Vector2.LEFT,
			point + Vector2.DOWN + Vector2.RIGHT,
		])
	else:
		points_relative = PackedVector2Array([
			point + Vector2.DOWN,
			point + Vector2.UP,
			point + Vector2.RIGHT,
			point + Vector2.UP + Vector2.LEFT,
			point + Vector2.LEFT,
			point + Vector2.DOWN + Vector2.LEFT,
			])
	for point_relative in points_relative:
		if checked_tiles.has(point_relative):
			continue
		to_destroy.append(point_relative)
		_check_balls(point_relative, to_destroy, range)



func _flood_fill(grid_position : Vector2, range):
	checked_tiles.clear()
	var to_destroy = []
	_check_balls(grid_position, to_destroy, range)



func _show_range(list):
	var overlay = load("res://overlay.tscn").instantiate()
	add_child(overlay)
	overlay.add_to_group("overlay")
	overlay.hexes = list
	overlay._ready()



func _clear_flood():
	for node in get_tree().get_nodes_in_group("overlay"):
		node.queue_free()

# Once you added all points to the AStar node, you've got to connect them.
# The points don't have to be on a grid: you can use this class
# to create walkable graphs however you'd like.
# It's a little harder to code at first, but works for 2d, 3d,
# orthogonal grids, hex grids, tower defense games...
func astar_connect_walkable_cells(points_array):
	for point in points_array:
		var point_index = calculate_point_index(point)
		# For every cell in the map, we check the one to the top, right.
		# left and bottom of it. If it's in the map and not an obstalce.
		# We connect the current point with it.
		var points_relative
		if point.y as int%2 == 0:
			points_relative = PackedVector2Array([
				point + Vector2i.RIGHT,
				point + Vector2i.LEFT,
				point + Vector2i.DOWN,
				point + Vector2i.UP,
				point + Vector2i.UP + Vector2i.LEFT,
				point + Vector2i.DOWN + Vector2i.LEFT,
			])
		else:
			points_relative = PackedVector2Array([
				point + Vector2i.RIGHT,
				point + Vector2i.LEFT,
				point + Vector2i.DOWN,
				point + Vector2i.UP,
				point + Vector2i.DOWN + Vector2i.RIGHT,
				point + Vector2i.UP + Vector2i.RIGHT,
			])
		for point_relative in points_relative:
			var point_relative_index = calculate_point_index(point_relative)
			if is_outside_map_bounds(point_relative):
				continue
			if not astar_node.has_point(point_relative_index):
				continue
			# Note the 3rd argument. It tells the astar_node that we want the
			# connection to be bilateral: from point A to B and B to A.
			# If you set this value to false, it becomes a one-way path.
			# As we loop through all points we can set it to false.
			astar_node.connect_points(point_index, point_relative_index, false)

func get_astar_path(world_start, world_end):
	self.path_start_position = local_to_map(world_start)
	self.path_end_position = local_to_map(world_end)
	#_recalculate_path()
	var path_world = []
	for point in _point_path:
		var point_world = map_to_local(Vector2i(point.x, point.y)) #+ _half_cell_size
		path_world.append(point_world)
	return path_world
