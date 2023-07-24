extends Area2D

var direction = Vector2.RIGHT
var speed = 600
var distance = 0
var is_in_water = false
var knocks_back = false


func _ready():
	add_to_group("player_bullets")
	add_to_group("water_bullets")
	add_to_group("Splashables")


func _physics_process(delta):
	print(is_in_water)
	if not is_in_water:
		direction.y = move_toward(direction.y, 200, 2 * delta)
	translate(direction * speed * delta)
	distance += speed * delta


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
		if area.is_in_group("water_bodies"):
			is_in_water = true
		else:
			destroy()


func _on_area_exited(area):
	if area.is_in_group("water_bodies"):
		is_in_water = false


func _on_body_entered(body):
	if not body.is_in_group("player_bullets"):
		destroy()

