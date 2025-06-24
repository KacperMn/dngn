extends Node2D

@onready var level_manager = $level_manager
@onready var dungeon_generator = $dungeon_generator
@onready var player_scene = preload("res://src/player.tscn")
@onready var room_drawer = $room_drawer

@onready var dungeon
@onready var _dimensions
@onready var Doors
@onready var Contents

func _ready():
	_load_properties()
	dungeon_generator.generate()
	spawn_player(dungeon_generator._start)
	_print_dungeon()
	_draw_dungeon()
	
func _load_properties():
	dungeon_generator._dimensions = level_manager._dimensions
	dungeon_generator._start = level_manager._start
	dungeon_generator._critical_path_length = 3 + level_manager.level * 2
	dungeon_generator._branches = level_manager.level
	dungeon_generator._branch_length = Vector2i(2, 3)

func spawn_player(start_pos: Vector2i):
	var player = player_scene.instantiate()
	add_child(player)
	player.position = grid_to_world(start_pos)

func _print_dungeon() -> void:
	dungeon = dungeon_generator.dungeon
	_dimensions = dungeon_generator._dimensions
	print("Dungeon Layout:")
	var dungeon_as_string : String = ""
	for y in range(_dimensions.y -1, -1, -1):
		for x in _dimensions.x:
			if dungeon[x][y]:
				dungeon_as_string += "[" + str(dungeon[x][y]) + "]"
			else:
				dungeon_as_string += "   "
		dungeon_as_string += "\n"
	print(dungeon_as_string)

@export var _room_scene : PackedScene
@export var _room_icons : Array[Texture2D]
const BOTTOM_LEFT_CORNER: Vector2 = Vector2(320, 896)
const ROOM_SIZE: Vector2 = Vector2(160, 160)

func _draw_dungeon() -> void:
	dungeon = dungeon_generator.dungeon
	_dimensions = dungeon_generator._dimensions
	Doors = dungeon_generator.Doors
	Contents = dungeon_generator.Contents
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
