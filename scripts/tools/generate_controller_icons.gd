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
	_save_chat_bubble()
	_save_town_tileset()

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

func _save_chat_bubble() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/ui/")
	var s := 16
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var white := Color.WHITE
	var outline := Color(0.2, 0.2, 0.2)
	# Bubble body: rounded rect from (1,1) to (14,10)
	for y in range(1, 11):
		for x in range(1, 15):
			# Corners cut for rounded look
			if (x == 1 or x == 14) and (y == 1 or y == 10):
				continue
			img.set_pixel(x, y, white)
	# Outline top/bottom
	for x in range(2, 14):
		img.set_pixel(x, 0, outline)
		img.set_pixel(x, 11, outline)
	# Outline left/right
	for y in range(2, 10):
		img.set_pixel(0, y, outline)
		img.set_pixel(15, y, outline)
	# Corner outline pixels
	img.set_pixel(1, 1, outline)
	img.set_pixel(14, 1, outline)
	img.set_pixel(1, 10, outline)
	img.set_pixel(14, 10, outline)
	# Speech tail: small triangle pointing down-left
	img.set_pixel(4, 12, outline)
	img.set_pixel(5, 12, white)
	img.set_pixel(6, 12, white)
	img.set_pixel(7, 12, outline)
	img.set_pixel(3, 13, outline)
	img.set_pixel(4, 13, white)
	img.set_pixel(5, 13, white)
	img.set_pixel(6, 13, outline)
	img.set_pixel(2, 14, outline)
	img.set_pixel(3, 14, white)
	img.set_pixel(4, 14, outline)
	# Three dots inside the bubble (ellipsis)
	var dot_col := Color(0.4, 0.4, 0.4)
	img.set_pixel(5, 5, dot_col)
	img.set_pixel(5, 6, dot_col)
	img.set_pixel(7, 5, dot_col)
	img.set_pixel(7, 6, dot_col)
	img.set_pixel(9, 5, dot_col)
	img.set_pixel(9, 6, dot_col)
	img.save_png("res://assets/ui/chat_bubble.png")
	print("[ICON-GEN] Saved chat_bubble.png")

