extends Node

#shoot 
#hit mob
#jump on mob
#kill mob
#break brick
#land sound

class_name Master

@export var mapdecider : Map_Decider
@export var mapspawner : Map_Spawner
@export var player : PlayerMasterAndMover
@export var StartUI : Control 
@export var MainUI: MainUI

@export var hurt_inv_time = 0.4
var hurt_time_counter = 0.0
var can_be_hurt : bool = true
func hurt_player():
	if can_be_hurt:
		can_be_hurt = false
		player.set_life_current(player.get_current_life() - 1)

@onready var startingcamloc : Node2D = $StartingCameraSpot
@onready var opening_hatch : Sprite2D = $OpeningHatch
var camera : CameraEffects
func set_camera(inCam: CameraEffects):
	camera = inCam
	change_camera_target(startingcamloc)
	print(camera)
	
func change_camera_target(in_target : Node2D):
	if camera:
		camera.target = in_target

func _physics_process(delta):
	if !can_be_hurt:
		hurt_time_counter += delta
		player.sprite.modulate = Color.DARK_RED
		if hurt_time_counter > hurt_inv_time:
			can_be_hurt = true
			hurt_time_counter = 0
			player.sprite.modulate = Color.GHOST_WHITE

var _gem_count = 0

func get_gem_count() -> int:
	return _gem_count

func set_gem_count(value : int) -> void:
	_gem_count = clamp(value, 0, 9999)
	MainUI.display_gem_count(get_gem_count())

func get_gem(incount : int):
	set_gem_count(get_gem_count() + incount)
	
func get_gem_bonus(bonus:int):
	MainUI.display_gem_bonus(bonus)
	
func set_gem_bonus(bonus_post_calculation : int):
	set_gem_count(get_gem_count() + bonus_post_calculation)
	
func restart_game():
	SoundManager.stop_all_sounds()
	SoundManager.play_sound("death")
	player.jumpmove.can_move = false
	player.sprite.hide()
	player.velocity = Vector2.ZERO
	await get_tree().create_timer(2).timeout
	get_tree().reload_current_scene()
	
func finish_game():
	SoundManager.stop_sound("boss_music")
	HitStpo.start_hitstop(3)
	await get_tree().create_timer(4).timeout
	get_tree().reload_current_scene()
	
func _ready():
	Pooler.end_boss.connect(finish_game)
	HitStpo.start_hitstop(1)
	SoundManager.play_sound("start_intro", 0.01, false)
	Pooler.gem_collected.connect(get_gem)
	player.calculate_bonus.connect(get_gem_bonus)
	#from player hurt box
	player.take_damage.connect(hurt_player)
	mapdecider.spawning.connect(mapspawner.spawn_block)
	MainUI.gem_bonus_count.connect(set_gem_bonus)
	player.camera_effect.set_camera.connect(set_camera)
	#from set life in player
	player.dead.connect(restart_game)
	
	# ===== 第一段：按你现有的竖向流程 =====
	mapdecider.make_starting_chunk()
	
	for i in 5:
		mapdecider.off_set_y += 16 * 5
		mapdecider.make_blank_chunk()
	
	for i in 15:
		mapdecider.off_set_y += 16 * 5
		mapdecider.make_one_chunk()
	
	mapdecider.off_set_y += 16 * 5
	mapdecider.make_specific_chunk(4)
	
	for i in 15:
		mapdecider.off_set_y += 16 * 5
		mapdecider.make_one_chunk()
	
	mapdecider.off_set_y += 16 * 5
	mapdecider.make_specific_chunk(3)
	
	for i in 20:
		mapdecider.off_set_y += 16 * 5
		mapdecider.make_one_chunk()
	
	mapdecider.off_set_y += 16 * 5
	mapdecider.make_specific_chunk(4)
	
	for i in 10:
		mapdecider.off_set_y += 16 * 5
		mapdecider.make_blank_chunk()
		
	mapdecider.off_set_y += 16 * 5
	mapdecider.make_specific_chunk(2)

	mapdecider.off_set_x = 16
	for i in 4:
		mapdecider.make_specific_chunk_right(5, "mid")
	
	# 行尾：这里用 1 号块示例；保留右侧墙
	mapdecider.make_specific_chunk_right(1, "right")
	
	# 横向结束后，把后续竖向的 x 锚点对齐到“最后一个横向块”的起点
	mapdecider.lock_vertical_to_last_right_chunk()
	
	
	
	
	
	
	
	
	
	# ===== 第二段：继续竖向（沿横向末端所在的 x 继续往下） =====

	for i in 5:
		mapdecider.off_set_y += 16 * 5
		mapdecider.make_blank_chunk()
	
	for i in 15:
		mapdecider.off_set_y += 16 * 5
		mapdecider.make_one_chunk()
	
	mapdecider.off_set_y += 16 * 5
	mapdecider.make_specific_chunk(4)
	
	for i in 15:
		mapdecider.off_set_y += 16 * 5
		mapdecider.make_one_chunk()
	
	mapdecider.off_set_y += 16 * 5
	mapdecider.make_specific_chunk(3)
	
	for i in 20:
		mapdecider.off_set_y += 16 * 5
		mapdecider.make_one_chunk()
	
	mapdecider.off_set_y += 16 * 5
	mapdecider.make_specific_chunk(4)
	
	for i in 10:
		mapdecider.off_set_y += 16 * 5
		mapdecider.make_blank_chunk()
		
	mapdecider.off_set_y += 16 * 5
	mapdecider.make_specific_chunk(2)

	for i in 4:
		mapdecider.make_specific_chunk_right(5, "mid")
	
	# 行尾：这里用 1 号块示例；保留右侧墙
	mapdecider.make_specific_chunk_right(1, "right")
	
	# 横向结束后，把后续竖向的 x 锚点对齐到“最后一个横向块”的起点
	mapdecider.lock_vertical_to_last_right_chunk()
	

	






















const bullet : PackedScene = preload("res://Scenes/bullets/basic_bullet.tscn")
func _on_start_button_pressed():
	StartUI.hide()
	SoundManager.play_sound("UI_select")
	SoundManager.stop_sound("start_intro")
	opening_hatch.show()
	await get_tree().create_timer(0.5).timeout
	camera.add_trauma(0.3)
	for i in 10:
		await get_tree().create_timer(0.1).timeout
		SoundManager.play_sound("shoot", 1, false)
		var tempb = bullet.instantiate()
		tempb.global_position = Vector2(110, -200)
		add_child(tempb)
	
	await get_tree().create_timer(1).timeout
	player.start_game()
	SoundManager.play_sound("intro", 1, true)

func smooth_switch(camera):
	var tween = create_tween()
	tween.tween_property(camera, "global_position", player.global_position, 0.5)
	tween.finished.connect(player.start_game)
