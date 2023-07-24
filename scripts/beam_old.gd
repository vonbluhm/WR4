extends Node2D

@onready var source = get_node("../..")

var bounces = 1

const MAX_LENGTH = 2000

@onready var line = $Line2D
var direction
var max_cast_to
var r
@onready var init_rotation = source.rotation

var segments = []

func _ready():
	segments.append($Segment)
	for i in range(bounces):
		var raycast = $Segment.duplicate()
		raycast.enabled = false
		add_child(raycast)
		segments.append(raycast)
	
	max_cast_to = round(MAX_LENGTH * direction)
	print(direction)
	print(max_cast_to)
	$Segment.global_position = source.global_position
	$Segment.target_position = max_cast_to
	
	$Line2D.top_level = true

func _physics_process(_delta):
	r = source.rotation - init_rotation
	line.clear_points()
	line.add_point(global_position)
	
	var idx = -1
	for raycast in segments:
		idx += 1
		if idx == 0:
			raycast.global_position = global_position
		var raycast_collision = raycast.get_collision_point()
		raycast.target_position = round(max_cast_to.rotated(r))
		
		if raycast.is_colliding():
			print("tarP ", raycast.target_position)
			print("GlP ", raycast.global_position)
			print(raycast_collision)
			print(raycast.get_collider())
			var collider = raycast.get_collider()
			line.add_point(raycast_collision)
			max_cast_to = max_cast_to.bounce(raycast.get_collision_normal())
			
			if idx < segments.size() - 1:
				segments[idx+1].enabled = true
				segments[idx+1].global_position = raycast_collision
			if idx == segments.size() - 1:
				$ContactPoint.global_position = raycast_collision
		else:
			line.add_point(global_position + max_cast_to.rotated(r))
			if idx == 0:
				raycast.target_position = max_cast_to.rotated(r)
				$ContactPoint.global_position = global_position + max_cast_to.rotated(r)
			else:
				$ContactPoint.global_position = raycast.global_position + max_cast_to.rotated(r)
	
	if not Input.is_action_pressed("fire"):
		queue_free()
