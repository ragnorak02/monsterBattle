@tool
extends SceneTree
## One-time tool script: generates 12x12 controller button icon PNGs.
## Run with:  Z:/godot/godot.exe --path . --headless --script res://scripts/tools/generate_controller_icons.gd

const SIZE := 12
const OUT_DIR := "res://assets/ui/controller/"

func _init() -> void:
	_generate_all()
	quit()

func _generate_all() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_save_circle_button("btn_a", "A", Color(0.298, 0.686, 0.314))   # Green
	_save_circle_button("btn_b", "B", Color(0.957, 0.263, 0.212))   # Red
	_save_circle_button("btn_x", "X", Color(0.129, 0.588, 0.953))   # Blue
	_save_circle_button("btn_y", "Y", Color(1.0, 0.757, 0.027))     # Yellow
	_save_start_icon()
	_save_dpad_icon()
	_save_lstick_icon()
	print("[ICON-GEN] All 7 controller icons generated in %s" % OUT_DIR)

func _save_circle_button(filename: String, letter: String, color: Color) -> void:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(5.5, 5.5)
	var radius := 5.5
	# Draw filled circle
	for y in SIZE:
		for x in SIZE:
			var dist := Vector2(x + 0.5, y + 0.5).distance_to(center)
			if dist <= radius:
				img.set_pixel(x, y, color)
			elif dist <= radius + 0.7:
				var alpha := clampf(1.0 - (dist - radius) / 0.7, 0.0, 1.0)
				img.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	# Draw letter — simple 3x5 pixel font centered
	var glyph := _get_glyph(letter)
	var gw := 3
	var gh := 5
	var ox := (SIZE - gw) / 2  # 4
	var oy := (SIZE - gh) / 2  # 3
	for gy in gh:
		for gx in gw:
			if glyph[gy * gw + gx]:
				img.set_pixel(ox + gx, oy + gy, Color.WHITE)
	img.save_png(OUT_DIR + filename + ".png")
	print("[ICON-GEN] Saved %s.png" % filename)

func _get_glyph(letter: String) -> Array:
	match letter:
		"A": return [0,1,0, 1,0,1, 1,1,1, 1,0,1, 1,0,1]
		"B": return [1,1,0, 1,0,1, 1,1,0, 1,0,1, 1,1,0]
		"X": return [1,0,1, 1,0,1, 0,1,0, 1,0,1, 1,0,1]
		"Y": return [1,0,1, 1,0,1, 0,1,0, 0,1,0, 0,1,0]
	return [0,0,0, 0,0,0, 0,0,0, 0,0,0, 0,0,0]

func _save_start_icon() -> void:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Hamburger menu: 3 horizontal lines
	var col := Color.WHITE
	for x in range(2, 10):
		img.set_pixel(x, 3, col)
		img.set_pixel(x, 5, col)
		img.set_pixel(x, 7, col)
		img.set_pixel(x, 8, col)  # bottom bar thicker for clarity
	img.save_png(OUT_DIR + "btn_start.png")
	print("[ICON-GEN] Saved btn_start.png")

func _save_dpad_icon() -> void:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var col := Color.WHITE
	# Vertical bar (center column, 3px wide)
	for y in SIZE:
		if y >= 1 and y <= 10:
			for x in range(4, 8):
				img.set_pixel(x, y, col)
	# Horizontal bar
	for x in SIZE:
		if x >= 1 and x <= 10:
			for y in range(4, 8):
				img.set_pixel(x, y, col)
	img.save_png(OUT_DIR + "dpad.png")
	print("[ICON-GEN] Saved dpad.png")

func _save_lstick_icon() -> void:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(5.5, 5.5)
	var col := Color.WHITE
	# Draw circle outline
	for y in SIZE:
		for x in SIZE:
			var dist := Vector2(x + 0.5, y + 0.5).distance_to(center)
			if dist >= 4.0 and dist <= 5.5:
				img.set_pixel(x, y, col)
	# Draw crosshair in center
	for i in range(3, 9):
		img.set_pixel(i, 5, col)
		img.set_pixel(i, 6, col)
		img.set_pixel(5, i, col)
		img.set_pixel(6, i, col)
	img.save_png(OUT_DIR + "lstick.png")
	print("[ICON-GEN] Saved lstick.png")
