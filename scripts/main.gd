extends Node3D

const CELL_SIZE := 3.0
const WALL_HEIGHT := 2.6
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const JOYSTICK_SCENE := preload("res://scenes/joystick.tscn")
const CEILING_LIGHT_SCENE := preload("res://scenes/ceiling_light.tscn")
const WALLPAPER_SHADER := preload("res://shaders/wallpaper.gdshader")
const CARPET_SHADER := preload("res://shaders/carpet.gdshader")
const CHALK_ICON := preload("res://assets/chalk.svg")
const MENU_ICON := preload("res://assets/menu.svg")
const DOORWAY_SHADER := preload("res://shaders/light_doorway.gdshader")
const SHAFT_SHADER := preload("res://shaders/light_shaft.gdshader")
const DOOR_SIZE := Vector2(1.1, 2.2)
const DOOR_LIGHT_COLOR := Color(1.0, 0.88, 0.68)
# Share of the corridor width covered by the carpet border, on each side.
const CARPET_BORDER_RATIO := 0.1
const BASEBOARD_HEIGHT := 0.14
const BASEBOARD_DEPTH := 0.025
const TOP_TRIM_HEIGHT := 0.05
const TOP_TRIM_DEPTH := 0.012

# One wallpaper per floor, cycled. Pattern ids match shaders/wallpaper.gdshader.
const WALLPAPERS := [
	{"name": "pinstripe", "pattern": 1, "scale": 5.0, "width": 0.07},
	{"name": "dots", "pattern": 2, "scale": 5.0, "width": 0.07},
	{"name": "lattice", "pattern": 3, "scale": 2.2, "width": 0.025},
	{"name": "chevron", "pattern": 5, "scale": 3.0, "width": 0.045},
	{"name": "scallop", "pattern": 7, "scale": 3.0, "width": 0.035},
	{"name": "plus", "pattern": 6, "scale": 4.0, "width": 0.05},
	{"name": "ticking", "pattern": 8, "scale": 2.5, "width": 0.06},
	{"name": "grid", "pattern": 4, "scale": 2.0, "width": 0.02},
]

var LEVELS := [
	{
		"title": "Passage I",
		"maze": ["#####", "#S..#", "#.#.#", "#.#.#", "#.#E#", "#####"],
		"ambient": Color(1.0, 0.95, 0.86),
		"ambient_energy": 0.7,
		"background": Color(0.55, 0.7, 0.85),
		"fog": Color(0.88, 0.84, 0.75),
		"fog_density": 0.0025,
		"wall": Color(0.78, 0.72, 0.62),
		"floor": Color(0.55, 0.5, 0.44),
		"ceiling": Color(0.92, 0.88, 0.78),
	},
	{
		"title": "Passage II",
		"cells": Vector2i(3, 3),
		"loops": 0,
		"rooms": 0,
		"ambient": Color(1.0, 0.88, 0.72),
		"ambient_energy": 0.72,
		"background": Color(0.6, 0.75, 0.9),
		"fog": Color(0.9, 0.8, 0.65),
		"fog_density": 0.003,
		"wall": Color(0.82, 0.68, 0.52),
		"floor": Color(0.58, 0.48, 0.38),
		"ceiling": Color(0.95, 0.86, 0.68),
	},
	{
		"title": "Passage III",
		"cells": Vector2i(4, 4),
		"loops": 1,
		"rooms": 0,
		"ambient": Color(0.82, 0.95, 0.9),
		"ambient_energy": 0.7,
		"background": Color(0.55, 0.78, 0.85),
		"fog": Color(0.75, 0.9, 0.86),
		"fog_density": 0.0028,
		"wall": Color(0.64, 0.76, 0.7),
		"floor": Color(0.45, 0.55, 0.52),
		"ceiling": Color(0.86, 0.93, 0.88),
	},
	{
		"title": "Passage IV",
		"cells": Vector2i(5, 5),
		"loops": 2,
		"rooms": 1,
		"ambient": Color(1.0, 0.86, 0.86),
		"ambient_energy": 0.7,
		"background": Color(0.65, 0.75, 0.9),
		"fog": Color(0.93, 0.82, 0.82),
		"fog_density": 0.0028,
		"wall": Color(0.8, 0.66, 0.66),
		"floor": Color(0.56, 0.46, 0.46),
		"ceiling": Color(0.95, 0.87, 0.86),
	},
	{
		"title": "Passage V",
		"cells": Vector2i(6, 6),
		"loops": 3,
		"rooms": 1,
		"ambient": Color(0.9, 0.88, 1.0),
		"ambient_energy": 0.7,
		"background": Color(0.6, 0.7, 0.9),
		"fog": Color(0.86, 0.84, 0.95),
		"fog_density": 0.003,
		"wall": Color(0.7, 0.67, 0.8),
		"floor": Color(0.5, 0.48, 0.58),
		"ceiling": Color(0.88, 0.86, 0.95),
	},
	{
		"title": "Passage VI",
		"cells": Vector2i(7, 7),
		"loops": 4,
		"rooms": 2,
		"ambient": Color(1.0, 0.92, 0.76),
		"ambient_energy": 0.7,
		"background": Color(0.62, 0.76, 0.92),
		"fog": Color(0.92, 0.85, 0.72),
		"fog_density": 0.003,
		"wall": Color(0.8, 0.7, 0.54),
		"floor": Color(0.58, 0.5, 0.4),
		"ceiling": Color(0.95, 0.9, 0.76),
	},
	{
		"title": "Passage VII",
		"cells": Vector2i(8, 8),
		"loops": 5,
		"rooms": 2,
		"ambient": Color(0.84, 0.92, 1.0),
		"ambient_energy": 0.7,
		"background": Color(0.55, 0.76, 0.96),
		"fog": Color(0.78, 0.87, 0.96),
		"fog_density": 0.003,
		"wall": Color(0.66, 0.74, 0.84),
		"floor": Color(0.46, 0.52, 0.6),
		"ceiling": Color(0.87, 0.91, 0.97),
	},
	{
		"title": "Passage VIII",
		"cells": Vector2i(9, 9),
		"loops": 6,
		"rooms": 3,
		"ambient": Color(0.9, 0.95, 0.8),
		"ambient_energy": 0.7,
		"background": Color(0.6, 0.8, 0.7),
		"fog": Color(0.84, 0.9, 0.76),
		"fog_density": 0.003,
		"wall": Color(0.7, 0.76, 0.58),
		"floor": Color(0.5, 0.55, 0.42),
		"ceiling": Color(0.89, 0.93, 0.81),
	},
	{
		"title": "Passage IX",
		"cells": Vector2i(10, 10),
		"loops": 7,
		"rooms": 3,
		"ambient": Color(1.0, 0.86, 0.8),
		"ambient_energy": 0.7,
		"background": Color(0.66, 0.76, 0.92),
		"fog": Color(0.95, 0.83, 0.79),
		"fog_density": 0.003,
		"wall": Color(0.84, 0.68, 0.62),
		"floor": Color(0.6, 0.48, 0.44),
		"ceiling": Color(0.96, 0.87, 0.83),
	},
	{
		"title": "Passage X",
		"cells": Vector2i(11, 11),
		"loops": 8,
		"rooms": 4,
		"ambient": Color(0.92, 0.9, 1.0),
		"ambient_energy": 0.7,
		"background": Color(0.62, 0.7, 0.92),
		"fog": Color(0.88, 0.86, 0.96),
		"fog_density": 0.003,
		"wall": Color(0.72, 0.69, 0.82),
		"floor": Color(0.52, 0.5, 0.6),
		"ceiling": Color(0.9, 0.88, 0.96),
	},
]

