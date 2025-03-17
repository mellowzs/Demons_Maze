extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -500.0
var is_jumping = false  # Flag to track if jumping animation is still playing
var is_attacking = false  
@onready var hobo_sprite_2d: AnimatedSprite2D = $HoboSprite2D


func _ready():
	# Connect the animation_finished signal
	hobo_sprite_2d.animation_finished.connect(_on_animation_finished)
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# Handle actions
	if Input.is_action_just_pressed("attack") and not is_attacking and not is_jumping:
		hobo_sprite_2d.play("attack1")
		is_attacking = true
	elif Input.is_action_just_pressed("jump") and not is_jumping and not is_attacking:
		velocity.y = JUMP_VELOCITY
		hobo_sprite_2d.play("jump")
		is_jumping = true
	elif not is_jumping and not is_attacking: # prevent changing animation if jump is playing
		if Input.is_action_pressed("left"):
			hobo_sprite_2d.play("run")
		elif Input.is_action_pressed("right"):
			hobo_sprite_2d.play("run")
		else:
			hobo_sprite_2d.animation = "default"

	# Handle horizontal movement
	var direction := Input.get_axis("left", "right")
	if direction != 0:
		hobo_sprite_2d.flip_h = velocity.x < 0
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, 50)  # Smooth deceleration to zero
	   
	move_and_slide()
	
func _on_animation_finished():
	# Reset jump flag when animation completes
	if hobo_sprite_2d.animation == "jump":
		print(hobo_sprite_2d.animation + " animation finished!")
		is_jumping = false
	elif hobo_sprite_2d.animation == "attack1":
		print(hobo_sprite_2d.animation + " animation finished!")
		is_attacking = false


func _on_hobo_hitbox_body_entered(_body: Node2D) -> void:
	hobo_sprite_2d.play("hurt")
