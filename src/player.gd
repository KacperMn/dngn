extends CharacterBody2D

const SPEED = 200.0

func _physics_process(delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * SPEED
	if direction != Vector2.ZERO:
		velocity = velocity.normalized() * SPEED
	move_and_slide()

func door_entered():
	print("Player entered a door!")
