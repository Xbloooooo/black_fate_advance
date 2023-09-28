extends Node2D

enum State { IDLE, MARCH, SELECT, WAIT }
@export var state = State.IDLE
const MASS = 1.0
const ARRIVE_DISTANCE = 2.0
@export var speed: float = 350.0
@export var color: int = 0
@export var range = 3
var _path = []
var _target_point_world = Vector2()
var _target_position = Vector2()
var _velocity = Vector2()


# Called when the node enters the scene tree for the first time.
func _ready():
	self.add_to_group("unit")
	_change_state(State.IDLE)

func _process(_delta):
	if state != State.MARCH:
		return
	var _arrived_to_next_point = _move_to(_target_point_world)
	if _arrived_to_next_point:
		_path.remove_at(0)
		if len(_path) == 0:
			_final_move(_target_point_world)
			_change_state(State.IDLE)
			return
		_target_point_world = _path[0]


func _unhandled_input(event):
	if event.is_action_pressed("click") or event.is_action_pressed("ui_accept"):
		var global_mouse_pos = get_global_mouse_position()
		##TODO replace this with a map_to_world/world_to_map based solution
		#	FIND OUT WHAT THIS CODE DOES
		#if global_mouse_pos.x >= global_position.x-31 && global_mouse_pos.y >= global_position.y-31 && global_mouse_pos.x <= global_position.x+31 && global_mouse_pos.y <= global_position.y+31 && _state == States.SELECT:
			#return
		if global_mouse_pos.x >= global_position.x-20 && global_mouse_pos.y >= global_position.y-20 && global_mouse_pos.x <= global_position.x+20 && global_mouse_pos.y <= global_position.y+20:
			_change_state(State.SELECT)
			get_parent()._flood_fill(get_parent().local_to_map(position), range)
			return
		#if Input.is_key_pressed(KEY_SHIFT):
		#	global_position = global_mouse_pos
		if state == State.SELECT:
			_target_position = global_mouse_pos
			_change_state(State.MARCH)


func _move_to(world_position):
	var desired_velocity = (world_position - position).normalized() * speed
	var steering = desired_velocity - _velocity
	_velocity += steering / MASS
	position += _velocity * get_process_delta_time()
	#rotation = _velocity.angle()
	return position.distance_to(world_position) < ARRIVE_DISTANCE
	
func _final_move(world_position):
	position = world_position
	var grid_position = get_parent().local_to_map(position)
	var group = self.get_groups()
	return


func _change_state(new_state):
	get_parent()._clear_flood()
	if new_state == State.MARCH:
		_path = get_parent().get_astar_path(position, _target_position)
		if not _path or len(_path) == 1:
			_change_state(State.IDLE)
			var grid_position = get_parent().local_to_map(_target_point_world)
			#if grid_position != Vector2i(0,0):
				#get_parent().set_cell(0,Vector2i(grid_position.x,grid_position.y),0)
				#get_parent()._ready()

			return
		# The index 0 is the starting cell.
		# We don't want the character to move back to it in this example.
		_target_point_world = _path[1]
	state = new_state

