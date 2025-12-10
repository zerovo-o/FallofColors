extends Node2D

var player : PlayerMasterAndMover
@onready var bosslife : boss_life = $CanvasLayer
@onready var body_sprite : Sprite2D = $Body/BodySprite
@onready var head_sprite : Sprite2D = $Body/HeadSprite

@export var num_segments = 5
@export var segment_spacing = 0.2  # Spacing between segments (0-1)
@export var follow_speed = 10.0
@export var oscillation_speed : float = 2
@export var oscillation_apmplitude : float = 2
@export var attack_speed : float = 300
@export var attack_duration : float = 0.5
@export var attack_duration2 : float = 0.5
@export var return_speed : float = 30
@export var idle_duration : float = 2.4
@export var idle_duration2 : float = 2.4
@export var bubble_spawn_pause : float = 0.4
@onready var state_label : Label = $Label
@onready var left_arm_shoulder : Node2D = $Body/LeftArmShoulder
@onready var right_arm_shoulder : Node2D = $Body/RightArmShoulder

var left_arm_path: Path2D
var left_hand: CharacterBody2D
var body: CharacterBody2D
var lfet_side_segments: Array = []

var right_arm_path : Path2D
var right_hand : CharacterBody2D
var right_side_segmetns : Array = []

var time : float = 0
var time2 : float = 0
const arm_seg :PackedScene = preload("res://Scenes/Enemy/arm_length_path.tscn")

enum Left_Hand_State {IDLE, OSCILLATE, CIRCLE, FIGURE_EIGHT, ATTACK}
var current_state = Left_Hand_State.IDLE

enum Right_Hand_State {IDLE, ATTACK, FIGURE_EIGHT, OSCILLATE}
var current_right_state = Right_Hand_State.IDLE

var state_timer: float = 0.0
var state_duration: float = 3.0
var attack_direction : Vector2 = Vector2.ZERO
var attack_timer : float = 0
var bubble_timer : float = 0
var was_dle : bool = false
var right_was_dle : bool = false

var state_timer2: float = 0.0
var state_duration2: float = 3.0
var attack_direction2 : Vector2 = Vector2.ZERO
var attack_timer2 : float = 0
var bubble_timer2 : float = 0

const  spore_scene: PackedScene = preload("res://Scenes/Enemy/spore.tscn")

func launch_spore(spawn_left_hand : bool, should_seek : bool):
	if spore_scene:
		var spore = spore_scene.instantiate()
		add_child(spore)
		if spawn_left_hand:
			spore.global_position = left_hand.global_position
		else:
			spore.global_position = right_hand.global_position
		if should_seek and player:
			spore.set_target(player)

func _ready():
	player = get_node("/root/Master/Player") 
	
	left_arm_path = $LeftArmPath
	left_hand = $LeftHand
	
	right_arm_path = $RightArmPath
	right_hand = $RightHand
	
	body = $Body
	
		# Create segments
	for i in range(num_segments):
		var segment : PathFollow2D = arm_seg.instantiate()
		segment.loop = false
		left_arm_path.add_child(segment)
		lfet_side_segments.append(segment)
		
	for i in range(num_segments):
		var seg: PathFollow2D = arm_seg.instantiate()
		seg.loop = false
		right_arm_path.add_child(seg)
		right_side_segmetns.append(seg)



@export var spore_from_face_timer : float = 0.6
var spore_FFT_time : float = 0.0
func _physics_process(delta):
	spore_FFT_time += delta
	if spore_FFT_time > spore_from_face_timer:
		var spore = spore_scene.instantiate()
		add_child(spore)
		spore.global_position = head_sprite.global_position
		spore.set_target(player)
		spore_FFT_time = 0
		
	time += delta
	state_timer += delta
	bubble_timer += delta
	
	time2 += delta
	state_timer2 += delta
	bubble_timer2 += delta	
	
	#for right side  
	if current_right_state == Right_Hand_State.ATTACK:
		attack_timer2 += delta
		if attack_timer2 >= attack_duration2:
			switch_state_right_hand()
	elif current_right_state == Right_Hand_State.IDLE:
		if state_timer2 >= idle_duration2:
			switch_state_right_hand()
	elif state_timer2 >= state_duration2:
		switch_state_right_hand()
	#ADD OWN UPDATES
	
	#for left side
	if current_state == Left_Hand_State.ATTACK:
		attack_timer += delta
		if attack_timer >= attack_duration:
			switch_state()
	elif current_state == Left_Hand_State.IDLE:
		if state_timer >= idle_duration:
			switch_state()
	elif state_timer >= state_duration:
		switch_state()
	
	update_head_position(delta)
	update_curve()
	update_segments(delta)
