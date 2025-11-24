extends Camera2D
class_name CameraEffects

@export var decay = 1  # How quickly the shaking stops [0, 1].
@export var max_offset = Vector2(100, 75)  # Maximum hor/ver shake in pixels.
@export var max_roll = 0.1  # Maximum rotation in radians (use sparingly).

var trauma = 0.0  # Current shake strength.
var trauma_power = 2  # Trauma exponent. Use [2, 3].

var target : Node2D 

func _ready():
	randomize()
	await get_tree().create_timer(0.4).timeout
	set_camera.emit(self)

func follow_new_target() -> bool:
	if target: 
		return true
	else:
		return false

func add_trauma(amount):
	trauma = min(trauma + amount, 1.0)

signal set_camera(cam)
func _process(delta):
	if follow_new_target():
		#print("following  ", target)
		global_position = target.global_position
	
	
	
	
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		shake()

func shake():
	var amount = pow(trauma, trauma_power)
	rotation = max_roll * amount * randf_range(-1, 1)
	offset.x = max_offset.x * amount * randf_range(-1, 1)
	offset.y = (max_offset.y * amount * randf_range(-1, 1)) + 45