var world: SubViewport
var player: Player
var joystick: Joystick
var menu_button: Button
var chalk_button: Button
var fade_overlay: ColorRect
var menu_overlay: ColorRect
var portal_node: Node3D
var portal_time := 0.0
var doorway_material: ShaderMaterial
var shaft_material: ShaderMaterial
var door_light: SpotLight3D
var trim_material: StandardMaterial3D
var hud: Label
var status: Label
var won := false
var current_level := 0
var current_layout: Array = []
var current_theme: Dictionary = {}
var wall_material: ShaderMaterial
var level_width := 0
var level_height := 0
var start_cell := Vector2i.ZERO
var goal_cell := Vector2i.ZERO

func _ready() -> void:
	get_tree().paused = false
	build_extra_levels()
	var start_level := int(Engine.get_meta("passages_level", 0))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			start_level = int(arg.trim_prefix("--level=")) - 1
			Engine.set_meta("passages_level", start_level)
	current_level = clampi(start_level, 0, LEVELS.size() - 1)
	current_theme = LEVELS[current_level]
	apply_lighting()
	if current_theme.has("maze"):
		current_layout = current_theme["maze"]
	else:
		var cells: Vector2i = current_theme["cells"]
		var loops := int(current_theme.get("loops", 0))
		var rooms := int(current_theme.get("rooms", 0))
		current_layout = generate_maze(cells.x, cells.y, loops, rooms)
	level_width = current_layout[0].length()
	level_height = current_layout.size()
	setup_viewport()
	setup_environment()
	build_level()
	spawn_player()
	build_goal()
	if "--peek-exit" in OS.get_cmdline_user_args():
		peek_exit()
	build_ui()
	fade_in()
	match_menu_icon_to_backdrop()

func _process(delta: float) -> void:
	if is_instance_valid(portal_node) and not won:
		portal_time += delta
		var pulse := 1.0 + sin(portal_time * 1.6) * 0.06
		doorway_material.set_shader_parameter("intensity", pulse)
		shaft_material.set_shader_parameter("intensity", 0.12 * pulse)
		door_light.light_energy = 2.2 * pulse

func fade_in() -> void:
	if fade_overlay:
		var tween := create_tween()
		tween.tween_property(fade_overlay, "color:a", 0.0, 0.5)

