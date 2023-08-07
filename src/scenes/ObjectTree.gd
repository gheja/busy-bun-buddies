extends Node2D

var wood_left = 3

# 0: fully grown, 1: chopped down, 2: just the trunk
var state = 0

func update_sprite():
	for obj in $Visuals.get_children():
		obj.hide()
	
	if state == 0:
		$Visuals/State0.show()
	if state == 1:
		$Visuals/State1.show()
	if state == 2:
		$Visuals/State2.show()
	
	pass

func update_tree():
	update_sprite()

func chop():
	if state == 0:
		state = 1
	
	elif state == 1:
		if wood_left > 0:
			wood_left -= 1
			# note: we might want to return how much wood was collected
		
		if wood_left == 0:
			state = 2
	
	update_tree()

func get_state():
	return state

func _ready():
	state = 0
	update_tree()

