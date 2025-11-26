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

# 彩虹效果状态
var rainbow_effect_active = false

func _ready():
	# 创建粒子效果
	create_particles()
	create_bubble_particles()  # 创建呼吸泡泡效果
	
	# 启动旋转动画
	rotate_gem()
	
	# 调整彩色宝石大小和颜色
	if main_sprite != null:
		main_sprite.scale = Vector2(1.2, 1.2)  # 稍微大一点
	if glow_sprite != null:
		glow_sprite.scale = Vector2(2.2, 2.2)  # 进一步调整发光效果大小
		glow_sprite.modulate = Color(1.0, 1.0, 1.0, 0.8)  # 白色发光，减少透明度

func _physics_process(delta):
	if is_active and player != null:
		var dir = player.global_position - global_position
		var dis : float = dir.length()
		
		if dis > pick_up_distance and dis <= max_distance:
			dir = dir.normalized()
			var movement = dir * attraction_speed * delta 
			global_position += movement
			
		if dis <= pick_up_distance:
			# 拾取彩色宝石时触发彩虹效果
			trigger_rainbow_effect()
			Pooler.gem_collected.emit(20)  # 彩色宝石价值20个普通宝石
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
		var scale_factor : float = 2.0 + combined_glow * 0.5  # 缩放在2.0-2.5之间变化
		glow_sprite.scale = Vector2(scale_factor, scale_factor)
		
		# 添加颜色变化效果 - 彩色循环效果
		var color_time = glow_time * 2.0
		glow_sprite.modulate.r = (sin(color_time) + 1) * 0.5
		glow_sprite.modulate.g = (sin(color_time + 2.0) + 1) * 0.5
		glow_sprite.modulate.b = (sin(color_time + 4.0) + 1) * 0.5

# 旋转宝石动画
func rotate_gem():
	var rotation_time = 0.0
	var base_rotation_speed = 0.04  # 稍快一点
	var pulse_speed = 0.1
	
	while true:
		# 检查节点是否仍在场景树中
		if get_tree() == null:
			break
			
		rotation_time += 0.016  # 约60 FPS
		
		if main_sprite != null:
			# 基础旋转加上脉冲效果
			var pulse = sin(rotation_time * pulse_speed) * 0.03
			main_sprite.rotation += base_rotation_speed + pulse
			
		if glow_sprite != null:
			# 发光精灵反向旋转，加上脉冲效果
			var pulse = sin(rotation_time * pulse_speed * 2.0) * 0.02
			glow_sprite.rotation -= base_rotation_speed * 0.9 + pulse
			
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
	particles.name = "RainbowGemParticles"
	
	# 创建粒子材质
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, -1, 0)  # 向上发射
	particle_material.spread = 90  # 增加发射角度
	particle_material.gravity = Vector3(0, -100, 0)  # 调整重力
	particle_material.initial_velocity_min = 40.0  # 修复窄化转换问题：使用浮点数
	particle_material.initial_velocity_max = 150.0  # 修复窄化转换问题：使用浮点数
	particle_material.angular_velocity_min = -600.0  # 修复窄化转换问题：使用浮点数
	particle_material.angular_velocity_max = 600.0  # 修复窄化转换问题：使用浮点数
	particle_material.scale_curve = null
	particle_material.color = Color(1.0, 1.0, 1.0, 1)  # 白色，不透明
	particle_material.color_ramp = null
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE  # 改为球形发射
	particle_material.emission_sphere_radius = 20.0  # 设置球形半径
	particle_material.particle_flag_align_y = true
	
	# 如果你有星星形状的粒子纹理，可以在这里设置
	# particle_material.texture = preload("res://Art/glint.png")
	
	particles.process_material = particle_material
	particles.lifetime = 5.0  # 延长生命周期
	particles.amount = 100  # 增加粒子数量
	particles.emitting = false  # 默认不发射，只在特殊时刻发射
	particles.visibility_rect = Rect2(-200, -200, 400, 400)  # 扩大可视区域
	particles.scale = Vector2(2.0, 2.0)  # 调整粒子大小
	
	add_child(particles)