func build_extra_levels() -> void:
	if LEVELS.size() >= 50:
		return
	var palettes := [
		{
			"ambient": Color(1.0, 0.92, 0.76),
			"wall": Color(0.8, 0.7, 0.54),
			"floor": Color(0.58, 0.5, 0.4),
			"ceiling": Color(0.95, 0.9, 0.76),
		},
		{
			"ambient": Color(0.84, 0.92, 1.0),
			"wall": Color(0.66, 0.74, 0.84),
			"floor": Color(0.46, 0.52, 0.6),
			"ceiling": Color(0.87, 0.91, 0.97),
		},
		{
			"ambient": Color(0.9, 0.95, 0.8),
			"wall": Color(0.7, 0.76, 0.58),
			"floor": Color(0.5, 0.55, 0.42),
			"ceiling": Color(0.89, 0.93, 0.81),
		},
		{
			"ambient": Color(1.0, 0.86, 0.8),
			"wall": Color(0.84, 0.68, 0.62),
			"floor": Color(0.6, 0.48, 0.44),
			"ceiling": Color(0.96, 0.87, 0.83),
		},
		{
			"ambient": Color(0.92, 0.9, 1.0),
			"wall": Color(0.72, 0.69, 0.82),
			"floor": Color(0.52, 0.5, 0.6),
			"ceiling": Color(0.9, 0.88, 0.96),
		},
	]
	for i in range(LEVELS.size(), 50):
		var palette: Dictionary = palettes[(i - 10) % palettes.size()]
		var cells := mini(12 + int(float(i - 10) * 0.45), 30)
		var loops := mini(4 + int(float(i - 10) / 3.0), 14)
		var rooms := mini(2 + int(float(i - 10) / 5.0), 8)
		LEVELS.append({
			"title": "Passage " + to_roman(i + 1),
			"cells": Vector2i(cells, cells),
			"loops": loops,
			"rooms": rooms,
			"ambient": palette["ambient"],
			"background": Color(0.55, 0.7, 0.85),
			"fog": palette["ceiling"],
			"fog_density": 0.0025,
			"wall": palette["wall"],
			"floor": palette["floor"],
			"ceiling": palette["ceiling"],
		})
	for i in range(LEVELS.size()):
		LEVELS[i]["title"] = "Passage " + to_roman(i + 1)

