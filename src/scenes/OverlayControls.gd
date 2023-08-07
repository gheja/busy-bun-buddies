extends Control

var scroll_direction = Vector2(0, 0)

func _ready():
	$ScrollTop.hide()
	$ScrollBottom.hide()
	$ScrollLeft.hide()
	$ScrollRight.hide()
	
	$Menu.hide()
	$MenuButton.show()
	
	$BottomBar.hide()
	
	# $MenuButton.connect("mouse")

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
	
	if $Menu.visible:
		return
	
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

func _on_MenuButton_pressed():
	$Menu.show()
	$MenuButton.hide()

func _on_ButtonBack_pressed():
	$Menu.hide()
	$MenuButton.show()

func set_tooltip(s):
	if s != "":
		$TooltipHideTimer.start()
		$BottomBar/TooltipLabel.text = s
		$BottomBar.show()
	else:
		$BottomBar.hide()

func _on_ButtonBack_gui_input(event):
	if event is InputEventMouseMotion:
		set_tooltip("Back to game")

func _on_MenuButton_gui_input(event):
	if event is InputEventMouse:
		set_tooltip("Menu")

# it would be much nicer to hide the tooltip when leaving the object but...
func _on_TooltipHideTimer_timeout():
	set_tooltip("")
