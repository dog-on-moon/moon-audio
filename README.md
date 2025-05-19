![screen-shot](https://github.com/dog-on-moon/moon-audio/blob/main/readme/banner.png)

# 🌙 moon-audio - see more: [moonSuite](https://dog-game.xyz/tools/)

moon-audio is a developer-first audio plugin for Godot, decoupling audio design from implementation via resources. 

Inspired by Fmod, moon-audio implements AudioEvents, resource middleware that lives in-between your audio samples and implementation.
AudioEvents make it much easier to configure and tune audio playback without having to dig into your scenes.

![screen-shot](https://github.com/dog-on-moon/moon-audio/blob/main/readme/pic1.png)

## 🔉 AudioEvent

Each AudioEvent has several properties for audio manipulation and control.

- **Streams**: An array of AudioEventStreams (see below).
- **Audio Bus**: The target audio bus for the AudioEvent.
- **Positional**: Determines if this audio is positional (modes: Off, 2D, and 3D).
- **Persistent**: **Determines if the audio is cut off when its parent leaves the scene tree. If true, then the audio will continue playing until it is completed or manually released/stopped.**
- **Max Polyphony**: Determines how many of this event's instances are allowed simultaneously. If the limit is surpassed, then the oldest instances are force stopped.
- **Volume dB**: A volume offset for this event's playback.
- **Pitch Scale**: Pitch scale multiplier for this event's playback.
- **Positional Tracking**: If this audio has 2D or 3D positional audio, setting this to True will cause the event's playback position to follow its positional target. Otherwise, it will remain at its starting position upon playback.
- **Positional Preset**: If this audio has 2D or 3D positional audio, this is the resource that defines its distance falloff.

Additionally, AudioEvents can be tested in the inspector with manual play/release/stop buttons.

## 🌊 AudioEventStream

An AudioEventStream reflects an individual audio stream played back over the lifetime of an AudioEvent.

They have several properties for further control:

- **Stream**: The AudioStream to use for this event stream.
- **Volume dB**: A volume offset for this event stream.
- **Pitch Scale**: Pitch scale multiplier for this event stream.
- **Start Time**: Determines the starting position in the audio the stream plays back from.
- **Delay**: Causes the event stream to start late when the event is initialized.
- **Attack Duration**: Adds a "fade-in" effect to this audio stream.
- **Release Duration**: Adds a "fade-out" effect to this audio stream.

## ▶️ Playback

AudioEvents can be played back in two ways:

1. Using an `AudioEventPlayer` node.
2. Calling `AudioEvent.play` directly.

Both methods create an `ActiveAudioEvent` node, which manage the playback of AudioStreamPlayers.
ActiveAudioEvents have individual control for volume and pitch scale.

ActiveAudioEvents can also be created with an optional "positional parent" target. If set,
this allows the ActiveAudioEvent's 2D and 3D positional properties to target a specific node's transform,
as opposed to its parent.

The node will clean itself up once its audio is done playing. Alternatively, you can call
`ActiveAudioEvent.release` to fade it out (depending on how its AudioEventStreams are defined),
or `ActiveAudioEvent.stop` to immediately stop it.

## Installation

- Add the folder from addons into your project's addons folder.
