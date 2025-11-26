extends Node
class_name Master

# 这个是"总导演"。它把所有系统串起来，同时也变成了"关卡段流式生成"的调度器：
# - 段的定义：一段 = 竖向长串 + 一行横向 + 锁锚点
# - 建段：接近当前段底部时开始异步生成下一段（避免卡顿）
# - 删段：玩家一进入新段顶部，立刻删除旧段（保持场上几乎只有当前段）
# - 为了不挡 UI，把每段容器挂到 mapspawner 节点下（世界层），UI 在上层显示正常

@export var mapdecider : Map_Decider
@export var mapspawner : Map_Spawner
@export var player : PlayerMasterAndMover
@export var StartUI : Control 
@onready var main_ui: MainUI = $Player/CanvasLayer/MainUI
@onready var red_effect_manager = $"../Scripts/colorGem/RedEffectManager"
@onready var yellow_effect_manager = $"../Scripts/colorGem/YellowEffectManager"
@onready var blue_effect_manager = $"../Scripts/colorGem/BlueEffectManager"
@onready var rainbow_full_effect_manager = $"../Scripts/colorGem/RainbowFullEffectManager"
@onready var green_effect_manager = $"../Scripts/colorGem/GreenEffectManager"

@export var hurt_inv_time: float = 0.4
var hurt_time_counter: float = 0.0
var can_be_hurt : bool = true

func hurt_player() -> void:
	if can_be_hurt:
		can_be_hurt = false
		player.set_life_current(player.get_current_life() - 1)

@onready var startingcamloc : Node2D = $StartingCameraSpot
@onready var opening_hatch : Sprite2D = $OpeningHatch
var camera : CameraEffects = null

func set_camera(inCam: CameraEffects) -> void:
	camera = inCam
	change_camera_target(startingcamloc)
	print(camera)
	
func change_camera_target(in_target : Node2D) -> void:
	if camera:
		camera.target = in_target

func _physics_process(delta: float) -> void:
	# 受伤闪烁（原逻辑）
	if not can_be_hurt:
		hurt_time_counter += delta
		player.sprite.modulate = Color.DARK_RED
		if hurt_time_counter > hurt_inv_time:
			can_be_hurt = true
			hurt_time_counter = 0.0
			player.sprite.modulate = Color.GHOST_WHITE
	# 段流式调度：随帧驱动“建下一段 / 进入新段删旧段”
	_maybe_build_next()
	_maybe_delete_old_on_enter_new()

# ===== 宝石/通用逻辑（原样） =====
var _gem_count: int = 0

func get_gem_count() -> int:
	return _gem_count

func set_gem_count(value : int) -> void:
	_gem_count = clamp(value, 0, 9999)
	main_ui.display_gem_count(get_gem_count())

func get_gem(incount : int) -> void:
	set_gem_count(get_gem_count() + incount)
	
func get_gem_bonus(bonus:int) -> void:
	main_ui.display_gem_bonus(bonus)
	
func set_gem_bonus(bonus_post_calculation : int) -> void:
	set_gem_count(get_gem_count() + bonus_post_calculation)
	
func restart_game() -> void:
	SoundManager.stop_all_sounds()
	SoundManager.play_sound("death")
	player.jumpmove.can_move = false
	player.sprite.hide()
	player.velocity = Vector2.ZERO
	
	# 重置所有调制效果
	reset_all_modulate_effects()
	
	await get_tree().create_timer(2).timeout
	get_tree().reload_current_scene()

# 重置所有调制效果
func reset_all_modulate_effects():
	# 重置红色调效果
	if red_effect_manager != null:
		red_effect_manager.reset_scene_colors()
		
	# 重置暖色调效果
	if yellow_effect_manager != null:
		yellow_effect_manager.reset_scene_colors()
		
	# 重置蓝色调效果
	if blue_effect_manager != null:
		blue_effect_manager.reset_scene_colors()
		
	# 重置完整彩虹效果
	if rainbow_full_effect_manager != null:
		rainbow_full_effect_manager.reset_scene_colors()
		
	# 重置绿色调效果
	if green_effect_manager != null:
		green_effect_manager.reset_scene_colors()

func finish_game() -> void:
	SoundManager.stop_sound("boss_music")
	HitStpo.start_hitstop(3)
	await get_tree().create_timer(4).timeout
	get_tree().reload_current_scene()
	
