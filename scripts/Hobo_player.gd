extends CharacterBody2D
class_name player_hobo
signal died
const SPEED = 300.0
const JUMP_VELOCITY = -650.0	
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
	
	if velocity.y > 0 and not is_on_floor() and is_jumping:  # Falling
		var fall_timer := 0.0  # Timer to control frame switch speed
		if hobo_sprite_2d.frame < 3 or hobo_sprite_2d.frame > 5:
			hobo_sprite_2d.frame = 3  # Reset to frame 6 if out of range
		
		fall_timer += delta
		if fall_timer >= 0.1:  # Adjust speed of frame switching
			fall_timer = 0
			hobo_sprite_2d.frame = 3 if hobo_sprite_2d.frame == 5 else 5  # Toggle between 4 and 5
	# If falling fast enough, trigger a high-fall animation
	if velocity.y > 0 and not is_on_floor() and !is_jumping:  # Adjust threshold as needed
		hobo_sprite_2d.frame = 6  # High fall frame

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

func _on_frame_changed():
	if hobo_sprite_2d.animation == "jump":
		if hobo_sprite_2d.frame >= 5:  # Stop at frame 5
			hobo_sprite_2d.frame = 5
			hobo_sprite_2d.stop()
	
func _on_animation_finished():
	# Reset jump flag when animation completes
	if hobo_sprite_2d.animation == "jump" and is_on_floor():
		print(hobo_sprite_2d.animation + " animation finished!")
		is_jumping = false
	elif hobo_sprite_2d.animation == "attack1":
		print(hobo_sprite_2d.animation + " animation finished!")
		is_attacking = false
	if hobo_sprite_2d.animation == "die":
		queue_free()  # Remove player after death animation


func _on_hobo_hitbox_body_entered(body: Node2D) -> void:
	if body is zombie:
		died.emit()
		set_physics_process(false)  # Stop movement updates
		velocity = Vector2.ZERO  # Stop player from moving
		hobo_sprite_2d.play("die")
		set_collision_layer_value(1, false)  # Disable player collision
		set_collision_mask_value(1, false)  # Prevent interactions
		
