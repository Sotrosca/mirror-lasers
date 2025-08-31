extends Node2D

# Level1 - Version with visual editor support
var grid_width = 8
var grid_height = 6

# Get references to UI nodes created in editor
@onready var game_board_control = $UI/GameBoard
@onready var game_board = $UI/GameBoard/GridContainer
@onready var cell_nodes = []

# Game state
var board_data = []

enum EntityType {
	EMPTY = 0,
	WALL = 1,
	LASER = 2,
	MIRROR = 3,
	TARGET = 4
}

enum Direction {
	NORTH = 0,
	EAST = 1,
	SOUTH = 2,
	WEST = 3
}

func _ready():
	print("🚀 Starting Level1 with visual editor support...")

	# Initialize board data
	initialize_board()

	# Get cell nodes from editor (if they exist)
	setup_cell_references()

	# If no cells exist, create them programmatically
	if cell_nodes.is_empty():
		create_cells_programmatically()

	# Setup test level
	setup_test_level()

	print("✅ Level ready! Visual editor + script working together")

func setup_cell_references():
	# Try to get existing cell nodes from editor
	cell_nodes.clear()

	if game_board:
		var children = game_board.get_children()
		if children.size() == grid_width * grid_height:
			# Cells exist in editor, organize them in 2D array
			for y in range(grid_height):
				var row = []
				for x in range(grid_width):
					var index = y * grid_width + x
					row.append(children[index])
				cell_nodes.append(row)
			print("📋 Using cells created in visual editor")
		else:
			print("⚠️ Expected %d cells, found %d" % [grid_width * grid_height, children.size()])

func create_cells_programmatically():
	# Fallback: create cells via script if not in editor
	print("🔧 Creating cells programmatically...")

	for y in range(grid_height):
		var row = []
		for x in range(grid_width):
			var cell_rect = ColorRect.new()
			cell_rect.name = "Cell_%d_%d" % [x, y]
			cell_rect.custom_minimum_size = Vector2(64, 64)
			cell_rect.color = Color(0.9, 0.9, 0.9)

			var label = Label.new()
			label.name = "Label"
			label.size = Vector2(64, 64)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 32)
			cell_rect.add_child(label)

			game_board.add_child(cell_rect)
			row.append(cell_rect)

		cell_nodes.append(row)

func initialize_board():
	board_data.clear()
	for y in range(grid_height):
		var row = []
		for x in range(grid_width):
			row.append({
				"type": EntityType.EMPTY,
				"direction": Direction.NORTH,
				"illuminated": false
			})
		board_data.append(row)

func setup_test_level():
	# Create walls around border
	for x in range(grid_width):
		set_cell(x, 0, EntityType.WALL)
		set_cell(x, grid_height - 1, EntityType.WALL)

	for y in range(grid_height):
		set_cell(0, y, EntityType.WALL)
		set_cell(grid_width - 1, y, EntityType.WALL)

	# Place game elements
	set_cell(1, 1, EntityType.LASER, Direction.EAST)
	set_cell(6, 1, EntityType.TARGET)
	set_cell(4, 1, EntityType.MIRROR, Direction.NORTH)
	set_cell(3, 2, EntityType.WALL)
	set_cell(3, 3, EntityType.WALL)

	update_visuals()
	simulate_lasers()

func set_cell(x: int, y: int, type: EntityType, direction: Direction = Direction.NORTH):
	if is_valid_position(x, y):
		board_data[y][x]["type"] = type
		board_data[y][x]["direction"] = direction

func is_valid_position(x: int, y: int) -> bool:
	return x >= 0 and x < grid_width and y >= 0 and y < grid_height

func update_visuals():
	if cell_nodes.is_empty():
		return

	for y in range(grid_height):
		for x in range(grid_width):
			var cell_data = board_data[y][x]
			var cell_node = cell_nodes[y][x]
			var label = cell_node.get_node("Label")

			# Update colors and symbols
			match cell_data["type"]:
				EntityType.EMPTY:
					cell_node.color = Color(0.9, 0.9, 0.9)
					label.text = ""
				EntityType.WALL:
					cell_node.color = Color(0.3, 0.3, 0.3)
					label.text = "█"
					label.add_theme_color_override("font_color", Color.WHITE)
				EntityType.LASER:
					cell_node.color = Color.RED
					label.text = get_direction_arrow(cell_data["direction"])
					label.add_theme_color_override("font_color", Color.WHITE)
				EntityType.MIRROR:
					cell_node.color = Color.CYAN
					label.text = get_mirror_symbol(cell_data["direction"])
					label.add_theme_color_override("font_color", Color.BLACK)
				EntityType.TARGET:
					if cell_data["illuminated"]:
						cell_node.color = Color.GREEN
						label.text = "✓"
						label.add_theme_color_override("font_color", Color.WHITE)
					else:
						cell_node.color = Color.YELLOW
						label.text = "◉"
						label.add_theme_color_override("font_color", Color.BLACK)

			# Illumination overlay
			if cell_data["illuminated"] and cell_data["type"] != EntityType.WALL:
				cell_node.color = cell_node.color.lightened(0.3)

