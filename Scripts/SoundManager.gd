extends Node

var sounds = {
	"jump": preload("res://Sounds/TavuttavutavuQUIET.wav"),
	"shoot": preload("res://Sounds/Dukaduka.wav"),
	"explosion": preload("res://Sounds/Break.wav"),
	"powerup" : preload("res://Sounds/powerupsfx.wav"),
	"land": preload("res://Sounds/SoftLand.wav"),
	"bounce": preload("res://Sounds/twattwatQUIET.wav"),
	"hurt": preload("res://Sounds/human - Deghah.wav"),
	"intro" : preload("res://Sounds/introsong.wav"),
	"frog" : preload("res://Sounds/human - frogblug.wav"),
	"shoot_spore": preload("res://Sounds/POPLOW.wav"),
	"start_intro":preload("res://Sounds/STARTINTROQUIET.wav"),
	"plant" : preload("res://Sounds/human - plant.wav"),
	"UI_move" : preload("res://Sounds/UICHANGE.wav"),
	"UI_select": preload("res://Sounds/UISELECT.wav"),
	"death" : preload("res://Sounds/deathsound.wav"),
	"bat" : preload("res://Sounds/Chomp.wav"),
	"roach" : preload("res://Sounds/Tawkkwuwaaho.wav"),
	"spike" : preload("res://Sounds/Tukadukaduka.wav"),
	"boss_music" : preload("res://Sounds/goofyboss.wav")
	# Add more sound effects as needed
}
var looping_sounds = {}

func play_sound(sound_name: String, volume_db: float = 0.0, loop: bool = false):
	if sounds.has(sound_name):
		var audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
		audio_player.stream = sounds[sound_name]
		audio_player.volume_db = volume_db
		audio_player.finished.connect(_on_sound_finished.bind(audio_player, loop))
		
		if loop:
			audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
			looping_sounds[sound_name] = audio_player
		
		audio_player.play()
		
		if loop:
			while true:
				await audio_player.finished
				if not loop or not is_instance_valid(audio_player):
					break
				audio_player.play()
		else:
			await audio_player.finished
			audio_player.queue_free()
	else:
		print("Sound not found: ", sound_name)

func stop_sound(sound_name: String):
	if looping_sounds.has(sound_name):
		var audio_player = looping_sounds[sound_name]
		audio_player.stop()
		audio_player.queue_free()
		looping_sounds.erase(sound_name)

func _on_sound_finished(audio_player: AudioStreamPlayer, loop: bool):
	if not loop and is_instance_valid(audio_player):
		audio_player.queue_free()

func stop_all_sounds():
	for sound_name in looping_sounds.keys():
		stop_sound(sound_name)