func to_roman(value: int) -> String:
	var numerals := [
		[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"],
		[100, "C"], [90, "XC"], [50, "L"], [40, "XL"],
		[10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"],
	]
	var result := ""
	var n := value
	for pair in numerals:
		while n >= int(pair[0]):
			result += str(pair[1])
			n -= int(pair[0])
	return result

func setup_viewport() -> void:
	var game_layer := CanvasLayer.new()
	game_layer.layer = 0
	add_child(game_layer)
	world = SubViewport.new()
	world.own_world_3d = true
	world.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	world.msaa_3d = Viewport.MSAA_4X
	world.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	world.use_taa = false
	add_child(world)
	resize_world()
	get_tree().root.size_changed.connect(resize_world)
	var screen := TextureRect.new()
	screen.texture = world.get_texture()
	screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	screen.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_layer.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func resize_world() -> void:
	# Render at the device's real pixel size (or the design size, whichever is larger).
	var window := DisplayServer.window_get_size()
	var design := get_viewport().get_visible_rect().size
	world.size = Vector2i(maxi(window.x, int(design.x)), maxi(window.y, int(design.y)))

func apply_lighting() -> void:
	var t := float(current_level) / float(LEVELS.size() - 1)
	current_theme["ambient_energy"] = lerpf(0.7, 0.04, t)
	current_theme["fill_energy"] = lerpf(0.55, 0.015, t)
	current_theme["headlamp_energy"] = lerpf(0.2, 1.3, t)
	current_theme["fog_density"] = lerpf(0.003, 0.0008, t)
	var fog_color: Color = current_theme["fog"]
	current_theme["fog"] = fog_color.lerp(Color(0.02, 0.02, 0.03), t * 0.8)

func setup_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = current_theme["background"]
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = current_theme["ambient"]
	environment.ambient_light_energy = current_theme["ambient_energy"]
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.glow_enabled = true
	environment.glow_intensity = 0.5
	environment.glow_bloom = 0.0
	environment.glow_hdr_threshold = 1.0
	environment.fog_enabled = true
	environment.fog_light_color = current_theme["fog"]
	environment.fog_density = current_theme["fog_density"]
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	world.add_child(world_environment)
	var fill_light := DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-55, -30, 0)
	fill_light.light_color = Color(1.0, 0.93, 0.8)
	fill_light.light_energy = float(current_theme.get("fill_energy", 0.55))
	fill_light.shadow_enabled = false
	world.add_child(fill_light)

func generate_maze(cells_x: int, cells_y: int, loops: int, rooms: int) -> Array:
	var width := cells_x * 2 + 1
	var height := cells_y * 2 + 1
	var grid: Array = []
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append("#")
		grid.append(row)
	var stack: Array[Vector2i] = [Vector2i(0, 0)]
	grid[1][1] = "."
	while not stack.is_empty():
		var current: Vector2i = stack.back()
		var options: Array[Vector2i] = []
		for direction in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
			var neighbor: Vector2i = current + direction
			if neighbor.x >= 0 and neighbor.x < cells_x and neighbor.y >= 0 and neighbor.y < cells_y:
				var tile_x := neighbor.x * 2 + 1
				var tile_y := neighbor.y * 2 + 1
				if grid[tile_y][tile_x] == "#":
					options.append(neighbor)
		if options.is_empty():
			stack.pop_back()
		else:
			var next_cell: Vector2i = options.pick_random()
			var current_tile := Vector2i(current.x * 2 + 1, current.y * 2 + 1)
			var next_tile := Vector2i(next_cell.x * 2 + 1, next_cell.y * 2 + 1)
			var wall_tile := Vector2i((current_tile.x + next_tile.x) / 2, (current_tile.y + next_tile.y) / 2)
			grid[wall_tile.y][wall_tile.x] = "."
			grid[next_tile.y][next_tile.x] = "."
			stack.append(next_cell)
	var exit_tile := Vector2i((cells_x - 1) * 2 + 1, (cells_y - 1) * 2 + 1)
	if loops > 0:
		add_loops(grid, loops)
	if rooms > 0:
		add_rooms(grid, rooms, exit_tile)
	grid[1][1] = "S"
	grid[exit_tile.y][exit_tile.x] = "E"
	var rows: Array = []
	for row in grid:
		var line := ""
		for cell in row:
			line += str(cell)
		rows.append(line)
	return rows

func add_loops(grid: Array, count: int) -> void:
	var width: int = grid[0].size()
	var height: int = grid.size()
	var candidates: Array[Vector2i] = []
	for y in range(1, height - 1):
		for x in range(1, width - 1):
			if grid[y][x] != "#":
				continue
			var open_neighbors := 0
			if grid[y][x - 1] != "#":
				open_neighbors += 1
			if grid[y][x + 1] != "#":
				open_neighbors += 1
			if grid[y - 1][x] != "#":
				open_neighbors += 1
			if grid[y + 1][x] != "#":
				open_neighbors += 1
			if open_neighbors >= 2:
				candidates.append(Vector2i(x, y))
	candidates.shuffle()
	for i in range(count):
		if i >= candidates.size():
			break
		var candidate: Vector2i = candidates[i]
		grid[candidate.y][candidate.x] = "."

func add_rooms(grid: Array, count: int, exit_tile: Vector2i) -> void:
	var width: int = grid[0].size()
	var height: int = grid.size()
	var centers: Array[Vector2i] = []
	for y in range(1, height - 1, 2):
		for x in range(1, width - 1, 2):
			if Vector2i(x, y) == Vector2i(1, 1) or Vector2i(x, y) == exit_tile:
				continue
			centers.append(Vector2i(x, y))
	centers.shuffle()
	var placed := 0
	for center in centers:
		if placed >= count:
			break
		var blocked := false
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var nx: int = center.x + dx
				var ny: int = center.y + dy
				if nx <= 0 or nx >= width - 1 or ny <= 0 or ny >= height - 1:
					blocked = true
				elif Vector2i(nx, ny) == Vector2i(1, 1) or Vector2i(nx, ny) == exit_tile:
					blocked = true
		if blocked:
			continue
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				grid[center.y + dy][center.x + dx] = "."
		placed += 1

func build_level() -> void:
	var wallpaper: Dictionary = WALLPAPERS[current_level % WALLPAPERS.size()]
	var wall_color: Color = current_theme["wall"]
	wall_material = make_paper_material(wall_color, wall_color.darkened(0.12), int(wallpaper["pattern"]), float(wallpaper["scale"]), float(wallpaper["width"]), 0.85)
	trim_material = StandardMaterial3D.new()
	trim_material.albedo_color = wall_color.lerp(Color(0.97, 0.96, 0.93), 0.55)
	trim_material.roughness = 0.45
	var floor_color: Color = current_theme["floor"]
	var floor_material := make_carpet_material(floor_color, floor_color.lerp(wall_color.darkened(0.55), 0.9))
	var ceiling_color: Color = current_theme["ceiling"]
	var ceiling_material := make_paper_material(ceiling_color, ceiling_color, 0, 1.0, 0.0, 1.0)
	var span_x := level_width * CELL_SIZE
	var span_z := level_height * CELL_SIZE
	add_box(Vector3(0, -0.1, 0), Vector3(span_x, 0.2, span_z), floor_material)
	add_box(Vector3(0, WALL_HEIGHT + 0.1, 0), Vector3(span_x, 0.2, span_z), ceiling_material)
	var wall_mesh := build_wall_mesh(wall_material, trim_material)
	var wall_shape := BoxShape3D.new()
	wall_shape.size = Vector3(CELL_SIZE, WALL_HEIGHT, CELL_SIZE)
	var library := MeshLibrary.new()
	library.create_item(0)
	library.set_item_mesh(0, wall_mesh)
	library.set_item_shapes(0, [wall_shape])
	var grid_map := GridMap.new()
	grid_map.mesh_library = library
	grid_map.cell_size = Vector3(CELL_SIZE, WALL_HEIGHT, CELL_SIZE)
	grid_map.position = Vector3(-level_width * CELL_SIZE * 0.5, 0.0, -level_height * CELL_SIZE * 0.5)
	world.add_child(grid_map)
	var light_spacing := 2 if level_width < 24 else 3
	for y in range(level_height):
		var row: String = current_layout[y]
		for x in range(level_width):
			var tile := row.substr(x, 1)
			if tile == "#":
				grid_map.set_cell_item(Vector3i(x, 0, y), 0)
			else:
				if x % light_spacing == 1 and y % light_spacing == 1:
					var fixture := CEILING_LIGHT_SCENE.instantiate()
					fixture.position = cell_to_world(Vector2i(x, y)) + Vector3(0, WALL_HEIGHT - 0.003, 0)
					world.add_child(fixture)
				if tile == "S":
					start_cell = Vector2i(x, y)
				elif tile == "E":
					goal_cell = Vector2i(x, y)

func make_paper_material(paper: Color, ink: Color, pattern: int, pattern_scale: float, line_width: float, roughness: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = WALLPAPER_SHADER
	material.set_shader_parameter("paper_color", paper)
	material.set_shader_parameter("ink_color", ink)
	material.set_shader_parameter("pattern", pattern)
	material.set_shader_parameter("pattern_scale", pattern_scale)
	material.set_shader_parameter("line_width", line_width)
	material.set_shader_parameter("roughness_value", roughness)
	return material

func make_carpet_material(field: Color, border: Color) -> ShaderMaterial:
	var maze_image := Image.create(level_width, level_height, false, Image.FORMAT_L8)
	for y in range(level_height):
		var row: String = current_layout[y]
		for x in range(level_width):
			maze_image.set_pixel(x, y, Color.WHITE if row.substr(x, 1) == "#" else Color.BLACK)
	var material := ShaderMaterial.new()
	material.shader = CARPET_SHADER
	material.set_shader_parameter("maze_map", ImageTexture.create_from_image(maze_image))
	material.set_shader_parameter("maze_size", Vector2(level_width, level_height))
	material.set_shader_parameter("maze_origin", Vector2(-level_width * CELL_SIZE * 0.5, -level_height * CELL_SIZE * 0.5))
	material.set_shader_parameter("cell_size", CELL_SIZE)
	material.set_shader_parameter("border_width", CELL_SIZE * CARPET_BORDER_RATIO)
	material.set_shader_parameter("field_color", field)
	material.set_shader_parameter("border_color", border)
	return material

# Wall block with a baseboard and a slim top trim. GridMap centers items, so the
# mesh spans -WALL_HEIGHT/2..WALL_HEIGHT/2 vertically.
func build_wall_mesh(paper_material: Material, trim_material: Material) -> ArrayMesh:
	var half_height := WALL_HEIGHT * 0.5
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box_arrays(Vector3(CELL_SIZE, WALL_HEIGHT, CELL_SIZE), Vector3.ZERO))
	mesh.surface_set_material(0, paper_material)
	var base_size := Vector3(CELL_SIZE + BASEBOARD_DEPTH * 2.0, BASEBOARD_HEIGHT, CELL_SIZE + BASEBOARD_DEPTH * 2.0)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box_arrays(base_size, Vector3(0, -half_height + BASEBOARD_HEIGHT * 0.5, 0)))
	mesh.surface_set_material(1, trim_material)
	var top_size := Vector3(CELL_SIZE + TOP_TRIM_DEPTH * 2.0, TOP_TRIM_HEIGHT, CELL_SIZE + TOP_TRIM_DEPTH * 2.0)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box_arrays(top_size, Vector3(0, half_height - TOP_TRIM_HEIGHT * 0.5, 0)))
	mesh.surface_set_material(2, trim_material)
	return mesh

