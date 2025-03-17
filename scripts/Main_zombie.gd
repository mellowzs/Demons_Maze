extends CharacterBody2D
class_name zombie
@onready var zombie_sprite_2d: AnimatedSprite2D = $ZombieSprite2D
@onready var ray_cast: RayCast2D = $ZombieSprite2D/RayCast2D
@onready var timer: Timer = $Timer
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

@export var player: CharacterBody2D
@export var SPEED: int = 50
@export var CHASE_SPEED: int = 150
@export var ACCELERATION: int = 300

enum States {
	WANDER,
	CHASE,
	ATTACK,
	DIE}

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction: Vector2
var right_bounds: Vector2
var left_bounds: Vector2

var current_state = States.WANDER

func _ready():
	left_bounds = self.position + Vector2(-125, 0)
	right_bounds = self.position + Vector2(125, 0)
	nav_agent.path_desired_distance = 4.0  # Stop before reaching player
	nav_agent.target_desired_distance = 4.0  # Stop if close enough

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	handle_movement (delta)
	change_direction()
	look_for_player()

func look_for_player():
	if player == null or not is_instance_valid(player):
		stop_chase()
		return  # Prevent errors if player is deleted

	if ray_cast.is_colliding():
		var collider = ray_cast.get_collider()
		if collider == player:
			if (player.position - self.position).length() < 40:  # Attack range
				attack_player()
			else:
				chase_player()
		elif current_state == States.CHASE:
			stop_chase()
	elif current_state == States.CHASE:
		stop_chase()

func chase_player() -> void:
	if player == null or not is_instance_valid(player):
		stop_chase()
		return  # Stop chasing if player is deleted

	timer.stop()
	current_state = States.CHASE
	
func stop_chase() -> void:
	if timer.time_left <= 0:
		timer.start()

func attack_player():
	current_state = States.ATTACK
	await zombie_sprite_2d.animation_finished #wait for animation to fini

func handle_movement(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta  # Ensures zombie falls normally
	if player == null or not is_instance_valid(player):
		zombie_sprite_2d.play("default")  # Idle animation
		return
	else:
		if current_state == States.WANDER:
			velocity.x = direction.x * SPEED  # Ensure horizontal movement only
			zombie_sprite_2d.play("walk")
		elif current_state == States.CHASE:
			# Move in the correct direction towards the player
			direction = (player.position - self.position).normalized()
			velocity.x = direction.x * CHASE_SPEED
			zombie_sprite_2d.play("chase")  
		elif current_state == States.ATTACK:
			velocity.x = 0  # Stop moving
			await zombie_sprite_2d.animation_finished #wait for animation to fini
			zombie_sprite_2d.play("attack1")
		else:
			zombie_sprite_2d.play("default")  # Idle animation
	move_and_slide()
	

func change_direction() -> void:
	if current_state == States.WANDER:
		if zombie_sprite_2d.flip_h:
			# Moving left
			direction = Vector2(-1, 0)
			if self.position.x <= left_bounds.x:
				zombie_sprite_2d.flip_h = false  # Flip to right
				direction = Vector2(1, 0)  # Correct direction
		else:
			# Moving right
			direction = Vector2(1, 0)
			if self.position.x >= right_bounds.x:
				zombie_sprite_2d.flip_h = true  # Flip to left
				direction = Vector2(-1, 0)  # Correct direction
		
		# Update raycast position to match flip_h
		ray_cast.target_position.x = 100 if !zombie_sprite_2d.flip_h else -100

	elif current_state == States.CHASE:
		# Ensure correct flipping
		if direction.x > 0:
			zombie_sprite_2d.flip_h = false
			ray_cast.target_position.x = 100
		else:
			zombie_sprite_2d.flip_h = true
			ray_cast.target_position.x = -100

func _on_timer_timeout():
	current_state = States.WANDER
