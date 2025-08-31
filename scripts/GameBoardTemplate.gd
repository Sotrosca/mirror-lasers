@tool
extends Control

# SHARED BOARD TEMPLATE LOGIC
# All comments and code in ENGLISH per repository rules.

signal cell_clicked(grid_x, grid_y, button_index)
signal victory_achieved

@export var grid_width: int = 8
@export var grid_height: int = 6
@export var cell_size: int = 64
@export var separation: int = 2

# Internal state arrays
var cells: Array = []          # 2D references to ColorRect nodes
var map_data: Array = []       # 2D cell type ints
var directions: Array = []     # 2D direction ints
var lit_cells: Array = []      # 2D bool illuminated
var _inputs_connected: bool = false

# Enums
enum CellType { EMPTY, WALL, LASER, MIRROR, TARGET }
enum Direction { RIGHT, UP, LEFT, DOWN }

func _ready():
	# In editor we want immediate visual grid; in game we also run logic.
	_rebuild_for_editor()
	if not Engine.is_editor_hint():
		_connect_cell_inputs()
		# Initial draw runtime
		simulate_lasers()

var _editor_prev_dims: Vector2i = Vector2i(-1, -1)

func _notification(_what):
	# Additional hooks can be added here if needed later.
	pass

func _process(_delta):
	if Engine.is_editor_hint():
		var dims = Vector2i(grid_width, grid_height)
		if dims != _editor_prev_dims:
			_editor_prev_dims = dims
			_rebuild_for_editor()

func _rebuild_for_editor():
	# Rebuild data + grid safely (editor or runtime). Avoid connecting signals multiple times.
	_initialize_data_arrays()
	_generate_visual_grid_if_missing()
	_update_all_visuals()

# PUBLIC API --------------------------------------------------
func set_cell(x: int, y: int, type: int, direction: int = Direction.RIGHT):
	if not _in_bounds(x, y):
		return
	map_data[y][x] = type
	directions[y][x] = direction
	_update_cell_visual(x, y)
	simulate_lasers()

func get_cell_type(x: int, y: int) -> int:
	if not _in_bounds(x, y):
		return CellType.EMPTY
	return map_data[y][x]

func reset_board():
	for y in range(grid_height):
		for x in range(grid_width):
			map_data[y][x] = CellType.EMPTY
			directions[y][x] = Direction.RIGHT
			lit_cells[y][x] = false
	_update_all_visuals()

# INTERNAL SETUP ----------------------------------------------
func _initialize_data_arrays():
	cells.clear(); map_data.clear(); directions.clear(); lit_cells.clear()
	for y in range(grid_height):
		var cell_row: Array = []
		var data_row: Array = []
		var dir_row: Array = []
		var lit_row: Array = []
		for x in range(grid_width):
			cell_row.append(null)
			data_row.append(CellType.EMPTY)
			dir_row.append(Direction.RIGHT)
			lit_row.append(false)
		cells.append(cell_row)
		map_data.append(data_row)
		directions.append(dir_row)
		lit_cells.append(lit_row)

func _generate_visual_grid_if_missing():
	var grid: GridContainer = $GridContainer
	# Always rebuild (simpler) to reflect size changes.
	for child in grid.get_children():
		child.queue_free()
	# Use call_deferred in editor to avoid warnings if needed.
	if Engine.is_editor_hint():
		_call_build_cells_deferred()
	else:
		_build_cells()

func _call_build_cells_deferred():
	call_deferred("_build_cells")

func _build_cells():
	var grid: GridContainer = $GridContainer
	if not grid: return
	grid.columns = grid_width
	for y in range(grid_height):
		for x in range(grid_width):
			var cell := ColorRect.new()
			cell.mouse_filter = Control.MOUSE_FILTER_STOP
			cell.custom_minimum_size = Vector2(cell_size, cell_size)
			cell.name = "Cell_%d_%d" % [x, y]
			grid.add_child(cell)
			_ensure_cell_label(cell)
			cells[y][x] = cell
	# Fallback: ensure inputs are connected if runtime.
	if not Engine.is_editor_hint():
		_connect_cell_inputs()
	_update_all_visuals()

func _ensure_cell_label(cell: ColorRect):
	var label: Label = cell.get_node_or_null("Label")
	if not label:
		label = Label.new()
		label.name = "Label"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 32)
		label.anchors_preset = Control.PRESET_FULL_RECT
		cell.add_child(label)

func _connect_cell_inputs():
	if _inputs_connected:
		return
	for y in range(grid_height):
		for x in range(grid_width):
			var cell: ColorRect = cells[y][x]
			if cell:
				cell.gui_input.connect(_on_cell_gui_input.bind(x, y))
	_inputs_connected = true