func box_arrays(size: Vector3, offset: Vector3) -> Array:
	var box := BoxMesh.new()
	box.size = size
	var arrays := box.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in range(vertices.size()):
		vertices[i] += offset
	arrays[Mesh.ARRAY_VERTEX] = vertices
	return arrays

func add_box(position: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.position = position
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	collision.shape = box_shape
	body.add_child(collision)
	world.add_child(body)

func spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.position = cell_to_world(start_cell) + Vector3(0, 0.05, 0)
	world.add_child(player)
	var camera := player.get_node("Camera3D") as Camera3D
	camera.current = true
	var headlamp := player.get_node("Camera3D/Headlamp") as SpotLight3D
	headlamp.light_energy = float(current_theme.get("headlamp_energy", 0.25))
	var east_open: bool = start_cell.x + 1 < level_width and current_layout[start_cell.y].substr(start_cell.x + 1, 1) != "#"
	player.rotation.y = -PI * 0.5 if east_open else PI

func build_goal() -> void:
	var goal_area := Area3D.new()
	goal_area.position = cell_to_world(goal_cell) + Vector3(0, 1.0, 0)
	var goal_collision := CollisionShape3D.new()
	var goal_shape := BoxShape3D.new()
	goal_shape.size = Vector3(2.4, 2.0, 2.4)
	goal_collision.shape = goal_shape
	goal_area.add_child(goal_collision)
	# The doorway sits on the dead-end wall; its local +Z faces back into the cell.
	portal_node = Node3D.new()
	var far_dir := find_door_dir(goal_cell)
	portal_node.position = cell_to_world(goal_cell) + Vector3(far_dir.x, 0, far_dir.y) * (CELL_SIZE * 0.5)
	portal_node.rotation.y = atan2(-far_dir.x, -far_dir.y)
	build_doorway(portal_node)
	goal_area.body_entered.connect(_on_goal_body_entered)
	world.add_child(goal_area)
	world.add_child(portal_node)

func build_doorway(root: Node3D) -> void:
	doorway_material = ShaderMaterial.new()
	doorway_material.shader = DOORWAY_SHADER
	doorway_material.set_shader_parameter("opening_size", DOOR_SIZE)
	doorway_material.set_shader_parameter("light_color", DOOR_LIGHT_COLOR)
	var opening := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = DOOR_SIZE
	opening.mesh = quad
	opening.material_override = doorway_material
	opening.position = Vector3(0, DOOR_SIZE.y * 0.5, 0.03)
	opening.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(opening)

	# Casing around the opening, in the trim colour.
	var casing_width := 0.09
	var casing_depth := 0.05
	var post_height := DOOR_SIZE.y + casing_width
	for side in [-1.0, 1.0]:
		add_casing(root, Vector3(casing_width, post_height, casing_depth), Vector3(side * (DOOR_SIZE.x + casing_width) * 0.5, post_height * 0.5, casing_depth * 0.5))
	add_casing(root, Vector3(DOOR_SIZE.x + casing_width * 2.0, casing_width, casing_depth), Vector3(0, DOOR_SIZE.y + casing_width * 0.5, casing_depth * 0.5))

	shaft_material = ShaderMaterial.new()
	shaft_material.shader = SHAFT_SHADER
	shaft_material.set_shader_parameter("light_color", DOOR_LIGHT_COLOR)
	var shaft := MeshInstance3D.new()
	shaft.mesh = build_shaft_mesh(DOOR_SIZE, Vector2(2.0, 2.5), 3.2)
	shaft.material_override = shaft_material
	shaft.position.z = 0.04
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(shaft)

	door_light = SpotLight3D.new()
	door_light.light_color = DOOR_LIGHT_COLOR
	door_light.light_energy = 2.2
	door_light.spot_range = 9.0
	door_light.spot_angle = 70.0
	door_light.spot_attenuation = 1.4
	door_light.shadow_enabled = false
	door_light.position = Vector3(0, 1.7, 0.1)
	door_light.rotation = Vector3(deg_to_rad(-12.0), PI, 0)
	root.add_child(door_light)

	root.add_child(build_dust(Vector3(DOOR_SIZE.x * 0.6, DOOR_SIZE.y * 0.5, 1.4), Vector3(0, DOOR_SIZE.y * 0.5, 1.5)))

func add_casing(root: Node3D, size: Vector3, position: Vector3) -> void:
	var casing := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	casing.mesh = box
	casing.material_override = trim_material
	casing.position = position
	root.add_child(casing)

# Open-ended frustum from the door outward along +Z (no floor face, to avoid z-fighting).
func build_shaft_mesh(near_size: Vector2, far_size: Vector2, length: float) -> ArrayMesh:
	var near := [Vector3(-near_size.x * 0.5, 0, 0), Vector3(near_size.x * 0.5, 0, 0), Vector3(near_size.x * 0.5, near_size.y, 0), Vector3(-near_size.x * 0.5, near_size.y, 0)]
	var far := [Vector3(-far_size.x * 0.5, 0, length), Vector3(far_size.x * 0.5, 0, length), Vector3(far_size.x * 0.5, far_size.y, length), Vector3(-far_size.x * 0.5, far_size.y, length)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# right, top, left
	for edge in [[1, 2], [2, 3], [3, 0]]:
		var a: int = edge[0]
		var b: int = edge[1]
		for vertex in [[near[a], 0.0], [far[a], 1.0], [far[b], 1.0], [near[a], 0.0], [far[b], 1.0], [near[b], 0.0]]:
			surface.set_uv(Vector2(0, vertex[1]))
			surface.add_vertex(vertex[0])
	surface.generate_normals()
	return surface.commit()

func build_dust(extents: Vector3, center: Vector3) -> GPUParticles3D:
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = extents
	process.direction = Vector3(0, 1, 0)
	process.spread = 180.0
	process.initial_velocity_min = 0.02
	process.initial_velocity_max = 0.07
	process.gravity = Vector3.ZERO
	process.scale_min = 0.5
	process.scale_max = 1.2
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	process.color_ramp = ramp
	var mote := StandardMaterial3D.new()
	mote.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mote.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mote.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mote.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mote.vertex_color_use_as_albedo = true
	mote.albedo_color = Color(DOOR_LIGHT_COLOR, 0.4)
	var soft_dot := Gradient.new()
	soft_dot.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var dot_texture := GradientTexture2D.new()
	dot_texture.gradient = soft_dot
	dot_texture.fill = GradientTexture2D.FILL_RADIAL
	dot_texture.fill_from = Vector2(0.5, 0.5)
	dot_texture.fill_to = Vector2(0.5, 0.0)
	dot_texture.width = 16
	dot_texture.height = 16
	mote.albedo_texture = dot_texture
	var quad := QuadMesh.new()
	quad.size = Vector2(0.014, 0.014)
	quad.material = mote
	var dust := GPUParticles3D.new()
	dust.amount = 48
	dust.lifetime = 6.0
	dust.preprocess = 6.0
	dust.process_material = process
	dust.draw_pass_1 = quad
	dust.position = center
	dust.visibility_aabb = AABB(-extents * 1.5, extents * 3.0)
	return dust

# Dev helper: stand a little way back from the exit, facing the door.
func peek_exit() -> void:
	var door_dir := find_door_dir(goal_cell)
	var stand := goal_cell
	for i in range(1):
		if is_wall_cell(stand - door_dir) or stand.x - door_dir.x < 0 or stand.y - door_dir.y < 0:
			break
		stand -= door_dir
	player.position = cell_to_world(stand) + Vector3(0, 0.05, 0)
	player.rotation.y = atan2(-door_dir.x, -door_dir.y)

# Wall the exit door hangs on: opposite the way in when possible, else any wall.
func find_door_dir(cell: Vector2i) -> Vector2i:
	var back := -find_open_dir(cell)
	if is_wall_cell(cell + back):
		return back
	for direction in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]:
		if is_wall_cell(cell + direction):
			return direction
	return back

func is_wall_cell(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= level_width or cell.y < 0 or cell.y >= level_height:
		return false
	return current_layout[cell.y].substr(cell.x, 1) == "#"

func find_open_dir(cell: Vector2i) -> Vector2i:
	for direction in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]:
		var neighbor: Vector2i = cell + direction
		if neighbor.x >= 0 and neighbor.x < level_width and neighbor.y >= 0 and neighbor.y < level_height:
			if current_layout[neighbor.y].substr(neighbor.x, 1) != "#":
				return direction
	return Vector2i(0, -1)

func build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Label.new()
	hud.text = "%s\nFind the lit exit.\n\nDrag the ring to move and turn\nCenter stops you" % current_theme["title"]
	hud.position = Vector2(24, 48)
	hud.add_theme_font_size_override("font_size", 18)
	hud.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	hud.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	hud.add_theme_constant_override("shadow_offset_x", 2)
	hud.add_theme_constant_override("shadow_offset_y", 2)
	canvas.add_child(hud)
	status = Label.new()
	status.text = ""
	status.position = Vector2(24, 230)
	status.add_theme_font_size_override("font_size", 22)
	status.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	status.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	status.add_theme_constant_override("shadow_offset_x", 2)
	status.add_theme_constant_override("shadow_offset_y", 2)
	canvas.add_child(status)
	menu_button = Button.new()
	menu_button.icon = MENU_ICON
	menu_button.expand_icon = true
	menu_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_button.tooltip_text = "Menu"
	menu_button.anchor_left = 1.0
	menu_button.anchor_right = 1.0
	menu_button.offset_left = -76
	menu_button.offset_right = -20
	menu_button.offset_top = 44
	menu_button.offset_bottom = 100
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		menu_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	set_menu_icon_color(Color.WHITE if current_theme["ambient_energy"] < 0.3 else Color.BLACK)
	menu_button.pressed.connect(open_menu)
	canvas.add_child(menu_button)
	chalk_button = Button.new()
	chalk_button.icon = CHALK_ICON
	chalk_button.expand_icon = true
	chalk_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chalk_button.tooltip_text = "Chalk"
	chalk_button.anchor_left = 1.0
	chalk_button.anchor_right = 1.0
	chalk_button.anchor_top = 1.0
	chalk_button.anchor_bottom = 1.0
	chalk_button.offset_left = -112
	chalk_button.offset_right = -24
	chalk_button.offset_top = -208
	chalk_button.offset_bottom = -120
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.08, 0.08, 0.6 if state == "pressed" else 0.4)
		style.set_corner_radius_all(44)
		style.set_content_margin_all(10)
		if state == "focus":
			style.draw_center = false
		chalk_button.add_theme_stylebox_override(state, style)
	chalk_button.pressed.connect(_on_chalk_pressed)
	canvas.add_child(chalk_button)
	joystick = JOYSTICK_SCENE.instantiate()
	joystick.anchor_left = 0.5
	joystick.anchor_right = 0.5
	joystick.anchor_top = 1.0
	joystick.anchor_bottom = 1.0
	joystick.offset_left = -140
	joystick.offset_right = 140
	joystick.offset_top = -340
	joystick.offset_bottom = -60
	canvas.add_child(joystick)
	joystick.value_changed.connect(player.set_move_input)
	player.started_moving.connect(_on_player_started_moving)
	fade_overlay = ColorRect.new()
	fade_overlay.color = Color(0, 0, 0, 1)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(fade_overlay)
	fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var menu_layer := CanvasLayer.new()
	menu_layer.layer = 10
	menu_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(menu_layer)
	menu_overlay = ColorRect.new()
	menu_overlay.color = Color(0, 0, 0, 0.6)
	menu_overlay.visible = false
	menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_layer.add_child(menu_overlay)
	menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	menu_overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	var title := Label.new()
	title.text = "Menu"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	var resume_button := Button.new()
	resume_button.text = "Resume"
	resume_button.custom_minimum_size = Vector2(0, 48)
	resume_button.add_theme_font_size_override("font_size", 18)
	resume_button.pressed.connect(close_menu)
	vbox.add_child(resume_button)
	var restart_level_button := Button.new()
	restart_level_button.text = "Restart level"
	restart_level_button.custom_minimum_size = Vector2(0, 48)
	restart_level_button.add_theme_font_size_override("font_size", 18)
	restart_level_button.pressed.connect(_on_restart_level)
	vbox.add_child(restart_level_button)
	var restart_scratch_button := Button.new()
	restart_scratch_button.text = "Restart from scratch"
	restart_scratch_button.custom_minimum_size = Vector2(0, 48)
	restart_scratch_button.add_theme_font_size_override("font_size", 18)
	restart_scratch_button.pressed.connect(_on_restart_scratch)
	vbox.add_child(restart_scratch_button)

