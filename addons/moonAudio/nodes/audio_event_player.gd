@tool
@icon("res://addons/moonAudio/icons/audio_event_player.png")
extends Node
class_name AudioEventPlayer
## Provides an interface for playing an AudioEvent.

const ActiveAudioEvent = preload("uid://dnl3yg010hsyy")

## The event that is played upon performing the event.
@export var event: AudioEvent

## Volume adjustment for all audio events controlled by this player.
@export_range(-12.0, 12.0, 0.01, "or_less", "or_greater", "suffix:dB") var volume_db := 0.0:
	set(x):
		if Engine.is_editor_hint():
			volume_db = clampf(x, -80.0, 48.0)
		else:
			volume_db = x
			
		for aae in active_events:
			aae.volume_db = x

## Pitch adjustment for all audio events controlled by this player.
@export_range(0.01, 4.0, 0.01, "or_greater", "suffix:x") var pitch_scale := 1.0:
	set(x):
		pitch_scale = x
		for aae in active_events:
			aae.pitch_scale = x

## Automatically plays the audio event upon _ready.
@export var autoplay := false

@export_category("Audio Testing")
@warning_ignore_start("unused_private_class_variable")
@export_tool_button("Play", "Play") var _1 = play
@export_tool_button("Release", "MoveUp") var _2 = release_all
@export_tool_button("Stop", "Stop") var _3 = stop_all
@warning_ignore_restore("unused_private_class_variable")

@onready var positional_parent := get_parent()

## All active events currently playing within this AudioEventPlayer.
var active_events: Array[ActiveAudioEvent] = []

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if autoplay:
		play()

## Plays a new event instantiation.
func play() -> ActiveAudioEvent:
	if not event:
		return null
	var aae := event.play(self, positional_parent)
	aae.volume_db = volume_db
	aae.pitch_scale = pitch_scale
	active_events.append(aae)
	aae.finished.connect(_handle_finished.bind(aae))
	return aae

func _handle_finished(aae: ActiveAudioEvent):
	active_events.erase(aae)

## Releases all active events.
func release_all():
	for aae in active_events.duplicate():
		aae.release()

## Stops all active events.
func stop_all():
	for aae in active_events.duplicate():
		aae.stop()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PARENTED:
		positional_parent = get_parent()
