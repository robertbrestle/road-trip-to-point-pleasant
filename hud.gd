extends CanvasLayer

signal start_game

const ICON_SIZE: int = 32
const ICON_OFFSET: int = 48
const ICON_SCALE: float = .5
const MAX_ICONS: int = 5

const SPEED_ROTATION_MAX: float = 300
const SPEED_ROTATION_OFFSET: float = -150
const SPEED_ROTATION_SHAKE: float = 90

func _on_start_button_pressed():
	start_new_game()

func _on_restart_button_pressed():
	$TitleScreen.show()
	$SuccessScreen.hide()
	$ScoreLabel.hide()
	hide_all_icons()
	
func start_new_game():
	$TitleScreen.hide()
	$SuccessScreen.hide()
	$ScoreLabel.show()
	start_game.emit()
	$FuelAnimationPlayer.play("default")
	$OilAnimationPlayer.play("default")
	$IconAnimationPlayer.stop()
	hide_all_icons()

# update the health display
func update_health(health, health_max):
	hide_all_icons()
	var icons_to_show = health_max - health
	if icons_to_show == 0:
		return
	
	var icons = get_tree().get_nodes_in_group("icons")
	
	for n in icons_to_show:
		if n == MAX_ICONS:
			break
		icons[n].visible = true
	
	if icons_to_show > MAX_ICONS:
		$IconAnimationPlayer.play("engine_flash")
	

func hide_all_icons():
	$IconAnimationPlayer.stop()
	var icons = get_tree().get_nodes_in_group("icons")
	for i in icons:
		i.visible = false

# update the running time
func update_score(time):
	$ScoreLabel.text = str(get_time_string(time))

func update_mileage(distance):
	$MilageLabel.text = distance

func update_speedometer(speed, max_speed):
	if speed == 0:
		$SpeedNeedle.rotation_degrees = SPEED_ROTATION_OFFSET
		return
	
	#$SpeedLabel.text = speed
	var speed_percentage = (speed / max_speed) * SPEED_ROTATION_MAX
	var new_rotation = SPEED_ROTATION_OFFSET + speed_percentage
	if new_rotation >= SPEED_ROTATION_SHAKE:
		new_rotation += (randi() % 10) - 5
	else:
		new_rotation += (randi() % 2) - 1
	$SpeedLabel.text = str(new_rotation)
	$SpeedNeedle.rotation_degrees = new_rotation

# get a string representation of the time as "mm:ss"
func get_time_string(time):
	var minutes: int = time / 60
	var seconds: int = fmod(time, 60)
	var time_string := "%02d:%02d" % [minutes, seconds]
	return str(time_string)

# show the game over screens
func show_game_over(title, time, distance, mobs_hit):
	$ScoreLabel.hide()
	get_node("SuccessScreen/TitleLabel").text = title
	get_node("SuccessScreen/DistanceLabel").text = distance + " miles in " + get_time_string(time)
	get_node("SuccessScreen/PenaltyLabel").text = str(mobs_hit) + " enemies hit"
	$SuccessScreen.show()

func toggle_cluster(enabled):
	var nodes = get_tree().get_nodes_in_group("cluster")
	for n in nodes.size():
		nodes[n].visible = enabled