func set_menu_icon_color(color: Color) -> void:
	menu_button.add_theme_color_override("icon_normal_color", color)
	menu_button.add_theme_color_override("icon_hover_color", color)
	menu_button.add_theme_color_override("icon_focus_color", color)
	menu_button.add_theme_color_override("icon_pressed_color", Color(color, 0.6))
	menu_button.add_theme_color_override("icon_disabled_color", Color(color, 0.35))

# Reads back one rendered frame and picks black or white menu lines depending on
# how bright the scene is behind the button.
func match_menu_icon_to_backdrop() -> void:
	for i in range(3):
		await RenderingServer.frame_post_draw
	if not is_inside_tree():
		return
	var image := world.get_texture().get_image()
	if image == null:
		return
	var screen := get_viewport().get_visible_rect().size
	var rect := menu_button.get_global_rect()
	var pixel_scale := Vector2(image.get_width(), image.get_height()) / screen
	var total := 0.0
	var samples := 0
	for sy in range(5):
		for sx in range(5):
			var point := rect.position + rect.size * Vector2((sx + 0.5) / 5.0, (sy + 0.5) / 5.0)
			var pixel := Vector2i(point * pixel_scale).clamp(Vector2i.ZERO, Vector2i(image.get_width() - 1, image.get_height() - 1))
			total += image.get_pixelv(pixel).get_luminance()
			samples += 1
	set_menu_icon_color(Color.BLACK if total / samples > 0.4 else Color.WHITE)

func cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3(
		(cell.x - (level_width - 1) * 0.5) * CELL_SIZE,
		0.0,
		(cell.y - (level_height - 1) * 0.5) * CELL_SIZE
	)

func _on_player_started_moving() -> void:
	var tween := create_tween()
	tween.tween_property(hud, "modulate:a", 0.0, 0.5)

func _on_chalk_pressed() -> void:
	if won:
		return
	var camera := player.get_node("Camera3D") as Camera3D
	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * 3.2
	var query := PhysicsRayQueryParameters3D.create(from, to, 0xFFFFFFFF, [player.get_rid()])
	var hit := world.find_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var hit_position: Vector3 = hit["position"]
	var hit_normal: Vector3 = hit["normal"]
	add_chalk_mark(hit_position, hit_normal)

func add_chalk_mark(hit_position: Vector3, normal: Vector3) -> void:
	var marker := Node3D.new()
	marker.position = hit_position + normal * 0.04
	world.add_child(marker)
	marker.look_at(hit_position, Vector3.UP)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.95, 0.95, 0.88)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for angle in [-45.0, 45.0]:
		var instance := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.4, 0.07, 0.02)
		instance.mesh = box
		instance.material_override = material
		instance.rotation_degrees = Vector3(0, 0, angle)
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		marker.add_child(instance)

