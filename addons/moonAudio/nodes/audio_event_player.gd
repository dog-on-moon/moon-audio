@tool
@icon("res://addons/moonAudio/icons/audio_event_player.png")
extends Node
class_name AudioEventPlayer
## Provides an interface for playing an AudioEvent.

## The event that is played upon performing the event.
@export var event: AudioEvent:
	set(x):
		event = x
		update_configuration_warnings()

## Volume adjustment for all audio events controlled by this player.
@export_range(-12.0, 12.0, 0.01, "or_less", "or_greater", "suffix:dB") var volume_db := 0.0:
	set(x):
		if Engine.is_editor_hint():
			volume_db = clampf(x, -80.0, 48.0)
		else:
			volume_db = x
			
		for aae in active_events:
			aae.volume_db = x

## Float API for event volume control.
var volume_float: float:
	set(x):
		volume_db = linear_to_db(x)
	get:
		return db_to_linear(volume_db)

## Pitch adjustment for all audio events controlled by this player.
@export_range(0.01, 4.0, 0.01, "or_greater", "suffix:x") var pitch_scale := 1.0:
	set(x):
		pitch_scale = x
		for aae in active_events:
			aae.pitch_scale = x

## Float API for adjusting both float/pitch scale for charges.
var fx_charge: float:
	set(x):
		volume_float = x
		pitch_scale = x

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

@onready var mp := Godaemon.mp(self, false)

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

## Creates a fx_charge lerp interval off of this event player.
func lerp_charge_interval(duration: float, from: float = 0.0, to: float = 1.0, _ease := Tween.EASE_IN_OUT, trans := Tween.TRANS_LINEAR) -> LerpFunc:
	return LerpFunc.new(_set_charge, duration, from, to, _ease, trans)

func _set_charge(x: float):
	fx_charge = x

func _get_configuration_warnings() -> PackedStringArray:
	if not event:
		return PackedStringArray(["No event is defined on this EventPlayer.\nDefine one."])
	return PackedStringArray([])
