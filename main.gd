extends Node

@export var mob_scene: PackedScene
@export var static_object_scene: PackedScene
@export var repair_scene: PackedScene

@export var audio_enabled: bool = false
@export var is_paused: bool = false

var player_distance_last_mob_spawn: int
var spawn_mob_distance: int = 100

var elapsed_seconds: int = 0
var distance_traveled: float = 0

const DISTANCE_OFFSET: int = 160
const QUARTER_MILE: int = 1320
const FULL_MILE: int = 5280
const FINISH_DISTANCE: int = (FULL_MILE * 10) + DISTANCE_OFFSET


const ROAD_LINE_INTERVAL: float = 41.25 # 128th of a mile
var next_road_line: int = 0
var next_mile_marker: int = 0

var sign_texture
var road_line_texture
var hit_sounds = []
var spinout_sound
var tada_sound

# Called when the node enters the scene tree for the first time.
func _ready():
	# preload textures
	sign_texture = preload("res://art/sign.png")
	road_line_texture = preload("res://art/backgrounds/road_lines_3.png")
	# preload audio clips	
	hit_sounds.push_back(preload("res://audio/hit1.wav"))
	hit_sounds.push_back(preload("res://audio/hit2.wav"))
	hit_sounds.push_back(preload("res://audio/hit3.wav"))
	spinout_sound = preload("res://audio/screech.mp3")
	tada_sound = preload("res://audio/tada.mp3")
	
	if audio_enabled:
		$Music.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_paused:
		return
		
	$TestLabel.text = "Player.car_speed = " + var_to_str($Player.car_speed) + "\ndistance_traveled = " + var_to_str(distance_traveled) + "\nplayer_distance_last_mob_spawn = " + str(player_distance_last_mob_spawn) + "\nhealth = " + str($Player.health)
	
	if $Player.car_speed > 0:
		distance_traveled += $Player.car_speed / 2500
	
	if distance_traveled >= next_mile_marker:
		spawn_sign("Mile\n" + get_mileage_string(distance_traveled))
		next_mile_marker += QUARTER_MILE
	
	if distance_traveled >= next_road_line:
		spawn_road_line("left")
		spawn_road_line("right")
		next_road_line += ROAD_LINE_INTERVAL
	
	if distance_traveled >= FINISH_DISTANCE:
		game_over()
	
	$HUD.update_mileage(get_mileage_string(distance_traveled))
	$HUD.update_speedometer($Player.car_speed, $Player.TOP_SPEED)

func _on_hud_start_game():
	elapsed_seconds = 0
	distance_traveled = 0
	next_mile_marker = 0
	next_road_line = 0
	
	player_distance_last_mob_spawn = 0
	$Player.start($StartPosition.position, $PlayerBoundaryStart.global_position, $PlayerBoundaryEnd.global_position)
	
	$MobTimer.wait_time = 1
	$MobTimer.start()
	
	$ScoreTimer.wait_time = 1
	$ScoreTimer.start()
	
	$HUD.update_score(elapsed_seconds)
	$HUD.update_health($Player.health, $Player.health_max)
	
	# deletes all spawned nodes
	get_tree().call_group("despawn", "queue_free")
	
	# stop title music
	$Music.stop()
	
	is_paused = false

func _on_mob_timer_timeout():
	if player_distance_last_mob_spawn + spawn_mob_distance < distance_traveled:
		player_distance_last_mob_spawn = distance_traveled
		spawn_mob()
	if $Player.is_over_fast_threshold():
		$MobTimer.wait_time = randf_range(.3, 1)
	else:
		$MobTimer.wait_time = randf_range(.5, 2)

func spawn_mob():
	# create instance of the mob scene
	var mob = mob_scene.instantiate()
	mob.add_to_group("static")
	# choose spawn/despawn location
	var mob_spawn_location = get_node("MobPathStart/MobSpawnLocation")
	mob_spawn_location.progress_ratio = randf();
	var mob_despawn_location = get_node("MobPathEnd/MobDespawnLocation")
	mob_despawn_location.progress_ratio = randf();
	# set the mob's position to a NON-random location
	mob.position = mob_spawn_location.position
	mob.rotation = 0
	# set velocity - mob script multiplies velocity by player speed
	mob.linear_velocity = mob_spawn_location.position.direction_to(mob_despawn_location.position)

	add_child(mob)

func spawn_sign(message):
	var sign = static_object_scene.instantiate()
	sign.message = message
	sign.texture = sign_texture
	sign.add_to_group("static")
	sign.position = $SignStart.position
	sign.rotation = 0
	sign.linear_velocity = $SignStart.position.direction_to($SignEnd.position)
	add_child(sign)

func spawn_road_line(side):
	var road_line = static_object_scene.instantiate()
	road_line.message = ""
	road_line.texture = road_line_texture
	road_line.add_to_group("static")
	
	var spawn_location = get_node("MobPathStart/MobSpawnLocation")
	var despawn_location = get_node("MobPathEnd/MobDespawnLocation")
	if side == "left":
		spawn_location.progress_ratio = 0.33
		despawn_location.progress_ratio = 0.33
	elif side == "right":
		spawn_location.progress_ratio = 0.66
		despawn_location.progress_ratio = 0.665
		road_line.horizontal_flipped = true
	road_line.position = spawn_location.position
	road_line.position.y += 7
	road_line.rotation = 0
	road_line.linear_velocity = spawn_location.position.direction_to(despawn_location.position)
	add_child(road_line)

func start_repair_minigame():
	is_paused = true
	if audio_enabled:
		$CarHitSounds.stop()
		$CarHitSounds.stream = spinout_sound
		$CarHitSounds.play()
	$Player.start_spinout()
	$HUD.toggle_cluster(false)

func _on_player_spinout():
	$HUD.toggle_cluster(false)
	toggle_static(false)
	$RepairMinigame.visible = true
	$RepairMinigame.reset()

func _on_repair_minigame_complete():
	Input.set_custom_mouse_cursor(null)
	$RepairMinigame.visible = false
	$HUD.toggle_cluster(true)
	toggle_static(true)
	$Player.toggle_sprite(true)
	$Player.reset_health()
	$HUD.update_health($Player.health, $Player.health_max)
	$Player.is_paused = false
	is_paused = false

func get_mileage_string(distance):
	var true_distance = distance / FULL_MILE
	# force 2 decimal places of precision
	return "%.2f" % true_distance

func get_speed_string():
	var true_speed = $Player.car_speed / 5000
	return str("%.1f" % true_speed)

func _on_player_hit():
	# play sound effect
	if audio_enabled:
		$CarHitSounds.stream = hit_sounds[randi() % hit_sounds.size()]
		$CarHitSounds.play()
	
	$HUD.update_health($Player.health, $Player.health_max)
	if $Player.health == 0:
		start_repair_minigame()

func game_over():
	$MobTimer.stop()
	$ScoreTimer.stop()
	$Player.stop()
	$HUD.show_game_over("You made it to Point Pleasant!", elapsed_seconds, get_mileage_string(distance_traveled - DISTANCE_OFFSET), $Player.mobs_hit)
	is_paused = true
	if audio_enabled:
		$CarHitSounds.stop()
		$CarHitSounds.stream = tada_sound
		$CarHitSounds.play()

func _on_score_timer_timeout():
	elapsed_seconds += 1
	$HUD.update_score(elapsed_seconds)

func toggle_static(enabled):
	var nodes = get_tree().get_nodes_in_group("static")
	for n in nodes.size():
		nodes[n].visible = enabled
