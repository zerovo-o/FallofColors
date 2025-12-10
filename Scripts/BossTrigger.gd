extends Node2D


func _on_area_2d_area_entered(area):
	SoundManager.stop_all_sounds()
	HitStpo.start_hitstop(0.1)
	await get_tree().create_timer(1.5).timeout
	SoundManager.play_sound("boss_music", 0.5, true)
	Pooler.start_boss.emit()
	queue_free()
