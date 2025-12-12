extends EnemyMain2

@onready var sprite : spriteEffect = $Sprite2D

var go_left : bool = true

@onready var left_ray : RayCast2D = $leftRay
@onready var right_ray : RayCast2D = $rightRay
var vertical_speed : float = 0.0
var time_changer : float = randf_range(1, 3)
var time_changer_holder = 0.0

@onready var anim : AnimationPlayer = $AnimationPlayer

func _ready():
	var speed_mod : float = randf_range(0.1, 1.5)
	anim.speed_scale = speed_mod
	speed *= speed_mod

func _physics_process(delta):
	# 垂直速度在随机时间间隔内变化（漂浮效果）
	time_changer_holder += delta
	if time_changer_holder > time_changer:
		time_changer_holder = 0
		vertical_speed = randf_range(-45, 45)

	# 如果左右射线检测到碰撞，改变移动方向
	if left_ray.is_colliding():
		go_left = false
	if right_ray.is_colliding():
		go_left = true

	# 根据 go_left 设置水平速度并翻转贴图
	if go_left:
		velocity = Vector2(-1 * speed, vertical_speed)
		$Sprite2D.flip_h = true   # 向左时水平翻转
	else:
		velocity = Vector2(1 * speed, vertical_speed)
		$Sprite2D.flip_h = false  # 向右时不翻转（原向）

	move_and_slide()

func _on_bounce_area_2d_area_entered(area):
	sprite.hitting = true
	life -= 1
	SoundManager.play_sound("bat", 1, false)
	Pooler.get_pop().global_position = global_position
	if life <= 0:
		SoundManager.play_sound("explosion", 0.1, false)
		Pooler.get_pop().global_position = global_position
		Pooler.get_gem().global_position = global_position
		queue_free()
