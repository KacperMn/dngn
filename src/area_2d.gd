extends Area2D

@onready var game_manager = get_node("/root/game_manager") # Make sure the name matches your scene!

func _on_body_entered(body):
    body.door_entered()