# 创建呼吸泡泡效果
func create_bubble_particles():
	bubble_particles = CPUParticles2D.new()
	bubble_particles.name = "BreathingBubbles"
	bubble_particles.position = Vector2(0, 0)
	bubble_particles.amount = 40  # 增加粒子数量
	bubble_particles.lifetime = 6.0  # 延长生命周期
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
	bubble_particles.emission_sphere_radius = 25.0  # 增大球形半径
	
	# 粒子参数
	bubble_particles.direction = Vector2(0, -1)
	bubble_particles.spread = 100  # 增加扩散角度
	
	# 重力
	bubble_particles.gravity = Vector2(0, -40)  # 调整重力
	
	# 初始速度
	bubble_particles.set_param_min(CPUParticles2D.PARAM_INITIAL_LINEAR_VELOCITY, 8.0)
	bubble_particles.set_param_max(CPUParticles2D.PARAM_INITIAL_LINEAR_VELOCITY, 80.0)  # 增加最大速度差异
	
	# 线性加速度
	bubble_particles.set_param_min(CPUParticles2D.PARAM_LINEAR_ACCEL, -30.0)  # 添加负加速度
	bubble_particles.set_param_max(CPUParticles2D.PARAM_LINEAR_ACCEL, 30.0)
	
	# 径向加速度
	bubble_particles.set_param_min(CPUParticles2D.PARAM_RADIAL_ACCEL, -15.0)
	bubble_particles.set_param_max(CPUParticles2D.PARAM_RADIAL_ACCEL, 15.0)
	
	# 切向加速度
	bubble_particles.set_param_min(CPUParticles2D.PARAM_TANGENTIAL_ACCEL, -15.0)
	bubble_particles.set_param_max(CPUParticles2D.PARAM_TANGENTIAL_ACCEL, 15.0)
	
	# 角速度
	bubble_particles.set_param_min(CPUParticles2D.PARAM_ANGULAR_VELOCITY, -300.0)
	bubble_particles.set_param_max(CPUParticles2D.PARAM_ANGULAR_VELOCITY, 300.0)
	
	# 颜色 - 创建颜色渐变效果
	var color_ramp = Gradient.new()
	color_ramp.set_color(0, Color(1.0, 1.0, 1.0, 1))  # 起始为白色不透明
	color_ramp.set_color(0.5, Color(1.0, 1.0, 1.0, 0.8))  # 中间为白色半透明
	color_ramp.set_color(1, Color(1.0, 1.0, 1.0, 0))  # 结束为白色透明
	bubble_particles.color = Color(1.0, 1.0, 1.0, 1)  # 基础颜色为白色不透明
	
	# 尺寸 - 创建大小变化效果，让粒子有大有小
	bubble_particles.set_param_min(CPUParticles2D.PARAM_SCALE, 0.2)  # 最小尺寸更小
	bubble_particles.set_param_max(CPUParticles2D.PARAM_SCALE, 3.0)  # 最大尺寸更大
	
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
	breathing_timer.wait_time = 0.4
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
	var breath = sin(time * 5.0) * 0.5 + 0.7  # 更快的呼吸频率，范围 0.2-1.2
	
	# 添加额外的波动效果
	var pulse = sin(time * 15.0) * 0.3 + 0.3  # 更快的脉冲效果
	
	# 结合两种效果
	var combined_effect = breath + pulse

	# 更新粒子参数以创建呼吸效果
	# 修复窄化转换问题：显式转换为float类型
	var scale_value : float = 1.0 + combined_effect * 1.5
	bubble_particles.set_param_min(CPUParticles2D.PARAM_SCALE, scale_value * 0.4)  # 最小尺寸
	bubble_particles.set_param_max(CPUParticles2D.PARAM_SCALE, scale_value * 3.5)  # 最大尺寸

	var alpha : float = 0.7 + combined_effect * 0.3
	bubble_particles.color = Color(1.0, 1.0, 1.0, alpha)  # 白色

# 触发彩虹效果
func trigger_rainbow_effect():
	# 启动粒子效果
	if particles != null:
		particles.emitting = true
		# 检查节点是否仍在场景树中
		if get_tree() != null:
			# 1秒后停止发射
			await get_tree().create_timer(1.0).timeout
		particles.emitting = false

	# 设置持续的彩虹效果
	rainbow_effect_active = true
	apply_persistent_rainbow_effect()

	# 同时播放一次性全屏彩虹效果
	play_fullscreen_rainbow_effect()

	# 添加屏幕震动效果
	if get_tree() != null:
		var master = get_tree().root.get_node("Master")
		if master != null and master.camera != null:
			master.camera.add_trauma(0.8)

	# 播放特殊音效
	SoundManager.play_sound("powerup", 1.2, false)

