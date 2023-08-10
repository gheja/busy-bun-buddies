extends Node2D

var goods = [ 0, 0 ]

func goods_in(good_type: int, amount: int):
	goods[good_type] += amount

func goods_out(good_type: int, amount: int):
	if goods[good_type] < amount:
		return false
	
	goods[good_type] -= amount
	return true

func _ready():
	$Sprite.hide()
