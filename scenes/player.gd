extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

const SPEED := 300.0

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED
	_update_animation(direction)
	move_and_slide()


func _update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		animated_sprite.stop()
		return

	if absf(direction.x) > absf(direction.y):
		animated_sprite.play("right")
		animated_sprite.flip_h = direction.x < 0.0
		animated_sprite.flip_v = false
	else:
		animated_sprite.play("up")
		animated_sprite.flip_h = false
		animated_sprite.flip_v = direction.y > 0.0
