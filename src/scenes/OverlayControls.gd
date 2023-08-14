extends Control

var scroll_direction = Vector2(0, 0)
var bun_under_cursor = null

var hints_to_show = []

func _ready():
	randomize()
	
	$ScrollTop.hide()
	$ScrollBottom.hide()
	$ScrollLeft.hide()
	$ScrollRight.hide()
	
	$Menu.hide()
	$MenuButton.show()
	
	$BunMenu.hide()
	
	$Hint.hide()
	
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
	if $Menu.visible or $BunMenu.visible or $Hint.visible:
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
	$Menu/ButtonOptions.modulate =       Lib.if2(n == 0, C.COLOR_MENU_ACTIVE, C.COLOR_MENU_INACTIVE)
	$Menu/ButtonObjectives.modulate =    Lib.if2(n == 1, C.COLOR_MENU_ACTIVE, C.COLOR_MENU_INACTIVE)
	$Menu/ButtonStats.modulate =         Lib.if2(n == 2, C.COLOR_MENU_ACTIVE, C.COLOR_MENU_INACTIVE)
	$Menu/ButtonLevelFinished.modulate = Lib.if2(n == 3, C.COLOR_MENU_ACTIVE, C.COLOR_MENU_INACTIVE)
	
	$Menu/MenuPages/Options.visible       = (n == 0)
	$Menu/MenuPages/Objectives.visible    = (n == 1)
	$Menu/MenuPages/Stats.visible         = (n == 2)
	$Menu/MenuPages/LevelFinished.visible = (n == 3)

func modulate_by_bun_job(obj, job, new_job, value):
	if new_job == value:
		obj.modulate = C.COLOR_JOB_NEW
	elif job == value:
		obj.modulate = C.COLOR_JOB_CURRENT
	else:
		obj.modulate = C.COLOR_JOB_INACTIVE

func show_bun_menu(bun):
	GameState.set_paused(true)
	set_cursor_shape(C.CURSOR_POINTER)
	$MenuButton.hide()
	$BunMenu.show()
	bun_under_cursor = bun
	modulate_by_bun_job($BunMenu/ColorRect/JobNone,       bun.job, bun.new_job, C.JOB_NONE)
	modulate_by_bun_job($BunMenu/ColorRect/JobFarmer,     bun.job, bun.new_job, C.JOB_FARMER)
	modulate_by_bun_job($BunMenu/ColorRect/JobLumberjack, bun.job, bun.new_job, C.JOB_LUMBERJACK)
	set_cursor_shape(C.CURSOR_POINTER)
	
	$BunMenu/ColorRect/TakeAwayMatch.visible = bun_under_cursor.has_match

func hide_bun_menu():
	hide_menu()

func bun_set_job(job):
	if Lib.is_object_valid(bun_under_cursor):
		bun_under_cursor.set_new_job(job)
		AudioManager.play_sound(3, bun_under_cursor.pitch_shift, bun_under_cursor.pitch_shift)
	
	hide_bun_menu()

func pop_hint():
	var s
	
	s = hints_to_show.pop_front()
	
	$Hint/HintLabel.text = s
	
	AudioManager.play_sound(4)


func show_hint(s):
	if s is Array:
		hints_to_show = s
	else:
		hints_to_show = [ s ]
	
	$Hint.show()
	$MenuButton.hide()
	GameState.set_paused(true)
	set_cursor_shape(C.CURSOR_POINTER)
	
	pop_hint()

