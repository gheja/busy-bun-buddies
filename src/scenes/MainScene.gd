extends Node2D

var bun_under_cursor = null
onready var overlay = $Camera2D/OverlayControls

var level = null
var level_base = null
var total_goods = [ 0, 0 ]
var needed_goods = [ 7, 10 ]
var matches_found = 0
var total_matches = 0
var max_burned_trees = 0

# just the coordinates of the cursor (both mouse and touch), not displayed directly
var cursor_position = Vector2.ZERO
var cursor_clicked = false

var tutorial_hints_group = 0

var camera_global_position_float = Vector2.ZERO

func handle_scroll(delta):
	var scroll_direction = overlay.get_scroll_direction()
	
	scroll_direction *= delta / 0.016667
	
	if scroll_direction != Vector2.ZERO:
		camera_global_position_float += scroll_direction
	
	var sbtl = Lib.get_first_group_member("scroll_bounds_top_left")
	var sbbr = Lib.get_first_group_member("scroll_bounds_bottom_right")
	
	if camera_global_position_float.x < sbtl.global_position.x:
		camera_global_position_float.x = sbtl.global_position.x
	
	if camera_global_position_float.y < sbtl.global_position.y:
		camera_global_position_float.y = sbtl.global_position.y
		
	if camera_global_position_float.x > sbbr.global_position.x:
		camera_global_position_float.x = sbbr.global_position.x
	
	if camera_global_position_float.y > sbbr.global_position.y:
		camera_global_position_float.y = sbbr.global_position.y
	
	$Camera2D.global_position = Vector2(round(camera_global_position_float.x), round(camera_global_position_float.y))

func handle_bun_inspect():
	var bun = null
	
	for obj in get_tree().get_nodes_in_group("buns"):
		if obj.get_rectangle().has_point(cursor_position):
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

func handle_cursor_click():
	if not cursor_clicked:
		return
	
	if bun_under_cursor:
		overlay.show_bun_menu(bun_under_cursor)
		AudioManager.play_sound(2, bun_under_cursor.pitch_shift, bun_under_cursor.pitch_shift)
	
	cursor_clicked = false

func level_finished(reason):
	print("level_finished() ", reason)
	
	if Lib.has_seen_this("level_finished"):
		return
	
	if reason == C.LEVEL_FINISHED_SUCCESS:
		unlock_next_level()
	
	overlay.show_level_finished(reason)

func do_lose(reason):
	print("do_lose() ", reason)
	level_finished(reason)

func do_win():
	print("do_win()")
	level_finished(C.LEVEL_FINISHED_SUCCESS)

func update_firefighter_button():
	overlay.set_firefighter_button_visibility(Lib.has_any_flames())

func update_fire_overlay():
	var value = float(clamp(Lib.get_flame_level(), 0, 8)) / 8.0
	
	overlay.set_fire_overlay(value)

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
	
	var has_not_hungry_buns = false
	for obj in get_tree().get_nodes_in_group("buns"):
		if obj.mood != C.MOOD_HUNGRY:
			has_not_hungry_buns = true
			break
	
	overlay.set_stats(total_goods, needed_goods, total_trees, burned_trees, max_burned_trees, matches_found, total_matches)
	
	if burned_trees >= max_burned_trees:
		do_lose(C.LEVEL_FAILED_FIRE)
	
	if total_goods[Lib.GOOD_CROP] == 0 and not has_not_hungry_buns:
		do_lose(C.LEVEL_FAILED_OUT_OF_FOOD)
	
	# won't check for win condition if the forest is still on fire
	if not Lib.has_any_flames():
		if total_goods[Lib.GOOD_CROP] >= needed_goods[Lib.GOOD_CROP] and total_goods[Lib.GOOD_WOOD] >= needed_goods[Lib.GOOD_WOOD] and matches_found == total_matches:
			do_win()

func on_level_loaded():
	for obj in get_tree().get_nodes_in_group("barn"):
		obj.connect("goods_amounts_changed", self, "on_stats_changed")
	
	for obj in get_tree().get_nodes_in_group("tree"):
		obj.connect("stats_changed", self, "on_stats_changed")
	
	for obj in get_tree().get_nodes_in_group("buns"):
		obj.connect("picked_up_match", self, "on_bun_picked_up_match")
		obj.connect("started_a_fire", self, "on_bun_started_a_fire")
		obj.connect("finished_fighting_the_fire", self, "on_bun_finished_fighting_the_fire")
		obj.connect("lost_match", self, "on_bun_lost_match")
		obj.connect("bun_starving", self, "on_bun_starving")
	
	camera_global_position_float = Lib.get_first_group_member("camera_start_position").global_position
	
	level = $LevelContainer.get_children()[0]
	level_base = level.get_level_base()
	
	total_matches = level_base.total_matches
	max_burned_trees = level_base.max_burned_trees
	needed_goods = level_base.needed_goods
	matches_found = 0
	tutorial_hints_group = level_base.tutorial_hints_group
	
	if level_base.total_matches == 0:
		overlay.set_matches_visibility(false)
	else:
		overlay.set_matches_visibility(true)
	
	if tutorial_hints_group == 1:
		$WelcomeHintTimer.start()
		$Welcome2HintTimer.start()
		$SwitchToLumberjackHintTimer.start()
	elif tutorial_hints_group == 2:
		$SecondTutorialHintTimer.start()
	
	Lib.has_seen_this_clear()
	overlay.set_level_finished_button_visibility(false)
	on_stats_changed()

