extends Node2D

@onready var level_manager = $level_manager
@onready var dungeon_generator = $dungeon_generator

func _ready():
	_load_properties()
	dungeon_generator.generate()

	# Spawn player at entrance (implement spawn_player method)
	#spawn_player(dungeon_generator._start)

func _load_properties():
	dungeon_generator._dimensions = level_manager._dimensions
	dungeon_generator._start = level_manager._start
	dungeon_generator._critical_path_length = 3 + level_manager.level * 2
	dungeon_generator._branches = level_manager.level
	dungeon_generator._branch_length = Vector2i(2, 3)

func spawn_player(start_pos: Vector2i):
	var player_scene = preload("res://src/player.tscn")
	var player = player_scene.instantiate()
	add_child(player)
	# Convert grid position to world position as needed
	player.position = dungeon_generator.grid_to_world(start_pos)
	# Optionally, connect a signal from player to game_manager for room tracking

# Example for tracking rooms (to be expanded)
var visited_rooms = {}

func on_player_enter_room(room_pos: Vector2i):
	visited_rooms[room_pos] = true
	dungeon_generator.draw_room(room_pos) # Only draw the current room
