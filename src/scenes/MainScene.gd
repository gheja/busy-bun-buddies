extends Node2D

var bun_under_cursor = null
onready var overlay = $Camera2D/OverlayControls

func handle_scroll():
	var scroll_direction = overlay.get_scroll_direction()
	
	if scroll_direction != Vector2.ZERO:
		$Camera2D.position += scroll_direction

func handle_bun_inspect():
	var mouse_position = get_global_mouse_position()
	var bun = null
	
	for obj in get_tree().get_nodes_in_group("buns"):
		if obj.get_rectangle().has_point(mouse_position):
			bun = obj
			break
	
	bun_under_cursor = bun

func update_tooltip():
	if bun_under_cursor:
		overlay.set_cursor_shape(1)
		overlay.set_tooltip("Inspect")
	else:
		overlay.set_cursor_shape(0)
		overlay.set_tooltip("")

func handle_mouse_click():
	if bun_under_cursor:
		overlay.show_bun_menu(bun_under_cursor)

func _process(_delta):
	if GameState.is_paused():
		return
	
	handle_scroll()
	handle_bun_inspect()
	update_tooltip()

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			handle_mouse_click()
