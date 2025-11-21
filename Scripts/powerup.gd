extends StaticBody2D
@export var upG : Upgrade

@onready var label_name : Label =  $Label
@onready var sprite : Sprite2D = $Sprite2D

func _ready():
	label_name.text = upG.upgrade_name
	sprite.texture = upG.icon

func _on_area_2d_area_entered(area):
		area.get_parent().apply_upgrade(upG)
		queue_free()
