@tool
@icon("res://addons/moon-audio/icons/audio_event.png")
extends Resource
class_name AudioEvent
## Models the playback of dynamic audio, with various parameter modulation options.

#region Exports

enum Positional {
	Off,  ## The event is played with no positional attenuation.
	_2D,  ## The event is played with 2D positional attenuation.
	_3D,  ## the event is played with 3D positional attenuation.
}

## Models all audio events played on the audio event.
@export var streams: Array[AudioEventStream] = []

#region Testing

static var editor_positional_root: Node = null

static var editor_active_events: Array[ActiveAudioEvent] = []

@warning_ignore_start("unused_private_class_variable")
@export_tool_button("Play", "Play") var _1 = _test_play
@export_tool_button("Release", "MoveUp") var _2 = _test_release
@export_tool_button("Stop", "Stop") var _3 = _test_stop
@warning_ignore_restore("unused_private_class_variable")

func _test_play():
	if not editor_positional_root:
		editor_positional_root = Node.new()
		Engine.get_singleton(&"EditorInterface").get_base_control().add_child(editor_positional_root)
	
	var p := positional
	var db := volume_db
	positional = Positional.Off
	volume_db -= 10.0
	
	var e := play(editor_positional_root)
	editor_active_events.append(e)
	e.finished.connect(_test_handle_finished.bind(e))
	
	set_block_signals(true)
	volume_db = db
	positional = p
	set_block_signals(false)

func _test_release():
	for aae in editor_active_events.duplicate():
		aae.release()

func _test_stop():
	for aae in editor_active_events.duplicate():
		aae.stop()

func _test_handle_finished(aae: ActiveAudioEvent):
	editor_active_events.erase(aae)

#endregion

@export_group("Settings")

## The audio bus this event is played on.
@export var audio_bus := "Master":
	set(x):
		audio_bus = x
		emit_changed()

## Determines if this event is positional.
## Positional transforms are associated with the parent node the event is created with.
@export var positional := Positional.Off:
	set(x):
		positional = x
		notify_property_list_changed()

## Persistent events will continue playback even if their parent cleans up.
## This is done by reparenting the node to the viewport.
@export var persistent := true:
	set(x):
		persistent = x
		emit_changed()

## The number of instances of this audio event that can be playing at any given time.
## Upon exceeding this amount, older instances are forcefully cleaned up.
@export_range(0, 8, 1, "or_greater", "suffix:instance") var max_polyphony := 0.0:
	set(x):
		max_polyphony = x
		emit_changed()

@export_group("Mixing")

## Volume adjustment for the audio event.
@export_range(-24.0, 24.0, 0.01, "or_less", "or_greater", "suffix:dB") var volume_db := 0.0:
	set(x):
		volume_db = clampf(x, -80.0, 48.0)
		emit_changed()

## Pitch adjustment for the whole audio event.
@export_range(0.01, 4.0, 0.01, "or_greater", "suffix:x") var pitch_scale := 1.0:
	set(x):
		pitch_scale = x
		emit_changed()

@export_group("Positional", "positional_")

## If true, the audio position is actively tracked across the lifetime of the event instantiation.
## Otherwise, the audio source is only positioned at the initial audio emission.
@export var positional_tracking := true:
	set(x):
		positional_tracking = x
		emit_changed()

## A preset resource used for modelling audio falloff.
@export var positional_preset: Resource:
	set(x):
		if positional_preset:
			positional_preset.changed.disconnect(emit_changed)
		positional_preset = x
		if positional_preset:
			positional_preset.changed.connect(emit_changed)
		emit_changed()

#endregion

## All active events currently playing within this AudioEvent.
var active_events: Array[ActiveAudioEvent] = []

## Creates an active instantiation of the AudioEvent and associates it with a parent node.
## The positional parent is optional, but can be used to target a specific node for positional tracking.
func play(parent: Node, positional_parent: Node = null) -> ActiveAudioEvent:
	var aae := ActiveAudioEvent.new()
	aae.event = self
	aae.positional_parent = positional_parent if positional_parent else parent
	active_events.append(aae)
	aae.finished.connect(_handle_finished.bind(aae))
	parent.add_child(aae)
	
	if max_polyphony and active_events.size() > max_polyphony:
		var oldest_aae: ActiveAudioEvent = active_events.pop_front()
		oldest_aae.stop()
	
	return aae

func _handle_finished(aae: ActiveAudioEvent):
	active_events.erase(aae)

func _validate_property(property: Dictionary) -> void:
	if not Engine.is_editor_hint():
		return
	if property.name == &"audio_bus":
		property.hint = PROPERTY_HINT_ENUM
		var buses := PackedStringArray()
		for idx in AudioServer.bus_count:
			buses.append(AudioServer.get_bus_name(idx))
		property.hint_string = ",".join(buses)
	
	match positional:
		Positional.Off:
			if property.name.begins_with("positional_"):
				property.usage = 0
		Positional._2D:
			if property.name == &"positional_preset":
				property.hint_string = "AudioPositionalPreset2D"
		Positional._3D:
			if property.name == &"positional_preset":
				property.hint_string = "AudioPositionalPreset3D"

static var _lateloads: Dictionary[String, AudioEvent] = {}

static func lateload(path: String) -> AudioEvent:
	if path not in _lateloads:
		_lateloads[path] = load(path)
	return _lateloads[path]

static func lateplay(path: String, parent: Node, positional_parent: Node = null) -> ActiveAudioEvent:
	return lateload(path).play(parent, positional_parent)
