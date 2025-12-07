extends Node

# 红色调效果管理器
# 负责管理游戏中所有与红色调相关的视觉效果

var red_effect_active = false
var red_modulate: CanvasModulate = null

# 不同类型的节点颜色调整
const BACKGROUND_RED = Color(1.0, 0.204, 0.22, 0.424) 
const BLOCK_RED = Color(0.973, 0.188, 0.204, 0.58)
const ENEMY_RED = Color(0.713, 0.0, 0.006, 0.596) 

func _ready():
	# 初始化为默认状态
	red_effect_active = false
	if red_modulate != null:
		red_modulate.queue_free()
		red_modulate = null
	
	# 监听红宝石收集事件
	Pooler.gem_collected.connect(_on_gem_collected)

func _on_gem_collected(value: int):
	# 如果是红宝石（价值5个普通宝石）
	if value == 5:
		activate_red_effect()

# 激活红色调效果
func activate_red_effect():
	red_effect_active = true
	apply_scene_red_tint()

# 应用场景红色调
func apply_scene_red_tint():
	# 创建或更新场景着色效果
	if get_tree() == null:
		return
	var root = get_tree().root
	# 移除其他可能存在的调制效果
	remove_other_modulates()
	
	if red_modulate == null:
		red_modulate = CanvasModulate.new()
		red_modulate.name = "RedModulate"
		red_modulate.color = BACKGROUND_RED
		root.add_child(red_modulate)
	else:
		red_modulate.color = BACKGROUND_RED

# 移除其他调制效果
func remove_other_modulates():
	var root = get_tree().root
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
	# 移除彩虹调制
	var rainbow_modulate = root.get_node_or_null("RainbowModulate")
	if rainbow_modulate != null:
		rainbow_modulate.queue_free()

# 重置场景颜色为原始颜色
func reset_scene_colors():
	red_effect_active = false
	# 移除红色调效果
	if red_modulate != null:
		if is_instance_valid(red_modulate):
			red_modulate.queue_free()
		red_modulate = null

# 更新特定类型节点的颜色
func update_node_colors(node_type: String, parent_node: Node):
	if not red_effect_active:
		return
	
	match node_type:
		"block":
			# 更新方块颜色
			pass  # 已删除 _update_children_color 函数
		"enemy":
			# 更新敌人颜色
			pass  # 已删除 _update_children_color 函数
