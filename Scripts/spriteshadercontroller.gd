extends Sprite2D
class_name spriteEffect

var hit_timer : float = 0.1
var hit_time : float = 0
var hitting : bool = false

func _ready():
	var mat = material.duplicate()
	material = mat

func _process(delta):
	if hitting == true:
		hit_time += delta
		material.set_shader_parameter(('active'), true) 
		if hit_time > hit_timer:
			hit_time = 0
			hitting = false
			material.set_shader_parameter(('active'), false) 
			
func call_hitting():
	if hitting:
		material.set_shader_parameter(('active'), false) 
		material.set_shader_parameter(('active'), true) 
		hit_time = 0
				