func reload_current_level():
	for obj in $LevelContainer.get_children():
		$LevelContainer.remove_child(obj)
	
	var level_scene = load(GameState.levels[GameState.current_level_index]).instance()
	$LevelContainer.add_child(level_scene)
	on_level_loaded()

func load_level(number):
	GameState.current_level_index = number
	reload_current_level()

func unlock_next_level():
	var n = GameState.current_level_index + 1
	
	if GameState.max_level_index_unlocked > n:
		return
	
	if n > GameState.max_level_index:
		return
	
	GameState.max_level_index_unlocked = n
	GameState.save_to_config()

func load_next_level():
	load_level(GameState.current_level_index + 1)

func on_bun_picked_up_match():
	on_stats_changed()
	
	if tutorial_hints_group == 0 or Lib.has_seen_this("hint:on_bun_picked_up_match"):
		return
	
	$MatchHintTimer.start()

func on_bun_started_a_fire():
	on_stats_changed()
	
	if tutorial_hints_group == 0 or Lib.has_seen_this("hint:on_bun_started_a_fire"):
		return
	
	$FireHintTimer.start()

func on_bun_finished_fighting_the_fire():
	on_stats_changed()
	
	if tutorial_hints_group == 0 or Lib.has_seen_this("hint:on_bun_finished_fighting_the_fire"):
		return
	
	$FireExtinguishedHintTimer.start()

func on_bun_lost_match():
	matches_found += 1
	
	on_stats_changed()

func on_bun_starving():
	# to check the lose condition
	on_stats_changed()

func set_cursor_position(position: Vector2):
	cursor_position = position + $Camera2D.position - Vector2(64/2, 64/2)

func set_cursor_clicked():
	cursor_clicked = true

func _process(delta):
	# this must be executed before OverlayControls _process(), but this won't be
	# called when the game is paused... so hacky solution is to process here
	# when unpaused and process there when paused
	overlay.process_scroll_direction()
	overlay.process_mouse_cursor()
	
	if GameState.is_paused():
		return
	
	handle_scroll(delta)
	handle_bun_inspect()
	handle_cursor_click()
	update_firefighter_button()
	update_tooltip()
	update_fire_overlay()

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	GameState.load_from_config()
	
	# if GameState.max_level_index_unlocked == 0:
	load_level(GameState.max_level_index_unlocked)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		set_cursor_position(event.position)
	elif event is InputEventMouseButton:
		# BUG: this somehow catches the touch input as well, although it should
		# be handled in the OverlayControls. this fires first on bun click
		# before the touch events fire. so this pops up the menu even if the
		# player just starts dragging.
		if event.pressed:
			set_cursor_clicked()

func _on_WelcomeHintTimer_timeout():
	overlay.show_hint([ "Welcome to the tiny island of your bun!" ])

func _on_Welcome2HintTimer_timeout():
	overlay.show_hint([ "The buns are busy people, this one is now farming.", "Buns need food and wood for the winter.", "To check the stock, see the menu above.", "Options and objectives are also there." ])

func _on_SwitchToLumberjackHintTimer_timeout():
	if not (total_goods[Lib.GOOD_CROP] > needed_goods[Lib.GOOD_CROP]):
		# this is not a one-shot timer
		return
	
	$SwitchToLumberjackHintTimer.stop()
	overlay.show_hint([ "Your bun has collected enough food for the winter.", "You can ask the bun to chop some wood.", "Click on the bun and select the new job." ])

func _on_SecondTutorialHintTimer_timeout():
	overlay.show_hint([ "These buns don't know what they should do.", "Help them by assigning jobs to them." ])

func _on_ThirdTutorialHintTimer_timeout():
	# overlay.show_hint([ "Great job!" ])
	pass

func _on_MatchHintTimer_timeout():
	overlay.show_hint([ "Oh, a bun just found a match on the ground.", "Buns are naturally curious, so...", "You might want to take the match away.", "(Click on the bun and select that action.)" ])

func _on_FireHintTimer_timeout():
	overlay.show_hint([ "Oh no! The bun just started a fire!", "Use the \"Fight fire!\" button to extinguish it!" ])

func _on_FireExtinguishedHintTimer_timeout():
	overlay.show_hint([ "Huh, that was close...", "The buns might be too curious after all..." ])

