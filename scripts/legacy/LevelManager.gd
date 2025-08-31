extends Node
class_name LevelManager

# Manages level loading and game state
var current_map: GameMap
var level_completed: bool = false

# Signals
signal level_completed_signal()
signal level_failed_signal()

func _init():
	current_map = GameMap.new()

# Load a level from file
func load_level(level_path: String) -> bool:
	var loaded_map = GameMap.load_from_file(level_path)
	if loaded_map:
		current_map = loaded_map
		level_completed = false
		return true
	return false

# Create a simple test level
func create_test_level() -> GameMap:
	var test_map = GameMap.new(8, 6)
	test_map.level_name = "Test Level"
	test_map.level_description = "A simple test level with laser, mirror, and target"
	
	# Place walls around the border
	for x in range(test_map.width):
		test_map.place_entity(Vector2i(x, 0), MapTypes.EntityType.WALL)
		test_map.place_entity(Vector2i(x, test_map.height - 1), MapTypes.EntityType.WALL)
	
	for y in range(test_map.height):
		test_map.place_entity(Vector2i(0, y), MapTypes.EntityType.WALL)
		test_map.place_entity(Vector2i(test_map.width - 1, y), MapTypes.EntityType.WALL)
	
	# Place a laser emitter
	test_map.place_entity(Vector2i(1, 1), MapTypes.EntityType.LASER, MapTypes.Direction.EAST)
	
	# Place a target
	test_map.place_entity(Vector2i(6, 1), MapTypes.EntityType.TARGET)
	
	# Place a mirror (player will need to rotate this)
	test_map.place_entity(Vector2i(4, 1), MapTypes.EntityType.MIRROR, MapTypes.Direction.NORTHEAST)
	
	# Make some cells non-placeable (obstacles)
	test_map.place_entity(Vector2i(3, 2), MapTypes.EntityType.WALL)
	test_map.place_entity(Vector2i(3, 3), MapTypes.EntityType.WALL)
	
	return test_map

# Save current level to file
func save_current_level(file_path: String) -> bool:
	if current_map:
		return current_map.save_to_file(file_path)
	return false

# Simulate laser behavior and check win condition
func update_laser_simulation():
	if current_map:
		LaserSimulator.simulate_lasers(current_map)
		check_win_condition()

# Check if level is completed
func check_win_condition():
	if current_map and current_map.check_win_condition():
		level_completed = true
		level_completed_signal.emit()

# Reset level to initial state
func reset_level():
	if current_map:
		level_completed = false
		current_map.clear_illumination()

# Get current map
func get_current_map() -> GameMap:
	return current_map

# Place entity on map and update simulation
func place_entity_and_update(pos: Vector2i, entity_type: MapTypes.EntityType, direction: MapTypes.Direction = MapTypes.Direction.NORTH) -> bool:
	if current_map and current_map.place_entity(pos, entity_type, direction):
		update_laser_simulation()
		return true
	return false

# Remove entity from map and update simulation
func remove_entity_and_update(pos: Vector2i) -> bool:
	if current_map and current_map.remove_entity(pos):
		update_laser_simulation()
		return true
	return false

# Rotate entity and update simulation
func rotate_entity_and_update(pos: Vector2i, clockwise: bool = true) -> bool:
	if current_map and current_map.rotate_entity(pos, clockwise):
		update_laser_simulation()
		return true
	return false
