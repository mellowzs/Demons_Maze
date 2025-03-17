extends CharacterBody2D

@onready var zombie_sprite_2d: AnimatedSprite2D = $ZombieSprite2D
@onready var ray_cast: RayCast2D = $ZombieSprite2D/RayCast2D
@onready var timer: Timer = $Timer
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D  # Navigation for pathfinding

@export var player: CharacterBody2D
@export var SPEED: int = 50
@export var CHASE_SPEED: int = 150
@export var ATTACK_RANGE: float = 80
@export var ACCELERATION: int = 300

enum States {
	WANDER,
	CHASE,
	SEARCH,
	ATTACK,
	DIE
}

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction: Vector2
var right_bounds: Vector2
var left_bounds: Vector2
var current_state = States.WANDER
var last_seen_position: Vector2 = Vector2.ZERO  # Memory of the player's last known location

func _ready():
	left_bounds = position + Vector2(-125, 0)
	right_bounds = position + Vector2(125, 0)
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0
	add_to_group("zombies")  # Add zombie to group

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	handle_movement(delta)
	change_direction()
	look_for_player()

func look_for_player():
	if ray_cast.is_colliding():
		var collider = ray_cast.get_collider()
		if collider == player:
			last_seen_position = player.position  # Store last seen position
			if (player.position - position).length() < ATTACK_RANGE:
				if randf() < 0.7:  # 70% chance to attack, 30% chance to hesitate
					attack_player()
				else:
					current_state = States.WANDER
			else:
				if randf() < 0.8:  # 80% chance to chase, 20% to hesitate
					chase_player()
				else:
					current_state = States.WANDER
			# Alert other zombies
			get_tree().call_group("zombies", "alert_zombies", player.position)
	elif current_state == States.CHASE:
		# If we were chasing but lost the player, move to last seen position
		if (position - last_seen_position).length() > 10:
			nav_agent.target_position = last_seen_position
			current_state = States.SEARCH
		else:
			stop_chase()

func chase_player():
	current_state = States.CHASE
	nav_agent.target_position = player.position  # Set the player's position as the target

func stop_chase():
	if timer.time_left <= 0:
		timer.start()

func attack_player():
	current_state = States.ATTACK
	velocity = Vector2.ZERO  # Stop moving
	zombie_sprite_2d.play("attack1")
	await zombie_sprite_2d.animation_finished  # Wait for animation to finish
	current_state = States.CHASE  # Resume chasing after attack

func alert_zombies(player_position: Vector2):
	if current_state == States.WANDER or current_state == States.SEARCH:
		last_seen_position = player_position
		current_state = States.CHASE

func handle_movement(delta: float) -> void:
	if current_state == States.WANDER:
		velocity.x = direction.x * SPEED
		zombie_sprite_2d.play("walk")
	elif current_state == States.CHASE or current_state == States.SEARCH:
		var next_pos = nav_agent.get_next_path_position()
		var move_dir = (next_pos - position).normalized()
		velocity.x = move_dir.x * CHASE_SPEED
		zombie_sprite_2d.play("chase")
	else:
		zombie_sprite_2d.play("default")  # Idle animation
	move_and_slide()

func change_direction() -> void:
	print("______________________________________")
	print("Direction:", direction)  # Check if direction is correct
	print("Velocity:", velocity)  # Check if velocity is being set properly
	print("Distance to Player:", (player.position - self.position).length())  # Check if distance changes
	print("Player pos: ", player.position)
	print("Zombie Pos: ", self.position)
	print("______________________________________")
	print("")
	if current_state == States.WANDER:
		if zombie_sprite_2d.flip_h:
			direction = Vector2(-1, 0)
			if position.x <= left_bounds.x:
				zombie_sprite_2d.flip_h = false
				direction = Vector2(1, 0)
		else:
			direction = Vector2(1, 0)
			if position.x >= right_bounds.x:
				zombie_sprite_2d.flip_h = true
				direction = Vector2(-1, 0)
		ray_cast.target_position.x = 100 if !zombie_sprite_2d.flip_h else -100
	elif current_state == States.CHASE:
		if velocity.x > 0:
			zombie_sprite_2d.flip_h = false
			ray_cast.target_position.x = 100
		else:
			zombie_sprite_2d.flip_h = true
			ray_cast.target_position.x = -100

func _on_timer_timeout():
	current_state = States.WANDER
