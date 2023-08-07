extends Node2D

# tomato

# 0: hidden, 1..4
var state = 0
var state_max = 4

var recently_handled = false

# how many times this plant was cropped
var generation = 0

func update_sprite():
	for obj in $Visuals.get_children():
		obj.hide()
	
	# meh...
	if state == 0:
		$Visuals/State0.show()
	if state == 1:
		$Visuals/State1.show()
	if state == 2:
		$Visuals/State2.show()
	if state == 3:
		$Visuals/State3.show()
	if state == 4:
		$Visuals/State4.show()

func update_plant():
	update_sprite()

func grow():
	state += 1
	update_plant()

func interact():
	if state == state_max:
		state = 0
		generation += 1
	else:
		recently_handled = true
		$VisualsExtra/WaterSprite.show()
		$RecentlyHandledTimer.start()
	
	update_plant()

func get_state():
	return state

func get_was_recently_handled():
	return recently_handled

func get_generation():
	return generation

func _ready():
	$VisualsExtra/WaterSprite.hide()
	# state = 0
	state = 4
	update_plant()

func _on_RecentlyHandledTimer_timeout():
	grow()
	$VisualsExtra/WaterSprite.hide()
	recently_handled = false
