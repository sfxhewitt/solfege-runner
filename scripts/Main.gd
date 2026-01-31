extends Control

# Simple voice-controlled solfege runner
# Godot 4.x

@onready var lane: ColorRect = $Lane
@onready var player: ColorRect = $Player
@onready var label: Label = $HUD/Label
@onready var status_label: Label = $HUD/Status
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

# Solfege sequence (C major)
var solfege_names := ["Do","Re","Mi","Fa","Sol","La","Ti","Do"]
# Frequencies for C4..C5
var solfege_freqs := [261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88, 523.25]
var current_index := 0

# Lane and obstacles
var player_speed := 0.25 # lane units per second
var obstacle_speed := 0.20
var obstacles := []
var obstacle_timer := 0.0
var spawn_interval := 2.0

# Pitch detection
var capture_bus := "Capture"
var capture_effect: AudioEffectCapture
var sample_rate := 48000
var last_pitch := 0.0

# Motion / bounce
var player_y_vel := 0.0
var bounce_strength := 18.0
var bounce_damping := 0.86

# Tuning / tolerance
var cents_tolerance := 50.0

func _ready():
	# Set up audio capture bus
	var bus_idx = AudioServer.get_bus_index(capture_bus)
	if bus_idx == -1:
		AudioServer.add_bus(AudioServer.bus_count)
		bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_idx, capture_bus)
		AudioServer.set_bus_volume_db(bus_idx, 0)

	# Ensure capture effect exists
	if AudioServer.get_bus_effect_count(bus_idx) == 0:
		capture_effect = AudioEffectCapture.new()
		AudioServer.add_bus_effect(bus_idx, capture_effect, 0)
	else:
		capture_effect = AudioServer.get_bus_effect(bus_idx, 0)

	# Start mic recording (requires permission on some platforms)
	sample_rate = AudioServer.get_mix_rate()
	var mic = AudioStreamMicrophone.new()
	audio_player.stream = mic
	audio_player.bus = capture_bus
	audio_player.play()

	_position_player()
	_update_labels()
	status_label.text = "Mic ready"

func _process(delta):
	# Update pitch
	var pitch = _detect_pitch()
	if pitch > 0:
		last_pitch = pitch
	
	# Determine target and move player
	var target_freq = solfege_freqs[current_index]
	var in_tune = _is_in_tune(last_pitch, target_freq)
	
	# Forward movement only if in tune
	if in_tune:
		player.position.x = lerp(player.position.x, lane.position.x + lane.size.x * 0.75, delta * player_speed * 6.0)
		status_label.text = "In tune!"
	else:
		player.position.x = lerp(player.position.x, lane.position.x + lane.size.x * 0.25, delta * player_speed * 6.0)
		status_label.text = "Off pitch — bounce back"

	# Vertical bounce (return to lane center when off pitch)
	var target_y = _lane_center(current_index)
	if in_tune:
		# Stick to target lane
		player_y_vel = (target_y - player.position.y) * 0.35
	else:
		# Bounce away and settle
		player_y_vel += (target_y - player.position.y) * 0.02
		player_y_vel *= bounce_damping
	player.position.y += player_y_vel

	# Obstacle generation and movement
	obstacle_timer += delta
	if obstacle_timer >= spawn_interval:
		_spawn_obstacle()
		obstacle_timer = 0.0

	_update_obstacles(delta)
	_check_collisions(in_tune)
	_update_labels()

func _position_player():
	player.position = Vector2(lane.position.x + lane.size.x * 0.25, _lane_center(current_index))

func _lane_center(idx: int) -> float:
	var step = lane.size.y / float(solfege_names.size())
	return lane.position.y + step * (idx + 0.5)

func _update_labels():
	var target_name = solfege_names[current_index]
	label.text = "Pitch: %s Hz | Target: %s" % [str(round(last_pitch)), target_name]

