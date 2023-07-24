extends CharacterBody2D

var max_run_speed = 200
var run_accel = 800
var jump_force = -200
var max_fall_speed = 500
var gravity = 600
var surface_y = 0

@onready var FSM = $FSM
@onready var shielded_cs = $ShieldCS
@onready var brief_shield_scene = preload("res://scenes/brief_shield.tscn")
@onready var constant_shield_scene = preload("res://scenes/constant_shield.tscn")
@onready var orb_thrown_scene = preload("res://scenes/orb_thrown.tscn")
var double_jump = false
var shield

@onready var label_4 = 	$Camera2D/Control/Label4

func _ready():
	add_to_group("player_character")
	add_to_group("splashables")


func _physics_process(delta):
	#Apply gravity, listen to directional input, listen to action input
	velocity = get_char_velocity(delta)
	listen_to_shield_input()
	listen_to_fire_input()
	listen_to_ability_input()
	move_and_slide()
	$Camera2D/Control/Label.text = str(floor(FSM.orb_power))+"\n"+str(floor(FSM.elemental_affinity))
	$Camera2D/Control/Label2.text = str(FSM.on_surface)
	$Camera2D/Control/Label3.text = str(FSM.mov_st)+"\n"+str(FSM.is_on_ground())


func get_char_velocity(delta):
	#Calculates the character's horisontal and vertical velocity
	#based on user's input and activated abilities.
	#mov_st is determined in ./FSM
	var out: Vector2 = velocity
	match FSM.mov_st:
		0:
			out = regular_scheme(out, delta)
		1:
			out = gliding_scheme(out, delta)
		2:
			out = flight_scheme(out, delta)
		3:
			out = bounce_scheme(out, delta)
		4:
			out = swimming_scheme(out, delta)
		5:
			out = resurface_scheme(out, delta)
		6:
			out = surfaced_scheme(out, delta)
		7:
			out = srf_rolling_scheme(out, delta)
		8:
			out = wall_rolling_scheme(out, delta)
		9:
			out = dash_scheme(out, delta)
	
	return out


func regular_scheme(out: Vector2, delta: float):
	#Regular movement scheme, which is used by default
	var _x = sign(Input.get_axis("move_left", "move_right"))
	out.x = roundi(move_toward(out.x, _x * max_run_speed, run_accel * delta))
	out.y = apply_gravity(out.y, delta)
	out.y = listen_to_jump_input(out.y)
	
	return out


func swimming_scheme(out: Vector2, delta: float):
	var _x = sign(Input.get_axis("move_left", "move_right"))
	out.x = roundi(move_toward(out.x, _x * 0.5 * max_run_speed, 0.5 * run_accel * delta))
	if Input.is_action_just_pressed("jump") and not FSM.wall_rolling_condition and not Input.is_action_pressed("aim_down"):
		out.y = 1.5 * jump_force
	else:
		out.y = apply_gravity(out.y, delta)
	
	return out


func resurface_scheme(out: Vector2, delta: float):
	var _x = sign(Input.get_axis("move_left", "move_right"))
	out.x = roundi(move_toward(out.x, _x * max_run_speed, run_accel * delta))
	out.y = move_toward(out.y, -max_fall_speed, gravity * delta)
	return out


func surfaced_scheme(out: Vector2, delta: float):
	var _x = sign(Input.get_axis("move_left", "move_right"))
	out.x = roundi(move_toward(out.x, _x * max_run_speed, run_accel * delta))
	if not FSM.is_in_water:
		out.y = apply_gravity(out.y, delta)
	else:
		out.y = move_toward(out.y, -10, gravity * delta)
	if not (Input.is_action_pressed("aim_down") and Input.is_action_just_pressed("jump")):
		out.y = listen_to_jump_input(out.y)
	return out


func srf_rolling_scheme(out: Vector2, delta: float):
	var _x = sign(Input.get_axis("move_left", "move_right"))
	if FSM.on_surface:
		out.x = roundi(move_toward(out.x, FSM.roll_facing * max_run_speed, run_accel * delta))
	else:
		out.x = roundi(move_toward(out.x, (FSM.roll_facing + 0.5 * _x) * max_run_speed, run_accel * delta))
	out.y = listen_to_jump_input(out.y)
	if not FSM.is_in_water:
		out.y = apply_gravity(out.y, delta)
	else:
		out.y = move_toward(out.y, 0, gravity * delta)
	return out


