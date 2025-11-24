extends Control
class_name MainUI

@onready var bullet_count_label:Label = $LPanel/BulletLabel
@onready var full_round_containter : VBoxContainer = $LPanel/Full_rounds
@onready var empty_round_containter : VBoxContainer = $LPanel/Empty_rounds
const full_round : PackedScene = preload("res://Scenes/bullets/full_round.tscn")

const empty_round : PackedScene = preload("res://Scenes/bullets/empty_round.tscn")

@onready var life_labe : Label = $RPanel/LifeLabel
@onready var empty_heart_container : VBoxContainer = $RPanel/empty_hearts
@onready var full_heart_container : VBoxContainer = $RPanel/full_heart
const full_heart : PackedScene = preload("res://Scenes/bullets/full_heart.tscn")

@onready var gem_count_label : Label = $LPanel/GemCount
@onready var gem_bonus_label : Label = $GemBonusLabel

signal gem_bonus_count(amount)





@export var decay = 1  # How quickly the shaking stops [0, 1].
@export var max_offset = Vector2(100, 75)  # Maximum hor/ver shake in pixels.
@export var max_roll = 0.1  # Maximum rotation in radians (use sparingly).

var trauma = 0.0  # Current shake strength.
var trauma_power = 2  # Trauma exponent. Use [2, 3].




func add_trauma(amount):
	trauma = min(trauma + amount, 1.0)


var shake_ammo_bool : bool = false
var shake_heart_bool: bool = false

func _process(delta):
	if trauma <= 0 :
		shake_ammo_bool = false
		shake_heart_bool = false		
	
	if trauma and shake_heart_bool:
		trauma = max(trauma - decay * delta, 0)
		shake_heart()
	if trauma and shake_ammo_bool:
		trauma = max(trauma - decay * delta, 0)
		shake_ammo()

func shake_ammo():
	var amount = pow(trauma, trauma_power)
	empty_round_containter.rotation = max_roll * amount * randf_range(-1, 1)
	empty_round_containter.position.x = (max_offset.x * amount * randf_range(-1, 1)) +478
	empty_round_containter.position.y = (max_offset.y * amount * randf_range(-1, 1)) + 180

func shake_heart():
	var amount = pow(trauma, trauma_power)
	empty_heart_container.rotation = max_roll * amount * randf_range(-1, 1)
	empty_heart_container.position.x = (max_offset.x * amount * randf_range(-1, 1)) + 4
	empty_heart_container.position.y = (max_offset.y * amount * randf_range(-1, 1)) + 178



var tween: Tween

func fade_dir(dir : int):
	tween = create_tween()
	tween.tween_property(self, "modulate:a", dir, 0.5)
	
	# Connect the finished signal to a function
	tween.finished.connect(_on_tween_finished)

func start_fade_out():
	fade_dir(0)


func start_fade_in():
	fade_dir(1)


func _on_tween_finished():
	#shouldn't be hardcoded here!

	print("Fade out completed!")
	# You can perform any actions you need here
	# For example, you might want to hide the panel:
	# self.visible = false

# If you want to disconnect the signal later:
func _exit_tree():
	if tween and tween.finished.is_connected(_on_tween_finished):
		tween.finished.disconnect(_on_tween_finished)

func display_bullet_count(amnt : int, maxamnt:int):
	add_trauma(0.1)
	shake_ammo_bool= true
	#clear everything
	var emptys = empty_round_containter.get_children()
	for i in emptys:
		i.queue_free()
	var fulls = full_round_containter.get_children()
	for i in fulls:
		i.queue_free()
	
	#fill full rounds
	for i in amnt:
		var t = full_round.instantiate()
		full_round_containter.add_child(t)
	
	#fill empty
	for i in maxamnt:
		var t = empty_round.instantiate()
		empty_round_containter.add_child(t)
	bullet_count_label.text = str(amnt) + "/" + str(maxamnt)
	
	
func display_life_count(amnt : int, maxint : int):
	add_trauma(0.1)
	if amnt > 0:
		SoundManager.play_sound("hurt", 1,false)
		HitStpo.start_hitstop(0.5)
	shake_heart_bool = true
	#clear everything
	var emptys = empty_heart_container.get_children()
	for i in emptys:
		i.queue_free()
	var fulls = full_heart_container.get_children()
	for i in fulls:
		i.queue_free()
	
	#fill full rounds
	for i in amnt:
		var t = full_heart.instantiate()
		full_heart_container.add_child(t)
	
	#fill empty
	for i in maxint:
		var t = empty_round.instantiate()
		empty_heart_container.add_child(t)
	life_labe.text = str(amnt) + "/" + str(maxint)
	
	
	
func display_gem_count(amnt : int):
	gem_count_label.text = str(amnt)
	
func display_gem_bonus(amnt : int ):
	var gem_bonus_calculated : int = 0
	if amnt >= 25:
		gem_bonus_calculated = 50
		gem_bonus_count.emit(gem_bonus_calculated)
		gem_bonus_label.text = "max combo"
		await get_tree().create_timer(1).timeout
		gem_bonus_label.text += "\ngem bonus: " + str(gem_bonus_calculated)
		await get_tree().create_timer(1).timeout
		gem_bonus_label.text = ""
	elif amnt >= 20:
		
		gem_bonus_calculated = 20
		gem_bonus_count.emit(gem_bonus_calculated)
		gem_bonus_label.text = "great combo"
		await get_tree().create_timer(1).timeout
		gem_bonus_label.text += "\ngem bonus: " + str(gem_bonus_calculated)
		await get_tree().create_timer(2).timeout
		gem_bonus_label.text = ""
	elif amnt >= 15:
		
		gem_bonus_calculated = 10
		gem_bonus_count.emit(gem_bonus_calculated)
		gem_bonus_label.text = "good combo"
		await get_tree().create_timer(1).timeout
		gem_bonus_label.text += "\ngem bonus: " + str(gem_bonus_calculated)
		await get_tree().create_timer(2).timeout
		gem_bonus_label.text = ""
	elif amnt >= 10:
		
		gem_bonus_calculated = 7
		gem_bonus_count.emit(gem_bonus_calculated)
		gem_bonus_label.text = "mid combo"
		await get_tree().create_timer(1).timeout
		gem_bonus_label.text += "\ngem bonus: " + str(gem_bonus_calculated)
		await get_tree().create_timer(2).timeout
		gem_bonus_label.text = ""
	elif amnt >= 5:
		gem_bonus_calculated = 5
		gem_bonus_count.emit(gem_bonus_calculated)
		gem_bonus_label.text = "weak combo"
		await get_tree().create_timer(1).timeout
		gem_bonus_label.text += "\ngem bonus: " + str(gem_bonus_calculated)
		await get_tree().create_timer(2).timeout
		gem_bonus_label.text = ""
	
	else:
		return
		#gem_bonus_label.text = "no combo"
	
	
	
