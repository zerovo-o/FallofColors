extends Control
#@onready var container : VBoxContainer = $Panel/MarginContainer/VBoxContainer
@onready var blackoutpane : Panel = $BlackOut

func _ready():

	fade_out()
	
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
	print(container)
	if first_button is BaseButton:
		first_button.grab_focus()