func bounce_scheme(out: Vector2, delta: float):
	var _x = sign(Input.get_axis("move_left", "move_right"))
	match FSM.last_mov_st:
		0:
			out.x = roundi(move_toward(out.x, _x * max_run_speed, run_accel * delta))
		4:
			out.x = roundi(move_toward(out.x, _x * 0.5 * max_run_speed, 0.5 * run_accel * delta))
		6:
			out.x = roundi(move_toward(out.x, _x * 0.5 * max_run_speed, 0.5 * run_accel * delta))
		7:
			out.x = roundi(move_toward(out.x, (FSM.roll_facing + 0.5 * _x) * max_run_speed, run_accel * delta))
	if FSM.set_to_bounce and not FSM.had_bounced and $FSM/BounceTimer.is_stopped():
		out.y = 2 * max_fall_speed
		FSM.had_bounced = false
	else:
		out.y = apply_gravity(out.y, delta)
	if FSM.had_bounced:
		if $JumpHoldTimer.time_left > 0:
			if Input.is_action_pressed("jump"):
				out.y = 2 * jump_force
			else:
				$JumpHoldTimer.stop()
				FSM.had_bounced = false
		else:
			FSM.had_bounced = false
	elif not FSM.had_bounced:
		if not (FSM.is_on_ground() or FSM.on_surface):
			if Input.is_action_just_pressed("jump"):
				FSM.set_to_bounce = true
		elif FSM.is_on_ground() or FSM.on_surface:
			$FSM/BounceTimer.start()
			FSM.had_bounced = true
			out.y = 2 * jump_force
			$JumpHoldTimer.start()
	return out


func gliding_scheme(out: Vector2, delta: float):
	var _x = sign(Input.get_axis("move_left", "move_right"))
	out.x = roundi(move_toward(out.x, (FSM.gliding_facing + 0.5 * _x) * max_run_speed, run_accel * delta))
	out.y = roundi(move_toward(out.y, 50, gravity * delta))
	return out


func flight_scheme(out: Vector2, delta: float):
	var _x = sign(Input.get_axis("move_left", "move_right"))
	var _y = sign(Input.get_axis("aim_up", "aim_down"))
	out.x = roundi(move_toward(out.x, _x * max_run_speed, 0.5 * run_accel * delta))
	out.y = roundi(move_toward(out.y, _y * max_run_speed, 0.5 * run_accel * delta))
	return out


func wall_rolling_scheme(out: Vector2, delta: float):
	var col_map = FSM.coll_map
	if col_map[0]:
		out.x = roundi(move_toward(out.x, FSM.facing * 3 * max_run_speed, 1.5 * run_accel))
		
	elif col_map[1]:
		out.x = roundi(FSM.facing * 3 * max_run_speed / sqrt(2))
		out.y = roundi(FSM.facing * 3 * max_run_speed / sqrt(2))
	elif col_map[2]:
		out.y = roundi(FSM.facing * 3 * max_run_speed)
	elif col_map[4]:
		out.x = roundi(-FSM.facing * 3 * max_run_speed)
	elif col_map[5]:
		out.x = roundi(-FSM.facing * 3 * max_run_speed / sqrt(2))
		out.y = roundi(-FSM.facing * 3 * max_run_speed / sqrt(2))
	elif col_map[6]:
		out.y = roundi(-FSM.facing * 3 * max_run_speed)
		if col_map[5]:
			out.x = roundi(-FSM.facing * 3 * max_run_speed / sqrt(2))
			out.y = roundi(-FSM.facing * 3 * max_run_speed / sqrt(2))
		elif col_map[7]:
			out.x = roundi(FSM.facing * 3 * max_run_speed / sqrt(2))
			out.y = roundi(-FSM.facing * 3 * max_run_speed / sqrt(2))
	elif col_map[7]:
		out.x = roundi(FSM.facing * 3 * max_run_speed / sqrt(2))
		out.y = roundi(-FSM.facing * 3 * max_run_speed / sqrt(2))
	elif col_map.all(is_false):
		out.y = apply_gravity(out.y, delta)
	out.y = listen_to_jump_input(out.y)
	return out


func dash_scheme(out: Vector2, delta: float):
	out.x = 2 * max_run_speed * FSM.dashing_facing
	out.y = 0
	return out


func is_false(boolean):
	return not boolean

func set_surface_y(y):
	surface_y = y


func apply_gravity(y: float, delta):
	#Applies the downward component to the velocity
	y = move_toward(y, max_fall_speed, gravity * delta)
	
	return roundi(y)


