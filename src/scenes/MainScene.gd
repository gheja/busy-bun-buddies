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

var tutorial_level = false

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
		AudioManager.play_sound(2)

func do_lose():
	print("do_lose()")
	
	if Lib.has_seen_this("game_ended"):
		return
	
	overlay.show_level_finished(false)

func do_win():
	print("do_win()")
	
	if Lib.has_seen_this("game_ended"):
		return
	
	overlay.show_level_finished(true)

func update_firefighter_button():
	overlay.set_firefighter_button_visibility(Lib.has_any_flames())

func on_stats_changed():
	var win_condition_met = false
	var lose_condition_met = false
	
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
	
	overlay.set_stats(total_goods, needed_goods, total_trees, burned_trees, max_burned_trees, matches_found, total_matches)
	
	if burned_trees >= max_burned_trees:
		lose_condition_met = true
	
	# won't check for win condition if the forest is still on fire
	if not Lib.has_any_flames():
		if  total_goods[Lib.GOOD_CROP] >= needed_goods[Lib.GOOD_CROP] and total_goods[Lib.GOOD_WOOD] >= needed_goods[Lib.GOOD_WOOD] and matches_found == total_matches:
			win_condition_met = true
	
	if lose_condition_met:
		do_lose()
	elif win_condition_met:
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
	
	level = $LevelContainer.get_children()[0]
	level_base = level.get_level_base()
	
	total_matches = level_base.total_matches
	max_burned_trees = level_base.max_burned_trees
	matches_found = 0
	
	# for now...
	tutorial_level = true
	
	Lib.has_seen_this_clear()
	overlay.set_level_finished_button_visibility(false)
	on_stats_changed()

func on_bun_picked_up_match():
	on_stats_changed()
	
	if not tutorial_level or Lib.has_seen_this("hint:on_bun_picked_up_match"):
		return
	
	$MatchHintTimer.start()

func on_bun_started_a_fire():
	on_stats_changed()
	
	if not tutorial_level or Lib.has_seen_this("hint:on_bun_started_a_fire"):
		return
	
	$FireHintTimer.start()

func on_bun_finished_fighting_the_fire():
	on_stats_changed()
	
	if not tutorial_level or Lib.has_seen_this("hint:on_bun_finished_fighting_the_fire"):
		return
	
	$FireExtinguishedHintTimer.start()

func on_bun_lost_match():
	matches_found += 1
	
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

func _on_MatchHintTimer_timeout():
	overlay.show_hint([ "Oh, a bun just found a match on the ground.", "Buns are naturally curious, so...", "You might want to take the match away.", "(Click on the bun and select that action.)" ])

func _on_FireHintTimer_timeout():
	overlay.show_hint([ "Oh no! The bun just started a fire!", "Use the \"Fight fire!\" button to extinguish it!" ])

func _on_FireExtinguishedHintTimer_timeout():
	overlay.show_hint([ "Huh, that was close...", "The buns might be too curious after all..." ])