func _save_town_tileset() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/overworld/")
	# 8 tiles in a horizontal strip, each 16x16
	var tile_count := 8
	var img := Image.create(16 * tile_count, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Tile 0: Grass (green)
	_fill_tile(img, 0, Color(0.298, 0.588, 0.196))
	# Grass detail pixels
	_set_tile_pixel(img, 0, 3, 4, Color(0.247, 0.529, 0.161))
	_set_tile_pixel(img, 0, 10, 8, Color(0.247, 0.529, 0.161))
	_set_tile_pixel(img, 0, 7, 12, Color(0.349, 0.639, 0.247))

	# Tile 1: Path/dirt (tan)
	_fill_tile(img, 1, Color(0.761, 0.682, 0.522))
	_set_tile_pixel(img, 1, 4, 6, Color(0.722, 0.643, 0.482))
	_set_tile_pixel(img, 1, 11, 3, Color(0.722, 0.643, 0.482))

	# Tile 2: Water (blue)
	_fill_tile(img, 2, Color(0.196, 0.392, 0.710))
	_set_tile_pixel(img, 2, 5, 5, Color(0.298, 0.490, 0.780))
	_set_tile_pixel(img, 2, 10, 10, Color(0.298, 0.490, 0.780))

	# Tile 3: Dark grass / tree canopy (dark green)
	_fill_tile(img, 3, Color(0.137, 0.349, 0.110))
	# Tree canopy detail — lighter spots
	_set_tile_pixel(img, 3, 4, 3, Color(0.196, 0.420, 0.161))
	_set_tile_pixel(img, 3, 8, 7, Color(0.196, 0.420, 0.161))
	_set_tile_pixel(img, 3, 12, 11, Color(0.110, 0.290, 0.090))
	# Trunk hint at bottom
	for y in range(13, 16):
		for x in range(6, 10):
			_set_tile_pixel(img, 3, x, y, Color(0.400, 0.282, 0.161))

	# Tile 4: House wall (warm brown)
	_fill_tile(img, 4, Color(0.529, 0.420, 0.322))
	# Window
	for y in range(5, 11):
		for x in range(5, 11):
			_set_tile_pixel(img, 4, x, y, Color(0.400, 0.600, 0.800))
	# Window frame
	for x in range(5, 11):
		_set_tile_pixel(img, 4, x, 5, Color(0.361, 0.286, 0.216))
		_set_tile_pixel(img, 4, x, 10, Color(0.361, 0.286, 0.216))
	for y in range(5, 11):
		_set_tile_pixel(img, 4, 5, y, Color(0.361, 0.286, 0.216))
		_set_tile_pixel(img, 4, 10, y, Color(0.361, 0.286, 0.216))
	# Door at bottom center
	for y in range(12, 16):
		for x in range(6, 10):
			_set_tile_pixel(img, 4, x, y, Color(0.361, 0.243, 0.161))

	# Tile 5: House roof (red-brown)
	_fill_tile(img, 5, Color(0.690, 0.220, 0.180))
	# Roof ridge line
	for x in range(0, 16):
		_set_tile_pixel(img, 5, x, 7, Color(0.561, 0.161, 0.129))
		_set_tile_pixel(img, 5, x, 8, Color(0.561, 0.161, 0.129))
	# Lighter top half
	for y in range(0, 7):
		for x in range(0, 16):
			_set_tile_pixel(img, 5, x, y, Color(0.741, 0.259, 0.212))

	# Tile 6: Fence (light wood)
	_fill_tile(img, 6, Color(0.298, 0.588, 0.196))  # grass base
	# Fence posts
	for y in range(2, 14):
		_set_tile_pixel(img, 6, 2, y, Color(0.722, 0.600, 0.400))
		_set_tile_pixel(img, 6, 13, y, Color(0.722, 0.600, 0.400))
	# Horizontal rail
	for x in range(2, 14):
		_set_tile_pixel(img, 6, x, 5, Color(0.761, 0.639, 0.439))
		_set_tile_pixel(img, 6, x, 10, Color(0.761, 0.639, 0.439))

	# Tile 7: Flowers / garden (green with color spots)
	_fill_tile(img, 7, Color(0.322, 0.612, 0.220))
	# Flower dots
	_set_tile_pixel(img, 7, 3, 3, Color(1.0, 0.4, 0.4))
	_set_tile_pixel(img, 7, 4, 3, Color(1.0, 0.4, 0.4))
	_set_tile_pixel(img, 7, 8, 6, Color(1.0, 0.9, 0.2))
	_set_tile_pixel(img, 7, 9, 6, Color(1.0, 0.9, 0.2))
	_set_tile_pixel(img, 7, 5, 10, Color(0.6, 0.3, 0.9))
	_set_tile_pixel(img, 7, 6, 10, Color(0.6, 0.3, 0.9))
	_set_tile_pixel(img, 7, 12, 4, Color(1.0, 0.6, 0.8))
	_set_tile_pixel(img, 7, 13, 4, Color(1.0, 0.6, 0.8))
	_set_tile_pixel(img, 7, 2, 12, Color(0.4, 0.7, 1.0))
	_set_tile_pixel(img, 7, 11, 13, Color(1.0, 0.5, 0.3))

	img.save_png("res://assets/sprites/overworld/tileset_town.png")
	print("[ICON-GEN] Saved tileset_town.png (8 tiles)")

func _fill_tile(img: Image, tile_index: int, color: Color) -> void:
	var ox := tile_index * 16
	for y in range(16):
		for x in range(16):
			img.set_pixel(ox + x, y, color)

func _set_tile_pixel(img: Image, tile_index: int, x: int, y: int, color: Color) -> void:
	img.set_pixel(tile_index * 16 + x, y, color)
