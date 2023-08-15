extends KinematicBody2D

export var default_job: int = C.JOB_NONE
export var fixed_pitch_shift: float = -1

signal picked_up_match
signal started_a_fire
signal finished_fighting_the_fire
signal lost_match
signal bun_starving

onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var current_direction_name = "down"

var max_speed_walk = 20
var max_speed_run = 35

var direction = Vector2.DOWN
var speed = 0
var velocity = Vector2.ZERO
var is_navigating = false
var mood = C.MOOD_OK
var has_match = false
var has_to_fight_fire = false

# for some variation in sounds
var pitch_shift = 1.0

# --- job ---
var job = C.JOB_NONE
var task = C.TASK_IDLING
var job_override = C.JOB_NO_CHANGE
var farmer_water_held = 0
var farmer_crops_held = 0
var lumberjack_wood_held = 0
var firefighter_water_amount = 0

# when changing jobs...
var new_job = C.JOB_NO_CHANGE

var target_reached = false
var target_object: Node2D = null
var secondary_object: Node2D = null
var task_steps_left = 0
var task_animation_name = "idle"

# [ [ time needed to finish, animation name ], ... ]
var task_definitions = [
	[ 0, "idle" ],     # TASK_IDLING
	[ 3, "working" ],  # TASK_COLLECTING
	[ 0, "working" ],  # TASK_DROPPING_OFF
	[ 5, "hacking" ],  # TASK_SEEDING
	[ 3, "working" ],  # TASK_WATERING_1
	[ 3, "watering" ], # TASK_WATERING_2
	[ 3, "chopping" ], # TASK_CHOPPING_TREE
	[ 8, "sleeping" ], # TASK_SLEEPING
	[ 3, "eating" ],   # TASK_EATING
	[ 6, "starting_fire" ], # TASK_STARTING_THE_FIRE
	[ 3, "idle" ],          # TASK_FLEE
	[ 1, "working" ],       # TASK_FIREFIGHTER_1
	[ 1, "fighting_fire" ], # TASK_FIREFIGHTER_2
]

# --- needs ---
var tiredness = 0
var hunger = 0

var tiredness_increase = 0.006
var hunger_increase = 0.0074

func _ready():
	$AnimatedSprite.play("idle")
	nav_agent.max_speed = 100
	nav_agent.radius = 15
	nav_agent.avoidance_enabled = true
	
	job = default_job
	
	randomize_stats()
	
	# start_carry_container_animations()
	update_carry_container()

func randomize_stats():
	tiredness = randf() * 0.2
	hunger = randf() * 0.2
	
	if fixed_pitch_shift == -1:
		pitch_shift = 1.0 + (randf() - 0.5) * 0.6
	else:
		pitch_shift = fixed_pitch_shift
	
	$ThinkStartTimer.wait_time = randf()
	$ThinkStartTimer.start()

func start_carry_container_animations():
	for obj in $CarryContainer.get_children():
		if not obj is AnimatedSprite:
			continue
		
		obj.play("default")

func update_direction_name():
	if direction.x < -0.5:
		current_direction_name = "left"
	elif direction.x > 0.5:
		current_direction_name = "right"
	elif direction.y < -0.5:
		current_direction_name = "up"
	else:
		current_direction_name = "down"

func update_velocity():
	velocity = direction * speed

func update_animation():
	var animation_base_name = "idle"
	var a
	var animations_with_no_direction = [ "idle", "sleeping", "eating", "starting_fire" ]
	
	if task == C.TASK_SLEEPING or task == C.TASK_EATING:
		animation_base_name = task_animation_name
	elif target_reached and task_steps_left > 0:
		animation_base_name = task_animation_name
	else:
		if abs(velocity.x) > 0.1 or abs(velocity.y) > 0.1:
			animation_base_name = "walk"
		else:
			animation_base_name = "idle"
	
	if animation_base_name in animations_with_no_direction:
		a = animation_base_name
	else:
		a = animation_base_name + "_" + current_direction_name
	
	if $AnimatedSprite.animation != a:
		$AnimatedSprite.play(a)

func update_position():
	velocity = move_and_slide(velocity)

