extends Node2D
class_name Bullet

@export var movement_curve: CurveTexture

var lifetime: float = 0.0

var speed: float = 400

func _physics_process(delta: float) -> void:
	global_position += movement_curve.curve.sample(lifetime) * Vector2(speed, 0).rotated(rotation) * delta
	lifetime += delta
	
	if Game.game.combo < 1:
		queue_free()
		return
	
	if(lifetime > 10):
		queue_free()
		return
	
	if(cursor_within_hitbox()):
		Game.game.combo = 0
		Game.game.ghost_jumpscare_sounds_player.play()
		queue_free()
	
func cursor_within_hitbox() -> bool:
	return global_position.distance_to(get_viewport().get_mouse_position()) < 12 * scale.x
