extends TileMap

var hexes: Array: 
	set(value):
		hexes = value

# Called when the node enters the scene tree for the first time.
func _ready():
	if hexes.size() != 0:
		for hex in hexes:
			_spawn_ball(hex)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func _spawn_ball(mappedhex):
	var range = load("res://range.tscn").instantiate()
	add_child(range)
	range.position = map_to_local(mappedhex)
	return range