func update_bun_dot():
	var bun_pos = self.global_position
	var camera_pos = Lib.get_camera().global_position
	var dot_pos = camera_pos
	var width = 58
	var height = 58
	
	# the lame an brute force approach instead of knowing the proper math
	var direction = camera_pos.direction_to(self.global_position + Vector2(0, -6)).normalized()
	
	for i in range(0, 200):
		dot_pos += direction
		
		if dot_pos.x > camera_pos.x + width / 2:
			dot_pos.x = camera_pos.x + width / 2
			break
			
		if dot_pos.x < camera_pos.x - width / 2:
			dot_pos.x = camera_pos.x - width / 2
			break
			
		if dot_pos.y > camera_pos.y + height / 2:
			dot_pos.y = camera_pos.y + height / 2
			break
			
		if dot_pos.y < camera_pos.y - height / 2:
			dot_pos.y = camera_pos.y - height / 2
			break
	
	if bun_pos.x > camera_pos.x - 28 and bun_pos.x < camera_pos.x + 28 and bun_pos.y > camera_pos.y - 28 and bun_pos.y < camera_pos.y + 28:
		$BunDot.visible = false
	else:
		$BunDot.visible = true
	
	$BunDot.global_position = dot_pos

func _process(_delta):
	if GameState.is_paused():
		return
	
	update_velocity()
	update_direction_name()
	update_animation()
	update_position()
	update_bun_dot()

func _physics_process(_delta):
	var next
	
	if is_navigating:
		if Lib.is_object_valid(target_object):
			if Lib.dist_2d(self.global_position, target_object.global_position) < C.OBJECT_REACHED_DISTANCE:
				arrived_to_target()
			else:
				# print("navigating...")
				next = nav_agent.get_next_location()
				direction = (next - self.global_position).normalized()
				
				if task == C.TASK_FLEE or task == C.TASK_FIREFIGHTER_1 or task == C.TASK_FIREFIGHTER_2:
					speed = max_speed_run
				else:
					speed = max_speed_walk
	else:
		speed = 0
	
	# if not next:
	# 	direction = Vector2.DOWN
	# 	speed = 0

# --- job and task related functions ---

func get_plants_with_state(state_min: int, state_max: int):
	var objs = []
	var min_generation = 99999999
	
	# we should priorize plants already growing before ones that need seeding
	for obj in get_tree().get_nodes_in_group("plant"):
		if not Lib.is_object_valid(obj):
			continue
		
		if obj.is_in_group("claimed"):
			continue
		
		if obj.get_generation() < min_generation:
			min_generation = obj.get_generation()
	
	for obj in get_tree().get_nodes_in_group("plant"):
		if not Lib.is_object_valid(obj):
			continue
		
		if obj.is_in_group("claimed"):
			continue
		
		if obj.get_generation() > min_generation:
			continue
		
		if not (obj.get_state() >= state_min and obj.get_state() <= state_max):
			continue
		
		if obj.get_was_recently_handled():
			continue
		
		objs.append(obj)
	
	return objs

func get_trees_with_state(state_min: int, state_max: int):
	var objs = []
	
	for obj in get_tree().get_nodes_in_group("tree"):
		if not Lib.is_object_valid(obj):
			continue
		
		if obj.is_in_group("claimed"):
			continue
		
		if not (obj.get_state() >= state_min and obj.get_state() <= state_max):
			continue
		
		objs.append(obj)
	
	return objs

func show_and_play_animation(obj: AnimatedSprite, animation: String):
	if not Lib.is_object_valid(obj):
		return
	
	if obj.animation != animation or not obj.playing:
		obj.play(animation)
	
	obj.show()

