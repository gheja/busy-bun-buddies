extends Node2D

signal fire_propagate
signal fire_died

const STATE_MAX = 5

var tree: Node2D = null
var state = 0

func update_sprite():
	if state == 0:
		$AnimatedSprite.play("fire_low")
	elif state == 1:
		$AnimatedSprite.play("fire_medium")
	else:
		$AnimatedSprite.play("fire_high")

func grow():
	state += 1
	
	update_sprite()
	
	if state > 2 and state < STATE_MAX:
		emit_signal("fire_propagate")
	
	if state == STATE_MAX:
		emit_signal("fire_died")
		self.queue_free()

func bind_to_tree(value):
	tree = value

func _ready():
	state = 0
	update_sprite()

func _on_Timer_timeout():
	grow()
