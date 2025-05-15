@tool
@icon("res://addons/moonAudio/icons/active_audio_event.png")
extends Node
## The live instantiation of an AudioEvent.

## Emitted once this event is finished (or was stopped or cleaned up early).
signal finished

var _has_finished := false

## Master volume control on this event.
var volume_db := 0.0:
	set(x):
		volume_db = x
		if is_node_ready():
			_update_volume()

## Master pitch scale control on this audio event.
var pitch_scale := 1.0:
	set(x):
		pitch_scale = x
		if is_node_ready():
			_update_pitch_scale()

## The event this ActiveAudioEvent is associated with. Set from the event.
var event: AudioEvent:
	set(x):
		if event:
			event.changed.disconnect(_hot_update)
		event = x
		if event:
			event.changed.connect(_hot_update)
		if is_node_ready():
			_hot_update()

## The parent node whose positional properties are read. Set from the event.
var positional_parent: Node = null

## A mapping from each stream to their respective audio stream player.
var audio_players: Dictionary[AudioEventStream, Node] = {}

## All tweens for the audio attack.
var attack_tweens: Array[Tween] = []

func _ready() -> void:
	# Setup state.
	set_physics_process(positional_parent != null and event.positional_tracking and event.positional != AudioEvent.Positional.Off)
	process_physics_priority = 1000
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	
	# Create all event streams.
	for stream in event.streams:
		# Create the AudioStreamPlayer.
		var ap: Node
		match event.positional:
			AudioEvent.Positional.Off:
				ap = AudioStreamPlayer.new()
			AudioEvent.Positional._2D:
				ap = AudioStreamPlayer2D.new()
				ap.top_level = true
			AudioEvent.Positional._3D:
				ap = AudioStreamPlayer3D.new()
				ap.top_level = true
		
		# Setup the base properties.
		ap.stream = stream.stream
		ap.volume_db = event.volume_db + stream.volume_db + volume_db
		ap.pitch_scale = event.pitch_scale * stream.pitch_scale * pitch_scale
		ap.bus = event.audio_bus
		audio_players[stream] = ap
		add_child(ap)
		_update_ap_positionality(ap)
		
		# Setup the playback.
		if not stream.delay:
			ap.play()
			
			if stream.attack_duration:
				var t := create_tween()
				t.tween_property(ap, ^"volume_linear", ap.volume_linear, float(stream.attack_duration) * 0.001).from(0.0)
				ap.volume_linear = 0.0
				attack_tweens.append(t)
		else:
			var t := create_tween()
			t.tween_interval(float(stream.delay) * 0.001)
			t.tween_callback(ap.play)
			
			if stream.attack_duration:
				t.tween_property(ap, ^"volume_linear", ap.volume_linear, float(stream.attack_duration) * 0.001).from(0.0)
				ap.volume_linear = 0.0
			attack_tweens.append(t)
		
		# Setup stream callback.
		_awaiting_streams[ap] = null
		ap.finished.connect(_stream_finished.bind(ap))

var released := false

## Releases the event, allowing fade-outs for streams.
func release():
	if released:
		return
	released = true
	
	# Pause all tweens.
	for t in attack_tweens:
		if t.is_running():
			t.pause()
	
	# End active players.
	for stream in audio_players:
		var ap := audio_players[stream]
		if ap in _awaiting_streams.keys():
			if ap.playing:
				if not stream.release_duration:
					# Playing, stop it immediately and release it.
					ap.stop()
					_stream_finished(ap)
				else:
					# Playing, has fade out, so do that.
					var t := create_tween()
					t.tween_property(ap, ^"volume_linear", 0.0, float(stream.release_duration) * 0.001)
					t.tween_callback(_stream_finished.bind(ap))
			else:
				# Not playing, just release it.
				_stream_finished(ap)

## Force stops the event immediately.
func stop():
	for ap in _awaiting_streams.keys():
		_stream_finished(ap)

var _awaiting_streams: Dictionary[Node, Object] = {}

func _stream_finished(ap: Node):
	if ap in _awaiting_streams:
		_awaiting_streams.erase(ap)
		if not _awaiting_streams:
			queue_free()
			_emit_finished()

func _update_volume():
	for stream in audio_players:
		var ap := audio_players[stream]
		ap.volume_db = event.volume_db + stream.volume_db + volume_db

func _update_pitch_scale():
	for stream in audio_players:
		var ap := audio_players[stream]
		ap.pitch_scale = event.pitch_scale * stream.pitch_scale * pitch_scale

func _hot_update():
	_update_volume()
	_update_pitch_scale()
	
	set_physics_process(positional_parent != null and event.positional_tracking and event.positional != AudioEvent.Positional.Off)
	for stream in audio_players:
		var ap := audio_players[stream]
		ap.bus = event.audio_bus
		_update_ap_positionality(ap)

func _update_ap_positionality(ap: Node):
	match event.positional:
		AudioEvent.Positional._2D:
			var preset: AudioPositionalPreset2D = event.positional_preset
			if preset:
				ap.attenuation = preset.attenuation
				ap.max_distance = preset.max_distance
				ap.panning_strength = preset.panning_strength
				ap.area_mask = preset.area_mask
			if positional_parent:
				var pp: Node2D = positional_parent
				ap.global_transform = pp.global_transform
		AudioEvent.Positional._3D:
			var preset: AudioPositionalPreset3D = event.positional_preset
			if preset:
				ap.attenuation_model = preset.attenuation_model
				ap.unit_size = preset.unit_size
				ap.max_distance = preset.max_distance
				ap.panning_strength = preset.panning_strength
				ap.area_mask = preset.area_mask
				ap.doppler_tracking = preset.doppler
				ap.emission_angle_enabled = preset.emission_angle_enabled
				ap.emission_angle_degrees = preset.emission_angle_degrees
				ap.emission_angle_filter_attenuation_db = preset.emission_angle_filter_attenuation_db
				ap.attenuation_filter_cutoff_hz = preset.attenuation_filter_cutoff_hz if preset.attenuation_filter_enabled else 20500
				ap.attenuation_filter_db = preset.attenuation_filter_db
			if positional_parent:
				var pp: Node3D = positional_parent
				ap.global_transform = pp.global_transform

func _physics_process(delta: float) -> void:
	if not positional_parent or not is_instance_valid(positional_parent):
		set_physics_process(false)
		return
	match event.positional:
		AudioEvent.Positional._2D:
			var pp: Node2D = positional_parent
			for ap: AudioStreamPlayer2D in _awaiting_streams:
				ap.global_transform = pp.global_transform
		AudioEvent.Positional._3D:
			var pp: Node3D = positional_parent
			for ap: AudioStreamPlayer3D in _awaiting_streams:
				ap.global_transform = pp.global_transform

func _notification(what: int) -> void:
	if not Engine.is_editor_hint():
		if what == NOTIFICATION_EXIT_TREE and _awaiting_streams and event.persistent:
			is_queued_for_deletion()
			reparent(get_viewport())
		if what == NOTIFICATION_PREDELETE:
			if _awaiting_streams and event.persistent:
				cancel_free()
			else:
				_emit_finished()

func _emit_finished():
	if not _has_finished:
		_has_finished = true
		finished.emit()
