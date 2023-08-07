extends Node2D

# The pathfinding is not working properly with collision shapes and the
# navigation agent seems to be handled as a single point. So when an agent
# walks it's sprite might clip into tiles that should not be navigable. This
# is a hacky solution but I don't have any better now.
func create_navigation_map():
	var cell
	
	$NavigationMap.clear()
	
	for i in $TileMap.get_used_cells(): 
		cell = $TileMap.get_cellv(i)
		
		if cell != TileMap.INVALID_CELL:
			$NavigationMap.set_cellv(i, 0)
	
	for map in [ $TileMapHouse, $TileMapHouseRoof ]:
		for i in map.get_used_cells(): 
			cell = map.get_cellv(i)
			
			if cell != TileMap.INVALID_CELL:
				$NavigationMap.set_cellv(i, 2)

func _ready():
	create_navigation_map()