func open_menu() -> void:
	menu_overlay.visible = true
	get_tree().paused = true

func close_menu() -> void:
	menu_overlay.visible = false
	get_tree().paused = false

func _on_restart_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_restart_scratch() -> void:
	Engine.set_meta("passages_level", 0)
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_goal_body_entered(body: Node3D) -> void:
	if body == player and not won:
		won = true
		player.set_physics_process(false)
		joystick.reset()
		joystick.set_process_input(false)
		joystick.modulate = Color(1, 1, 1, 0.45)
		chalk_button.disabled = true
		if current_level + 1 < LEVELS.size():
			status.text = "Passage complete."
			menu_button.disabled = true
			var tween := create_tween()
			tween.tween_property(fade_overlay, "color:a", 1.0, 0.6)
			await tween.finished
			if not is_inside_tree():
				return
			Engine.set_meta("passages_level", current_level + 1)
			get_tree().reload_current_scene()
		else:
			status.text = "You completed all passages.\nOpen the menu to restart."

func _unhandled_input(event: InputEvent) -> void:
	if won:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
		else:
			var target := -1
			if event.keycode == KEY_N:
				var step := 10 if event.shift_pressed else 1
				target = mini(current_level + step, LEVELS.size() - 1)
			elif event.keycode == KEY_0:
				target = 9
			elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
				target = int(event.keycode) - int(KEY_1)
			if target >= 0 and target < LEVELS.size():
				Engine.set_meta("passages_level", target)
				get_tree().reload_current_scene()
