extends Node2D
class_name Bullet

@export var movement_curve: CurveTexture

var lifetime: float = 0.0

var speed: float = 400

func _physics_process(delta: float) -> void:
	global_position += movement_curve.curve.sample(lifetime) * Vector2(speed, 0).rotated(rotation) * delta
	lifetime += delta
	
	if(lifetime > 10):
		queue_free()
		return
	
	if(cursor_within_hitbox()):
		Game.game.combo = 0
		queue_free()
	
func cursor_within_hitbox() -> bool:
	return global_position.distance_to(get_viewport().get_mouse_position()) < 16 * scale.x
