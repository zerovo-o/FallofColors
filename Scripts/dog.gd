
extends "res://Scripts/turtle.gd"

signal touched_player


var _triggered := false

func _ready() -> void:
	# 保留海龟初始化
	super._ready()
	# 连接所有 Area2D 的 body_entered 和 area_entered（防止节点名不一致导致没连上）
	_connect_all_areas(self)
	print("[Dog] ready, areas connected")


	# 让狗不具备“伤害玩家”的碰撞：关闭两块 HurtArea2D
	if has_node("HurtArea2D"):
		var h1 := $HurtArea2D as Area2D
		h1.monitorable = false
		h1.monitoring = false
		h1.collision_layer = 0
		h1.collision_mask = 0
	if has_node("HurtArea2D2"):
		var h2 := $HurtArea2D2 as Area2D
		h2.monitorable = false
		h2.monitoring = false
		h2.collision_layer = 0
		h2.collision_mask = 0


# 递归连接所有 Area2D 的两个信号
func _connect_all_areas(n: Node) -> void:
	for c in n.get_children():
		if c is Area2D:
			var a := c as Area2D
			if not a.is_connected("body_entered", Callable(self, "_on_any_body_entered")):
				a.body_entered.connect(_on_any_body_entered)
			if not a.is_connected("area_entered", Callable(self, "_on_any_area_entered")):
				a.area_entered.connect(_on_any_area_entered)
		if c.get_child_count() > 0:
			_connect_all_areas(c)

func _on_any_body_entered(body: Node) -> void:
	if _triggered:
		return
	if _is_player_related(body):
		_triggered = true
		print("[Dog] body_entered by Player -> emit touched_player")
		touched_player.emit()

func _on_any_area_entered(area: Area2D) -> void:
	if _triggered:
		return
	if _is_player_related(area):
		_triggered = true
		print("[Dog] area_entered by Player -> emit touched_player")
		touched_player.emit()

# 更稳的玩家识别：类型 / 分组 / 名称 / 向上爬祖先
func _is_player_related(node: Node) -> bool:
	if node == null:
		return false
	# 1) 类型（你的工程里 Master 用过 PlayerMasterAndMover，通常是 class_name 导出）
	if node is PlayerMasterAndMover:
		return true
	# 2) 分组（如果你的 Player 在 "Player" 组里，会更稳）
	if node.has_method("is_in_group") and node.is_in_group("Player"):
		return true
	# 3) 名称（顶层节点名一般就是 "Player"）
	if node.name == "Player":
		return true
	# 4) 向上找祖先，最多爬 6 层
	var cur := node.get_parent()
	var depth := 0
	while cur != null and depth < 6:
		if cur is PlayerMasterAndMover:
			return true
		if cur.has_method("is_in_group") and cur.is_in_group("Player"):
			return true
		if cur.name == "Player":
			return true
		cur = cur.get_parent()
		depth += 1
	return false


# Scripts/dog.gd
func _on_bounce_area_2d_area_entered(area: Area2D) -> void:
	# 狗不可被踩死：吞掉父类(turtle.gd)的伤害逻辑
	pass
