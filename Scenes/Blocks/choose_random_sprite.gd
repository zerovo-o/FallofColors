extends StaticBody2D
@onready var sprite : Sprite2D = $Sprite2D

func _ready():
	sprite.frame = randi_range(1,sprite.get_hframes()-1 )

