@tool
@icon("res://addons/moonAudio/icons/audio_positional_preset_2d.png")
extends Resource
class_name AudioPositionalPreset2D

## The volume is attenuated over distance with this as an exponent.
@export_exp_easing("attenuation") var attenuation := 1.0:
	set(x):
		attenuation = x
		emit_changed()

## Maximum distance from which audio is still hearable.
@export_range(0, 4096, 0.01, "suffix:px") var max_distance := 2000.0:
	set(x):
		max_distance = x
		emit_changed()

## Scales the panning strength for this event.
@export_range(0, 3, 0.01, "suffix:x") var panning_strength := 1.0:
	set(x):
		panning_strength = x
		emit_changed()

## Determines which [Area2D] layers affect the sound for reverb and audio bus effects.
@export_flags_2d_physics var area_mask := 1:
	set(x):
		area_mask = x
		emit_changed()
