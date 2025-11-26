extends Node

# 完整彩虹效果管理器
# 负责管理游戏中所有与完整彩虹色相关的视觉效果

var rainbow_effect_active = false
var rainbow_modulate: CanvasModulate = null

# 不同类型的节点颜色调整
const BACKGROUND_RAINBOW = Color(1.0, 1.0, 1.0, 1.0) 
const BLOCK_RAINBOW = Color(0.9, 0.9, 0.9, 0.7)
const ENEMY_RAINBOW = Color(0.7, 0.7, 0.7, 1.0) 

func _ready():
	# 初始化为默认状态
	rainbow_effect_active = false
	if rainbow_modulate != null:
		rainbow_modulate.queue_free()
		rainbow_modulate = null
	
	# 监听彩色宝石收集事件
	Pooler.gem_collected.connect(_on_gem_collected)

func _on_gem_collected(value: int):
	# 如果是彩色宝石（价值20个普通宝石）
	if value == 20:
		activate_rainbow_effect()

# 激活彩虹效果
func activate_rainbow_effect():
	rainbow_effect_active = true
	apply_scene_rainbow_tint()

# 应用场景彩虹色调
func apply_scene_rainbow_tint():
	# 创建或更新场景着色效果
	if get_tree() == null:
		return
	var root = get_tree().root
	# 移除其他可能存在的调制效果
	remove_other_modulates()
	
	if rainbow_modulate == null:
		rainbow_modulate = CanvasModulate.new()
		rainbow_modulate.name = "RainbowModulate"
		rainbow_modulate.color = BACKGROUND_RAINBOW
		root.add_child(rainbow_modulate)
	else:
		rainbow_modulate.color = BACKGROUND_RAINBOW

# 移除其他调制效果
func remove_other_modulates():
	var root = get_tree().root
	# 移除红色调制
	var red_modulate = root.get_node_or_null("RedModulate")
	if red_modulate != null:
		red_modulate.queue_free()
	# 移除黄色调制
	var yellow_modulate = root.get_node_or_null("YellowModulate")
	if yellow_modulate != null:
		yellow_modulate.queue_free()
	# 移除蓝调制
	var blue_modulate = root.get_node_or_null("BlueModulate")
	if blue_modulate != null:
		blue_modulate.queue_free()
	# 移除绿色调制
	var green_modulate = root.get_node_or_null("GreenModulate")
	if green_modulate != null:
		green_modulate.queue_free()

# 重置场景颜色为原始颜色
func reset_scene_colors():
	rainbow_effect_active = false
	# 移除彩虹效果
	if rainbow_modulate != null:
		if is_instance_valid(rainbow_modulate):
			rainbow_modulate.queue_free()
		rainbow_modulate = null

# 更新特定类型节点的颜色
func update_node_colors(node_type: String, parent_node: Node):
	if not rainbow_effect_active:
		return
	
	match node_type:
		"block":
			# 更新方块颜色
			_update_children_color(parent_node, BLOCK_RAINBOW)
		"enemy":
			# 更新敌人颜色
			_update_children_color(parent_node, ENEMY_RAINBOW)

# 递归更新子节点颜色
func _update_children_color(parent: Node, color: Color):
	for child in parent.get_children():
		# 跳过角色节点和特定方块节点
		if child.name == "Player" or child.name == "Spike" or child.name == "Spike_Block" :
			continue
			
		if child is Sprite2D:
			# 检查是否是紫色方块或平台，如果是则跳过
			if child.name == "PurpleBlock" or child.name == "PurplePlatform":
				continue
				
			child.modulate = color
		elif child.get_child_count() > 0:
			_update_children_color(child, color)