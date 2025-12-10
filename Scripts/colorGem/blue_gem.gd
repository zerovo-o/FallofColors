extends Node2D
var player 
var is_active = false
@export var max_distance : float = 1000
@export var attraction_speed : float = 200
@export var pick_up_distance : float = 6

@onready var anim : AnimationPlayer = $AnimationPlayer
@onready var glow_sprite : Sprite2D = $Glow  # 发光精灵引用
@onready var main_sprite : Sprite2D = $Sprite2D  # 主精灵引用

# 发光效果变量
var glow_time = 0.0
var glow_speed = 3.0

# 粒子效果
var particles: GPUParticles2D
var bubble_particles: CPUParticles2D  # 呼吸泡泡效果

# 蓝色调效果状态
var blue_effect_active = false

func _ready():
	# 创建粒子效果
	create_particles()
	create_bubble_particles()  # 创建呼吸泡泡效果
	
	# 启动旋转动画
	rotate_gem()
	
	# 调整蓝宝石大小和颜色
	if main_sprite != null:
		main_sprite.scale = Vector2(1.0, 1.0)
	if glow_sprite != null:
		glow_sprite.scale = Vector2(2.0, 2.0)  # 进一步调整发光效果大小
		glow_sprite.modulate = Color(0.0, 0.5, 1.0, 0.8)  # 蓝色发光，减少透明度

func _physics_process(delta):
	if is_active and player != null:
		var dir = player.global_position - global_position
		var dis : float = dir.length()
		
		if dis > pick_up_distance and dis <= max_distance:
			dir = dir.normalized()
			var movement = dir * attraction_speed * delta 
			global_position += movement
			
		if dis <= pick_up_distance:
			# 拾取蓝宝石时触发蓝色调效果
			trigger_blue_effect()
			Pooler.gem_collected.emit(15)  # 蓝宝石价值15个普通宝石
			Pooler.return_gem(self)
			is_active = false
		elif dis > max_distance:
			Pooler.return_gem(self)
			print("lost it")
	
	# 更新发光效果
	update_glow_effect(delta)

# 发光效果函数
func update_glow_effect(delta):
	# 只有当存在发光精灵时才更新效果
	if glow_sprite != null:
		glow_time += delta * glow_speed
		# 使用正弦波创建脉动效果
		var glow_intensity : float = (sin(glow_time) + 1) * 0.5  # 范围 0-1
		
		# 添加额外的闪烁效果
		var flicker = sin(glow_time * 8) * 0.2  # 更快更明显的闪烁
		
		# 结合两种效果
		var combined_glow = glow_intensity + flicker
		
		var alpha : float = 0.6 + combined_glow * 0.4  # alpha在0.6-1.0之间变化
		glow_sprite.modulate.a = alpha
		
		# 轻微改变发光精灵的缩放以创建脉动效果
		var scale_factor : float = 1.8 + combined_glow * 0.5  # 缩放在1.8-2.3之间变化
		glow_sprite.scale = Vector2(scale_factor, scale_factor)
		
		# 添加颜色变化效果 - 始终保持蓝色
		glow_sprite.modulate.r = 0.0
		glow_sprite.modulate.g = 0.5
		glow_sprite.modulate.b = 1.0

# 旋转宝石动画
func rotate_gem():
	var rotation_time = 0.0
	var base_rotation_speed = 0.03
	var pulse_speed = 0.08
	
	while true:
		# 检查节点是否仍在场景树中
		if get_tree() == null:
			break
			
		rotation_time += 0.016  # 约60 FPS
		
		if main_sprite != null:
			# 基础旋转加上脉冲效果
			var pulse = sin(rotation_time * pulse_speed) * 0.02
			main_sprite.rotation += base_rotation_speed + pulse
			
		if glow_sprite != null:
			# 发光精灵反向旋转，加上脉冲效果
			var pulse = sin(rotation_time * pulse_speed * 2.0) * 0.01
			glow_sprite.rotation -= base_rotation_speed * 0.8 + pulse
			
		# 检查节点是否仍在场景树中
		if get_tree() == null:
			break
			
		await get_tree().create_timer(0.016).timeout  # 约60 FPS
		
		# 同时更新呼吸效果
		update_breathing_effect()

func _on_area_2d_area_entered(area):
	if area != null:
		var area_parent = area.get_parent()
		if area_parent != null:
			player = area_parent
			is_active = true
			if anim != null:
				anim.play("coinspin")