# 应用持续的彩虹效果
func apply_persistent_rainbow_effect():
	# 检查节点是否仍在场景树中
	if get_tree() == null:
		return
		
	# 获取主场景
	var root = get_tree().root
	
	# 移除其他可能存在的调制效果
	remove_other_modulates()
	
	# 创建或更新场景着色效果
	var rainbow_modulate = root.get_node_or_null("RainbowModulate")
	if rainbow_modulate == null:
		rainbow_modulate = CanvasModulate.new()
		rainbow_modulate.name = "RainbowModulate"
		rainbow_modulate.color = Color(1.0, 0.0, 0.0, 1.0)  # 初始为红色
		root.add_child(rainbow_modulate)
		
		# 启动彩虹颜色循环
		start_rainbow_cycle(rainbow_modulate)
	else:
		rainbow_modulate.color = Color(1.0, 0.0, 0.0, 1.0)
		
		# 启动彩虹颜色循环
		start_rainbow_cycle(rainbow_modulate)

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

# 开始彩虹颜色循环
func start_rainbow_cycle(modulate):
	var rainbow_timer = Timer.new()
	rainbow_timer.name = "RainbowCycleTimer"
	rainbow_timer.wait_time = 0.1  # 更快的颜色变化
	rainbow_timer.autostart = true
	rainbow_timer.one_shot = false
	rainbow_timer.connect("timeout", Callable(self, "cycle_rainbow_color").bind(modulate))
	add_child(rainbow_timer)

# 循环彩虹颜色
func cycle_rainbow_color(modulate):
	if modulate == null or not is_instance_valid(modulate):
		return
		
	var time = float(Time.get_ticks_msec()) / 500.0
	# 创建更丰富的循环变化的彩虹色
	var hue = fmod(time, 1.0)  # 色相在0-1之间循环
	var rgb = hsl_to_rgb(hue, 0.8, 0.3)  # 饱和度0.8，亮度0.3
	
	modulate.color = Color(rgb.x, rgb.y, rgb.z, modulate.color.a)

# HSL转RGB函数
func hsl_to_rgb(h, s, l):
	var c = (1.0 - abs(2.0 * l - 1.0)) * s
	var x = c * (1.0 - abs(fmod(h * 6.0, 2.0) - 1.0))
	var m = l - c / 2.0
	
	var r = 0.0
	var g = 0.0
	var b = 0.0
	
	if h < 1.0/6.0:
		r = c
		g = x
		b = 0.0
	elif h < 2.0/6.0:
		r = x
		g = c
		b = 0.0
	elif h < 3.0/6.0:
		r = 0.0
		g = c
		b = x
	elif h < 4.0/6.0:
		r = 0.0
		g = x
		b = c
	elif h < 5.0/6.0:
		r = x
		g = 0.0
		b = c
	else:
		r = c
		g = 0.0
		b = x
	
	return Vector3(r + m, g + m, b + m)

# 播放一次性全屏彩虹效果
func play_fullscreen_rainbow_effect():
	# 检查节点是否仍在场景树中
	if get_tree() == null:
		return
		
	# 创建一个全屏的彩虹效果
	var rainbow_overlay = ColorRect.new()
	rainbow_overlay.color = Color(1.0, 0.0, 0.0, 0.95)  # 初始为红色，高透明度
	rainbow_overlay.anchor_right = 1
	rainbow_overlay.anchor_bottom = 1
	rainbow_overlay.z_index = 100  # 确保在最上层
	rainbow_overlay.name = "RainbowScreenEffect"

	# 添加到场景树
	get_tree().root.add_child(rainbow_overlay)

	# 启动彩虹颜色循环
	start_rainbow_cycle(rainbow_overlay)

	# 创建淡出效果
	var fade_timer = Timer.new()
	fade_timer.name = "RainbowFadeTimer"
	fade_timer.wait_time = 5.0
	fade_timer.autostart = true
	fade_timer.one_shot = true
	fade_timer.connect("timeout", Callable(self, "fade_out_rainbow").bind(rainbow_overlay, fade_timer))
	add_child(fade_timer)

# 淡出彩虹效果
func fade_out_rainbow(overlay, timer):
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()
	if timer != null and is_instance_valid(timer):
		timer.queue_free()
