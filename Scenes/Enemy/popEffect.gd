extends Node2D
@onready var anim = $AnimationPlayer

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "pop":
		Pooler.return_pop(self)


func _on_sprite_2d_visibility_changed():
	anim.play("pop")
