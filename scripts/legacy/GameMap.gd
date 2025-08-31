extends RefCounted
class_name GameMap

# Game map that manages a 2D grid of cells
var width: int
var height: int
var cells: Array = []
var level_name: String = ""
var level_description: String = ""

# Signals for game events
signal target_illuminated(position: Vector2i)
signal all_targets_illuminated()
signal laser_path_changed()

func _init(w: int = 10, h: int = 10):
	width = w
	height = h
	initialize_cells()

# Initialize the cell grid with empty cells
func initialize_cells():
	cells.clear()
	cells.resize(height)
	
	for y in range(height):
		cells[y] = []
		cells[y].resize(width)
		for x in range(width):
			cells[y][x] = MapCell.new()

# Get cell at position (returns null if out of bounds)
func get_cell(pos: Vector2i):
	if is_valid_position(pos):
		return cells[pos.y][pos.x]
	return null

# Set cell at position
func set_cell(pos: Vector2i, cell) -> bool:
	if is_valid_position(pos):
		cells[pos.y][pos.x] = cell
		return true
	return false

# Check if position is within map bounds
func is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height

# Place an entity at the specified position
func place_entity(pos: Vector2i, entity_type: MapTypes.EntityType, direction: MapTypes.Direction = MapTypes.Direction.NORTH, color: MapTypes.LaserColor = MapTypes.LaserColor.WHITE) -> bool:
	var cell = get_cell(pos)
	if cell and cell.is_placeable:
		cell.set_entity(entity_type, direction, color)
		return true
	return false

# Remove entity from position (set to empty)
func remove_entity(pos: Vector2i) -> bool:
	var cell = get_cell(pos)
	if cell and cell.is_moveable:
		cell.set_entity(MapTypes.EntityType.EMPTY)
		return true
	return false

# Move entity from one position to another
func move_entity(from_pos: Vector2i, to_pos: Vector2i) -> bool:
	var from_cell = get_cell(from_pos)
	var to_cell = get_cell(to_pos)
	
	if from_cell and to_cell and from_cell.is_moveable and to_cell.is_placeable:
		# Copy entity data
		to_cell.set_entity(from_cell.entity_type, from_cell.direction, from_cell.laser_color)
		# Clear source cell
		from_cell.set_entity(MapTypes.EntityType.EMPTY)
		return true
	return false

# Rotate entity at position
func rotate_entity(pos: Vector2i, clockwise: bool = true) -> bool:
	var cell = get_cell(pos)
	if cell and cell.is_moveable and cell.entity_type != MapTypes.EntityType.EMPTY:
		var current_dir = cell.direction
		var new_dir: MapTypes.Direction
		
		if clockwise:
			new_dir = get_next_direction_clockwise(current_dir)
		else:
			new_dir = get_next_direction_counterclockwise(current_dir)
		
		cell.direction = new_dir
		return true
	return false

# Get next direction clockwise
func get_next_direction_clockwise(dir: MapTypes.Direction) -> MapTypes.Direction:
	match dir:
		MapTypes.Direction.NORTH: return MapTypes.Direction.EAST
		MapTypes.Direction.EAST: return MapTypes.Direction.SOUTH
		MapTypes.Direction.SOUTH: return MapTypes.Direction.WEST
		MapTypes.Direction.WEST: return MapTypes.Direction.NORTH
		_: return dir

# Get next direction counterclockwise
func get_next_direction_counterclockwise(dir: MapTypes.Direction) -> MapTypes.Direction:
	match dir:
		MapTypes.Direction.NORTH: return MapTypes.Direction.WEST
		MapTypes.Direction.WEST: return MapTypes.Direction.SOUTH
		MapTypes.Direction.SOUTH: return MapTypes.Direction.EAST
		MapTypes.Direction.EAST: return MapTypes.Direction.NORTH
		_: return dir

# Get all positions of entities of a specific type
func get_entities_of_type(entity_type: MapTypes.EntityType) -> Array:
	var positions = []
	
	for y in range(height):
		for x in range(width):
			if cells[y][x].entity_type == entity_type:
				positions.append(Vector2i(x, y))
	
	return positions

# Check if all targets are illuminated
func check_win_condition() -> bool:
	var target_positions = get_entities_of_type(MapTypes.EntityType.TARGET)
	
	for pos in target_positions:
		var cell = get_cell(pos)
		if cell and not cell.is_illuminated:
			return false
	
	return target_positions.size() > 0

# Clear all illumination states
func clear_illumination():
	for y in range(height):
		for x in range(width):
			cells[y][x].set_illuminated(false)

# Get direction vector from direction enum
func get_direction_vector(direction: MapTypes.Direction) -> Vector2i:
	match direction:
		MapTypes.Direction.NORTH: return Vector2i(0, -1)
		MapTypes.Direction.EAST: return Vector2i(1, 0)
		MapTypes.Direction.SOUTH: return Vector2i(0, 1)
		MapTypes.Direction.WEST: return Vector2i(-1, 0)
		MapTypes.Direction.NORTHEAST: return Vector2i(1, -1)
		MapTypes.Direction.SOUTHEAST: return Vector2i(1, 1)
		MapTypes.Direction.SOUTHWEST: return Vector2i(-1, 1)
		MapTypes.Direction.NORTHWEST: return Vector2i(-1, -1)
		_: return Vector2i(0, 0)

# Convert map to dictionary for serialization
func to_dict() -> Dictionary:
	var cell_data = []
	
	for y in range(height):
		var row = []
		for x in range(width):
			row.append(cells[y][x].to_dict())
		cell_data.append(row)
	
	return {
		"width": width,
		"height": height,
		"level_name": level_name,
		"level_description": level_description,
		"cells": cell_data
	}

# Create map from dictionary
static func from_dict(data: Dictionary) -> GameMap:
	var map = GameMap.new(data.get("width", 10), data.get("height", 10))
	map.level_name = data.get("level_name", "")
	map.level_description = data.get("level_description", "")
	
	var cell_data = data.get("cells", [])
	for y in range(map.height):
		for x in range(map.width):
			if y < cell_data.size() and x < cell_data[y].size():
				map.cells[y][x] = MapCell.from_dict(cell_data[y][x])
	
	return map

# Save map to file
func save_to_file(file_path: String) -> bool:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(to_dict())
		file.store_string(json_string)
		file.close()
		return true
	return false

# Load map from file
static func load_from_file(file_path: String) -> GameMap:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			return GameMap.from_dict(json.data)
	
	# Return default map if loading fails
	return GameMap.new()
