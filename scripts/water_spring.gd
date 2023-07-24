extends Node2D

var velocity = 0
var force = 0
var height = 0
var target_height = 0
@onready var collision = $Area2D/CollisionShape2D
var index = 0
var motion_factor = 0.02
var body_collided_with = null
var area_collided_with = null
signal splash


func water_update(spring_constant, dampening):
	height = roundi(position.y)
	var x = height - target_height
	var loss = -dampening * velocity
	force = - spring_constant * x + loss
	velocity += force
	position.y += velocity


func set_collision_width(value):
	var size = collision.shape.get_size()
	var new_size = Vector2(value, size.y)
	collision.shape.set_size(new_size)


func initialize(x_position, id):
	add_to_group("water_springs")
	$Area2D.position = position
	height = position.y
	target_height = position.y
	velocity = 0
	position.x = x_position
	index = id


func _on_area_2d_body_entered(body):
	if body == body_collided_with:
		return
	else:
		body_collided_with = body
		if body.is_in_group("splashables"):
			var speed = body.velocity.y * motion_factor
			splash.emit(index, speed)



func _on_area_2d_area_entered(area):
	if area == area_collided_with:
		return
	else:
		area_collided_with = area
		var speed = 0
		if area.is_in_group("player_bullets") and area.is_in_group("Splashables"):
			speed = area.get_velocity().y * motion_factor
		elif area.is_in_group("water_springs") or area.is_in_group("water_bodies"):
			return
		splash.emit(index, speed)
	#if a projection glides through the spring, generate particles on the surface


func _on_area_2d_area_exited(area):
	if area == area_collided_with:
		area_collided_with = null


func _on_area_2d_body_exited(body):
	if body == body_collided_with:
		body_collided_with = null
