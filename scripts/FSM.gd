extends Node2D

enum AnimationStatus {
	STANDSTILL = 0,
	RUNNING_LEFT = 1,
	RUNNING_RIGHT = 2,
	JUMPING,
	FALLING,
}

enum MovementStatus{
	GROUND = 0,
	GLIDING = 1,
	FLIGHT = 2,
	BOUNCING = 3,
	SWIMMING = 4,
	RESURFACING = 5,
	SURFACED = 6,
	ROLLING = 7,
	WALL_ROLLING = 8,
	CHARGE_AHEAD = 9
}

enum ShieldScheme {
	BRIEF = 0,
	CONSTANT = 1
}

enum ElementalPower {
	NONE = 0,
	WATER = 1,
	AIR = 2,
	CRYSTAL = 3,
	FIRE = 4
}

enum OrbStatus{
	ON_HANDS = 0,
	THROWN = 1,
	EXPANDED = 2,
}

enum Facing{
	LEFT = -1,
	RIGHT = 1,
}

@export var mov_st = MovementStatus.GROUND
var last_mov_st = mov_st
var shield_sch = ShieldScheme.BRIEF
@export var elem_pwr = ElementalPower.AIR
@export var orb_st = OrbStatus.ON_HANDS
@export var elem_vicinity = ElementalPower.NONE

@onready var wall_rolling_condition = (elem_pwr == 3 and crystal_ability_level >= 1 and orb_st == 2)


var was_jump_pressed = false
var can_jump_after_walking_off = false
var set_to_bounce = false
var had_bounced = false
var set_to_flight = false
var just_switched = false
@export var constant_shield_unlocked = false
var constant_shield_disabled = false
@export var facing = Facing.RIGHT
var roll_facing = facing
var gliding_facing = facing
var dashing_facing = facing
@onready var character = get_parent()
var is_in_water = false
var on_surface = false
var coll_map
var resurface_flag = false
var gliding_flag = false
var dashing_flag = false
var default_recharge_rate = 2 #per second
var max_orb_power = 200
var orb_power = max_orb_power
var orb_power_change_rate = default_recharge_rate 
var brief_shield_energy_cost = 4
var constant_shield_consumption_rate = -4
var max_elemental_affinity = max_orb_power
var elemental_affinity = 200
var elemental_weardown = 2
var elemental_recharge = 100

@export var nonelem_ability_level = 0
@export var water_ability_level = 0
@export var air_ability_level = 0
@export var crystal_ability_level = 0
@export var fire_ability_level = 0

@export var nonelem_attack_level = 0
@export var water_attack_level = 0
@export var air_attack_level = 0
@export var crystal_attack_level = 0
@export var fire_attack_level = 0

func _physics_process(delta):
	facing = set_facing()
	update_movement_status()
	update_orb_power(delta)
	update_elemental_affinity(delta)

