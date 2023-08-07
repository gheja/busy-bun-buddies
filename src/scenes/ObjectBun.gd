extends KinematicBody2D

onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var animation_base_name = "idle"
var current_direction_name = "down"

var direction = Vector2.DOWN
var speed = 0
var velocity = Vector2.ZERO
var is_navigating = false

# --- job ---
const JOB_NONE = 0
const JOB_FARMER = 1

const TASK_IDLING = 0
const TASK_COLLECTING = 1
const TASK_DROPPING_OFF = 2

var job = JOB_FARMER
var task = TASK_IDLING
var farmer_water_held = 0
var farmer_crops_held = 0

var target_reached = false
var target_object: Node2D = null
var secondary_object: Node2D = null


# --- needs ---
var tiredness = 0
var hunger = 0


func _ready():
	$AnimatedSprite.play("idle")
	nav_agent.max_speed = 100
	nav_agent.radius = 15
	nav_agent.avoidance_enabled = true

func update_direction_name():
	if velocity.y < 0.1:
		current_direction_name = "up"
	elif velocity.x < 0.1:
		current_direction_name = "left"
	elif velocity.x > 0.1:
		current_direction_name = "right"
	else:
		current_direction_name = "down"

func update_velocity():
	velocity = direction * speed

func update_animation():
	var a
	
	if abs(velocity.x) > 0.1 or abs(velocity.y) > 0.1:
		animation_base_name = "walk"
	else:
		animation_base_name = "idle"
	
	if animation_base_name == "idle":
		a = "idle"
	else:
		a = animation_base_name + "_" + current_direction_name
	
	if $AnimatedSprite.animation != a:
		$AnimatedSprite.play(a)

func update_position():
	velocity = move_and_slide(velocity)

func _process(_delta):
	update_velocity()
	update_direction_name()
	update_animation()
	update_position()

func _physics_process(_delta):
	var next
	
	if is_navigating:
		if Lib.is_object_valid(target_object):
			if Lib.dist_2d(self.global_position, target_object.global_position) < 10:
				arrived_to_target()
			else:
				# print("navigating...")
				next = nav_agent.get_next_location()
				direction = (next - self.global_position).normalized()
				speed = 20
	else:
		speed = 0
	
	# if not next:
	# 	direction = Vector2.DOWN
	# 	speed = 0

# --- job and task related functions ---

func arrived_to_target():
	print("arrived_to_target()")
	
	is_navigating = false
	target_reached = true
	think()

func set_task(new_task: int, obj: Node2D = null, claim: bool = false, secondary_obj: Node2D = null, secondary_claim: bool = false):
	print("set_task() ", [ new_task, obj, claim ])
	
	if target_object:
		Lib.unclaim_object(target_object)
		
	if secondary_object:
		Lib.unclaim_object(secondary_object)
	
	task = new_task
	target_object = obj
	secondary_object = secondary_obj
	target_reached = false
	
	if claim:
		Lib.claim_object(target_object)
	
	if secondary_claim:
		Lib.claim_object(secondary_object)

func swap_task_objects():
	var tmp = target_object
	
	target_object = secondary_object
	secondary_object = tmp

func think():
	print("think()")
	
	var obj
	
	if job == JOB_FARMER:
		if task == TASK_IDLING:
			if farmer_crops_held > 0:
				obj = Lib.get_nearest_object(self, "barn", false)
				if obj:
					set_task(TASK_DROPPING_OFF, obj, false)
			else:
				obj = Lib.get_nearest_object(self, "plant_ready", true)
				if obj:
					set_task(TASK_COLLECTING, obj, true)
				# else:
				# 	obj = Lib.get_nearest_object(self, "plant", true)
				# obj = Lib.get_nearest_object(self, "plant", true)
		elif task == TASK_COLLECTING:
			if target_reached:
				print("collecting")
				target_object.crop()
				farmer_crops_held += 1
				set_task(TASK_IDLING, null, false)
		elif task == TASK_DROPPING_OFF:
			if target_reached:
				print("dropping off")
				target_object.crops_in(farmer_crops_held)
				farmer_crops_held = 0
				set_task(TASK_IDLING, null, false)
	
	if Lib.is_object_valid(target_object):
		nav_agent.set_target_location(target_object.global_position)
		is_navigating = true
	

func _on_Timer_timeout():
	think()
