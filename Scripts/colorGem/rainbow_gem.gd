extends Node2D

# 彩虹宝石本体, 可拾取物
# 职责:
# - 进入吸附范围后向玩家吸附, 进入拾取距离后触发彩虹效果并回收到对象池
# - 本地演出: 自身旋转與发光脉动, 粒子與呼吸泡泡, 音效, 屏幕震动
# - 屏幕全局彩虹: 创建或复用名为 RainbowModulate 的 CanvasModulate, 启动颜色循环
# - 一次性全屏覆盖: 创建最上层 ColorRect 覆盖, 延时淡出
#
# 最小改动目标:
# - 把全局彩虹的颜色循环速度與饱和度亮度, 以及覆盖层的透明度與时长, 做成可导出参数
# - 你可以在 Inspector 中直接调数值, 或在脚本里改默认值

var player 
var is_active = false
@export var max_distance : float = 1000
@export var attraction_speed : float = 200
@export var pick_up_distance : float = 6

# MOD 可调参数: 屏幕彩虹循环關聯
# rainbow_cycle_period: N 秒转一圈, 越小越快
# rainbow_saturation: 饱和度 0..1
# rainbow_lightness: 亮度 0..1, 使用 HSL 的 L
@export var rainbow_cycle_period: float = 3.0
@export var rainbow_saturation: float = 0.8
@export var rainbow_lightness: float = 0.35

# MOD 可调参数: 一次性全屏覆盖
# overlay_enable: 是否启用覆盖层
# overlay_alpha: 覆盖层初始不透明度 0..1
# overlay_duration: 覆盖停留时长 秒
# overlay_fade_sec: 覆盖淡出时长 秒
@export var overlay_enable: bool = true
@export var overlay_alpha: float = 0.95
@export var overlay_duration: float = 5.0
@export var overlay_fade_sec: float = 0.6

@onready var anim : AnimationPlayer = $AnimationPlayer
@onready var glow_sprite : Sprite2D = $Glow  # 发光精灵引用
@onready var main_sprite : Sprite2D = $Sprite2D  # 主精灵引用

# 发光脉动参数
var glow_time = 0.0
var glow_speed = 3.0

# 粒子系统
var particles: GPUParticles2D
var bubble_particles: CPUParticles2D  # 呼吸泡泡

# 彩虹效果状态
var rainbow_effect_active = false

func _ready():
	# 创建粒子与泡泡
	create_particles()
	create_bubble_particles()
	
	# 启动本体旋转动画
	rotate_gem()
	
	# 调整精灵尺寸与发光参数
	if main_sprite != null:
		main_sprite.scale = Vector2(1.2, 1.2)
	if glow_sprite != null:
		glow_sprite.scale = Vector2(2.2, 2.2)
		glow_sprite.modulate = Color(1.0, 1.0, 1.0, 0.8)

func _physics_process(delta):
	if is_active and player != null:
		var dir = player.global_position - global_position
		var dis : float = dir.length()
		
		# 处于吸附范围内則向玩家移动
		if dis > pick_up_distance and dis <= max_distance:
			dir = dir.normalized()
			var movement = dir * attraction_speed * delta 
			global_position += movement
			
		# 进入拾取距离則触发
		if dis <= pick_up_distance:
			# 触发彩虹效果链路
			trigger_rainbow_effect()
			# 发 20 的宝石事件 代表彩虹宝石
			Pooler.gem_collected.emit(20)
			# 回收到对象池
			Pooler.return_gem(self)
			is_active = false
		elif dis > max_distance:
			# 飞出最大范围則回收
			Pooler.return_gem(self)
			print("lost it")
	
	# 每帧更新发光效果
	update_glow_effect(delta)

# 发光脉动與闪烁
func update_glow_effect(delta):
	if glow_sprite != null:
		glow_time += delta * glow_speed
		# 基础脉动 0..1
		var glow_intensity : float = (sin(glow_time) + 1.0) * 0.5
		# 更快的闪烁疊加
		var flicker = sin(glow_time * 8.0) * 0.2
		var combined_glow = glow_intensity + flicker
		
		# 透明度在 0.6..1.0 变化
		var alpha : float = 0.6 + combined_glow * 0.4
		glow_sprite.modulate.a = alpha
		
		# 发光精灵尺寸轻微脉动 2.0..2.5
		var scale_factor : float = 2.0 + combined_glow * 0.5
		glow_sprite.scale = Vector2(scale_factor, scale_factor)
		
		# 发光颜色做简单循环
		var color_time = glow_time * 2.0
		glow_sprite.modulate.r = (sin(color_time) + 1.0) * 0.5
		glow_sprite.modulate.g = (sin(color_time + 2.0) + 1.0) * 0.5
		glow_sprite.modulate.b = (sin(color_time + 4.0) + 1.0) * 0.5

