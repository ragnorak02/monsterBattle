extends PanelContainer

func _ready() -> void:
	# Ensure this stays on screen
	mouse_filter = Control.MOUSE_FILTER_IGNORE