#for Left Hand
func switch_state():
	state_timer = 0
	attack_timer = 0
	
	if current_state == Left_Hand_State.IDLE or was_dle:
		current_state = Left_Hand_State.ATTACK
		was_dle = false
		var angle = randf_range(-PI/4, PI/4)
		attack_direction = Vector2(sin(angle), - cos(angle)).normalized()
	else:
		var states = [Left_Hand_State.IDLE, Left_Hand_State.OSCILLATE, Left_Hand_State.CIRCLE, Left_Hand_State.FIGURE_EIGHT]
		states.erase(current_state)
		current_state = states[randi() % states.size()]
	
		if current_state == Left_Hand_State.IDLE:
			was_dle = true
			state_duration = idle_duration
		else:
			state_duration = 6.0
			
func switch_state_right_hand():
	state_timer2 = 0
	attack_timer2 = 0
	
	if current_right_state == Right_Hand_State.IDLE or right_was_dle:
		current_right_state = Right_Hand_State.ATTACK
		was_dle = false
		var angle = randf_range(-PI/4, PI/4)
		attack_direction2 = Vector2(sin(angle), - cos(angle)).normalized()
	else:
		var states = [Right_Hand_State.IDLE, Right_Hand_State.FIGURE_EIGHT, Right_Hand_State.OSCILLATE]
		states.erase(current_state)
		current_right_state = states[randi() % states.size()]
	
		if current_right_state == Right_Hand_State.IDLE:
			right_was_dle = true
			state_duration2 = idle_duration2
		else:
			state_duration2 = 6.0
		
func update_head_position(delta):
	match current_state:
		Left_Hand_State.IDLE:
			var direction = left_arm_shoulder.global_position - left_hand.global_position
			var distance = direction.length()
			if distance > 10:
				left_hand.velocity = direction.normalized() * min(return_speed, distance/delta)
			else:
				left_hand.velocity = Vector2.ZERO
		Left_Hand_State.OSCILLATE:
			if bubble_timer > bubble_spawn_pause:
				bubble_timer = 0
				launch_spore(true, false)
			var oscillation = sin(time * 2.0) * 50.0
			left_hand.velocity.x = (oscillation - left_hand.global_position.x) * 5.0
			left_hand.velocity.y = 0
		Left_Hand_State.CIRCLE:
			var angle = time * 2.0
			var target = Vector2(cos(angle), sin(angle)) * 50.0 + left_arm_shoulder.global_position
			left_hand.velocity = (target - left_hand.global_position) * 5.0
		Left_Hand_State.FIGURE_EIGHT:
			if bubble_timer > bubble_spawn_pause:
				bubble_timer = 0
				launch_spore(true, false)
			var angle = time * 2.0
			var target = Vector2(sin(angle) * 50.0, sin(angle * 2.0) * 25.0) + body.global_position + Vector2(0, -32)
			left_hand.velocity = (target - left_hand.global_position) * 5.0
		Left_Hand_State.ATTACK:
			if attack_timer < attack_duration/2:
				left_hand.velocity = attack_direction * attack_speed
			else:
				left_hand.velocity = (body.global_position - left_hand.global_position) * 2
	left_hand.move_and_slide()
	
	match current_right_state:
		Right_Hand_State.IDLE:
			var direction = right_arm_shoulder.global_position - right_hand.global_position
			var distance = direction.length()
			if distance > 10:
				right_hand.velocity = direction.normalized() * min(return_speed, distance/delta)
			else:
				right_hand.velocity = Vector2.ZERO
		Right_Hand_State.OSCILLATE:
			if bubble_timer2 > bubble_spawn_pause:
				bubble_timer2 = 0
				launch_spore(false, false)
			var oscillation = sin(time * 2.0) * 50.0
			right_hand.velocity.x = (oscillation - right_hand.global_position.x) * 5.0
			right_hand.velocity.y = 0
				
		Right_Hand_State.FIGURE_EIGHT:
			if bubble_timer2 > bubble_spawn_pause:
				bubble_timer2 = 0
				launch_spore(false, false)
			var angle = time2 * 2.0
			var target = Vector2(sin(angle) * 50.0, sin(angle * 2.0) * 25.0) + body.global_position + Vector2(0, -32)
			right_hand.velocity = (target - right_hand.global_position) * 5.0
		Right_Hand_State.ATTACK:
			if attack_timer2 < attack_duration2/2:
				right_hand.velocity = attack_direction2 * attack_speed
			else:
				right_hand.velocity = (body.global_position - right_hand.global_position) * 2
	right_hand.move_and_slide()
	
