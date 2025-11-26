extends Node

# 暖色调效果管理器
# 负责管理游戏中所有与暖色调相关的视觉效果

var warm_effect_active = false
var warm_modulate: CanvasModulate = null

# 不同类型的节点颜色调整
const BACKGROUND_WARM = Color(1.2, 0.8, 0.4, 1.0) 
const BLOCK_WARM = Color(0.9, 0.7, 0.5, 0.6)
const ENEMY_WARM = Color(0.7, 0.4, 0.0, 1.0) 

func _ready():
	# 初始化为默认状态
	warm_effect_active = false
	if warm_modulate != null:
		warm_modulate.queue_free()
		warm_modulate = null
	
	# 监听黄宝石收集事件
	Pooler.gem_collected.connect(_on_gem_collected)

func _on_gem_collected(value: int):
	# 如果是黄宝石（价值10个普通宝石）
	if value == 10:
		activate_warm_effect()

# 激活暖色调效果
func activate_warm_effect():
	warm_effect_active = true
	apply_scene_warm_tint()

# 应用场景暖色调
func apply_scene_warm_tint():
	# 创建或更新场景着色效果
	if get_tree() == null:
		return
	var root = get_tree().root
	# 移除其他可能存在的调制效果
	remove_other_modulates()
	
	if warm_modulate == null:
		warm_modulate = CanvasModulate.new()
		warm_modulate.name = "YellowModulate"
		warm_modulate.color = BACKGROUND_WARM
		root.add_child(warm_modulate)
	else:
		warm_modulate.color = BACKGROUND_WARM

# 移除其他调制效果
func remove_other_modulates():
	var root = get_tree().root
	# 移除红色调制
	var red_modulate = root.get_node_or_null("RedModulate")
	if red_modulate != null:
		red_modulate.queue_free()
	# 移除蓝调制
	var blue_modulate = root.get_node_or_null("BlueModulate")
	if blue_modulate != null:
		blue_modulate.queue_free()
	# 移除绿色调制
	var green_modulate = root.get_node_or_null("GreenModulate")
	if green_modulate != null:
		green_modulate.queue_free()
	# 移除彩虹调制
	var rainbow_modulate = root.get_node_or_null("RainbowModulate")
	if rainbow_modulate != null:
		rainbow_modulate.queue_free()

# 重置场景颜色为原始颜色
func reset_scene_colors():
	warm_effect_active = false
	# 移除暖色调效果
	if warm_modulate != null:
		if is_instance_valid(warm_modulate):
			warm_modulate.queue_free()
		warm_modulate = null

# 更新特定类型节点的颜色
func update_node_colors(node_type: String, parent_node: Node):
	if not warm_effect_active:
		return
	
	# 跳过带有"gem_ignore_modulate"组标记的节点
	if parent_node.is_in_group("gem_ignore_modulate"):
		return
	
	match node_type:
		"block":
			# 更新方块颜色
			_update_children_color(parent_node, BLOCK_WARM)
		"enemy":
			# 更新敌人颜色
			_update_children_color(parent_node, ENEMY_WARM)

# 递归更新子节点颜色
func _update_children_color(parent: Node, color: Color):
	for child in parent.get_children():
		# 跳过角色节点和特定方块节点
		if child.name == "Player" or child.name == "Spike" or child.name == "Spike_Block" :
			continue
			
		# 跳过带有"gem_ignore_modulate"组标记的节点
		if child.is_in_group("gem_ignore_modulate"):
			continue
			
		if child is Sprite2D:
			# 检查是否是紫色方块或平台，如果是则跳过
			if child.name == "PurpleBlock" or child.name == "PurplePlatform":
				continue
				
			child.modulate = color
		elif child.get_child_count() > 0:
			_update_children_color(child, color)