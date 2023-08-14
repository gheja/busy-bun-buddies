extends Node2D

export var total_matches = 3
export var match_timer_interval = 10
export var max_burned_trees = 3
export var needed_goods = [ 5, 5 ]

var match_left = 0

# The pathfinding is not working properly with collision shapes and the
# navigation agent seems to be handled as a single point. So when an agent
# walks it's sprite might clip into tiles that should not be navigable. This
# is a hacky solution but I don't have any better now.
func create_navigation_map():
	var cell
	
	# $NavigationMap.clear()
	
	for i in $TileMap.get_used_cells(): 
		cell = $TileMap.get_cellv(i)
		
		if $NavigationMap.get_cellv(i) != TileMap.INVALID_CELL:
			continue
		
		if cell != TileMap.INVALID_CELL:
			$NavigationMap.set_cellv(i, 0)
	
	# for map in [ $TileMapHouse, $TileMapHouseRoof ]:
	# for map in [ $TileMapHouse ]:
	# 	for i in map.get_used_cells(): 
	# 		cell = map.get_cellv(i)
	# 		
	# 		if cell != TileMap.INVALID_CELL:
	# 			$NavigationMap.set_cellv(i, 2)

func _ready():
	match_left = total_matches
	
	if match_left > 0:
		$MatchTimer.wait_time = match_timer_interval
		$MatchTimer.start()
	
	create_navigation_map()

func _on_HouseRoofHideArea_mouse_entered():
	$TileMapHouseRoof.modulate = Color(1.0, 1.0, 1.0, 0.2)

func _on_HouseRoofHideArea_mouse_exited():
	$TileMapHouseRoof.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_MatchTimer_timeout():
	if match_left == 0:
		return
	
	var bun = Lib.array_pick(get_tree().get_nodes_in_group("buns"))
	
	if bun.has_match:
		return
	
	bun.pick_up_match()
	match_left -= 1
