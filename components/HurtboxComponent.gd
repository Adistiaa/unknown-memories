class_name HurtboxComponent
extends Area2D

signal hit_received(hitbox: HitboxComponent)

@export var health_component: HealthComponent

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area is HitboxComponent:
		var hitbox: HitboxComponent = area as HitboxComponent
		if health_component:
			health_component.take_damage(hitbox.damage)
		hit_received.emit(hitbox)
