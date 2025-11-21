extends Resource
class_name Upgrade

enum UpgradeType{MORE_LIFE, MORE_BULLETS, BIGGER_BULLETS, NO_BOUNCE, BETTER_AIM, SLOW_WALL}

@export var icon : Texture
@export var type : UpgradeType
@export var upgrade_name : String
@export var upgrade_des : String

	#
#func _init(t : UpgradeType, i:Texture, n: String, d: String):
		#type = t
		#icon = icon
		#upgrade_name = n
		#upgrade_des = d
