extends Area2D

@onready var character = get_parent()
@onready var FSM = character.FSM
@onready var bullet_nonelem_scene = preload("res://scenes/bullet_non_elem.tscn")
@onready var bullet_water_scene = preload("res://scenes/water_bullet.tscn")
@onready var bullet_water_big_scene = preload("res://scenes/water_bullet_big.tscn")
@onready var bullet_air_scene = preload("res://scenes/bullet_air.tscn")
@onready var beam_scene = preload("res://scenes/beam.tscn")
@onready var bullet_fire_exp_scene = preload("res://scenes/bullet_fire_expanding.tscn")
var last_pos = null
signal set_orb_st
var collision_map = []

func _ready():
	if FSM.elem_pwr == 0:
		$AnimatedSprite2D.play("default")
	set_orb_st.emit(2)
	add_to_group("splashables")

func _physics_process(_delta):
	animation()
	listen_to_fire_input()
	listen_to_disengagement_conditions()
	listen_to_element_change()
	collision_map = scan_collisions()
	FSM.coll_map = collision_map
	character.label_4.text = str(collision_map)
	
	

func animation():
	match FSM.elem_pwr:
		0:
			$AnimatedSprite2D.stop()
			$AnimatedSprite2D.play("default")
		1:
			$AnimatedSprite2D.stop()
			$AnimatedSprite2D.play("water")
		2:
			$AnimatedSprite2D.stop()
			$AnimatedSprite2D.play("air")
		3:
			$AnimatedSprite2D.stop()
			$AnimatedSprite2D.play("crystal")
		4:
			$AnimatedSprite2D.stop()
			$AnimatedSprite2D.play("fire")


func listen_to_disengagement_conditions():
	if FSM.elem_vicinity == 0:
		if Input.is_action_just_pressed("shield"):
			disengage()
	else:
		if Input.is_action_just_pressed("shield"):
			$ShieldButtonHoldTimer.start()
		if Input.is_action_just_released("shield"):
			if not $ShieldButtonHoldTimer.is_stopped():
				$ShieldButtonHoldTimer.stop()
				disengage()
	if FSM.orb_power <= 0:
		FSM.elemental_affinity = 0
		disengage()


func disengage():
	set_orb_st.emit(0)
	FSM.shield_sch = 0
	FSM.set_orb_chngrt(FSM.default_recharge_rate)
	position = Vector2.ZERO
	character.shielded_cs.set_deferred("disabled", true)
	queue_free()


func listen_to_element_change():
	if FSM.elem_pwr != 0:
		#Switch to another shield
		match FSM.elem_pwr:
			1:
				#Instantiate the water shield
				pass
			2:
				pass
			3:
				pass
			4:
				pass
		

func destroy():
	#Destroys the shield. Called after receiving damage
	disengage()


