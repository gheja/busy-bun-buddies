extends Control

var scroll_direction = Vector2(0, 0)

func _ready():
	$ScrollTop.hide()
	$ScrollBottom.hide()
	$ScrollLeft.hide()
	$ScrollRight.hide()

func object_is_below_point(obj: Control, point: Vector2):
	return Rect2(obj.rect_global_position, obj.rect_size).has_point(point)

func add_scroll_direction(obj: Control, point: Vector2, vector: Vector2):
	if object_is_below_point(obj, point):
		scroll_direction += vector
		obj.visible = true
	else:
		obj.visible = false

func process_scroll_direction():
	var point = get_global_mouse_position()
	
	scroll_direction = Vector2.ZERO
	
	if object_is_below_point($MenuButton, point):
		return
	
	add_scroll_direction($ScrollTop,    point, Vector2( 0, -1))
	add_scroll_direction($ScrollBottom, point, Vector2( 0,  1))
	add_scroll_direction($ScrollLeft,   point, Vector2(-1,  0))
	add_scroll_direction($ScrollRight,  point, Vector2( 1,  0))

func process_mouse_cursor():
	var pos = get_tree().get_root().get_mouse_position()
	$MouseCursor.set_global_position(pos + Lib.get_camera().position - Vector2(32, 32))
	
func _process(_delta):
	process_scroll_direction()
	process_mouse_cursor()

func get_scroll_direction():
	return scroll_direction
