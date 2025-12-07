extends Node

# 绿色调效果管理器
# 负责管理游戏中所有与绿色调相关的视觉效果

var green_effect_active = false
var green_modulate: CanvasModulate = null

# 不同类型的节点颜色调整
const BACKGROUND_GREEN = Color(0.65, 1.2, 0.617, 0.435) 
const BLOCK_GREEN = Color(0.322, 0.933, 0.078, 0.718)
const ENEMY_GREEN = Color(0.847, 0.71, 0.047, 0.835) 

func _ready():
	# 初始化为默认状态
	green_effect_active = false
	if green_modulate != null:
		green_modulate.queue_free()
		green_modulate = null
	
	# 监听绿宝石收集事件
	Pooler.gem_collected.connect(_on_gem_collected)

func _on_gem_collected(value: int):
	# 如果是绿宝石（价值20个普通宝石）
	if value == 20:
		activate_green_effect()

# 激活绿色调效果
func activate_green_effect():
	green_effect_active = true
	apply_scene_green_tint()

# 应用场景绿色调
func apply_scene_green_tint():
	# 创建或更新场景着色效果
	if get_tree() == null:
		return
	var root = get_tree().root
	# 移除其他可能存在的调制效果
	remove_other_modulates()
	
	if green_modulate == null:
		green_modulate = CanvasModulate.new()
		green_modulate.name = "GreenModulate"
		green_modulate.color = BACKGROUND_GREEN
		root.add_child(green_modulate)
	else:
		green_modulate.color = BACKGROUND_GREEN

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
	# 移除彩虹调制
	var rainbow_modulate = root.get_node_or_null("RainbowModulate")
	if rainbow_modulate != null:
		rainbow_modulate.queue_free()

# 重置场景颜色为原始颜色
func reset_scene_colors():
	green_effect_active = false
	# 移除绿色调效果
	if green_modulate != null:
		if is_instance_valid(green_modulate):
			green_modulate.queue_free()
		green_modulate = null

# 更新特定类型节点的颜色
func update_node_colors(node_type: String, parent_node: Node):
	if not green_effect_active:
		return
	
	match node_type:
		"block":
			# 更新方块颜色
			pass  # 已删除 _update_children_color 函数
		"enemy":
			# 更新敌人颜色
			pass  # 已删除 _update_children_color 函数
