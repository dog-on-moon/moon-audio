@tool
extends EditorPlugin

const AudioPlayerConverter = preload("uid://nl4ktnnwghbr")

var audio_player_converter: EditorContextMenuPlugin

func _enter_tree() -> void:
	audio_player_converter = AudioPlayerConverter.new()
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCENE_TREE, audio_player_converter)

func _exit_tree() -> void:
	if audio_player_converter:
		remove_context_menu_plugin(audio_player_converter)
		audio_player_converter = null
