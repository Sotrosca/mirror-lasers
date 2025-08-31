extends RefCounted
class_name LaserSimulator

# Simulates laser behavior in the game map
static func simulate_lasers(game_map: GameMap):
	# Clear previous illumination
	game_map.clear_illumination()

	# Find all laser emitters
	var laser_positions = game_map.get_entities_of_type(MapTypes.EntityType.LASER)

	# Process each laser
	for laser_pos in laser_positions:
		var laser_cell = game_map.get_cell(laser_pos)
		if laser_cell:
			simulate_laser_beam(game_map, laser_pos, laser_cell.direction, laser_cell.laser_color)

# Simulate a single laser beam
static func simulate_laser_beam(game_map: GameMap, start_pos: Vector2i, direction: MapTypes.Direction, color: MapTypes.LaserColor, max_bounces: int = 50):
	var current_pos = start_pos
	var current_direction = direction
	var bounces = 0

	while bounces < max_bounces:
		# Move to next position
		var direction_vector = game_map.get_direction_vector(current_direction)
		var next_pos = current_pos + direction_vector

		# Check if next position is valid
		if not game_map.is_valid_position(next_pos):
			break

		var next_cell = game_map.get_cell(next_pos)
		if not next_cell:
			break

		current_pos = next_pos

		# Process the cell we just entered
		match next_cell.entity_type:
			MapTypes.EntityType.EMPTY, MapTypes.EntityType.DETECTOR:
				# Laser passes through, illuminate the cell
				next_cell.set_illuminated(true)

			MapTypes.EntityType.TARGET:
				# Illuminate target
				next_cell.set_illuminated(true)
				game_map.target_illuminated.emit(current_pos)

			MapTypes.EntityType.WALL:
				# Laser is blocked
				break

			MapTypes.EntityType.MIRROR:
				# Reflect laser
				next_cell.set_illuminated(true)
				current_direction = reflect_direction(current_direction, next_cell.direction)
				bounces += 1

			MapTypes.EntityType.SPLITTER:
				# Split laser beam (simplified - just reflect for now)
				next_cell.set_illuminated(true)
				current_direction = reflect_direction(current_direction, next_cell.direction)
				bounces += 1

			MapTypes.EntityType.PRISM:
				# Separate colors (simplified - just pass through for now)
				next_cell.set_illuminated(true)

			MapTypes.EntityType.LASER:
				# Hit another laser
				next_cell.set_illuminated(true)
				break

# Reflect laser direction based on mirror orientation
static func reflect_direction(laser_dir: MapTypes.Direction, mirror_dir: MapTypes.Direction) -> MapTypes.Direction:
	# Simplified reflection logic - mirrors reflect at 90 degree angles
	match mirror_dir:
		MapTypes.Direction.NORTH, MapTypes.Direction.SOUTH:
			# Vertical mirror
			match laser_dir:
				MapTypes.Direction.EAST: return MapTypes.Direction.WEST
				MapTypes.Direction.WEST: return MapTypes.Direction.EAST
				_: return laser_dir

		MapTypes.Direction.EAST, MapTypes.Direction.WEST:
			# Horizontal mirror
			match laser_dir:
				MapTypes.Direction.NORTH: return MapTypes.Direction.SOUTH
				MapTypes.Direction.SOUTH: return MapTypes.Direction.NORTH
				_: return laser_dir

		MapTypes.Direction.NORTHEAST, MapTypes.Direction.SOUTHWEST:
			# Diagonal mirror (\)
			match laser_dir:
				MapTypes.Direction.NORTH: return MapTypes.Direction.WEST
				MapTypes.Direction.EAST: return MapTypes.Direction.SOUTH
				MapTypes.Direction.SOUTH: return MapTypes.Direction.EAST
				MapTypes.Direction.WEST: return MapTypes.Direction.NORTH
				_: return laser_dir

		MapTypes.Direction.NORTHWEST, MapTypes.Direction.SOUTHEAST:
			# Diagonal mirror (/)
			match laser_dir:
				MapTypes.Direction.NORTH: return MapTypes.Direction.EAST
				MapTypes.Direction.EAST: return MapTypes.Direction.NORTH
				MapTypes.Direction.SOUTH: return MapTypes.Direction.WEST
				MapTypes.Direction.WEST: return MapTypes.Direction.SOUTH
				_: return laser_dir

	return laser_dir
