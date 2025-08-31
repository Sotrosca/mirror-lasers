extends Control

@onready var level1_button: Button = $VBox/Level1Button

func _ready():
	level1_button.pressed.connect(_on_level1)

func _on_level1():
	get_tree().change_scene_to_file("res://scenes/levels/Level1_Modular.tscn")
