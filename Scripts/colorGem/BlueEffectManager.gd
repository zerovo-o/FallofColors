extends Node

# 蓝色调效果管理器
# 负责管理游戏中所有与蓝色调相关的视觉效果

var blue_effect_active = false
var blue_modulate: CanvasModulate = null

# 不同类型的节点颜色调整
const BACKGROUND_BLUE = Color(0.176, 0.729, 0.941, 0.635) 
const BLOCK_BLUE = Color(0.157, 0.494, 1.0, 0.576)
const ENEMY_BLUE = Color(0.11, 0.424, 0.976, 0.769) 

func _ready():
	# 初始化为默认状态
	blue_effect_active = false
	if blue_modulate != null:
		blue_modulate.queue_free()
		blue_modulate = null
	
	# 监听蓝宝石收集事件
	Pooler.gem_collected.connect(_on_gem_collected)

func _on_gem_collected(value: int):
	# 如果是蓝宝石（价值15个普通宝石）
	if value == 15:
		activate_blue_effect()

# 激活蓝色调效果
func activate_blue_effect():
	blue_effect_active = true
	apply_scene_blue_tint()

# 应用场景蓝色调
func apply_scene_blue_tint():
	# 创建或更新场景着色效果
	if get_tree() == null:
		return
	var root = get_tree().root
	# 移除其他可能存在的调制效果
	remove_other_modulates()
	
	if blue_modulate == null:
		blue_modulate = CanvasModulate.new()
		blue_modulate.name = "BlueModulate"
		blue_modulate.color = BACKGROUND_BLUE
		root.add_child(blue_modulate)
	else:
		blue_modulate.color = BACKGROUND_BLUE

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
	blue_effect_active = false
	# 移除蓝色调效果
	if blue_modulate != null:
		if is_instance_valid(blue_modulate):
			blue_modulate.queue_free()
		blue_modulate = null

# 更新特定类型节点的颜色
func update_node_colors(node_type: String, parent_node: Node):
	if not blue_effect_active:
		return
	
	match node_type:
		"block":
			# 更新方块颜色
			pass  # 已删除 _update_children_color 函数
		"enemy":
			# 更新敌人颜色
			pass  # 已删除 _update_children_color 函数
