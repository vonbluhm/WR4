extends Area2D

var direction = Vector2.RIGHT
var speed = 600
var distance_traveled = 0
var angular_speed = PI / 64
var tiers = 5
var homing = false


func _ready():
	add_to_group("player_bullets")


func _physics_process(delta):
	if homing:
		pass#Adjust direction towards the nearby active enemy
	translate(direction * speed * delta)
	distance_traveled += speed * delta
	var level = ceili(distance_traveled / 50)
	if level >= tiers:
		destroy()
	else:
		scale = Vector2(level, level)


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
