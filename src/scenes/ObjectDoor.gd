extends Node2D


func _process(_delta):
	self.show()
	
	for bun in get_tree().get_nodes_in_group("buns"):
		if Lib.dist_2d(self.global_position, bun.global_position) < 8:
			self.hide()
			break