func set_stats(amounts, amounts_needed, _total_trees, burned_trees, max_burned_trees, matches_found, total_matches):
	$Menu/MenuPages/Stats/FoodCounter.text =        str(amounts[Lib.GOOD_CROP]) + " / " + str(amounts_needed[Lib.GOOD_CROP])
	$Menu/MenuPages/Stats/WoodCounter.text =        str(amounts[Lib.GOOD_WOOD]) + " / " + str(amounts_needed[Lib.GOOD_WOOD])
	$Menu/MenuPages/Stats/BurnedTreesCounter.text = str(burned_trees)           + " / " + str(max_burned_trees)
	$Menu/MenuPages/Stats/MatchesCounter.text =     str(matches_found)          + " / " + str(total_matches)
	
	$Menu/MenuPages/Stats/FoodCounter.modulate =        Lib.if2(amounts[Lib.GOOD_CROP] >= amounts_needed[Lib.GOOD_CROP], C.COLOR_STATS_GOOD, C.COLOR_STATS_NORMAL)
	$Menu/MenuPages/Stats/WoodCounter.modulate =        Lib.if2(amounts[Lib.GOOD_WOOD] >= amounts_needed[Lib.GOOD_WOOD], C.COLOR_STATS_GOOD, C.COLOR_STATS_NORMAL)
	$Menu/MenuPages/Stats/BurnedTreesCounter.modulate = Lib.if2(burned_trees < max_burned_trees,                         C.COLOR_STATS_GOOD, C.COLOR_STATS_BAD)
	$Menu/MenuPages/Stats/MatchesCounter.modulate =     Lib.if2(matches_found == total_matches,                          C.COLOR_STATS_GOOD, C.COLOR_STATS_NORMAL)

func set_firefighter_button_visibility(value):
	$FireFighterButton.visible = value

func set_level_finished_button_visibility(value):
	$Menu/ButtonLevelFinished.visible = value
	$Menu/MenuPages/LevelFinished.visible = value

func set_matches_visibility(value):
	$Menu/MenuPages/Stats/MatchesTextureRect.visible = value
	$Menu/MenuPages/Stats/MatchesCounter.visible = value
	$Menu/MenuPages/Stats/BurnedTreesTextureRect.visible = value
	$Menu/MenuPages/Stats/BurnedTreesCounter.visible = value

func show_level_finished(status: int):
	$Menu/MenuPages/LevelFinished/WinText.visible = (status == C.LEVEL_FINISHED_SUCCESS)
	$Menu/MenuPages/LevelFinished/LevelFinishedBackButton.visible = (status == C.LEVEL_FINISHED_SUCCESS)
	$Menu/MenuPages/LevelFinished/LevelFinishedContinueButton.visible = (status == C.LEVEL_FINISHED_SUCCESS)
	
	$Menu/MenuPages/LevelFinished/LoseFireText.visible = (status == C.LEVEL_FAILED_FIRE)
	$Menu/MenuPages/LevelFinished/LoseOutOfFoodText.visible = (status == C.LEVEL_FAILED_OUT_OF_FOOD)
	$Menu/MenuPages/LevelFinished/LevelFinishedRetryButton.visible = (status != C.LEVEL_FINISHED_SUCCESS)
	
	show_menu()
	set_menu_page(3)
	
	set_level_finished_button_visibility(true)
	$Menu/ButtonLevelFinished.grab_focus()
	
	# don't allow the player to go back to the game if lost
	$Menu/ButtonBack.visible = (status == C.LEVEL_FINISHED_SUCCESS)

func show_menu():
	if $Menu/MenuPages/LevelFinished.visible:
		set_menu_page(3)
		$Menu/ButtonLevelFinished.grab_focus()
	else:
		set_menu_page(2)
		$Menu/ButtonStats.grab_focus()
	
	$Menu.show()
	$MenuButton.hide()
	$Menu/ButtonBack.show()
	update_options_page()
	
	GameState.set_paused(true)
	set_cursor_shape(C.CURSOR_POINTER)

func hide_menu():
	bun_under_cursor = null
	
	$Menu.hide()
	$Hint.hide()
	$BunMenu.hide()
	$MenuButton.show()
	
	GameState.set_paused(false)

