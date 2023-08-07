extends Node2D

# tomato

# 0: hidden, 1..4
var grow_state = 0
var grow_state_max = 4
var sprites = [ -1, 7, 8, 9, 10 ]

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

func update_plant():
	if grow_state == grow_state_max:
		self.add_to_group("plant_ready")
	else:
		self.remove_from_group("plant_ready")
	
	update_sprite()

func crop():
	grow_state = 0
	update_plant()

func _ready():
	# grow_state = 0
	grow_state = grow_state_max
	update_plant()
