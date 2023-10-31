extends RigidBody2D

@export var playerRef: Player
var original_linear_velocity: Vector2

var is_mothman: bool = false
var mothman_texture

const SCALE_END: float = 700
const VELOCITY_DELAY: float = 0.25

# Called when the node enters the scene tree for the first time.
func _ready():
	playerRef = get_tree().get_first_node_in_group("Player")
	original_linear_velocity = linear_velocity
	#scale = Vector2(self.global_position.y / SCALE_END, self.global_position.y / SCALE_END)
	
	# relative scale
	var scaled_size = get_scaled_size()
	$AnimatedSprite2D.scale = Vector2(scaled_size, scaled_size)
	$CollisionShape2D.scale = Vector2(scaled_size, scaled_size)
	
	# fetch random mob
	if is_mothman:
		linear_velocity = original_linear_velocity * 200
		$AnimatedSprite2D.play("zzz_mothman")
	else:
		var mob_types = $AnimatedSprite2D.sprite_frames.get_animation_names()
		var mob = mob_types[randi() % (mob_types.size() - 1)]
		$AnimatedSprite2D.play(mob)
		
		var mob_animations = $AnimationPlayer.get_animation_list()
		var animation = mob_animations[randi() % mob_animations.size()];
		$AnimationPlayer.play(animation)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# if mothman, keep original velocity
	if not is_mothman:
		# if not mothman and speed is 0, stop mob
		if playerRef.car_speed == 0:
			linear_velocity = Vector2(0, 0)
			return
		# relative velocity
		linear_velocity = original_linear_velocity * playerRef.car_speed * ((self.global_position.y / 720) * VELOCITY_DELAY)
		
	
	$MobLabel.text = "Velocity = " + var_to_str(linear_velocity)
	
	# relative scale
	var scaled_size = get_scaled_size()
	$AnimatedSprite2D.scale = Vector2(scaled_size, scaled_size)
	$CollisionShape2D.scale = Vector2(scaled_size, scaled_size)
	
	#_animation_player.play("default")
	#$CollisionShape2D.scale = $AnimatedSprite2D.scale TODO: enable later


func get_scaled_size():
	var scaled_size = self.global_position.y / SCALE_END
	if scaled_size > 1:
		scaled_size = 1
	return scaled_size

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
