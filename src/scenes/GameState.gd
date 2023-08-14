extends Node

var paused = false
var music_enabled = true
var sounds_enabled = true
var current_level_index = 0
var max_level_index_unlocked = 1

var levels = [
	"res://scenes/levels/Level1.tscn"
]

func set_paused(value):
	get_tree().paused = value
	paused = value

func is_paused():
	return paused
