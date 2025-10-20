@tool
@icon("res://addons/moon-audio/icons/audio_positional_preset_3d.png")
extends Resource
class_name AudioPositionalPreset3D

## Decides how audio should get quieter over distance.
@export var attenuation_model := AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE:
	set(x):
		attenuation_model = x
		emit_changed()

@export_range(0.1, 100.0, 0.01, "suffix:m") var unit_size := 10.0:
	set(x):
		unit_size = x
		emit_changed()

@export_range(-24.0, 6.0, 0.001, "suffix:dB") var max_db := 3.0:
	set(x):
		max_db = x
		emit_changed()

## Maximum distance from which audio is still hearable.
@export_range(0, 4096, 0.01, "suffix:m") var max_distance := 0.0:
	set(x):
		max_distance = x
		emit_changed()

## Scales the panning strength for this event.
@export_range(0, 3, 0.01, "suffix:x") var panning_strength := 1.0:
	set(x):
		panning_strength = x
		emit_changed()

## Determines which [Area2D] layers affect the sound for reverb and audio bus effects.
@export_flags_3d_physics var area_mask := 1:
	set(x):
		area_mask = x
		emit_changed()

## Decides in which step the Doppler effect should be calculated.
@export var doppler := AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED:
	set(x):
		doppler = x
		emit_changed()

@export_subgroup("Emission Angle", "emission_angle")

## If [code]true[/code], the audio should be attenuated according to the direction of the sound.
@export var emission_angle_enabled := false:
	set(x):
		emission_angle_enabled = x
		emit_changed()

## The angle in which an audio reaches a listener unattenuated.
@export_range(0.1, 90.0, 0.1, "degrees") var emission_angle_degrees := 45.0:
	set(x):
		emission_angle_degrees = x
		emit_changed()

## Attenuation factor used if listener is outside of [member emission_angle_degrees] and
## [member emission_angle_enabled] is set, in decibels.
@export_range(-80.0, 0.0, 0.1, "suffix:dB") var emission_angle_filter_attenuation_db := -12.0:
	set(x):
		emission_angle_filter_attenuation_db = x
		emit_changed()

@export_subgroup("Attenuation Filter", "attenuation_filter")

## If [code]true[/code], the audio should be attenuated based on distance from the listener.
@export var attenuation_filter_enabled := false:
	set(x):
		attenuation_filter_enabled = x
		emit_changed()

## The cutoff frequency of the attenuation low-pass filter, in Hz.
## A sound above this frequency is attenuated more than a sound below this frequency.
@export_range(1, 20500, 1, "suffix:Hz") var attenuation_filter_cutoff_hz := 5000:
	set(x):
		attenuation_filter_cutoff_hz = x
		emit_changed()

## The angle in which an audio reaches a listener unattenuated.
@export_range(-80.0, 0.0, 0.1, "suffix:dB") var attenuation_filter_db := -24.0:
	set(x):
		attenuation_filter_db = x
		emit_changed()

static func create_from_stream_player(audio_stream_player_3d: AudioStreamPlayer3D) -> AudioPositionalPreset3D:
	var app := AudioPositionalPreset3D.new()
	app.attenuation_model = audio_stream_player_3d.attenuation_model
	app.unit_size = audio_stream_player_3d.unit_size
	app.max_db = audio_stream_player_3d.max_db
	app.max_distance = audio_stream_player_3d.max_distance
	app.panning_strength = audio_stream_player_3d.panning_strength
	app.area_mask = audio_stream_player_3d.area_mask
	app.doppler = audio_stream_player_3d.doppler_tracking
	app.emission_angle_enabled = audio_stream_player_3d.emission_angle_enabled
	app.emission_angle_degrees = audio_stream_player_3d.emission_angle_degrees
	app.emission_angle_filter_attenuation_db = audio_stream_player_3d.emission_angle_filter_attenuation_db
	app.attenuation_filter_enabled = audio_stream_player_3d.attenuation_filter_cutoff_hz < 20500
	app.attenuation_filter_cutoff_hz = audio_stream_player_3d.attenuation_filter_cutoff_hz if audio_stream_player_3d.attenuation_filter_cutoff_hz != 20500 else 5000
	app.attenuation_filter_db = audio_stream_player_3d.attenuation_filter_db
	return app
