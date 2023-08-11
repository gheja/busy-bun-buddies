extends Node

var menu_music_player: AudioStreamPlayer = null
var main_music_player: AudioStreamPlayer = null
var music_fade_ratio = 1.0
var music_fade_ratio_target = 1.0

var sounds = [
	preload("res://assets/music/Swaylle on opengameart.org/coffee.ogg"), # 0
]

var volume_overrides = [
]

func play_sound(index, pitch_shift_min: float = 1.0, pitch_shift_max: float = 1.0):
	var tmp = AudioStreamPlayer.new()
	tmp.stream = sounds[index]
	tmp.bus = "SFX"
	
	if volume_overrides.size() > index and volume_overrides[index] != null:
		tmp.volume_db = linear2db(volume_overrides[index])
	
	if pitch_shift_min != 1.0 or pitch_shift_max != 1.0:
		tmp.pitch_scale = rand_range(pitch_shift_min, pitch_shift_max)
	
	tmp.play()
	
	get_tree().root.call_deferred("add_child", tmp)

func _ready():
#	menu_music_player = AudioStreamPlayer.new()
#	menu_music_player.stream = sounds[4]
#	menu_music_player.volume_db = linear2db(0.3)
#	menu_music_player.bus = "Menu Music"
#	menu_music_player.play()
	
	main_music_player = AudioStreamPlayer.new()
	main_music_player.stream = sounds[0]
#	main_music_player.volume_db = linear2db(0.25)
	main_music_player.bus = "Main Music"
	main_music_player.pause_mode = PAUSE_MODE_PROCESS
	main_music_player.play()
	
#	get_tree().root.call_deferred("add_child", menu_music_player)
	get_tree().root.call_deferred("add_child", main_music_player)

func set_music_fade_ratio_target(value):
	music_fade_ratio_target = value

func _process(_delta):
#	music_fade_ratio = Lib.plerp(music_fade_ratio, music_fade_ratio_target, 0.25, delta)
#	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Menu Music"), linear2db(1 - music_fade_ratio))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Main Music"), linear2db(music_fade_ratio))