# 本体缓慢旋转加轻微脉动
func rotate_gem():
	var rotation_time = 0.0
	var base_rotation_speed = 0.04
	var pulse_speed = 0.1
	
	while true:
		if get_tree() == null:
			break
		rotation_time += 0.016  # 近似 60 FPS
		
		if main_sprite != null:
			var pulse = sin(rotation_time * pulse_speed) * 0.03
			main_sprite.rotation += base_rotation_speed + pulse
			
		if glow_sprite != null:
			var pulse2 = sin(rotation_time * pulse_speed * 2.0) * 0.02
			glow_sprite.rotation -= base_rotation_speed * 0.9 + pulse2
			
		if get_tree() == null:
			break
		await get_tree().create_timer(0.016).timeout  # 近似 60 FPS
		update_breathing_effect()

func _on_area_2d_area_entered(area):
	if area != null:
		var area_parent = area.get_parent()
		if area_parent != null:
			player = area_parent
			is_active = true
			if anim != null:
				anim.play("coinspin")

# 创建主粒子
func create_particles():
	particles = GPUParticles2D.new()
	particles.position = Vector2(0, 0)
	particles.name = "RainbowGemParticles"
	
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, -1, 0)
	particle_material.spread = 90
	particle_material.gravity = Vector3(0, -100, 0)
	particle_material.initial_velocity_min = 40.0
	particle_material.initial_velocity_max = 150.0
	particle_material.angular_velocity_min = -600.0
	particle_material.angular_velocity_max = 600.0
	particle_material.scale_curve = null
	particle_material.color = Color(1.0, 1.0, 1.0, 1.0)
	particle_material.color_ramp = null
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = 20.0
	particle_material.particle_flag_align_y = true
	
	particles.process_material = particle_material
	particles.lifetime = 5.0
	particles.amount = 100
	particles.emitting = false
	particles.visibility_rect = Rect2(-200, -200, 400, 400)
	particles.scale = Vector2(2.0, 2.0)
	
	add_child(particles)

# 创建呼吸泡泡粒子
func create_bubble_particles():
	bubble_particles = CPUParticles2D.new()
	bubble_particles.name = "BreathingBubbles"
	bubble_particles.position = Vector2(0, 0)
	bubble_particles.amount = 40
	bubble_particles.lifetime = 6.0
	bubble_particles.one_shot = false
	bubble_particles.preprocess = 0.0
	bubble_particles.speed_scale = 1.0
	bubble_particles.explosiveness = 0.0
	bubble_particles.randomness = 1.0
	bubble_particles.fixed_fps = 0.0
	bubble_particles.fract_delta = true
	bubble_particles.local_coords = true
	
	bubble_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	bubble_particles.emission_sphere_radius = 25.0
	bubble_particles.direction = Vector2(0, -1)
	bubble_particles.spread = 100
	bubble_particles.gravity = Vector2(0, -40)
	
	bubble_particles.set_param_min(CPUParticles2D.PARAM_INITIAL_LINEAR_VELOCITY, 8.0)
	bubble_particles.set_param_max(CPUParticles2D.PARAM_INITIAL_LINEAR_VELOCITY, 80.0)
	bubble_particles.set_param_min(CPUParticles2D.PARAM_LINEAR_ACCEL, -30.0)
	bubble_particles.set_param_max(CPUParticles2D.PARAM_LINEAR_ACCEL, 30.0)
	bubble_particles.set_param_min(CPUParticles2D.PARAM_RADIAL_ACCEL, -15.0)
	bubble_particles.set_param_max(CPUParticles2D.PARAM_RADIAL_ACCEL, 15.0)
	bubble_particles.set_param_min(CPUParticles2D.PARAM_TANGENTIAL_ACCEL, -15.0)
	bubble_particles.set_param_max(CPUParticles2D.PARAM_TANGENTIAL_ACCEL, 15.0)
	bubble_particles.set_param_min(CPUParticles2D.PARAM_ANGULAR_VELOCITY, -300.0)
	bubble_particles.set_param_max(CPUParticles2D.PARAM_ANGULAR_VELOCITY, 300.0)
	
	# 简单的透明度曲线
	var color_ramp = Gradient.new()
	color_ramp.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	color_ramp.set_color(0.5, Color(1.0, 1.0, 1.0, 0.8))
	color_ramp.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	bubble_particles.color = Color(1.0, 1.0, 1.0, 1.0)
	
	# 尺寸范围
	bubble_particles.set_param_min(CPUParticles2D.PARAM_SCALE, 0.2)
	bubble_particles.set_param_max(CPUParticles2D.PARAM_SCALE, 3.0)
	
	bubble_particles.draw_order = CPUParticles2D.DRAW_ORDER_INDEX
	
	add_child(bubble_particles)
	start_breathing_animation()

