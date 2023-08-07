extends Node2D

# tomato

# 0: hidden, 1..4
var grow_state = 0
var grow_state_max = 4
var sprites = [ -1, 7, 8, 9, 10 ]

var recently_handled = false

# how many times this plant was cropped
var generation = 0

func update_sprite():
	if sprites[grow_state] == -1:
		$Sprite.hide()
	else:
		$Sprite.show()
		$Sprite.frame = sprites[grow_state]

func grow():
	if grow_state < grow_state_max:
		grow_state += 1
	
	update_plant()

func seed_or_water():
	recently_handled = true
	$WaterSprite.show()
	$RecentlyHandledTimer.start()

func update_plant():
	update_sprite()

func crop():
	grow_state = 0
	generation += 1
	update_plant()

func get_grow_state():
	return grow_state

func get_was_recently_handled():
	return recently_handled

func get_generation():
	return generation

func _ready():
	$WaterSprite.hide()
	# grow_state = 0
	grow_state = 4
	update_plant()

func _on_RecentlyHandledTimer_timeout():
	grow()
	$WaterSprite.hide()
	recently_handled = false
