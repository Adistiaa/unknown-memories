extends Area2D

@export var next_scene: String = "res://stages/EnemyLeak.tscn"
@onready var fade_screen: ColorRect = $"../CanvasLayer/ColorRect"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		var boss = get_parent().get_node_or_null("EnemyBossLeak")
		
		if boss != null and is_instance_valid(boss):
			return 
			
		body.has_reached_end = true
		
		var tween = create_tween()
		tween.tween_property(fade_screen, "modulate:a", 1.0, 1.5)
		
		await tween.finished
		
		if next_scene != "":
			get_tree().change_scene_to_file(next_scene)