func update_carry_container():
	for obj in $CarryContainer.get_children():
		obj.hide()
	
	if has_match:
		show_and_play_animation($CarryContainer/Match, "default")
	elif has_to_fight_fire:
		if firefighter_water_amount == 0:
			$CarryContainer/FirefighterWaterEmpty.show()
		else:
			$CarryContainer/FirefighterWaterFull.show()
	elif task == C.TASK_SLEEPING:
		show_and_play_animation($CarryContainer/Sleeping, "default")
	elif task == C.TASK_EATING:
		show_and_play_animation($CarryContainer/Eating, "default")
	elif mood == C.MOOD_TIRED:
		$CarryContainer/Tired.show()
	elif mood == C.MOOD_HUNGRY:
		$CarryContainer/Hungry.show()
	elif farmer_crops_held > 0:
		$CarryContainer/Tomato.show()
	elif farmer_water_held > 0:
		$CarryContainer/Water.show()
	elif lumberjack_wood_held > 0:
		$CarryContainer/Wood.show()
	elif job != C.JOB_NONE and task == C.TASK_IDLING:
		show_and_play_animation($CarryContainer/Thinking, "default")

func arrived_to_target():
	print("arrived_to_target()")
	
	is_navigating = false
	target_reached = true
	think()

func set_task(new_task: int, obj: Node2D = null, claim: bool = false, secondary_obj: Node2D = null, secondary_claim: bool = false):
	print("set_task() ", [ new_task, obj, claim ])
	
	if Lib.is_object_valid(target_object):
		Lib.unclaim_object(target_object)
		
	if Lib.is_object_valid(secondary_object):
		Lib.unclaim_object(secondary_object)
	
	task = new_task
	target_object = obj
	secondary_object = secondary_obj
	target_reached = false
	is_navigating = false
	task_steps_left = task_definitions[task][0]
	task_animation_name = task_definitions[task][1]
	
	if claim:
		Lib.claim_object(target_object)
	
	if secondary_claim:
		Lib.claim_object(secondary_object)

func swap_task_objects(new_task):
	task = new_task
	
	var tmp = target_object
	target_object = secondary_object
	secondary_object = tmp
	target_reached = false
	is_navigating = false

# decreases the steps left in the task and returns true if finished,
# false otherwise
func do_task_and_is_finished():
	print("do_task_and_is_finished() task: ", task, ", steps left: ", task_steps_left)
	if task_steps_left > 0:
		task_steps_left -= 1
	
	if task_steps_left == 0:
		return true
	
	return false

func do_drop_off_goods():
	if farmer_crops_held > 0:
		target_object.goods_in(Lib.GOOD_CROP, farmer_crops_held)
		farmer_crops_held = 0
	
	if lumberjack_wood_held > 0:
		target_object.goods_in(Lib.GOOD_WOOD, lumberjack_wood_held)
		lumberjack_wood_held = 0
	
	set_task(C.TASK_IDLING)

func pick_up_match():
	has_match = true
	
	emit_signal("picked_up_match")

func take_away_match():
	has_match = false
	set_task(C.TASK_IDLING)
	
	emit_signal("lost_match")

func fight_the_fire():
	if has_match:
		# oh no...
		return
	
	has_to_fight_fire = true
	
	# stop whatever this bun is doing
	abort_current_task()

func finished_fighting_the_fire():
	has_to_fight_fire = false
	firefighter_water_amount = 0
	
	emit_signal("finished_fighting_the_fire")
	
	# stop whatever this bun is doing
	abort_current_task()

func set_new_job(job2):
	new_job = job2
	
	if job == new_job:
		new_job = C.JOB_NO_CHANGE

func start_new_job_if_any():
	if new_job == C.JOB_NO_CHANGE:
		return
	
	job = new_job
	new_job = C.JOB_NO_CHANGE

func abort_current_task():
	set_task(C.TASK_IDLING)

func update_job_override():
	if has_match:
		job_override = C.JOB_FIRESTARTER
	elif has_to_fight_fire:
		job_override = C.JOB_FIREFIGHTER
	elif mood == C.MOOD_TIRED:
		job_override = C.JOB_SLEEPER
	elif mood == C.MOOD_HUNGRY:
		job_override = C.JOB_EATER
	else:
		job_override = C.JOB_NO_CHANGE

func update_mood():
	if tiredness >= 0.75:
		mood = C.MOOD_TIRED
	elif hunger >= 0.75:
		mood = C.MOOD_HUNGRY
	else:
		mood = C.MOOD_OK