# 创建粒子效果
func create_particles():
	particles = GPUParticles2D.new()
	particles.position = Vector2(0, 0)
	particles.name = "BlueGemParticles"
	
	# 创建粒子材质
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, -1, 0)  # 向上发射
	particle_material.spread = 80  # 增加发射角度
	particle_material.gravity = Vector3(0, -80, 0)  # 调整重力
	particle_material.initial_velocity_min = 30.0  # 修复窄化转换问题：使用浮点数
	particle_material.initial_velocity_max = 120.0  # 修复窄化转换问题：使用浮点数
	particle_material.angular_velocity_min = -500.0  # 修复窄化转换问题：使用浮点数
	particle_material.angular_velocity_max = 500.0  # 修复窄化转换问题：使用浮点数
	particle_material.scale_curve = null
	particle_material.color = Color(0.0, 0.5, 1.0, 1)  # 蓝色，不透明
	particle_material.color_ramp = null
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE  # 改为球形发射
	particle_material.emission_sphere_radius = 15.0  # 设置球形半径
	particle_material.particle_flag_align_y = true
	
	# 如果你有星星形状的粒子纹理，可以在这里设置
	# particle_material.texture = preload("res://Art/glint.png")
	
	particles.process_material = particle_material
	particles.lifetime = 4.0  # 延长生命周期
	particles.amount = 80  # 增加粒子数量
	particles.emitting = false  # 默认不发射，只在特殊时刻发射
	particles.visibility_rect = Rect2(-150, -150, 300, 300)  # 扩大可视区域
	particles.scale = Vector2(1.5, 1.5)  # 调整粒子大小
	
	add_child(particles)

# 创建呼吸泡泡效果
func create_bubble_particles():
	bubble_particles = CPUParticles2D.new()
	bubble_particles.name = "BreathingBubbles"
	bubble_particles.position = Vector2(0, 0)
	bubble_particles.amount = 30  # 增加粒子数量
	bubble_particles.lifetime = 5.0  # 延长生命周期
	bubble_particles.one_shot = false
	bubble_particles.preprocess = 0.0
	bubble_particles.speed_scale = 1.0
	bubble_particles.explosiveness = 0.0
	bubble_particles.randomness = 1.0  # 最大随机性
	bubble_particles.fixed_fps = 0.0
	bubble_particles.fract_delta = true
	bubble_particles.local_coords = true
	
	# 发射形状
	bubble_particles.emitting = true
	bubble_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE  # 改为球形发射
	bubble_particles.emission_sphere_radius = 20.0  # 增大球形半径
	
	# 粒子参数
	bubble_particles.direction = Vector2(0, -1)
	bubble_particles.spread = 90  # 增加扩散角度
	
	# 重力
	bubble_particles.gravity = Vector2(0, -30)  # 调整重力
	
	# 初始速度
	bubble_particles.set_param_min(CPUParticles2D.PARAM_INITIAL_LINEAR_VELOCITY, 5.0)
	bubble_particles.set_param_max(CPUParticles2D.PARAM_INITIAL_LINEAR_VELOCITY, 60.0)  # 增加最大速度差异
	
	# 线性加速度
	bubble_particles.set_param_min(CPUParticles2D.PARAM_LINEAR_ACCEL, -20.0)  # 添加负加速度
	bubble_particles.set_param_max(CPUParticles2D.PARAM_LINEAR_ACCEL, 20.0)
	
	# 径向加速度
	bubble_particles.set_param_min(CPUParticles2D.PARAM_RADIAL_ACCEL, -10.0)
	bubble_particles.set_param_max(CPUParticles2D.PARAM_RADIAL_ACCEL, 10.0)
	
	# 切向加速度
	bubble_particles.set_param_min(CPUParticles2D.PARAM_TANGENTIAL_ACCEL, -10.0)
	bubble_particles.set_param_max(CPUParticles2D.PARAM_TANGENTIAL_ACCEL, 10.0)
	
	# 角速度
	bubble_particles.set_param_min(CPUParticles2D.PARAM_ANGULAR_VELOCITY, -200.0)
	bubble_particles.set_param_max(CPUParticles2D.PARAM_ANGULAR_VELOCITY, 200.0)
	
	# 颜色 - 创建颜色渐变效果
	var color_ramp = Gradient.new()
	color_ramp.set_color(0, Color(0.0, 0.5, 1.0, 1))  # 起始为蓝色不透明
	color_ramp.set_color(0.5, Color(0.0, 0.5, 1.0, 0.8))  # 中间为蓝色半透明
	color_ramp.set_color(1, Color(0.0, 0.5, 1.0, 0))  # 结束为蓝色透明
	bubble_particles.color = Color(0.0, 0.5, 1.0, 1)  # 基础颜色为蓝色不透明
	
	# 尺寸 - 创建大小变化效果，让粒子有大有小
	bubble_particles.set_param_min(CPUParticles2D.PARAM_SCALE, 0.1)  # 最小尺寸更小
	bubble_particles.set_param_max(CPUParticles2D.PARAM_SCALE, 2.0)  # 最大尺寸更大
	
	# 混合模式
	bubble_particles.draw_order = CPUParticles2D.DRAW_ORDER_INDEX
	
	add_child(bubble_particles)
	
	# 启动呼吸动画
	start_breathing_animation()

