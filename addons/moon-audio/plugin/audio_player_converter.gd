@tool
extends EditorContextMenuPlugin

const AUDIO_EVENT_PLAYER = preload("uid://83ubxhl30in2")

func _popup_menu(paths: PackedStringArray) -> void:
	var audio_stream_players: Array[Node] = []
	var audio_event_players: Array[AudioEventPlayer] = []
	
	for p in paths:
		var node: Node = Engine.get_main_loop().edited_scene_root.get_node(p)
		if node is AudioEventPlayer:
			audio_event_players.append(node)
		elif node is AudioStreamPlayer:
			audio_stream_players.append(node)
		elif node is AudioStreamPlayer2D:
			audio_stream_players.append(node)
		elif node is AudioStreamPlayer3D:
			audio_stream_players.append(node)
	
	if audio_stream_players:
		add_context_menu_item("Convert to AudioEventPlayer", _convert_to_events.bind(audio_stream_players), AUDIO_EVENT_PLAYER)
	
	if audio_event_players:
		# i'm not interested in adding a two-way converter, but the hook is here
		pass

func _convert_to_events(_x, asps: Array[Node]):
	for asp in asps:
		if not asp.is_inside_tree():
			continue
		
		# Create corresponding audio event.
		var event := AudioEvent.new()
		var stream := AudioEventStream.new()
		var audio_stream: AudioStream = asp.stream
		stream.stream = asp.stream
		event.volume_db = asp.volume_db
		event.pitch_scale = asp.pitch_scale
		event.audio_bus = asp.bus
		event.max_polyphony = asp.max_polyphony
		if audio_stream and audio_stream._has_loop():
			event.persistent = false
		event.streams.append(stream)
		
		# Setup positionality.
		if asp is AudioStreamPlayer2D:
			event.positional = AudioEvent.Positional._2D
			event.positional_preset = AudioPositionalPreset2D.create_from_stream_player(asp)
		elif asp is AudioStreamPlayer3D:
			event.positional = AudioEvent.Positional._3D
			event.positional_preset = AudioPositionalPreset3D.create_from_stream_player(asp)
		
		# Setup with new player.
		var aep := AudioEventPlayer.new()
		aep.event = event
		asp.get_parent().add_child(aep)
		aep.owner = asp.owner
		aep.autoplay = asp.autoplay
		var asp_name := asp.name
		asp.name += "-OLD"
		aep.name = asp_name.replace("Stream", "Event")