func get_direction_arrow(direction: Direction) -> String:
	match direction:
		Direction.NORTH: return "↑"
		Direction.EAST: return "→"
		Direction.SOUTH: return "↓"
		Direction.WEST: return "←"
		_: return "?"

func get_mirror_symbol(direction: Direction) -> String:
	match direction:
		Direction.NORTH, Direction.SOUTH: return "|"
		Direction.EAST, Direction.WEST: return "—"
		_: return "/"

func simulate_lasers():
	# Clear illumination
	for y in range(grid_height):
		for x in range(grid_width):
			board_data[y][x]["illuminated"] = false

	# Find lasers and trace beams
	for y in range(grid_height):
		for x in range(grid_width):
			var cell_data = board_data[y][x]
			if cell_data["type"] == EntityType.LASER:
				trace_laser(x, y, cell_data["direction"])

func trace_laser(start_x: int, start_y: int, direction: Direction):
	var current_x = start_x
	var current_y = start_y
	var current_dir = direction
	var max_steps = 50
	var steps = 0

	while steps < max_steps:
		steps += 1

		# Move in current direction
		match current_dir:
			Direction.NORTH: current_y -= 1
			Direction.EAST: current_x += 1
			Direction.SOUTH: current_y += 1
			Direction.WEST: current_x -= 1

		# Check bounds
		if not is_valid_position(current_x, current_y):
			break

		var cell_data = board_data[current_y][current_x]

		# Process cell
		match cell_data["type"]:
			EntityType.EMPTY, EntityType.TARGET:
				cell_data["illuminated"] = true
			EntityType.WALL:
				break
			EntityType.MIRROR:
				cell_data["illuminated"] = true
				current_dir = reflect_laser(current_dir, cell_data["direction"])
			EntityType.LASER:
				cell_data["illuminated"] = true
				break

func reflect_laser(laser_dir: Direction, mirror_dir: Direction) -> Direction:
	# Simple reflection logic
	match mirror_dir:
		Direction.NORTH, Direction.SOUTH:  # Vertical mirror |
			match laser_dir:
				Direction.EAST: return Direction.WEST
				Direction.WEST: return Direction.EAST
				_: return laser_dir
		Direction.EAST, Direction.WEST:   # Horizontal mirror —
			match laser_dir:
				Direction.NORTH: return Direction.SOUTH
				Direction.SOUTH: return Direction.NORTH
				_: return laser_dir
	return laser_dir

func world_to_grid(world_pos: Vector2) -> Vector2i:
	# Robust method: test the real global rect of each cell.
	# (Original math assumed grid started at GameBoard top-left, but GridContainer has internal offsets.)
	if cell_nodes.is_empty():
		return Vector2i(-1, -1)
	for y in range(grid_height):
		for x in range(grid_width):
			var cell: ColorRect = cell_nodes[y][x]
			if not is_instance_valid(cell):
				continue
			var cell_rect: Rect2 = Rect2(cell.global_position, cell.size)
			if cell_rect.has_point(world_pos):
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var grid_pos = world_to_grid(event.position)
		var x = grid_pos.x
		var y = grid_pos.y

		if is_valid_position(x, y):
			var cell_data = board_data[y][x]

			if event.button_index == MOUSE_BUTTON_LEFT:
				if cell_data["type"] == EntityType.EMPTY:
					set_cell(x, y, EntityType.MIRROR, Direction.NORTH)
					update_visuals()
					simulate_lasers()
					update_visuals()
					print("Mirror placed at (%d, %d)" % [x, y])

			elif event.button_index == MOUSE_BUTTON_RIGHT:
				if cell_data["type"] == EntityType.MIRROR:
					var new_dir = (cell_data["direction"] + 1) % 4
					set_cell(x, y, EntityType.MIRROR, new_dir)
					update_visuals()
					simulate_lasers()
					update_visuals()
					print("Mirror rotated at (%d, %d)" % [x, y])

			elif event.button_index == MOUSE_BUTTON_MIDDLE:
				if cell_data["type"] == EntityType.MIRROR:
					set_cell(x, y, EntityType.EMPTY)
					update_visuals()
					simulate_lasers()
					update_visuals()
					print("Mirror removed from (%d, %d)" % [x, y])

func _unhandled_key_input(event):
	if event.pressed:
		match event.keycode:
			KEY_R:
				setup_test_level()
				print("Level reset")
			KEY_P:
				print_board_state()

func print_board_state():
	print("Board state:")
	for y in range(grid_height):
		var row = ""
		for x in range(grid_width):
			var cell_data = board_data[y][x]
			var symbol = "."
			match cell_data["type"]:
				EntityType.WALL: symbol = "#"
				EntityType.LASER: symbol = "L"
				EntityType.MIRROR: symbol = "M"
				EntityType.TARGET: symbol = "T"

			if cell_data["illuminated"]:
				symbol = symbol.to_upper()
			row += symbol + " "
		print(row)
