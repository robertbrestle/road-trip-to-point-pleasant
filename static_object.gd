extends RigidBody2D

@export var playerRef: Player

const SCALE_END: float = 1000
const VELOCITY_DELAY: float = 0.25

var original_linear_velocity: Vector2
var message: String = ""
var texture
var horizontal_flipped: bool = false

func _ready():
	# reference player for car_speed
	playerRef = get_tree().get_first_node_in_group("Player")
	# update sign label
	get_node("Sprite2D/SignLabel").text = message
	$Sprite2D.texture = texture
	$Sprite2D.flip_h = horizontal_flipped
	# save original velocity
	original_linear_velocity = linear_velocity
	# relative scale
	var scaled_size = get_scaled_size()
	$Sprite2D.scale = Vector2(scaled_size, scaled_size)

func _process(delta):
	if playerRef.car_speed == 0:
		linear_velocity = Vector2(0, 0)
		return
	
	# relative velocity
	linear_velocity = original_linear_velocity * playerRef.car_speed * ((self.global_position.y / 720) * VELOCITY_DELAY)
	
	# relative scale
	var scaled_size = get_scaled_size()
	$Sprite2D.scale = Vector2(scaled_size, scaled_size)
	#$SignLabel.scale = Vector2(scaled_size, scaled_size)
	#get_node("Sprite2D/SignLabel").scale = Vector2(scaled_size, scaled_size)
	
	#$SignLabel.position = $Sprite2D.position
	

func get_scaled_size():
	var scaled_size = self.global_position.y / SCALE_END
	if scaled_size > 1:
		scaled_size = 1
	return scaled_size

func _on_visible_on_screen_notifier_2d_screen_exited():
	if !playerRef.is_paused:
		queue_free()