func listen_to_fire_input():
	orient_fire_source()
	if Input.is_action_pressed("fire"):
		match FSM.elem_pwr:
			0:
				var instance = bullet_nonelem_scene.instantiate()
				instance.direction = ($FireSourceRing/Source.global_position - global_position).normalized()
				instance.global_position = $FireSourceRing/Source.global_position
				if $BulletTimer.is_stopped():
					$BulletTimer.start()
					get_tree().get_root().add_child(instance)
			1:
				var instance = bullet_water_big_scene.instantiate()
				if FSM.water_attack_level == 0:
					instance = bullet_water_scene.instantiate()
				instance.direction = ($FireSourceRing/Source.global_position - global_position).normalized()
				instance.global_position = $FireSourceRing/Source.global_position
				if $BulletTimer.is_stopped():
					$BulletTimer.start()
					get_tree().get_root().add_child(instance)
			2:
				var instance = bullet_air_scene.instantiate()
				instance.direction = ($FireSourceRing/Source.global_position - global_position).normalized()
				if FSM.air_attack_level == 0:
					if Input.is_action_just_pressed("fire"):
						last_pos = null
					if $BulletTimer.is_stopped():
						var pos_selected = false
						while not pos_selected:
							var pos = randi() % 3
							if pos != last_pos:
								pos_selected = true
								last_pos = pos
								match pos:
									0:
										instance.global_position = $FireSourceRing/Source.global_position
									1:
										instance.global_position = $FireSourceRing/Source2.global_position
									2:
										instance.global_position = $FireSourceRing/Source3.global_position
						$BulletTimer.start()
						get_tree().get_root().add_child(instance)
				else:
					var number_of_bullets = 3 if FSM.air_attack_level == 1 else 6
					if $BulletTimer.is_stopped():
						var instances = []
						for idx in range(number_of_bullets):
							instances.append(bullet_air_scene.instantiate())
							get_tree().get_root().add_child(instances[idx])
							if idx < 3:
								instances[idx].direction = ($FireSourceRing/Source.global_position - global_position).normalized()
							else:
								instances[idx].direction = ($FireSourceRing/Source4.global_position - global_position).normalized()
							match idx:
								0:
									instances[idx].global_position = $FireSourceRing/Source.global_position
								1:
									instances[idx].global_position = $FireSourceRing/Source2.global_position
								2:
									instances[idx].global_position = $FireSourceRing/Source3.global_position
								3:
									instances[idx].global_position = $FireSourceRing/Source4.global_position
								4:
									instances[idx].global_position = $FireSourceRing/Source5.global_position
								5:
									instances[idx].global_position = $FireSourceRing/Source6.global_position
						$BulletTimer.start()
			3:
				if FSM.crystal_attack_level >= 1:
					var instance = beam_scene.instantiate()
					instance.direction = ($FireSourceRing/Source.global_position - global_position).normalized()
					match FSM.crystal_attack_level:
						1:
							instance.bounces = 1
						2:
							instance.bounces = 2
					if $FireSourceRing/Source.get_child_count() == 0:
						print("ring_rotation ", $FireSourceRing.rotation)
						$FireSourceRing/Source.add_child(instance)
			4:
				var instance = bullet_fire_exp_scene.instantiate()
				instance.direction = ($FireSourceRing/Source.global_position - global_position).normalized()
				instance.global_position = $FireSourceRing/Source.global_position
				if FSM.fire_attack_level >= 1:
					instance.tiers = 10
				if FSM.fire_attack_level == 2:
					instance.homing = true
				if $BulletTimer.is_stopped():
					$BulletTimer.start()
					get_tree().get_root().add_child(instance)


func orient_fire_source():
	#Determines the rotation of the fire source ring
	var x = Input.get_axis("move_left", "move_right")
	var y = Input.get_axis("aim_up", "aim_down")
	var target_angle
	var angular = PI/32
	if x == 0:
		if y < 0:
			target_angle = -0.5 * PI
		elif y > 0:
			target_angle = 0.5 * PI
		else:
			target_angle = acos(FSM.facing)
	elif x != 0:
		if y < 0:
			target_angle = (-0.5 + 0.25 * sign(x)) * PI 
		elif y > 0:
			target_angle = (0.5 - 0.25 * sign(x)) * PI 
		else:
			target_angle = acos(sign(x))
	
	if Input.is_action_just_pressed("fire"):
		$FireSourceRing.rotation = target_angle
	if abs($FireSourceRing.rotation - target_angle) > 2 * PI/3:
		if abs($FireSourceRing.rotation + TAU - target_angle) > 2 * PI/3:
			if abs($FireSourceRing.rotation - TAU - target_angle) > 2 * PI/3:
				$FireSourceRing.rotation = target_angle
			else:
				$FireSourceRing.rotation = $FireSourceRing.rotation - TAU
		else:
			$FireSourceRing.rotation = $FireSourceRing.rotation + TAU
	$FireSourceRing.rotation = move_toward($FireSourceRing.rotation, target_angle,  angular)
	


func scan_collisions():
	var out = []
	out.append($D.get_collider() != null)
	out.append($DL.get_collider() != null)
	out.append($L.get_collider() != null)
	out.append($UL.get_collider() != null)
	out.append($U.get_collider() != null)
	out.append($UR.get_collider() != null)
	out.append($R.get_collider() != null)
	out.append($DR.get_collider() != null)
	return out


func _on_shield_button_hold_timer_timeout():
	if FSM.elem_vicinity != 0:
		FSM.elem_pwr = FSM.elem_vicinity
		if FSM.elem_vicinity == 3:
			position.y = -22
			character.shielded_cs.set_deferred("disabled", false)
		else:
			position.y = 0
			character.shielded_cs.set_deferred("disabled", true)