# 启动呼吸泡泡的周期更新
func start_breathing_animation():
	if bubble_particles == null:
		return
	var breathing_timer = Timer.new()
	breathing_timer.name = "BreathingTimer"
	breathing_timer.wait_time = 0.4
	breathing_timer.autostart = true
	breathing_timer.one_shot = false
	breathing_timer.connect("timeout", Callable(self, "update_breathing_effect"))
	add_child(breathing_timer)

# 呼吸泡泡每帧的尺寸與透明度变化
func update_breathing_effect():
	if bubble_particles == null:
		return
	var time = float(Time.get_ticks_msec()) / 1000.0
	var breath = sin(time * 5.0) * 0.5 + 0.7
	var pulse = sin(time * 15.0) * 0.3 + 0.3
	var combined_effect = breath + pulse
	var scale_value : float = 1.0 + combined_effect * 1.5
	bubble_particles.set_param_min(CPUParticles2D.PARAM_SCALE, scale_value * 0.4)
	bubble_particles.set_param_max(CPUParticles2D.PARAM_SCALE, scale_value * 3.5)
	var alpha : float = 0.7 + combined_effect * 0.3
	bubble_particles.color = Color(1.0, 1.0, 1.0, alpha)

# 触发彩虹效果主流程: 粒子, 全局彩虹, 覆盖层, 震动, 音效
func trigger_rainbow_effect():
	# 短暂粒子喷发
	if particles != null:
		particles.emitting = true
		if get_tree() != null:
			await get_tree().create_timer(1.0).timeout
		particles.emitting = false

	# 持续的彩虹效果, 即屏幕 CanvasModulate 颜色循环
	rainbow_effect_active = true
	apply_persistent_rainbow_effect()

	# 一次性全屏覆盖, 强化反馈
	play_fullscreen_rainbow_effect()

	# 屏幕震动
	if get_tree() != null:
		var master = get_tree().root.get_node("Master")
		if master != null and master.camera != null:
			master.camera.add_trauma(0.8)

	# 音效
	SoundManager.play_sound("powerup", 1.2, false)

# 创建或复用全局 CanvasModulate, 并启动彩虹颜色循环
func apply_persistent_rainbow_effect():
	if get_tree() == null:
		return
		
	var root = get_tree().root
	
	# 移除其它颜色调制, 避免叠色
	remove_other_modulates()
	
	# 创建或复用名为 RainbowModulate 的 CanvasModulate
	var rainbow_modulate = root.get_node_or_null("RainbowModulate")
	if rainbow_modulate == null:
		rainbow_modulate = CanvasModulate.new()
		rainbow_modulate.name = "RainbowModulate"
		# 初始定为红色
		rainbow_modulate.color = Color(1.0, 0.0, 0.0, 1.0)
		root.add_child(rainbow_modulate)
		# MOD 循环速度受 rainbow_cycle_period 控制
		start_rainbow_cycle(rainbow_modulate)
	else:
		rainbow_modulate.color = Color(1.0, 0.0, 0.0, 1.0)
		start_rainbow_cycle(rainbow_modulate)

# 清除其它全屏调制节点
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

