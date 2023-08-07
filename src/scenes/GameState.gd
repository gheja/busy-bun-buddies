extends Node

var paused = false

func set_paused(value):
	get_tree().paused = value
	paused = value

func is_paused():
	return paused