# 启动呼吸动画
func start_breathing_animation():
	if bubble_particles == null:
		return

	# 创建一个周期性的动画来控制泡泡的呼吸效果
	var breathing_timer = Timer.new()
	breathing_timer.name = "BreathingTimer"
	breathing_timer.wait_time = 0.5
	breathing_timer.autostart = true
	breathing_timer.one_shot = false
	breathing_timer.connect("timeout", Callable(self, "update_breathing_effect"))
	add_child(breathing_timer)

# 更新呼吸效果
func update_breathing_effect():
	if bubble_particles == null:
		return

	# 使用时间创建更复杂的呼吸效果
	var time = float(Time.get_ticks_msec()) / 1000.0
	var breath = sin(time * 4.0) * 0.4 + 0.6  # 更快的呼吸频率，范围 0.2-1.0
	
	# 添加额外的波动效果
	var pulse = sin(time * 10.0) * 0.2 + 0.2  # 更快的脉冲效果
	
	# 结合两种效果
	var combined_effect = breath + pulse

	# 更新粒子参数以创建呼吸效果
	# 修复窄化转换问题：显式转换为float类型
	var scale_value : float = 0.8 + combined_effect * 1.2
	bubble_particles.set_param_min(CPUParticles2D.PARAM_SCALE, scale_value * 0.3)  # 最小尺寸
	bubble_particles.set_param_max(CPUParticles2D.PARAM_SCALE, scale_value * 2.5)  # 最大尺寸

	var alpha : float = 0.6 + combined_effect * 0.4
	bubble_particles.color = Color(0.0, 0.5, 1.0, alpha)  # 蓝色

# 触发蓝色调效果
func trigger_blue_effect():
	# 启动粒子效果
	if particles != null:
		particles.emitting = true
		# 检查节点是否仍在场景树中
		if get_tree() != null:
			# 1秒后停止发射
			await get_tree().create_timer(1.0).timeout
		particles.emitting = false

	# 设置持续的蓝色调效果
	blue_effect_active = true
	apply_persistent_blue_effect()

	# 同时播放一次性全屏蓝色调效果
	play_fullscreen_blue_effect()

	# 添加屏幕震动效果
	if get_tree() != null:
		var master = get_tree().root.get_node("Master")
		if master != null and master.camera != null:
			master.camera.add_trauma(0.6)

	# 播放特殊音效
	SoundManager.play_sound("powerup", 1.0, false)

# 应用持续的蓝色调效果
func apply_persistent_blue_effect():
	# 检查节点是否仍在场景树中
	if get_tree() == null:
		return
		
	# 获取主场景
	var root = get_tree().root

	# 移除其他可能存在的调制效果
	remove_other_modulates()

	# 创建或更新场景着色效果
	var blue_modulate = root.get_node_or_null("BlueModulate")
	if blue_modulate == null:
		blue_modulate = CanvasModulate.new()
		blue_modulate.name = "BlueModulate"
		blue_modulate.color = Color(0.7, 0.7, 1.0, 1.0)  # 蓝色调
		root.add_child(blue_modulate)
	else:
		blue_modulate.color = Color(0.7, 0.7, 1.0, 1.0)

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

# 播放一次性全屏蓝色调效果
func play_fullscreen_blue_effect():
	# 检查节点是否仍在场景树中
	if get_tree() == null:
		return
		
	# 创建一个全屏的蓝色调效果
	var blue_overlay = ColorRect.new()
	blue_overlay.color = Color(0.7, 0.7, 1.0, 0.9)  # 蓝色调，高透明度
	blue_overlay.anchor_right = 1
	blue_overlay.anchor_bottom = 1
	blue_overlay.z_index = 100  # 确保在最上层
	blue_overlay.name = "BlueScreenEffect"

	# 添加到场景树
	get_tree().root.add_child(blue_overlay)

	# 创建动画淡出效果
	var tween = create_tween()
	tween.tween_property(blue_overlay, "color", Color(0.7, 0.7, 1.0, 0), 4.0)  # 更慢的淡出效果
	tween.tween_callback(blue_overlay.queue_free)
