extends CharacterBody2D
class_name Zombie

var Player: player_hobo = null
var speed = 200.0
var gravity = ProjectSettings.get("physics/2d/default_gravity")  # Get default gravity
var direction: =Vector2.ZERO
@onready var zombie_sprite_2d: AnimatedSprite2D = $ZombieSprite2D

func _physics_process(delta: float) -> void:
	# Apply gravity to keep the NPC on the ground
	if not is_on_floor():
		velocity.y += gravity * delta

	if Player != null:
		var enemy_to_player = (Player.global_position - global_position).normalized()
		if enemy_to_player.length() > 20:
			direction = enemy_to_player
		else:
			direction = Vector2.ZERO
		
		if direction != Vector2.ZERO:
			# Move toward the player (X-axis only)
			velocity.x = speed * sign(enemy_to_player.x)  # Always move toward the player

			# Flip sprite based on direction (Assumes right-facing default)
			zombie_sprite_2d.flip_h = velocity.x < 0  
		else:
			velocity.x = move_toward(velocity.x, 0, speed * delta)# Stop moving if no player is detected

		move_and_slide()  # Apply movement with collision handling

func _on_player_detector_body_entered(body: Node2D) -> void:
	if body is player_hobo:
		Player = body
		print("Zombie detected the player!")
		zombie_sprite_2d.play("walk")

func _on_player_detector_body_exited(body: Node2D) -> void:
	if body is player_hobo:
		Player = null
		print("Zombie lost the player!")
		zombie_sprite_2d.play("default")