func update_curve():
	# Same as before
	var new_curve = Curve2D.new()
	var start = left_arm_shoulder.global_position
	var end = left_hand.global_position
	var segment_length = start.distance_to(end) / (num_segments + 1)
	var direction = (end - start).normalized()
	
	new_curve.add_point(left_arm_path.to_local(start))
	
	for i in range(1, num_segments + 1):
		var point = start + direction * (segment_length * i)
		new_curve.add_point(left_arm_path.to_local(point))
	
	new_curve.add_point(left_arm_path.to_local(end))
	
	# Smooth out the curve
	for i in range(1, new_curve.get_point_count() - 1):
		var prev = new_curve.get_point_position(i - 1)
		var current = new_curve.get_point_position(i)
		var next = new_curve.get_point_position(i + 1)
		
		var in_control = (current - prev) * 0.5
		var out_control = (next - current) * 0.5
		
		new_curve.set_point_in(i, -in_control)
		new_curve.set_point_out(i, out_control)
	
	left_arm_path.curve = new_curve
	
	
	
	# Same as before
	var new_curve2 = Curve2D.new()
	var start2 = right_arm_shoulder.global_position
	var end2 = right_hand.global_position
	var segment_length2 = start2.distance_to(end2) / (num_segments + 1)
	var direction2 = (end2 - start2).normalized()
	
	new_curve2.add_point(right_arm_path.to_local(start2))
	
	for i in range(1, num_segments + 1):
		var point2 = start2 + direction2 * (segment_length2 * i)
		new_curve2.add_point(right_arm_path.to_local(point2))
	
	new_curve2.add_point(right_arm_path.to_local(end2))
	
	# Smooth out the curve
	for i in range(1, new_curve2.get_point_count() - 1):
		var prev = new_curve2.get_point_position(i - 1)
		var current = new_curve2.get_point_position(i)
		var next = new_curve2.get_point_position(i + 1)
		
		var in_control = (current - prev) * 0.5
		var out_control = (next - current) * 0.5
		
		new_curve2.set_point_in(i, -in_control)
		new_curve2.set_point_out(i, out_control)
	
	right_arm_path.curve = new_curve2

func update_segments(delta):
	for i in range(lfet_side_segments.size()):
		var segment = lfet_side_segments[i]
		var target_ratio = float(i + 1) / (num_segments + 1)
		segment.progress_ratio = lerp(segment.progress_ratio, target_ratio, follow_speed * delta)
		var arm_length : Sprite2D = segment.get_node("Sprite2D")
		arm_length.global_position = left_arm_path.to_global(left_arm_path.curve.sample_baked(segment.progress_ratio * left_arm_path.curve.get_baked_length()))
		#print (left_arm_path.curve.get_baked_points(), Left_Hand_State.find_key(current_state))
	for i in range(right_side_segmetns.size()):
		var segment = right_side_segmetns[i]
		var target_ratio = float(i + 1) / (num_segments + 1)
		segment.progress_ratio = lerp(segment.progress_ratio, target_ratio, follow_speed * delta)
		var arm_length : Sprite2D = segment.get_node("Sprite2D")
		arm_length.global_position = right_arm_path.to_global(right_arm_path.curve.sample_baked(segment.progress_ratio * right_arm_path.curve.get_baked_length()))

func _on_bounce_area_2d_area_entered(area):
	body_sprite.hitting = true
	head_sprite.hitting = true
	SoundManager.play_sound( "frog", 0.4, false)
	bosslife.set_life_current(bosslife.get_current_life() -1)