func increase_needs():
	tiredness += tiredness_increase
	hunger += hunger_increase
	
	print("tiredness: ", tiredness, ", hunger: ", hunger)

func think_firestarter():
	var obj
	
	if task == C.TASK_IDLING:
		var objs = []
		
		# find all fully grown trees, not on fire
		for obj2 in get_trees_with_state(0, 0):
			if obj2.is_on_fire:
				continue
			
			objs.append(obj2)
		
		if objs.size() > 0:
			# # pick the nearest one
			# obj = Lib.get_nearest_object_from_list(self, objs)
			
			# pick a random one
			obj = Lib.array_pick(objs)
			
			if obj:
				set_task(C.TASK_STARTING_THE_FIRE, obj, true)
	
	elif task == C.TASK_STARTING_THE_FIRE:
		if target_reached:
			if do_task_and_is_finished():
				if Lib.is_object_valid(target_object):
					target_object.light_on_fire()
					has_match = false
					
					emit_signal("started_a_fire")
					emit_signal("lost_match")
					
					obj = Lib.get_nearest_object_in_group(self, "safe_spot", false)
					
					if obj:
						set_task(C.TASK_FLEE, obj, false)
	
	elif task == C.TASK_FLEE:
		if target_reached:
			if do_task_and_is_finished():
				set_task(C.TASK_IDLING)

func think_firefighter():
	var obj
	
	if not Lib.has_any_flames():
		finished_fighting_the_fire()
		return
	
	if task == C.TASK_IDLING:
		if firefighter_water_amount > 0:
			obj = Lib.get_nearest_object_in_group(self, "flame", false)
			set_task(C.TASK_FIREFIGHTER_2, obj, false)
		else:
			obj = Lib.get_nearest_object_in_group(self, "firefighter_water_spot", true)
			set_task(C.TASK_FIREFIGHTER_1, obj, true)
	
	elif task == C.TASK_FIREFIGHTER_1:
		if target_reached:
			if do_task_and_is_finished():
				firefighter_water_amount += 1
				set_task(C.TASK_IDLING)
	
	elif task == C.TASK_FIREFIGHTER_2:
		if target_reached:
			if do_task_and_is_finished():
				if Lib.is_object_valid(target_object):
					target_object.shrink()
					firefighter_water_amount = 0
				
				set_task(C.TASK_IDLING)

func think_sleeper():
	if task == C.TASK_IDLING:
		set_task(C.TASK_SLEEPING)
	
	elif task == C.TASK_SLEEPING:
		if do_task_and_is_finished():
			tiredness = 0
			update_mood()
			set_task(C.TASK_IDLING)

func think_eater():
	var obj
	
	if task == C.TASK_IDLING:
		obj = Lib.get_nearest_object_in_group(self, "barn", false)
		
		if obj:
			# not really dropping off but at the same place
			set_task(C.TASK_DROPPING_OFF, obj, false)
	
	elif task == C.TASK_DROPPING_OFF:
		if target_reached:
			
			# only eat if the barn has food and we can reduce it by 1
			if target_object.goods_out(Lib.GOOD_CROP, 1):
				set_task(C.TASK_EATING)
			else:
				emit_signal("bun_starving")
				# and retry, as the task was not updated - except when out of
				# food and all bunnies are hungry, then lose the level in the
				# signal handler
	
	elif task == C.TASK_EATING:
		if do_task_and_is_finished():
			hunger = 0
			
			update_mood()
			set_task(C.TASK_IDLING)

func think_free():
	update_mood()
	start_new_job_if_any()

