extends Node2D

@export var _x = 0
@export var _y = 0
@export var k = 0.015
@export var d = 0.03
var spread = 0.0002
var springs = []
var passes = 8
@export var distance_between_springs = 32
@export var spring_number = 0
@export var depth = 20
var water_length = distance_between_springs * spring_number

@onready var water_spring = preload("res://scenes/water_spring.tscn")

var target_height = global_position.y
@onready var bottom = target_height + depth

@onready var water_polygon = $WaterPolygon
@onready var water_border = $WaterBorder
@export var border_thickness = 1.1
@onready var collision_shape = $WaterBodyArea/CollisionShape2D
@onready var water_body_area = $WaterBodyArea


func _ready():
	global_position = Vector2(_x, _y)
	add_to_group("water_bodies")
	water_border.width = border_thickness
	for i in range(spring_number):
		var x_position = distance_between_springs * i
		var w = water_spring.instantiate()
		add_child(w)
		springs.append(w)
		w.initialize(x_position, i)
		w.set_collision_width(distance_between_springs)
		w.connect("splash", splash)
	var total_length = distance_between_springs * (spring_number - 1)
	var rectangle = RectangleShape2D.new().duplicate()
	var pos = Vector2(total_length * 0.5, depth * 0.5)
	var rect_size = Vector2(total_length, depth)
	water_body_area.position = pos
	rectangle.set_size(rect_size)
	collision_shape.set_shape(rectangle)

	


func _physics_process(_delta):
	for i in springs:
		i.water_update(k, d)
	var left_deltas = []
	var right_deltas = []
	for i in range(springs.size()):
		left_deltas.append(0)
		right_deltas.append(0)
	for j in range(passes):
		for i in range(springs.size()):
			if i > 0:
				left_deltas[i] = spread * (springs[i].height - springs[i-1].height)
				springs[i-1].velocity += left_deltas[i]
			if i < springs.size() - 1:
				right_deltas[i] = spread * (springs[i].height - springs[i+1].height)
				springs[i+1].velocity += right_deltas[i]
	new_border()
	draw_water_body()


func draw_water_body():
	var curve = water_border.curve
	var points = Array(curve.get_baked_points())
	var water_polygon_points = points
	var first_index = 0
	var last_index = water_polygon_points.size() - 1
	water_polygon_points.append(Vector2(water_polygon_points[last_index].x, bottom))
	water_polygon_points.append(Vector2(water_polygon_points[first_index].x, bottom))
	water_polygon_points = PackedVector2Array(water_polygon_points)
	water_polygon.set_polygon(water_polygon_points)


func new_border():
	var curve = Curve2D.new().duplicate()
	var surface_points = []
	for i in range(springs.size()):
		surface_points.append(springs[i].position)
	for i in range(surface_points.size()):
		curve.add_point(surface_points[i])
	water_border.curve = curve
	water_border.smooth(true)
	water_border.queue_redraw()


func splash(index, speed):
	if index >= 0 and index < springs.size():
		springs[index].velocity += speed
	


func _on_water_body_area_body_entered(body):
	if body.is_in_group("player_character"):
		body.FSM.is_in_water = true
		if body.FSM.resurface_flag:
			body.FSM.on_surface = true
			body.velocity.y = body.velocity.y * 0.1
		body.set_surface_y(global_position.y)
		if body.FSM.orb_st == 2 and body.FSM.elem_pwr == 4:
			body.extinguish()


func _on_water_body_area_body_exited(body):
	if body.is_in_group("player_character"):
		body.FSM.is_in_water = false
		if body.FSM.resurface_flag:
			if not Input.is_action_pressed("jump") and body.FSM.mov_st != 3:
				body.FSM.on_surface = true
			else:
				body.FSM.on_surface = false
			if body.velocity.y < 0 and not Input.is_action_pressed("jump"):
				if body.FSM.mov_st != 3:
					body.velocity.y = 0
