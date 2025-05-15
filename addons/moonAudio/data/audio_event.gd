@tool
@icon("res://addons/moonAudio/icons/audio_event.png")
extends Resource
class_name AudioEvent
## Models the playback of dynamic audio, with various parameter modulation options.

const ActiveAudioEvent = preload("uid://dnl3yg010hsyy")

#region Exports

enum Positional {
	Off,  ## The event is played with no positional attenuation.
	_2D,  ## The event is played with 2D positional attenuation.
	_3D,  ## the event is played with 3D positional attenuation.
}

## Models all audio events played on the audio event.
@export var streams: Array[AudioEventStream] = []

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
		emit_changed()

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
@export_range(-12.0, 12.0, 0.01, "or_less", "or_greater", "suffix:dB") var volume_db := 0.0:
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