# 启动一个计时器, 周期性调用 cycle_rainbow_color
func start_rainbow_cycle(modulate):
	var rainbow_timer = Timer.new()
	rainbow_timer.name = "RainbowCycleTimer"
	rainbow_timer.wait_time = 0.016  # 固定 tick 间隔, 实际速度由 period 控制
	rainbow_timer.autostart = true
	rainbow_timer.one_shot = false
	rainbow_timer.connect("timeout", Callable(self, "cycle_rainbow_color").bind(modulate))
	add_child(rainbow_timer)

# 按 HSL 循环色相, 动态更新 CanvasModulate 或 ColorRect 的颜色
func cycle_rainbow_color(modulate):
	if modulate == null or not is_instance_valid(modulate):
		return

	# 目标色相 按周期计算
	var t: float = float(Time.get_ticks_msec()) / 1000.0
	var period: float = max(rainbow_cycle_period, 0.01)
	var speed: float = 1.0 / period
	var target_hue: float = fmod(t * speed, 1.0)

	# 读取上一次的 hue 没有则用当前目标色相
	var prev_hue: float = target_hue
	if modulate.has_meta("rainbow_prev_hue"):
		prev_hue = float(modulate.get_meta("rainbow_prev_hue"))

	# 角度插值 让 hue 平滑靠近目标
	# factor 越小 越柔和 建议 0.06 到 0.12
	var TWO_PI: float = PI * 2.0
	var prev_rad: float = prev_hue * TWO_PI
	var target_rad: float = target_hue * TWO_PI
	var smooth_rad: float = lerp_angle(prev_rad, target_rad, 0.08)
	var smooth_hue: float = fposmod(smooth_rad, TWO_PI) / TWO_PI
	modulate.set_meta("rainbow_prev_hue", smooth_hue)

	# 饱和度與亮度沿用可调参数
	var sat: float = clamp(rainbow_saturation, 0.0, 1.0)
	var light: float = clamp(rainbow_lightness, 0.0, 1.0)

	var rgb: Vector3 = hsl_to_rgb(smooth_hue, sat, light)
	modulate.color = Color(rgb.x, rgb.y, rgb.z, modulate.color.a)

# 工具: HSL 转 RGB
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

# 一次性全屏覆盖, 与全局彩虹循环同步换色, 随后淡出
func play_fullscreen_rainbow_effect():
	if get_tree() == null or not overlay_enable:
		return
	# 覆盖层置于最上层
	var rainbow_overlay = ColorRect.new()
	rainbow_overlay.color = Color(1.0, 0.0, 0.0, clamp(overlay_alpha, 0.0, 1.0))
	rainbow_overlay.anchor_right = 1
	rainbow_overlay.anchor_bottom = 1
	rainbow_overlay.z_index = 100
	rainbow_overlay.name = "RainbowScreenEffect"
	get_tree().root.add_child(rainbow_overlay)
	# 使用同一套循环逻辑同步变色
	
	
	
	
	
	
	
	
	# 找到 Master
	var master := get_tree().root.get_node("Master")
	# 查找或创建覆盖层专用 CanvasLayer
	var overlay_layer := master.get_node_or_null("RainbowOverlayLayer")
	if overlay_layer == null:
		var cl := CanvasLayer.new()
		cl.name = "RainbowOverlayLayer"
		cl.layer = 10  # 覆盖层级，低于狗的层
		# 跟随视口对 ColorRect 没有硬性要求，这里可不启用
		master.add_child(cl)
		overlay_layer = cl
	# 把覆盖 ColorRect 加到这个 CanvasLayer
	overlay_layer.add_child(rainbow_overlay)

	# 设定停留时长后触发淡出
	var fade_timer = Timer.new()
	fade_timer.name = "RainbowFadeTimer"
	fade_timer.wait_time = float(max(overlay_duration, 0.01))
	fade_timer.autostart = true
	fade_timer.one_shot = true
	fade_timer.connect("timeout", Callable(self, "fade_out_rainbow").bind(rainbow_overlay, fade_timer))
	add_child(fade_timer)

# 覆盖层淡出並清理
func fade_out_rainbow(overlay, timer):
	if overlay != null and is_instance_valid(overlay):
		var tw := create_tween()
		# 对 modulate.a 做渐隐, 完成后销毁
		tw.tween_property(overlay, "modulate:a", 0.0, float(max(overlay_fade_sec, 0.01)))
		await tw.finished
		overlay.queue_free()
	if timer != null and is_instance_valid(timer):
		timer.queue_free()
