extends Control

var scroll_direction = Vector2(0, 0)
var bun_under_cursor = null

func _ready():
	$ScrollTop.hide()
	$ScrollBottom.hide()
	$ScrollLeft.hide()
	$ScrollRight.hide()
	
	$Menu.hide()
	$MenuButton.show()
	
	$BunMenu.hide()
	
	$BottomBar.hide()

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
	
	if is_menu_active():
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

func is_menu_active():
	if $Menu.visible or $BunMenu.visible:
		return true
	
	return false

func set_cursor_shape(n):
	$MouseCursor/MouseShapePointer.visible = (n == C.CURSOR_POINTER)
	$MouseCursor/MouseShapeInspect.visible = (n == C.CURSOR_INSPECT)

func set_tooltip(s):
	if s != "":
		$TooltipHideTimer.start()
		$BottomBar/TooltipLabel.text = s
		$BottomBar.show()
	else:
		$BottomBar.hide()

func set_menu_page(n):
	$Menu/ButtonOptions.modulate =    Lib.if2(n == 0, C.COLOR_MENU_ACTIVE, C.COLOR_MENU_INACTIVE)
	$Menu/ButtonObjectives.modulate = Lib.if2(n == 1, C.COLOR_MENU_ACTIVE, C.COLOR_MENU_INACTIVE)
	$Menu/ButtonStats.modulate =      Lib.if2(n == 2, C.COLOR_MENU_ACTIVE, C.COLOR_MENU_INACTIVE)
	
	$Menu/MenuPages/Options.visible    = (n == 0)
	$Menu/MenuPages/Objectives.visible = (n == 1)
	$Menu/MenuPages/Stats.visible      = (n == 2)

func modulate_by_bun_job(obj, job, new_job, value):
	if new_job == value:
		obj.modulate = C.COLOR_JOB_NEW
	elif job == value:
		obj.modulate = C.COLOR_JOB_CURRENT
	else:
		obj.modulate = C.COLOR_JOB_INACTIVE

func show_bun_menu(bun):
	GameState.set_paused(true)
	$MenuButton.hide()
	$BunMenu.show()
	bun_under_cursor = bun
	modulate_by_bun_job($BunMenu/ColorRect/JobNone,       bun.job, bun.new_job, C.JOB_NONE)
	modulate_by_bun_job($BunMenu/ColorRect/JobFarmer,     bun.job, bun.new_job, C.JOB_FARMER)
	modulate_by_bun_job($BunMenu/ColorRect/JobLumberjack, bun.job, bun.new_job, C.JOB_LUMBERJACK)
	set_cursor_shape(C.CURSOR_POINTER)

func hide_bun_menu():
	GameState.set_paused(false)
	$MenuButton.show()
	$BunMenu.hide()
	bun_under_cursor = null

func bun_set_job(job):
	if Lib.is_object_valid(bun_under_cursor):
		bun_under_cursor.set_new_job(job)
	
	hide_bun_menu()

func _on_MenuButton_pressed():
	GameState.set_paused(true)
	# set_menu_page(0)
	# $Menu/ButtonOptions.grab_focus()
	set_menu_page(2)
	$Menu/ButtonStats.grab_focus()
	$Menu.show()
	$MenuButton.hide()

func _on_ButtonBack_pressed():
	GameState.set_paused(false)
	$Menu.hide()
	$MenuButton.show()

# it would be much nicer to hide the tooltip when leaving the object but...
func _on_TooltipHideTimer_timeout():
	set_tooltip("")

func _on_BunMenuBack_gui_input(event):
	set_tooltip("Back")

func _on_JobNone_gui_input(event):
	set_tooltip("job: none")

func _on_JobFarmer_gui_input(event):
	set_tooltip("job: Farmer")

func _on_JobLumberjack_gui_input(event):
	set_tooltip("job: Lumberjack")

func _on_BunMenuBack_pressed():
	hide_bun_menu()

func _on_JobNone_pressed():
	bun_set_job(C.JOB_NONE)

func _on_JobFarmer_pressed():
	bun_set_job(C.JOB_FARMER)

func _on_JobLumberjack_pressed():
	bun_set_job(C.JOB_LUMBERJACK)

func _on_common_mouse_exited():
	set_tooltip("")

func _on_MenuButton_mouse_entered():
	set_tooltip("Menu")

func _on_ButtonBack_mouse_entered():
	set_tooltip("Back to game")

func _on_ButtonOptions_mouse_entered():
	set_tooltip("Options")

func _on_ButtonObjectives_mouse_entered():
	set_tooltip("Objectives")

func _on_ButtonStats_mouse_entered():
	set_tooltip("Stats")

func _on_ButtonOptions_pressed():
	set_menu_page(0)

func _on_ButtonObjectives_pressed():
	set_menu_page(1)

func _on_ButtonStats_pressed():
	set_menu_page(2)
