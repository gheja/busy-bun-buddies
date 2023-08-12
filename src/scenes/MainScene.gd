extends Node2D

var bun_under_cursor = null
onready var overlay = $Camera2D/OverlayControls

var total_goods = [ 0, 0 ]

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

func fight_the_fire():
	for obj in get_tree().get_nodes_in_group("buns"):
		obj.fight_the_fire()

func update_tooltip():
	if bun_under_cursor:
		overlay.set_cursor_shape(C.CURSOR_INSPECT)
		overlay.set_tooltip("Inspect")
	else:
		overlay.set_cursor_shape(C.CURSOR_POINTER)
		overlay.set_tooltip("")

func handle_mouse_click():
	if bun_under_cursor:
		overlay.show_bun_menu(bun_under_cursor)

func update_firefighter_button():
	overlay.set_firefighter_button_visibility(Lib.has_any_flames())

func on_stats_changed():
	for i in range(0, 2):
		total_goods[i] = 0
	
	for obj in get_tree().get_nodes_in_group("barn"):
		for i in range(0, 2):
			total_goods[i] += obj.goods[i]
	
	var total_trees = 0
	var burned_trees = 0
	for obj in get_tree().get_nodes_in_group("tree"):
		total_trees += 1
		
		if obj.state == 4:
			burned_trees += 1
	
	overlay.set_stats(total_goods, [ 7, 10 ], total_trees, burned_trees, 3)

func on_level_loaded():
	for obj in get_tree().get_nodes_in_group("barn"):
		obj.connect("goods_amounts_changed", self, "on_stats_changed")
	
	for obj in get_tree().get_nodes_in_group("tree"):
		obj.connect("stats_changed", self, "on_stats_changed")
	
	on_stats_changed()

func _process(_delta):
	if GameState.is_paused():
		return
	
	handle_scroll()
	handle_bun_inspect()
	update_firefighter_button()
	update_tooltip()

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	on_level_loaded()

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			handle_mouse_click()