func _spawn_obstacle():
	# gap follows solfege order
	var step = 1.0 / float(solfege_names.size())
	var gap_center = step * (current_index + 0.5)
	var gap_size = 0.20
	var obs = {
		"x": 1.1,
		"gap_min": gap_center - gap_size * 0.5,
		"gap_max": gap_center + gap_size * 0.5,
		"node": _create_obstacle_node(),
		"target_index": current_index
	}
	obstacles.append(obs)

func _create_obstacle_node() -> Node2D:
	var node = Node2D.new()
	add_child(node)
	# Draw two rectangles with a gap
	var top = ColorRect.new()
	top.color = Color(0.7,0.2,0.2,1)
	node.add_child(top)
	var bottom = ColorRect.new()
	bottom.color = Color(0.7,0.2,0.2,1)
	node.add_child(bottom)
	return node

func _update_obstacles(delta):
	for obs in obstacles:
		obs["x"] -= obstacle_speed * delta
		var x_px = lane.position.x + obs["x"] * lane.size.x
		var gap_min_px = lane.position.y + obs["gap_min"] * lane.size.y
		var gap_max_px = lane.position.y + obs["gap_max"] * lane.size.y
		var node: Node2D = obs["node"]
		var top: ColorRect = node.get_child(0)
		var bottom: ColorRect = node.get_child(1)
		# Top block
		top.position = Vector2(x_px - 10, lane.position.y)
		top.size = Vector2(20, gap_min_px - lane.position.y)
		# Bottom block
		bottom.position = Vector2(x_px - 10, gap_max_px)
		bottom.size = Vector2(20, (lane.position.y + lane.size.y) - gap_max_px)

	# Remove off-screen
	for i in range(obstacles.size() - 1, -1, -1):
		if obstacles[i]["x"] < -0.1:
			obstacles[i]["node"].queue_free()
			obstacles.remove_at(i)

func _check_collisions(in_tune: bool):
	# if player reaches the right edge, advance solfege target
	if player.position.x > lane.position.x + lane.size.x * 0.7 and in_tune:
		current_index = (current_index + 1) % solfege_names.size()

	# simple collision: if an obstacle passes player x and player y is not in gap
	for obs in obstacles:
		var obs_x = lane.position.x + obs["x"] * lane.size.x
		if abs(obs_x - player.position.x) < 26:
			var p_y = player.position.y + player.size.y * 0.5
			if p_y < lane.position.y + obs["gap_min"] * lane.size.y or p_y > lane.position.y + obs["gap_max"] * lane.size.y:
				# collision, bounce back and reset index
				player.position.x = lane.position.x + lane.size.x * 0.25
				current_index = 0
				status_label.text = "Hit obstacle! Back to Do."

# --- Pitch detection ---
func _detect_pitch() -> float:
	if capture_effect == null:
		return 0.0
	var frames = capture_effect.get_frames_available()
	if frames < 512:
		return last_pitch
	var use_frames = min(frames, 2048)
	var data = capture_effect.get_buffer(use_frames)
	# Convert to mono float array
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(data.size())
	for i in range(data.size()):
		samples[i] = data[i].x
	return _autocorrelation_pitch(samples, sample_rate)

func _autocorrelation_pitch(samples: PackedFloat32Array, rate: int) -> float:
	var size = samples.size()
	if size < 1024:
		return 0.0
	# Remove DC
	var mean = 0.0
	for s in samples:
		mean += s
	mean /= size
	for i in range(size):
		samples[i] -= mean
	# Autocorrelation
	var max_lag = int(rate / 60) # ~60 Hz low bound
	var min_lag = int(rate / 1000) # ~1kHz high bound
	var best_lag = 0
	var best_val = 0.0
	for lag in range(min_lag, max_lag):
		var sum = 0.0
		for i in range(size - lag):
			sum += samples[i] * samples[i + lag]
		if sum > best_val:
			best_val = sum
			best_lag = lag
	if best_lag == 0:
		return 0.0
	return float(rate) / float(best_lag)

func _is_in_tune(pitch: float, target: float) -> bool:
	if pitch <= 0:
		return false
	var cents = 1200.0 * log(pitch / target) / log(2.0)
	return abs(cents) <= cents_tolerance