func update_movement_status():
	#Determines mov_st based on conditions
	if is_in_water:
		match elem_pwr:
			0:
				if mov_st != MovementStatus.SWIMMING:
					set_move_st(MovementStatus.SWIMMING)
			1:
				if water_ability_level >= 1:
					if resurface_flag:
						if mov_st == 0 or mov_st == 4:
							set_move_st(MovementStatus.RESURFACING)
						
					elif mov_st != MovementStatus.SWIMMING:
						set_move_st(MovementStatus.SWIMMING)
				elif mov_st != MovementStatus.SWIMMING:
					set_move_st(MovementStatus.SWIMMING)
			2:
				if mov_st != MovementStatus.SWIMMING:
					set_move_st(MovementStatus.SWIMMING)
					gliding_flag = false
			3:
				if is_on_ground() and Input.is_action_pressed("aim_down"):
					if Input.is_action_just_pressed("jump") and crystal_ability_level >= 1:
						set_move_st(MovementStatus.WALL_ROLLING)
				elif mov_st != MovementStatus.SWIMMING and mov_st != MovementStatus.WALL_ROLLING:
					set_move_st(MovementStatus.SWIMMING)
					
			4:
				if mov_st != MovementStatus.SWIMMING:
					set_move_st(MovementStatus.SWIMMING)
	elif not is_in_water:
		match elem_pwr:
			0:
				if mov_st != MovementStatus.GROUND:
					set_move_st(MovementStatus.GROUND)
			1:
				if resurface_flag:
					if not(mov_st == 0 or mov_st == 3 or mov_st == 6 or mov_st == 7):
						set_move_st(MovementStatus.SURFACED)
				elif not resurface_flag and (mov_st == 6 or mov_st == 7):
					set_move_st(MovementStatus.GROUND)
			2:
				if gliding_flag:
					set_move_st(MovementStatus.GLIDING)
				if set_to_flight:
					set_move_st(MovementStatus.FLIGHT)
			3:
				if is_on_ground() and Input.is_action_pressed("aim_down"):
					if Input.is_action_just_pressed("jump") and crystal_ability_level >= 1:
						set_move_st(MovementStatus.WALL_ROLLING)
			4:
				if fire_ability_level >= 1:
					if (is_on_ground() and Input.is_action_pressed("aim_down")):
						if Input.is_action_just_pressed("jump"):
							dashing_flag = true
				if dashing_flag:
					set_move_st(MovementStatus.CHARGE_AHEAD)
					dashing_facing = facing
					if $DashTimer.is_stopped():
						$DashTimer.start()
					
	if elem_pwr == 1 and water_ability_level >= 2:
		if set_to_bounce:
			if mov_st != MovementStatus.BOUNCING:
				last_mov_st = mov_st
				was_jump_pressed = true
				set_move_st(MovementStatus.BOUNCING)
		if is_on_ground() and not set_to_bounce and not is_in_water:
			set_move_st(MovementStatus.GROUND)
	if orb_st != 2:
		if resurface_flag:
			resurface_flag = false
		if is_in_water:
			set_move_st(MovementStatus.SWIMMING)
		else:
			set_move_st(MovementStatus.GROUND)
	match mov_st:
		MovementStatus.GLIDING:
			if is_on_ground() or on_surface or is_in_water or character.is_on_wall():
				gliding_flag = false
			if Input.is_action_just_pressed("jump"):
				gliding_flag = false
			if not gliding_flag:
				if not is_in_water:
					set_move_st(MovementStatus.GROUND)
				else:
					set_move_st(MovementStatus.SWIMMING)
		MovementStatus.FLIGHT:
			if Input.is_action_just_pressed("jump") and not just_switched:
				set_to_flight = false
				set_move_st(MovementStatus.GROUND)
			if gliding_flag:
				set_to_flight = false
				set_move_st(MovementStatus.GLIDING)
				gliding_facing = facing
		MovementStatus.BOUNCING:
			if on_surface and not set_to_bounce:
				set_move_st(last_mov_st)
		MovementStatus.SWIMMING:
			if not is_in_water:
				set_move_st(MovementStatus.GROUND)
		MovementStatus.SURFACED:
			if Input.is_action_just_pressed("jump"):
				if Input.is_action_pressed("aim_down"):
					set_move_st(MovementStatus.ROLLING)
					roll_facing = facing
			if is_on_ground() and not is_in_water:
				set_move_st(MovementStatus.GROUND)
		MovementStatus.ROLLING:
			if is_on_ground():
				set_move_st(MovementStatus.GROUND)
			if character.is_on_wall_only():
				set_move_st(MovementStatus.SURFACED)
		MovementStatus.WALL_ROLLING:
			if coll_map[0] and (coll_map[2] or coll_map[6]):
				set_move_st(MovementStatus.GROUND)
		MovementStatus.CHARGE_AHEAD:
			if not dashing_flag:
				set_move_st(MovementStatus.GROUND)
				
	just_switched = false
	

func set_move_st(new_status: MovementStatus):
	mov_st = new_status


func update_orb_power(delta):
	if orb_power <= max_orb_power:
		orb_power += orb_power_change_rate * delta
	elif orb_power > max_orb_power:
		orb_power = max_orb_power
	if orb_power <= 0:
		orb_power = 0


func update_elemental_affinity(delta):
	if elemental_affinity <= max_elemental_affinity:
		if elem_vicinity == elem_pwr and elem_vicinity != 0 and orb_st == 2:
			elemental_affinity += elemental_recharge * delta
		else:
			elemental_affinity -= elemental_weardown * delta
	if elemental_affinity > max_elemental_affinity:
		elemental_affinity = max_elemental_affinity
	elif elemental_affinity <= 0:
		elemental_affinity = 0
		elem_pwr = ElementalPower.NONE


func set_facing():
	#Reads the left to right input to determine facing
	var out = facing
	if sign(Input.get_axis("move_left", "move_right")) != 0:
		out = sign(Input.get_axis("move_left", "move_right"))
	
	return out


func set_orb_st(idx: OrbStatus):
	orb_st = idx


func set_orb_chngrt(new_rate):
	#Changes the rate of orb power change in units per second. Use negative
	#values to make the orb consume energy and positive values to make it
	#regain energy
	orb_power_change_rate = new_rate


func is_on_ground():
	var out = character.is_on_floor() or not $CoyoteTimer.is_stopped()
	if Input.is_action_just_pressed("jump") and not out:
		out = not $CoyoteTimer.is_stopped()
		was_jump_pressed = true
		can_jump_after_walking_off = false
	elif not Input.is_action_pressed("jump") and not Input.is_action_just_released("jump"):
		coyote_time()
		out = character.is_on_floor() or not $CoyoteTimer.is_stopped()
	if was_jump_pressed and character.is_on_floor() and not set_to_bounce:
		was_jump_pressed = false
		can_jump_after_walking_off = true
	return out


func coyote_time():
	if not character.is_on_floor() and not was_jump_pressed and can_jump_after_walking_off:
		if $CoyoteTimer.is_stopped():
			$CoyoteTimer.start()
	elif character.is_on_floor():
		$CoyoteTimer.stop()
		can_jump_after_walking_off = true


func _on_coyote_timer_timeout():
	can_jump_after_walking_off = false


func _on_bounce_timer_timeout():
	set_to_bounce = false


func _on_dash_timer_timeout():
	dashing_flag = false
