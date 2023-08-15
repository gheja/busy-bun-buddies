extends Node

var paused = false
var music_enabled = true
var sounds_enabled = true
var current_level_index = 0
var max_level_index_unlocked = 0
var max_level_index = 0

var levels = [
	"res://scenes/levels/TutorialLevel1.tscn",
	"res://scenes/levels/Level1.tscn"
]

func _ready():
	max_level_index = levels.size() - 1

func set_paused(value):
	get_tree().paused = value
	paused = value

func is_paused():
	return paused

func save_to_config():
	pass

func load_from_config():
	pass
