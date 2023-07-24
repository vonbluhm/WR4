extends Area2D

var direction = Vector2.RIGHT
var speed = 600


func _ready():
	add_to_group("player_bullets")
	add_to_group("Splashables")


func _physics_process(delta):
	translate(direction * speed * delta)


func get_velocity():
	return Vector2(direction.x * speed, direction.y * speed)


func destroy():
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited():
	$LeftScreenTimer.start()


func _on_left_screen_timer_timeout():
	queue_free()


func _on_area_entered(area):
	if not area.is_in_group("player_bullets"):
		destroy()
