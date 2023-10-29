extends Node2D

signal complete

var textures = {}
var names = {}
var section_names = {}
var tool_sounds = {}

var instructions = []
var current_instruction = {}

var tool: String = ""
var section: String = ""

@export var audio_enabled: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	textures = {
		"drill": preload("res://art/icons/drill.png"),
		"hammer": preload("res://art/icons/hammer.png"),
		"wrench": preload("res://art/icons/wrench.png"),
		"fluid": preload("res://art/icons/fluid.png"),
		"screwdriver": preload("res://art/icons/screwdriver.png")
	}
	names = {
		"drill": "Drill",
		"hammer": "Hammer",
		"wrench": "Wrench",
		"fluid": "Fill",
		"screwdriver": "Screwdrive"
	}
	section_names = {
		"battery": "battery and fusebox",
		"engine": "engine",
		"alternator": "alternator",
		"fluids": "fluid lines",
		"air": "air filter"
	}
	tool_sounds = {
		"drill": preload("res://audio/repair/drill.mp3"),
		"hammer": preload("res://audio/repair/hammer.mp3"),
		"wrench": preload("res://audio/repair/wrench.mp3"),
		"fluid": preload("res://audio/repair/fluid.mp3"),
		"screwdriver": preload("res://audio/repair/drill.mp3"),
		"bad": preload("res://audio/hit3.wav")
	}
	
	#reset()

func reset():
	instructions = []
	current_instruction = {}
	# determine tool percentages
	var tool_list = names.keys()
	var section_list = section_names.keys()
	var num_instructions = randi_range(2,8)
	var num_user_actions: int = 0
	var last_section: String = ""
	
	for n in num_instructions:
		var inst_tool = tool_list[randi() % tool_list.size()]
		var inst_section = section_list[randi() % section_list.size()]
		while last_section == inst_section:
			inst_section = section_list[randi() % section_list.size()]
		var inst_amount = randi_range(2, 8)
		
		num_user_actions += inst_amount
		last_section = inst_section
		
		instructions.push_back({
			"tool": inst_tool,
			"section": inst_section,
			"amount": inst_amount,
			"tool_name": names[inst_tool],
			"section_name": section_names[inst_section]
		})
	
	$ProgressBar.value = 0
	$ProgressBar.max_value = num_user_actions
	
	Input.set_custom_mouse_cursor(null)
	
	get_next_instruction()

func _process(delta):
	if Input.is_action_just_released("1"):
		_on_screwdriver_texture_button_pressed()
	if Input.is_action_just_released("2"):
		_on_fluid_texture_button_pressed()
	if Input.is_action_just_released("3"):
		_on_drill_texture_button_pressed()
	if Input.is_action_just_released("4"):
		_on_hammer_texture_button_pressed()
	if Input.is_action_just_released("5"):
		_on_wrench_texture_button_pressed()

func set_mouse_cursor(key):
	if key != null:
		Input.set_custom_mouse_cursor(textures[key])
	else:
		Input.set_custom_mouse_cursor(null)

func _on_drill_texture_button_pressed():
	tool = "drill"
	set_mouse_cursor(tool)

func _on_hammer_texture_button_pressed():
	tool = "hammer"
	set_mouse_cursor(tool)

func _on_wrench_texture_button_pressed():
	tool = "wrench"
	set_mouse_cursor(tool)

func _on_fluid_texture_button_pressed():
	tool = "fluid"
	set_mouse_cursor(tool)

func _on_screwdriver_texture_button_pressed():
	tool = "screwdriver"
	set_mouse_cursor(tool)


func process_action(section):
	if current_instruction.size() == 0:
		return
	if current_instruction.tool == tool and current_instruction.section == section:
		current_instruction.amount -= 1
		$ProgressBar.value += 1
		if audio_enabled:
			$ToolSound.stream = tool_sounds[tool]
			$ToolSound.play()
		if current_instruction.amount <= 0:
			get_next_instruction()
	else:
		current_instruction.amount += 1
		$ProgressBar.max_value += 1
		if audio_enabled:
			$ToolSound.stream = tool_sounds["bad"]
			$ToolSound.play()
	if current_instruction.size() > 0:
		$Label.text = current_instruction.tool_name + " the " + current_instruction.section_name + " " + str(current_instruction.amount) + " times!"

func get_next_instruction():
	if instructions.size() > 0:
		current_instruction = instructions.pop_front()
		$Label.text = current_instruction.tool_name + " the " + current_instruction.section_name + " " + str(current_instruction.amount) + " times!"
	else:
		current_instruction = {}
		Input.set_custom_mouse_cursor(null)
		$Label.text = "Repair complete!"
		complete.emit()

func _on_battery_area_input_event(viewport, event, shape_idx):
	if (
		event is InputEventMouseButton and
		event.button_index == MOUSE_BUTTON_LEFT and
		event.is_pressed()
	):
		process_action("battery")

func _on_engine_area_input_event(viewport, event, shape_idx):
	if (
		event is InputEventMouseButton and
		event.button_index == MOUSE_BUTTON_LEFT and
		event.is_pressed()
	):
		process_action("engine")

func _on_alternator_area_input_event(viewport, event, shape_idx):
	if (
		event is InputEventMouseButton and
		event.button_index == MOUSE_BUTTON_LEFT and
		event.is_pressed()
	):
		process_action("alternator")

func _on_fluids_area_input_event(viewport, event, shape_idx):
	if (
		event is InputEventMouseButton and
		event.button_index == MOUSE_BUTTON_LEFT and
		event.is_pressed()
	):
		process_action("fluids")

func _on_air_area_input_event(viewport, event, shape_idx):
	if (
		event is InputEventMouseButton and
		event.button_index == MOUSE_BUTTON_LEFT and
		event.is_pressed()
	):
		process_action("air")
