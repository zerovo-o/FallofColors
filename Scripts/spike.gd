extends StaticBody2D
class_name blockSpike

var can_shoot: bool = true
@onready var anim : AnimationPlayer = $AnimationPlayer
@onready var hurtzone : Area2D = $Area2D
signal hurt_player()

func _on_spike_starter_area_entered(area):
	if can_shoot:
		can_shoot = false
		anim.play("spikeshoot")

var shot_once : bool = false 
func check_for_player_in_zone():
	if shot_once == false:
		SoundManager.play_sound("spike", 1, false)
		shot_once = true
	var players = hurtzone.get_overlapping_areas()
	if players.size() > 0:
		hurt_player.emit()	


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "spikeshoot":
		anim.play("idle")
		shot_once = false
		can_shoot = true
