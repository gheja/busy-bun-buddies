extends Node2D

signal fire_propagate
signal fire_died
signal fire_extinguished

const FIRE_SUM_MAX = 5

var fire_plus = 0
var fire_minus = 0
var fire_sum = 0
var shrink_state = 0

func update_sprite():
	if fire_sum == 0:
		pass
	elif fire_sum == 1:
		$AnimatedSprite.play("fire_low")
	elif fire_sum == 2:
		$AnimatedSprite.play("fire_medium")
	else:
		$AnimatedSprite.play("fire_high")

func update_fire():
	fire_sum = fire_plus - fire_minus
	update_sprite()

func grow():
	fire_plus += 1
	
	update_fire()
	
	if fire_sum > 3:
		emit_signal("fire_propagate")
	
	if fire_sum == FIRE_SUM_MAX:
		emit_signal("fire_died")
		self.queue_free()

func shrink():
	# stop growing once the buns started to put it out
	$Timer.stop()
	
	# clamp the fire size so the water looks effective right away
	if fire_plus > 2:
		fire_plus = 2
	
	fire_minus += 1
	
	update_fire()
	
	if fire_sum == 0:
		emit_signal("fire_extinguished")
		self.queue_free()

func _ready():
	fire_plus = 0
	fire_minus = 0
	
	grow()

func _on_Timer_timeout():
	grow()