# INPUT -------------------------------------------------------
func _on_cell_gui_input(event: InputEvent, x: int, y: int):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("cell_clicked", x, y, event.button_index)

# VISUALS -----------------------------------------------------
func _update_cell_visual(x: int, y: int):
	var cell: ColorRect = cells[y][x]
	if not cell: return
	var label: Label = cell.get_node("Label")
	var type: int = map_data[y][x]
	var dir: int = directions[y][x]
	var lit: bool = lit_cells[y][x]
	# Base visuals
	match type:
		CellType.EMPTY:
			cell.color = Color(0.9, 0.9, 0.9)
			label.text = ""
		CellType.WALL:
			cell.color = Color(0.25, 0.25, 0.25)
			label.text = "#"
			label.add_theme_color_override("font_color", Color.WHITE)
		CellType.LASER:
			cell.color = Color.RED
			label.text = _arrow_for_dir(dir)
			label.add_theme_color_override("font_color", Color.WHITE)
		CellType.MIRROR:
			cell.color = Color.CYAN
			label.text = _mirror_symbol(dir)
			label.add_theme_color_override("font_color", Color.BLACK)
		CellType.TARGET:
			if lit:
				cell.color = Color(0.1, 0.7, 0.1)
				label.text = "✓"
				label.add_theme_color_override("font_color", Color.WHITE)
			else:
				cell.color = Color(1, 0.9, 0.1)
				label.text = "◉"
				label.add_theme_color_override("font_color", Color.BLACK)
	# Illumination overlay (except walls)
	if lit and type not in [CellType.WALL]:
		cell.color = cell.color.lightened(0.35)

func _update_all_visuals():
	for y in range(grid_height):
		for x in range(grid_width):
			_update_cell_visual(x, y)

func _arrow_for_dir(dir: int) -> String:
	match dir:
		Direction.RIGHT: return "→"
		Direction.UP: return "↑"
		Direction.LEFT: return "←"
		Direction.DOWN: return "↓"
		_: return "?"

func _mirror_symbol(dir: int) -> String:
	# We repurpose the 4 direction states for 4 rotation states;
	# even = "\\" style mirror, odd = "/" style mirror. (Two visuals, two redundant rotations for cycling feel.)
	return "\\" if dir % 2 == 0 else "/"

# LASER SIMULATION --------------------------------------------
func simulate_lasers():
	# Clear illumination
	for y in range(grid_height):
		for x in range(grid_width):
			lit_cells[y][x] = false
	# Trace each laser
	for y in range(grid_height):
		for x in range(grid_width):
			if map_data[y][x] == CellType.LASER:
				_trace_laser(x, y, directions[y][x])
	_update_all_visuals()
	_check_victory()

func _trace_laser(sx: int, sy: int, dir: int):
	var x = sx
	var y = sy
	var d = dir
	var steps = 0
	var max_steps = grid_width * grid_height * 4
	while steps < max_steps:
		steps += 1
		match d:
			Direction.RIGHT: x += 1
			Direction.UP: y -= 1
			Direction.LEFT: x -= 1
			Direction.DOWN: y += 1
		if not _in_bounds(x, y):
			return
		var t = map_data[y][x]
		match t:
			CellType.EMPTY, CellType.LASER:
				lit_cells[y][x] = true
			CellType.TARGET:
				lit_cells[y][x] = true
			CellType.WALL:
				return
			CellType.MIRROR:
				lit_cells[y][x] = true
				d = _reflect(d, directions[y][x])

func _reflect(laser_dir: int, mirror_dir: int) -> int:
	# Diagonal mirror reflection.
	# We interpret even mirror_dir (0,2) as a "\\" mirror, odd (1,3) as "/" mirror.
	var is_slash: bool = mirror_dir % 2 == 1
	# Mapping tables for clarity.
	# For a "/" mirror:
	#   RIGHT -> UP, UP -> RIGHT, LEFT -> DOWN, DOWN -> LEFT
	# For a "\\" mirror:
	#   RIGHT -> DOWN, DOWN -> RIGHT, LEFT -> UP, UP -> LEFT
	if is_slash:
		match laser_dir:
			Direction.RIGHT: return Direction.UP
			Direction.UP: return Direction.RIGHT
			Direction.LEFT: return Direction.DOWN
			Direction.DOWN: return Direction.LEFT
	else:
		match laser_dir:
			Direction.RIGHT: return Direction.DOWN
			Direction.DOWN: return Direction.RIGHT
			Direction.LEFT: return Direction.UP
			Direction.UP: return Direction.LEFT
	return laser_dir

func _check_victory():
	for y in range(grid_height):
		for x in range(grid_width):
			if map_data[y][x] == CellType.TARGET and not lit_cells[y][x]:
				return
	emit_signal("victory_achieved")

# UTIL --------------------------------------------------------
func _in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < grid_width and y < grid_height
