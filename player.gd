extends Area2D

class_name Player

signal hit
signal spinout

# movement speed
@export var car_speed: float = 0

@export var health: int = 1
@export var health_max: int = 7
@export var is_hit: bool = false

@export var is_paused: bool = false

@export var mobs_hit: int = 0


const HORIZONTAL_SPEED_MAX: float = 800

const FAST_THRESHOLD: float = 6500
const ULTRA_FAST_THRESHOLD: float = 10400
const TOP_SPEED: float = 13000

const SPEED_ACCELERATION: int = 20
const SPEED_DECELERATION: int = 40
const SPEED_E_BRAKE: int = 200
const HIT_PENALTY: int = 1000

var is_game_over: bool = false


var screen_size: Vector2
var boundary_start: Vector2
var boundary_end: Vector2
var animation_left: int
var animation_right: int

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size
	hide()

func start(pos, boundaryStart, boundaryEnd):
	car_speed = 0
	mobs_hit = 0
	
	is_game_over = false
	position = pos
	boundary_start = Vector2(boundaryStart)
	boundary_end = Vector2(boundaryEnd)
	
	# determine animation threshold
	animation_left = (screen_size.x / 3)
	animation_right = (screen_size.x / 3) * 2
	
	reset_health()
	is_hit = false
	
	show()
	$CollisionShape2D.disabled = false
	
func stop():
	car_speed = 0
	is_game_over = true
	$HitTimer.stop()
	hide()

func is_over_fast_threshold():
	return car_speed > FAST_THRESHOLD

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_game_over || is_paused:
		return
	
	var velocity = Vector2.ZERO # the player's movement vector
	
	# TODO: add decaying velocity
	
	if not Input.is_anything_pressed():
		$SpinoutSound.stop()
	
	# move side to side
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1

	# change velocity
	if Input.is_action_pressed("e_brake") and car_speed > 0:
		car_speed -= SPEED_E_BRAKE
		if not $SpinoutSound.playing:
			$SpinoutSound.play()
	elif Input.is_action_pressed("move_down") and car_speed > 0:
		$SpinoutSound.stop()
		car_speed -= SPEED_DECELERATION
	elif Input.is_action_pressed("move_up") and car_speed < TOP_SPEED:
		$SpinoutSound.stop()
		car_speed += SPEED_ACCELERATION
	# prevent negative speeds
	if car_speed < 0:
		car_speed = 0
	
	$Label.text = "car_speed = " + var_to_str(car_speed)
	
	if velocity.length() > 0:
		# scale horizontal speed relative to car_speed
		if car_speed < HORIZONTAL_SPEED_MAX:
			velocity = velocity.normalized() * car_speed
		else:
			var speed_penalty = FAST_THRESHOLD / car_speed
			# if player is going above FAST_THRESHOLD, apply a negative modifier to the horizontal movement
			if speed_penalty < 1:
				velocity = velocity.normalized() * HORIZONTAL_SPEED_MAX * speed_penalty
			else: # apply regular horizontal max speed
				velocity = velocity.normalized() * HORIZONTAL_SPEED_MAX
		
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
	
	#$Label.text = "Player.velocity = " + var_to_str(velocity)
		
	# prevent player from leaving the screen
	position += velocity * delta
	#position = position.clamp(Vector2.ZERO, screen_size)
	position = position.clamp(boundary_start, boundary_end)
	
	# determine animation based on screen position
	if position.x < animation_left:
		$AnimatedSprite2D.animation = "left"
	elif position.x > animation_right:
		$AnimatedSprite2D.animation = "right"
	else:
		$AnimatedSprite2D.animation = "center"
	
	# change animation based on speed
	if is_hit:
		$AnimationPlayer.play("hit")
	elif car_speed == 0:
		$AnimationPlayer.stop()
	elif car_speed > ULTRA_FAST_THRESHOLD:
		$AnimationPlayer.play("ultra")
	elif car_speed > FAST_THRESHOLD:
		$AnimationPlayer.play("fast")
	else:
		$AnimationPlayer.play("slow")

func _on_body_entered(body):
	# remove enemy
	body.queue_free()
	
	mobs_hit += 1
	
	# if hit, ignore penalty
	if is_hit:
		return
	is_hit = true
	
	health -= 1
	car_speed -= HIT_PENALTY
	if car_speed < 0:
		car_speed = 0
	
	hit.emit()
	
	$HitTimer.start()

func _on_hit_timer_timeout():
	is_hit = false
	if !is_paused:
		$AnimatedSprite2D.visible = true

func toggle_sprite(enabled):
	$AnimatedSprite2D.visible = enabled

func reset_health():
	health = health_max

func start_spinout():
	is_paused = true
	car_speed = 0
	$AnimatedSprite2D.visible = true
	$AnimationPlayer.stop()
	$AnimationPlayer.play("spin")
	$SpinoutTimer.start()


func _on_spinout_timer_timeout():
	$SpinoutTimer.stop()
	toggle_sprite(false)
	spinout.emit()
