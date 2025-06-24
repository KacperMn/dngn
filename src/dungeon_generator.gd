extends Node2D

@export var _room_scene : PackedScene
@export var _room_icons : Array[Texture2D]

var _dimensions : Vector2i
var _start : Vector2i
var _critical_path_length : int
var _branches : int
var _branch_length : Vector2i

var dungeon : Array
var _branch_candidates : Array[Vector2i]
enum Doors {
	RIGHT = 1,
	UP = 2,
	LEFT = 4,
	DOWN = 8,
}
const DIRECTIONS : Array[Vector2i] = [
	Vector2i(1, 0),  # RIGHT
	Vector2i(0, 1),  # UP
	Vector2i(-1, 0), # LEFT
	Vector2i(0, -1)  # DOWN
]
const BOTTOM_LEFT_CORNER: Vector2 = Vector2(320, 896)
const ROOM_SIZE: Vector2 = Vector2(160, 160)
const Paths = ["CRITICAL", "BRANCH"]

# Contents of the dungeon cells
enum Contents {
	EMPTY = 0,
	ENTRANCE = 16,
	STAIRS = 32,
	ENEMY = 64,
	TREASURE = 128,
	MERCHANT = 256,
	CAMP = 512,
	BOSS = 1024,
	RANDOM = 2048,
}

func _ready() -> void:
	pass

func generate() -> void:
	_initialize_dungeon()
	_place_entrance()
	_generate_path(_start, _critical_path_length, Paths[0], [Contents.CAMP, Contents.BOSS, Contents.STAIRS])
	_generate_branches()
	_draw_dungeon()

func _initialize_dungeon() -> void:
	for x in _dimensions.x:
		dungeon.append([])
		for y in _dimensions.y:
			dungeon[x].append(Contents.EMPTY)
		
func _place_entrance() -> void:
	if _start.x < 0 or _start.x >= _dimensions.x:
		_start.x = randi_range(0, _dimensions.x - 1)
	if _start.y < 0 or _start.y >= _dimensions.y:
		_start.y = randi_range(0, _dimensions.y - 1)
	dungeon[_start.x][_start.y] |= Contents.ENTRANCE

func _place_doors(current, next, random) -> void:
	dungeon[current.x][current.y] |= Doors.values()[random]
	dungeon[next.x][next.y] |= Doors.values()[(random + 2) % 4]

func _add_branch_candidates(room, path_type) -> void:
	if path_type == Paths[0]:
		_branch_candidates.append(room)

func _handle_room(room, length, path_type, end_of_path) -> void:
	if length <= end_of_path.size():
		dungeon[room.x][room.y] |= end_of_path[end_of_path.size() - length]
	elif path_type == Paths[1]:
		dungeon[room.x][room.y] |= Contents.MERCHANT
	else:
		_add_branch_candidates(room, path_type)
		dungeon[room.x][room.y] |= Contents.RANDOM

func _generate_path(current : Vector2i, length: int, path_type: String, end_of_path: Array[int]) -> bool:
	if length == 0:
		return true
	var random: int = randi_range(0, 3)
	var direction : Vector2i = DIRECTIONS[random]
	for i in 4:
		var next = current + direction
		if next.x >= 0 and next.x < _dimensions.x and next.y >= 0 and next.y < _dimensions.y and not dungeon[next.x][next.y]:
			_place_doors(current, next, random)
			_handle_room(next, length, path_type, end_of_path)
			if _generate_path(next, length - 1, path_type, end_of_path):
				return true  # Success, stop searching
			else:
				dungeon[current.x][current.y] &= ~Doors.values()[random]
				dungeon[next.x][next.y] = Contents.EMPTY
				dungeon[next.x][next.y] &= ~Doors.values()[(random + 2) % 4]
		random += 1
		random %= 4
		direction = DIRECTIONS[random]
	return false

func _generate_branches() -> void:
	var branches_created : int = 0
	var i := 0
	while branches_created < _branches and i < _branch_candidates.size():
		var candidate = _branch_candidates[i]
		# Check if candidate is still a valid room (not empty)
		if dungeon[candidate.x][candidate.y] != Contents.EMPTY:
			if _generate_path(candidate, randi_range(_branch_length.x, _branch_length.y), Paths[1], [Contents.ENEMY, Contents.TREASURE]):
				branches_created += 1
				_branch_candidates.remove_at(i)
				continue  # Don't increment i, since we removed the current element
		# If not valid or branch failed, just move to next candidate
		i += 1

func _print_dungeon() -> void:
	var dungeon_as_string : String = ""
	for y in range(_dimensions.y -1, -1, -1):
		for x in _dimensions.x:
			if dungeon[x][y]:
				dungeon_as_string += "[" + str(dungeon[x][y]) + "]"
			else:
				dungeon_as_string += "   "
		dungeon_as_string += "\n"
	print(dungeon_as_string)

func _draw_dungeon() -> void:
	var room : Node2D
	for y in range(_dimensions.y - 1, -1, -1):
		for x in _dimensions.x:
			if dungeon[x][y]:
				room = _room_scene.instantiate()
				add_child(room)
				room.position = BOTTOM_LEFT_CORNER + Vector2(x, -y) * ROOM_SIZE
				for i in Doors.size():
					if dungeon[x][y] & Doors.values()[i]:
						room.add_door(i)
				for i in _room_icons.size():
					if dungeon[x][y] & Contents.values()[i]:
						room.set_icon(_room_icons[i])
						break

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return BOTTOM_LEFT_CORNER + Vector2(grid_pos.x, -grid_pos.y) * ROOM_SIZE
