extends Node

# Full rainbow effect manager
# Manages all scene-wide visuals related to full rainbow effect

var rainbow_effect_active = false
var rainbow_modulate: CanvasModulate = null

# Per-node-type tints
# MOD: make them @export for quick tuning in Inspector (minimal change)
@export var BACKGROUND_RAINBOW: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var BLOCK_RAINBOW: Color = Color(0.9, 0.9, 0.9, 0.7)
@export var ENEMY_RAINBOW: Color = Color(0.7, 0.7, 0.7, 1.0)

func _ready():
	# Initialize default state
	rainbow_effect_active = false
	if rainbow_modulate != null:
		rainbow_modulate.queue_free()
		rainbow_modulate = null
	
	# Listen to rainbow gem event
	Pooler.gem_collected.connect(_on_gem_collected)

func _on_gem_collected(value: int):
	# 20 == rainbow gem
	if value == 20:
		activate_rainbow_effect()

# Activate rainbow effect
func activate_rainbow_effect():
	rainbow_effect_active = true
	apply_scene_rainbow_tint()

# Apply scene-wide rainbow tint
func apply_scene_rainbow_tint():
	if get_tree() == null:
		return
	var root = get_tree().root
	# Remove other modulates
	remove_other_modulates()
	
	if rainbow_modulate == null:
		rainbow_modulate = CanvasModulate.new()
		rainbow_modulate.name = "RainbowModulate"
		rainbow_modulate.color = BACKGROUND_RAINBOW
		root.add_child(rainbow_modulate)
	else:
		rainbow_modulate.color = BACKGROUND_RAINBOW

# Remove other modulates
func remove_other_modulates():
	var root = get_tree().root
	var red_modulate = root.get_node_or_null("RedModulate")
	if red_modulate != null:
		red_modulate.queue_free()
	var yellow_modulate = root.get_node_or_null("YellowModulate")
	if yellow_modulate != null:
		yellow_modulate.queue_free()
	var blue_modulate = root.get_node_or_null("BlueModulate")
	if blue_modulate != null:
		blue_modulate.queue_free()
	var green_modulate = root.get_node_or_null("GreenModulate")
	if green_modulate != null:
		green_modulate.queue_free()

# Reset scene color to original
func reset_scene_colors():
	rainbow_effect_active = false
	if rainbow_modulate != null:
		if is_instance_valid(rainbow_modulate):
			rainbow_modulate.queue_free()
		rainbow_modulate = null

# Update node colors by type
func update_node_colors(node_type: String, parent_node: Node):
	if not rainbow_effect_active:
		return
	
	match node_type:
		"block":
			pass  # 已删除 _update_children_color 函数
		"enemy":
			pass  # 已删除 _update_children_color 函数