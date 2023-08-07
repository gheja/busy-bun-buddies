extends Node2D

func _process(_delta):
	var scroll_direction = $Camera2D/Control.get_scroll_direction()
	
	if scroll_direction != Vector2.ZERO:
		$Camera2D.position += scroll_direction

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	pass
