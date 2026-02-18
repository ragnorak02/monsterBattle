extends Node

func _ready() -> void:
	_print_environment_info()

	var container := $SceneContainer
	var overlay := $FadeOverlay as ColorRect
	SceneManager.setup(container, overlay)

	SceneManager.change_scene("res://scenes/gender_select.tscn", false)

func _print_environment_info() -> void:
	var godot_ver: String = Engine.get_version_info().get("string", "unknown")
	var os_name: String = OS.get_name()
	var arch: String = Engine.get_architecture_name()
	var renderer: String = str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown"))
	var gpu: String = RenderingServer.get_video_adapter_name()
	var viewport_w: int = ProjectSettings.get_setting("display/window/size/viewport_width", 0)
	var viewport_h: int = ProjectSettings.get_setting("display/window/size/viewport_height", 0)

	print("╔══════════════════════════════════════════════╗")
	print("║       MONSTER CATCHER — Environment Info     ║")
	print("╠══════════════════════════════════════════════╣")
	print("║  Godot Version : %s" % godot_ver)
	print("║  Platform / OS : %s (%s)" % [os_name, arch])
	print("║  Language       : GDScript")
	print("║  Renderer       : %s" % renderer)
	print("║  GPU            : %s" % gpu)
	print("║  Viewport       : %dx%d" % [viewport_w, viewport_h])
	print("╚══════════════════════════════════════════════╝")
