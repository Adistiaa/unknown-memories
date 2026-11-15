extends CharacterBody2D

@export_group("Movement")
@export var walk_speed: float = 65.0
@export var run_speed: float = 140.0
@export var jump_velocity: float = -280.0
@export var gravity: float = 900.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var cam: Camera2D = $Camera2D
@onready var sword_area: Area2D = $SwordArea

var spawn_position: Vector2
var is_dead: bool = false
var has_reached_end: bool = false

var hp: int = 5 

var max_jumps: int = 2
var jump_count: int = 0
var is_running: bool = false
var is_attacking: bool = false
var is_shooting: bool = false

var combo_step: int = 1
var combo_timer: float = 0.0

var last_tap_time: float = 0.0
var double_tap_window: float = 0.25
var last_direction: float = 1.0 

func _ready() -> void:
	anim.play("idle")
	anim.animation_finished.connect(_on_animation_finished)
	cam.limit_bottom = 270 
	cam.limit_top = 0
	cam.limit_left = 0
	
	cam.limit_right = 1500
	
	call_deferred("_set_spawn_point")
	sword_area.monitoring = true

func _set_spawn_point() -> void:
	spawn_position = global_position

func _physics_process(delta: float) -> void:
	if has_reached_end:
		velocity = Vector2.ZERO
		anim.play("idle")
		return

	_handle_timers(delta)
	_handle_movement(delta)
	_update_animations()

func _handle_timers(delta: float) -> void:
	if combo_timer > 0.0 and not is_attacking:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_step = 1

func _handle_movement(delta: float) -> void:
	if is_on_floor():
		jump_count = 0

	if not is_on_floor():
		velocity.y += gravity * delta

	if is_dead:
		move_and_slide()
		return

	if Input.is_action_just_pressed("jump") and jump_count < max_jumps and not is_attacking and not is_shooting:
		velocity.y = jump_velocity
		jump_count += 1

	if is_on_floor() and not is_attacking and not is_shooting:
		if Input.is_action_just_pressed("attack"):
			_perform_attack()
			return
		elif Input.is_action_just_pressed("shoot"):
			_perform_shoot()
			return

	var direction: float = Input.get_axis("move_left", "move_right")
	
	if Input.is_action_just_pressed("move_right"):
		if last_direction == 1.0 and (Time.get_ticks_msec() / 1000.0) - last_tap_time < double_tap_window:
			is_running = true
		last_tap_time = Time.get_ticks_msec() / 1000.0
		last_direction = 1.0
	elif Input.is_action_just_pressed("move_left"):
		if last_direction == -1.0 and (Time.get_ticks_msec() / 1000.0) - last_tap_time < double_tap_window:
			is_running = true
		last_tap_time = Time.get_ticks_msec() / 1000.0
		last_direction = -1.0
		
	if direction == 0.0 or signf(direction) != signf(last_direction):
		is_running = false

	if is_attacking or is_shooting:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * 0.2)
	else:
		if direction != 0.0:
			velocity.x = direction * (run_speed if is_running else walk_speed)
			anim.flip_h = (direction < 0.0)
			if direction < 0:
				sword_area.position.x = -25
			else:
				sword_area.position.x = 25
		else:
			velocity.x = move_toward(velocity.x, 0.0, walk_speed)

	move_and_slide()

func _update_animations() -> void:
	if is_attacking or is_shooting or is_dead or has_reached_end:
		return

	if not is_on_floor():
		if velocity.y < 0.0:
			anim.play("jump_up")
		else:
			anim.play("jump_fall")
	else:
		if absf(velocity.x) > 0.1:
			anim.play("run" if is_running else "walk")
		else:
			anim.play("idle")

func _perform_attack() -> void:
	is_attacking = true
	is_running = false
	combo_timer = 0.6
	
	if combo_step == 1:
		anim.play("attack_1")
		combo_step = 2
	else:
		anim.play("attack_2")
		combo_step = 1

	await get_tree().create_timer(0.15).timeout
	
	if is_dead: return
	
	for body in sword_area.get_overlapping_bodies():
		if body.has_method("take_damage") and body != self:
			body.take_damage(1)

func _perform_shoot() -> void:
	is_shooting = true
	is_running = false
	anim.play("shoot_bow")

func take_damage(amount: int) -> void:
	if is_dead: return
	hp -= amount
	
	anim.modulate = Color(1, 0, 0)
	var tween = create_tween()
	tween.tween_property(anim, "modulate", Color(1, 1, 1), 0.2)
	
	if hp <= 0:
		die_and_respawn()

func _on_animation_finished() -> void:
	if anim.animation == "attack_1" or anim.animation == "attack_2":
		is_attacking = false
	elif anim.animation == "shoot_bow":
		is_shooting = false

func die_and_respawn() -> void:
	if is_dead: return
	is_dead = true
	velocity = Vector2.ZERO
	is_running = false
	anim.play("dead")
	
	await get_tree().create_timer(1.2).timeout
	
	var temp_cam = Camera2D.new()
	temp_cam.limit_bottom = cam.limit_bottom
	temp_cam.limit_top = cam.limit_top
	temp_cam.limit_left = cam.limit_left
	get_tree().current_scene.add_child(temp_cam)
	
	temp_cam.global_position = cam.get_screen_center_position()
	temp_cam.make_current()
	
	global_position = spawn_position
	cam.reset_smoothing()
	cam.force_update_scroll()
	
	var target_pos = cam.get_screen_center_position()
	
	var tween = create_tween()
	tween.tween_property(temp_cam, "global_position", target_pos, 1.2).set_trans(Tween.TRANS_SINE)
	await tween.finished
	
	cam.make_current()
	temp_cam.queue_free()
	
	hp = 5 
	anim.play("idle")
	is_dead = false
