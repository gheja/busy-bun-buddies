extends Node2D

signal goods_amounts_changed

export var goods = [ 0, 0 ]

func goods_in(good_type: int, amount: int):
	goods[good_type] += amount
	emit_signal("goods_amounts_changed")

func goods_out(good_type: int, amount: int):
	if goods[good_type] < amount:
		return false
	
	goods[good_type] -= amount
	emit_signal("goods_amounts_changed")
	
	return true

func _ready():
	$Sprite.hide()
