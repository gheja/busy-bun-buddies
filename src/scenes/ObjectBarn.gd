extends Node2D

var crops_held = 0

func crops_in(amount):
	crops_held += amount

func crops_out(amount):
	if crops_held < amount:
		return false
	
	crops_held -= amount
	return true
