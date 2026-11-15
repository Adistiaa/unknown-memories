extends Control

func _ready() -> void:
	$VBoxContainer/BtnPlay.pressed.connect(_on_play_pressed)
	$VBoxContainer/BtnQuit.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Stage1_Forest.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
