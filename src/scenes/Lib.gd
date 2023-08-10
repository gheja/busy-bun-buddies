extends Node

const GOOD_CROP = 0
const GOOD_WOOD = 1

func get_first_group_member(group_name):
	var members = get_tree().get_nodes_in_group(group_name)
	
	if members.size() == 0:
		print("Warning: No object matching group \"", group_name, "\", returning null.")
		return null
	
	return members[0]

func dist_2d(p1, p2):
	return abs((Vector2(p1.x, p1.y) - Vector2(p2.x, p2.y)).length())

func unclaim_object(obj: Node2D):
	if obj.is_in_group("claimed"):
		obj.remove_from_group("claimed")

func claim_object(obj: Node2D):
	if not obj.is_in_group("claimed"):
		obj.add_to_group("claimed")

func get_camera() -> Camera2D:
	return get_first_group_member("cameras")

func get_nearest_object_from_list(caller_obj: Node2D, target_objects: Array):
	if not (target_objects is Array) or target_objects.size() == 0:
		return null
	
	var distance = 0
	var min_distance = 999999999
	var min_object = null
	
	for obj in target_objects:
		distance = dist_2d(caller_obj.global_position, obj.global_position)
		
		if distance < min_distance:
			min_distance = distance
			min_object = obj
	
	return min_object

func get_nearest_object_in_group(caller_obj: Node2D, group_name: String, only_unclaimed: bool):
	var objs = []
	
	for obj in get_tree().get_nodes_in_group(group_name):
		if only_unclaimed and obj.is_in_group("claimed"):
			continue
		
		objs.append(obj)
	
	if objs.size() == 0:
		return null
	
	return get_nearest_object_from_list(caller_obj, objs)

func is_object_valid(obj):
	if obj != null and is_instance_valid(obj) and obj.is_inside_tree():
		return true
	
	return false

func if2(condition, value_true, value_false):
	if condition:
		return value_true
	
	return value_false

func get_main_scene() -> PackedScene:
	return get_first_group_member("main_scenes")
