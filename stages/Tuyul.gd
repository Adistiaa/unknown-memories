extends CharacterBody2D

var speed: float = 45.0
var gravity: float = 900.0
var direction: int = 1

var hp: int = 12
var is_dead: bool = false
var is_hurt: bool = false
var is_attacking: bool = false

var flip_timer: float = 0.0
var attack_cooldown: float = 0.0
var player_in_range: Node2D = null

@onready var anim = $AnimatedSprite2D
@onready var edge_detector = $EdgeDetector
@onready var wall_detector = $WallDetector
@onready var attack_area = $AttackArea

func _ready() -> void:
	anim.animation_finished.connect(_on_animation_finished)
	attack_area.body_entered.connect(_on_player_entered)
	attack_area.body_exited.connect(_on_player_exited)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	if not is_on_floor():
		velocity.y += gravity * delta

	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	if is_hurt or is_attacking:
		velocity.x = move_toward(velocity.x, 0, speed)
		move_and_slide()
		return

	if player_in_range != null and attack_cooldown <= 0.0:
		_perform_random_attack()
		return

	if flip_timer > 0.0:
		flip_timer -= delta

	if is_on_floor() and flip_timer <= 0.0:
		if wall_detector.is_colliding() or not edge_detector.is_colliding():
			_flip_direction()

	velocity.x = direction * speed
	anim.play("walk")
	move_and_slide()

func _flip_direction() -> void:
	direction *= -1
	anim.flip_h = (direction < 0)
	
	edge_detector.position.x *= -1
	wall_detector.target_position.x *= -1
	
	if direction < 0:
		attack_area.position.x = -25
	else:
		attack_area.position.x = 25
	
	edge_detector.force_raycast_update()
	wall_detector.force_raycast_update()
	flip_timer = 0.4

func _perform_random_attack() -> void:
	is_attacking = true
	attack_cooldown = 1.8 
	
	var attack_choice = randi_range(1, 3)
	
	if attack_choice == 1:
		anim.play("attack_1")
	elif attack_choice == 2:
		anim.play("attack_2")
	else:
		anim.play("attack_3")
	
	if player_in_range != null and player_in_range.has_method("take_damage"):
		player_in_range.take_damage(1)

func take_damage(amount: int) -> void:
	if is_dead: return
	
	hp -= amount
	if hp <= 0:
		is_dead = true
		anim.play("dead")
		$CollisionShape2D.set_deferred("disabled", true)
		attack_area.set_deferred("monitoring", false)
	else:
		is_hurt = true
		anim.play("hit")
		velocity.x = -direction * 40
		velocity.y = -60

func _on_player_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = body

func _on_player_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = null

func _on_animation_finished() -> void:
	if is_dead:
		if anim.animation == "dead":
			queue_free()
		return

	if anim.animation == "hit":
		is_hurt = false
	elif anim.animation.begins_with("attack_1"):
		is_attacking = false
