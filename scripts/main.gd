extends Node
@onready var hobo = $Hobo


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hobo.died.connect(_on_player_died)

func _on_player_died():
	print("game over")
	get_tree().create_timer(3).timeout.connect(get_tree().reload_current_scene)
# Called every frame. 'delta' is the elapsed time since the previous frame.