func _ready() -> void:
	# 连接各种系统（原样）
	Pooler.end_boss.connect(finish_game)
	HitStpo.start_hitstop(1)
	SoundManager.play_sound("start_intro", 0.01, false)
	Pooler.gem_collected.connect(get_gem)
	player.calculate_bonus.connect(get_gem_bonus)
	player.take_damage.connect(hurt_player)
	mapdecider.spawning.connect(mapspawner.spawn_block)
	main_ui.gem_bonus_count.connect(set_gem_bonus)
	player.camera_effect.set_camera.connect(set_camera)
	player.dead.connect(restart_game)

	# 段流式开场：只建第一段，其余按需生成
	# 把“竖向左墙”的锚点对齐到 x=16（配合 MapDecider 的 (col-1) 机制）
	mapdecider.set_vertical_origin_x(16)
	_build_segment_async(true)

func _select_segment_difficulty(seg_id: int) -> String:
	#每段对应不同难度
	# 0 段（第一段）用 map_first
	if seg_id == 0:
		return "first"
	# 1 段（第二段）用 map_second
	elif seg_id == 1:
		return "second"
	# 2 段（第三段）用 map_third
	elif seg_id == 2:
		return "third"
	# 3 段（第四段）用 map_forth
	elif seg_id == 3:
		return "forth"
	# 4 段（第五段）用 map_fifth
	else:
		return "fifth"



# ===== 段流式（一段 = 竖向 + 横向 + 锁锚点） =====
const TILE: int = 16
const CHUNK_H: int = 5 * TILE
const BUILD_TRIGGER_MARGIN: int = 2 * CHUNK_H  # 接近当前段底部这么远时预生成下一段
const MAX_SEGMENTS: int = 5                  # 这里先设 5 段；想多就调这个数字

# 管理在场段的顺序 & 信息
var _loaded_order: Array[int] = []      # [旧段 id, 新段 id]
var _loaded_info: Dictionary = {}       # id -> {"root":Node2D, "ymin":float, "ymax":float}
var _next_id: int = 0
var _next_start_y: int = 0              # 下一段的竖向起点（延续 off_set_y）
var _next_anchor_x: int = 16            # 下一段的竖向锚点 x（由上一次横向 lock 得到）
var _building: bool = false
var _segments_built: int = 0            # 已生成段数

# 进入新段顶部就删旧段：用一个“阈值 y”进行触发
var _pending_delete_old_id: int = -1
var _pending_threshold_y: float = INF

# 这就是你原版“段”的构成，只是把 make_xxx 换成 async 版本，保持完全一样的顺序和次数
func spawn_one_segment_async(first: bool) -> void:
	if first:
		await mapdecider.make_starting_chunk_async()
	
	for i in 5:
		mapdecider.off_set_y += CHUNK_H
		await mapdecider.make_blank_chunk_async()
	
	for i in 15:
		mapdecider.off_set_y += CHUNK_H
		await mapdecider.make_one_chunk_async()
	
	mapdecider.off_set_y += CHUNK_H
	await mapdecider.make_specific_chunk_async(4)
	
	for i in 15:
		mapdecider.off_set_y += CHUNK_H
		await mapdecider.make_one_chunk_async()
	
	mapdecider.off_set_y += CHUNK_H
	await mapdecider.make_specific_chunk_async(3)
	
	for i in 20:
		mapdecider.off_set_y += CHUNK_H
		await mapdecider.make_one_chunk_async()
	
	mapdecider.off_set_y += CHUNK_H
	await mapdecider.make_specific_chunk_async(4)
	
	for i in 10:
		mapdecider.off_set_y += CHUNK_H
		await mapdecider.make_blank_chunk_async()
		
	mapdecider.off_set_y += CHUNK_H
	await mapdecider.make_specific_chunk_async(2)

	mapdecider.off_set_x = mapdecider.vertical_origin_x
	await mapdecider.make_specific_chunk_right_stack3_async([2,2,11], "mid")
	
	await mapdecider.make_specific_chunk_right_stack3_async([5,6,8], "mid")
	await mapdecider.make_specific_chunk_right_stack3_async([5,6,7], "mid")
	for i in 2:
		await mapdecider.make_specific_chunk_right_stack3_async([5,6,8], "mid")
	await mapdecider.make_specific_chunk_right_stack3_async([5,10,9], "mid")

# 横向收尾：锁锚点
	mapdecider.lock_vertical_to_last_right_chunk()

# 关键新增：下一段从三层底部开始（3 层 → 额外下推 2 * CHUNK_H）
	mapdecider.off_set_y += 2 * CHUNK_H


# 粗略计算一段的 y 范围，方便触发预生成/删除
func _compute_segment_bounds(root: Node2D) -> Vector2:
	var ymin: float = INF
	var ymax: float = -INF
	for n in root.get_children():
		for c in n.get_children():
			var nd := c as Node2D
			if nd != null:
				var y: float = nd.global_position.y
				if y < ymin:
					ymin = y
				if y > ymax:
					ymax = y
	return Vector2(ymin, ymax)

