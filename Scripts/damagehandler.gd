extends Area2D

var parent_player : PlayerMasterAndMover

func _ready():
	parent_player = get_parent()

func _on_area_entered(area):
	#where does this go?
	#this is a signal from the parent
	parent_player.take_damage.emit()