func listen_to_jump_input(y: float):
	#Checks if the jump button is pressed and changes vertical velocity accordingly
	if $JumpHoldTimer.is_stopped() and Input.is_action_just_pressed("jump"):
		if (FSM.is_on_ground() or FSM.on_surface) and not FSM.wall_rolling_condition and not Input.is_action_pressed("aim_down"):
			double_jump = false
			y = jump_force
			$JumpHoldTimer.start()
		else:
			#Double jump logic goes here
			if FSM.elem_pwr == 1 and FSM.water_ability_level == 2:
				FSM.set_to_bounce = true
			elif FSM.elem_pwr == 2 and FSM.air_ability_level != 2:
				if not double_jump and FSM.orb_st == 2:
					y = jump_force
					$JumpHoldTimer.start()
					double_jump = true
			elif FSM.elem_pwr == 2 and FSM.air_ability_level == 2:
				FSM.set_to_flight = true
				FSM.just_switched = true
			elif FSM.elem_pwr == 4 and FSM.fire_ability_level >= 1:
				FSM.dashing_flag = true
				FSM.just_switched = true
	elif $JumpHoldTimer.time_left > 0:
		if Input.is_action_pressed("jump"):
			y = jump_force
		else:
			$JumpHoldTimer.stop()
			FSM.set_to_bounce = false
	return roundi(y)


func listen_to_shield_input():
	match FSM.shield_sch:
		FSM.ShieldScheme.BRIEF:
			if Input.is_action_just_pressed("shield") and FSM.orb_st == 0:
				if (not FSM.constant_shield_unlocked or FSM.constant_shield_disabled):
					spawn_brief_shield()
				else:
					toggle_constant_shield()
		FSM.ShieldScheme.CONSTANT:
			if Input.is_action_just_pressed("shield"):
				toggle_constant_shield()


func spawn_brief_shield():
	#Spawns a shield around the character that only lasts for a few frames
	var instance = brief_shield_scene.instantiate()
	instance.connect("set_orb_st", FSM.set_orb_st)
	FSM.orb_power -= FSM.brief_shield_energy_cost
	add_child(instance)


func toggle_constant_shield():
	#Toggles the constant shield on and off
	if get_node_or_null("./Shield") == null:
		var instance = constant_shield_scene.instantiate()
		instance.connect("set_orb_st", FSM.set_orb_st)
		if FSM.elem_vicinity != 0:
			FSM.elem_pwr = FSM.elem_vicinity
		FSM.shield_sch = 1
		FSM.set_orb_chngrt(FSM.constant_shield_consumption_rate)
		if FSM.elem_pwr == 3:
			$ShieldCS.set_deferred("disabled", false)
			instance.position.y = -22
		add_child(instance)
		shield = get_node("./Shield")


func extinguish():
	FSM.elemental_affinity = 0
	shield.disengage()


func listen_to_fire_input():
	if Input.is_action_just_pressed("fire"):
		orient_fire_source()
		if FSM.orb_st == 0:
			#Throw the orb
			var instance = orb_thrown_scene.instantiate()
			instance.connect("set_orb_st", FSM.set_orb_st)
			instance.direction = ($FireSourceRing/Source.global_position - global_position).normalized()
			instance.global_position = $FireSourceRing/Source.global_position
			get_tree().get_root().add_child(instance)


func orient_fire_source():
	#Determines the rotation of the fire source ring
	var x = Input.get_axis("move_left", "move_right")
	var y = Input.get_axis("aim_up", "aim_down")
	if x == 0:
		if y < 0:
			$FireSourceRing.rotation = -0.5 * PI
		else:
			$FireSourceRing.rotation = acos(FSM.facing)
	elif x != 0:
		if y < 0:
			$FireSourceRing.rotation = (-0.5 + 0.25 * sign(x)) * PI 
		else:
			$FireSourceRing.rotation = acos(sign(x))


func listen_to_ability_input():
	if Input.is_action_just_pressed("toggle_ability") and FSM.orb_st == 2:
		match FSM.elem_pwr:
			1:
				FSM.resurface_flag = not FSM.resurface_flag
			2:
				if not (FSM.is_on_ground() or FSM.on_surface or FSM.is_in_water):
					FSM.gliding_flag = not FSM.gliding_flag
					if FSM.gliding_flag:
						FSM.gliding_facing = FSM.facing