# 真正建一段：建容器 -> 指定 MapSpawner 的生成根 -> 生成 -> 记录范围 -> 设删除阈值
func _build_segment_async(first: bool) -> void:
	# 在建/达上限就不建
	if _building:
		return
	if _segments_built >= MAX_SEGMENTS:
		return
	_building = true

	var prev_id: int = _loaded_order.back() if _loaded_order.size() > 0 else -1

	# 段容器。注意我挂到了 mapspawner 节点下（世界层），避免把 UI 遮住。
	var seg_id: int = _next_id

	# ★ 根据段号切换难度（0 段 first，1 段 second...）
	var diff := _select_segment_difficulty(seg_id)
	mapdecider.set_difficulty(diff)

	_next_id += 1
	var seg := Node2D.new()
	seg.name = "Segment_%d" % seg_id
	mapspawner.add_child(seg)
	var tiles := Node2D.new(); tiles.name = "Tiles"; seg.add_child(tiles)
	var enemies := Node2D.new(); enemies.name = "Enemies"; seg.add_child(enemies)

	# 把 MapSpawner 的生成根切到这两个容器
	mapspawner.set_spawn_roots(tiles, enemies)

	# 对齐本段起点：竖向 y 继续累加；竖向 x 用上次横向锁定的锚点
	mapdecider.off_set_x = 16           # 竖向阶段内部会用到（横向前会被覆盖成 vertical_origin_x）
	mapdecider.off_set_y = _next_start_y
	mapdecider.set_vertical_origin_x(_next_anchor_x)

	# 生成这整段（竖 + 横 + 锁）
	await spawn_one_segment_async(first)

	# 把 MapSpawner 的生成根还原，避免后面生成跑到段容器外
	mapspawner.set_spawn_roots()

	# 记录段的 y 范围
	var b: Vector2 = _compute_segment_bounds(seg)
	_loaded_info[seg_id] = {"root": seg, "ymin": b.x, "ymax": b.y}
	_loaded_order.append(seg_id)

	# 下一段起点：
	# - y: 直接用 mapdecider.off_set_y（已经累加到这段末尾）
	# - x: 用横向锁好的 vertical_origin_x（就是“最后一块的起点 x”）
	_next_start_y = mapdecider.off_set_y
	_next_anchor_x = mapdecider.vertical_origin_x

	# 设置“进入新段顶部即删旧段”的计划：阈值 = 新段顶部 ymin
	if prev_id != -1:
		_pending_delete_old_id = prev_id
		_pending_threshold_y = b.x

	_segments_built += 1
	_building = false

# 接近段底部，就开建下一段（异步分帧，玩家基本感觉不到卡）
func _maybe_build_next() -> void:
	if _loaded_order.size() == 0 or _building:
		return
	if _segments_built >= MAX_SEGMENTS:
		return
	var cur_id: int = _loaded_order.back()
	var info: Dictionary = _loaded_info[cur_id] as Dictionary
	var ymax: float = float(info["ymax"])
	if player.global_position.y > (ymax - float(BUILD_TRIGGER_MARGIN)):
		_build_segment_async(false)

# 玩家一旦进入新段顶部（y >= 阈值），立即把上一段删掉，保证场上几乎只有当前段
func _maybe_delete_old_on_enter_new() -> void:
	if _pending_delete_old_id == -1:
		return
	if player.global_position.y >= _pending_threshold_y:
		var old_id: int = _pending_delete_old_id
		if _loaded_info.has(old_id):
			var root := _loaded_info[old_id]["root"] as Node
			if root != null:
				root.queue_free()
			_loaded_info.erase(old_id)
		if _loaded_order.size() > 1:
			_loaded_order.pop_front()
		_pending_delete_old_id = -1
		_pending_threshold_y = INF

# ===== 开场动画（原逻辑，略） =====
const bullet : PackedScene = preload("res://Scenes/bullets/basic_bullet.tscn")

func _on_start_button_pressed() -> void:
	StartUI.hide()
	SoundManager.play_sound("UI_SELECT")
	SoundManager.stop_sound("start_intro")
	opening_hatch.show()
	await get_tree().create_timer(0.5).timeout
	if camera != null:
		camera.add_trauma(0.3)
	for i in 10:
		await get_tree().create_timer(0.1).timeout
		SoundManager.play_sound("shoot", 1, false)
		var tempb := bullet.instantiate()
		tempb.global_position = Vector2(110, -200)
		add_child(tempb)
	await get_tree().create_timer(1).timeout
	player.start_game()
	SoundManager.play_sound("intro", 1, true)

func smooth_switch(camera_node: Node) -> void:
	var tween := create_tween()
	tween.tween_property(camera_node, "global_position", player.global_position, 0.5)
	tween.finished.connect(player.start_game)
