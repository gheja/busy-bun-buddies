extends Node2D

signal stats_changed

var wood_left = 3

# 0: fully grown, 1: chopped down, 2: just the trunk, 3: (unused), 4: burned down
var state = 0
var is_on_fire = 0

func update_sprite():
	for obj in $Visuals.get_children():
		obj.hide()
	
	if state == 0:
		$Visuals/State0.show()
	elif state == 1:
		$Visuals/State1.show()
	elif state == 2:
		$Visuals/State2.show()
	elif state == 3:
		$Visuals/State3.show()
	elif state == 4:
		$Visuals/State4.show()
	
	pass

func update_tree():
	update_sprite()

func interact():
	if state == 0:
		state = 1
	
	elif state == 1:
		if wood_left > 0:
			wood_left -= 1
			# note: we might want to return how much wood was collected
		
		if wood_left == 0:
			state = 2
	
	update_tree()

func light_on_fire():
	if state >= 2 or is_on_fire:
		return
	
	is_on_fire = 1
	
	var tmp = preload("res://scenes/ObjectFlame.tscn").instance()
	self.add_child(tmp)
	
	tmp.connect("fire_propagate", self, "on_fire_propagate")
	tmp.connect("fire_died", self, "on_fire_died")
	tmp.connect("fire_extinguished", self, "on_fire_extinguished")
	
	update_tree()

func on_fire_propagate():
	var trees_near = []
	
	for obj in get_tree().get_nodes_in_group("tree"):
		if obj == self:
			continue
		
		if obj.is_on_fire:
			continue
		
		if Lib.dist_2d(self.global_position, obj.global_position) < 18:
			trees_near.append(obj)
	
	if trees_near.size() == 0:
		return
	
	var tree = Lib.array_pick(trees_near)
	tree.light_on_fire()

func on_fire_died():
	state = 4
	is_on_fire = 0
	update_tree()
	emit_signal("stats_changed")

func on_fire_extinguished():
	is_on_fire = 0
	update_tree()
	emit_signal("stats_changed")

func get_state():
	return state

func _ready():
	state = 0
	update_tree()

