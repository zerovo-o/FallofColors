extends Control

# delay-instancing decorative gems to avoid blocking on scene load
var RedGemScene = preload("res://Scenes/colorGem/red_gem.tscn")
var BlueGemScene = preload("res://Scenes/colorGem/blue_gem.tscn")
var YellowGemScene = preload("res://Scenes/colorGem/yellow_gem.tscn")
var GreenGemScene = preload("res://Scenes/colorGem/green_gem.tscn")

@onready var blackoutpane : Panel = $BlackOut

func _ready():
	fade_out()
	# 延迟实例化装饰性宝石，避免阻塞启动
	spawn_decorative_gems()

func _on_start_button_focus_entered():
	SoundManager.play_sound("UI_move")


func fade_out():
	await get_tree().create_timer(0.5).timeout
	var tween = create_tween()
	tween.tween_property(blackoutpane, "modulate:a", 0.0, 0.5)
	set_focus()


func _on_start_button_focus_exited():
	SoundManager.play_sound("UI_move")

func set_focus():
	var container : VBoxContainer = $Panel/MarginContainer/VBoxContainer
	var first_button : Button = container.get_child(0)
	if first_button is BaseButton:
		first_button.grab_focus()

func spawn_decorative_gems() -> void:
	# 在 idle 时延迟少量时间再实例化（非阻塞）
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout

	var parent = $Panel.get_node_or_null("DecorativeGems")
	if parent == null:
		parent = $Panel

	var r = RedGemScene.instantiate()
	r.position = Vector2(370, 300)
	r.scale = Vector2(0.45, 0.45)
	parent.add_child(r)

	var b = BlueGemScene.instantiate()
	b.position = Vector2(600, 300)
	b.scale = Vector2(0.45, 0.45)
	parent.add_child(b)

	var y = YellowGemScene.instantiate()
	y.position = Vector2(300, 340)
	y.scale = Vector2(0.45, 0.45)
	parent.add_child(y)

	var g = GreenGemScene.instantiate()
	g.position = Vector2(680, 340)
	g.scale = Vector2(0.45, 0.45)
	parent.add_child(g)