func think_farmer():
	var obj
	var obj2
	var handled = false
	
	if task == C.TASK_IDLING:
		if farmer_crops_held > 0:
			obj = Lib.get_nearest_object_in_group(self, "barn", false)
			
			if obj:
				set_task(C.TASK_DROPPING_OFF, obj, false)
				handled = true
		
		if not handled:
			obj = Lib.get_nearest_object_from_list(self, get_plants_with_state(4, 4))
			
			if obj:
				set_task(C.TASK_COLLECTING, obj, true)
				handled = true
		
		if not handled:
			obj = Lib.get_nearest_object_from_list(self, get_plants_with_state(0, 0))
			
			if obj:
				set_task(C.TASK_SEEDING, obj, true)
				handled = true
		
		if not handled:
			for i in range(1, 4):
				obj = Lib.get_nearest_object_from_list(self, get_plants_with_state(i, i))
				
				if obj:
					obj2 = Lib.get_nearest_object_in_group(self, "well", false)
					
					if obj2:
						set_task(C.TASK_WATERING_1, obj2, false, obj, true)
						handled = true
				
				if handled:
					break
	
	elif task == C.TASK_COLLECTING:
		if target_reached:
			print("collecting...")
			if do_task_and_is_finished():
				target_object.interact()
				farmer_crops_held += 1
				set_task(C.TASK_IDLING)
	
	elif task == C.TASK_DROPPING_OFF:
		if target_reached:
			print("dropping off...")
			if do_task_and_is_finished():
				do_drop_off_goods()
				start_new_job_if_any()
	
	elif task == C.TASK_SEEDING:
		if target_reached:
			print("seeding...")
			if do_task_and_is_finished():
				target_object.interact()
				set_task(C.TASK_IDLING)
				start_new_job_if_any()
	
	elif task == C.TASK_WATERING_1:
		if target_reached:
			print("getting water...")
			if do_task_and_is_finished():
				farmer_water_held += 1
				set_task(C.TASK_WATERING_2, secondary_object, true)
				# swap_task_objects(C.TASK_WATERING_2)
	
	elif task == C.TASK_WATERING_2:
		if target_reached:
			print("watering...")
			if do_task_and_is_finished():
				farmer_water_held = 0
				target_object.interact()
				set_task(C.TASK_IDLING)
				start_new_job_if_any()

func think_lumberjack():
	var obj
	var handled = false
	
	if task == C.TASK_IDLING:
		if lumberjack_wood_held > 0:
			obj = Lib.get_nearest_object_in_group(self, "barn", false)
			
			if obj:
				set_task(C.TASK_DROPPING_OFF, obj, false)
				handled = true
		
		if not handled:
			# try to find an already chopped tree
			obj = Lib.get_nearest_object_from_list(self, get_trees_with_state(1, 1))
			
			if obj:
				set_task(C.TASK_CHOPPING_TREE, obj, true)
				handled = true
		
		if not handled:
			# find a fully grown tree
			obj = Lib.get_nearest_object_from_list(self, get_trees_with_state(0, 0))
			
			if obj:
				set_task(C.TASK_CHOPPING_TREE, obj, true)
				handled = true
	
	elif task == C.TASK_DROPPING_OFF:
		if target_reached:
			print("dropping off...")
			if do_task_and_is_finished():
				do_drop_off_goods()
				start_new_job_if_any()
	
	elif task == C.TASK_CHOPPING_TREE:
		if target_reached:
			print("dropping off...")
			if do_task_and_is_finished():
				target_object.interact()
				lumberjack_wood_held += 1
				set_task(C.TASK_IDLING)

func think():
	print("")
	print("think()")
	
	increase_needs()
	update_mood()
	
	if task == C.TASK_IDLING:
		update_job_override()
	
	if job_override == C.JOB_FIRESTARTER:
		think_firestarter()
	elif job_override == C.JOB_FIREFIGHTER:
		think_firefighter()
	elif job_override == C.JOB_SLEEPER:
		think_sleeper()
	elif job_override == C.JOB_EATER:
		think_eater()
	else:
		if job == C.JOB_NONE:
			think_free()
		elif job == C.JOB_FARMER:
			think_farmer()
		elif job == C.JOB_LUMBERJACK:
			think_lumberjack()
	
	if Lib.is_object_valid(target_object) and not target_reached:
		nav_agent.set_target_location(target_object.global_position)
		is_navigating = true
	
	update_carry_container()

func _on_ThinkTimer_timeout():
	think()

func get_rectangle():
	return Rect2(self.global_position.x - 6, self.global_position.y - 14, 12, 16)

func _on_ThinkStartTimer_timeout():
	$ThinkTimer.start()
