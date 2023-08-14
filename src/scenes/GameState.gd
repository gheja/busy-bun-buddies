extends Node

var paused = false
var music_enabled = true
var sounds_enabled = true

func set_paused(value):
	get_tree().paused = value
	paused = value

func is_paused():
	return paused
