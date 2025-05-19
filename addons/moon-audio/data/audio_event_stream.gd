@tool
@icon("res://addons/moon-audio/icons/audio_event_stream.png")
extends Resource
class_name AudioEventStream
## Models an individual audio stream playing within an audio event.

## The base audio stream played back.
@export var stream: AudioStream = null

## Volume adjustment on the audio stream.
@export_range(-12.0, 12.0, 0.01, "or_less", "or_greater", "suffix:dB") var volume_db := 0.0:
	set(x):
		volume_db = clampf(x, -80.0, 48.0)

## Pitch adjustment for the whole audio event.
@export_range(0.01, 4.0, 0.01, "or_greater", "suffix:x") var pitch_scale := 1.0

## The starting position in this stream.
@export_range(0.0, 1.0, 0.001, "or_greater", "suffix:s") var start_time := 0.0

## A delay in when this stream is played.
@export_range(0.0, 1000.0, 1, "or_greater", "suffix:ms") var delay := 0.0

## Applies a "fade-in" effect on the stream's volume.
@export_range(0, 1000, 1, "or_greater", "suffix:ms") var attack_duration := 0.0

## Applies a "fade-out" effect on the stream's release.
@export_range(0, 1000, 1, "or_greater", "suffix:ms") var release_duration := 0.0
