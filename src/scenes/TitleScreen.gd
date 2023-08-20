extends Node2D

var intro_finished = false

func set_intro_finished():
	intro_finished = true

func start_game():
	var _tmp = get_tree().change_scene("res://scenes/MainScene.tscn")
	AudioManager.play_sound(5)

func _unhandled_input(event):
	if not intro_finished:
		return
	
	if event is InputEventMouseButton:
		if event.pressed:
			start_game()
	elif event is InputEventKey:
		if event.is_pressed():
			start_game()
	
	# should note here if touch happens so the touch interface could be shown
	# right away
