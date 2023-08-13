extends Node2D

var intro_finished = false

func set_intro_finished():
	intro_finished = true

func _unhandled_input(event):
	if not intro_finished:
		return
	
	if (event is InputEventMouseButton) or (event is InputEventKey):
		var _tmp = get_tree().change_scene("res://scenes/MainScene.tscn")