func update_options_page():
	$Menu/MenuPages/Options/MusicEnabled.icon = Lib.if2(GameState.music_enabled, preload("res://assets/graphics/button_music_on.png"), preload("res://assets/graphics/button_music_off.png"))
	$Menu/MenuPages/Options/MusicLabel.text = "Music: " + Lib.if2(GameState.music_enabled, "on", "off")
	
	$Menu/MenuPages/Options/SoundsEnabled.icon = Lib.if2(GameState.sounds_enabled, preload("res://assets/graphics/button_sound_on.png"), preload("res://assets/graphics/button_sound_off.png"))
	$Menu/MenuPages/Options/SoundsLabel.text = "Sounds: " + Lib.if2(GameState.sounds_enabled, "on", "off")

func button_pressed():
	AudioManager.play_sound(5)

func button_pressed_2():
	AudioManager.play_sound(6)

func _on_MenuButton_pressed():
	show_menu()
	button_pressed()

func _on_ButtonBack_pressed():
	hide_menu()
	button_pressed()

# it would be much nicer to hide the tooltip when leaving the object but...
func _on_TooltipHideTimer_timeout():
	set_tooltip("")

func _on_BunMenuBack_gui_input(_event):
	set_tooltip("Back")

func _on_JobNone_gui_input(_event):
	set_tooltip("job: none")

func _on_JobFarmer_gui_input(_event):
	set_tooltip("job: Farmer")

func _on_JobLumberjack_gui_input(_event):
	set_tooltip("job: Lumberjack")

func _on_TakeAwayMatch_gui_input(_event):
	set_tooltip("Take match")

func _on_BunMenuBack_pressed():
	hide_bun_menu()
	button_pressed()

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

func _on_ButtonLevelFinished_mouse_entered():
	set_tooltip("Level finished")

func _on_FoodTextureRect_mouse_entered():
	set_tooltip("Food")

func _on_WoodTextureRect_mouse_entered():
	set_tooltip("Wood")

func _on_BurnedTreesTextureRect_mouse_entered():
	set_tooltip("Burned trees")

func _on_MatchesTextureRect_mouse_entered():
	set_tooltip("Matches found")

func _on_ButtonOptions_pressed():
	set_menu_page(0)
	button_pressed_2()

func _on_ButtonObjectives_pressed():
	set_menu_page(1)
	button_pressed_2()

func _on_ButtonStats_pressed():
	set_menu_page(2)
	button_pressed_2()

func _on_ButtonLevelFinished_pressed():
	set_menu_page(3)
	button_pressed_2()

func _on_TakeAwayMatch_pressed():
	bun_under_cursor.take_away_match()
	AudioManager.play_sound(8, bun_under_cursor.pitch_shift, bun_under_cursor.pitch_shift)
	
	hide_bun_menu()

func _on_FireFighterButton_pressed():
	Lib.get_main_scene().fight_the_fire()
	AudioManager.play_sound(7)

func _on_FireFighterButton_mouse_entered():
	set_tooltip("Fight fire!")

func _on_HintContinueButton_mouse_entered():
	set_tooltip("Continue...")

func _on_HintContinueButton_pressed():
	if hints_to_show.size() > 0:
		pop_hint()
	else:
		hide_menu()
		button_pressed()

func _on_LevelFinishedBackButton_mouse_entered():
	set_tooltip("Back to game")

func _on_LevelFinishedContinueButton_mouse_entered():
	set_tooltip("Next level")

func _on_LevelFinishedRetryButton_mouse_entered():
	set_tooltip("Retry level")

func _on_LevelFinishedBackButton_pressed():
	hide_menu()
	show_hint([ "Open the menu again to continue to the next level." ])
	button_pressed()

func _on_LevelFinishedContinueButton_pressed():
	Lib.get_main_scene().load_next_level()
	hide_menu()
	button_pressed()

func _on_LevelFinishedRetryButton_pressed():
	Lib.get_main_scene().reload_current_level()
	hide_menu()
	button_pressed()

func _on_MusicEnabled_pressed():
	GameState.music_enabled = not GameState.music_enabled
	Lib.apply_options()
	update_options_page()
	button_pressed()

func _on_SoundsEnabled_pressed():
	GameState.sounds_enabled = not GameState.sounds_enabled
	Lib.apply_options()
	update_options_page()
	button_pressed()
