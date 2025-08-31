extends RefCounted
class_name MapCell

# Properties of a single cell in the game map
var entity_type: MapTypes.EntityType = MapTypes.EntityType.EMPTY
var direction: MapTypes.Direction = MapTypes.Direction.NORTH
var laser_color: MapTypes.LaserColor = MapTypes.LaserColor.WHITE
var is_illuminated: bool = false
var is_placeable: bool = true  # Can the player place objects here?
var is_moveable: bool = true   # Can the player move objects from here?

func _init(type: MapTypes.EntityType = MapTypes.EntityType.EMPTY):
	entity_type = type

# Set the entity type and configure default properties
func set_entity(type: MapTypes.EntityType, dir: MapTypes.Direction = MapTypes.Direction.NORTH, color: MapTypes.LaserColor = MapTypes.LaserColor.WHITE):
	entity_type = type
	direction = dir
	laser_color = color
	
	# Configure default properties based on entity type
	match entity_type:
		MapTypes.EntityType.WALL:
			is_placeable = false
			is_moveable = false
		MapTypes.EntityType.TARGET:
			is_placeable = false
			is_moveable = false
		_:
			is_placeable = true
			is_moveable = true

# Check if this cell can be illuminated by a laser
func can_be_illuminated() -> bool:
	return entity_type != MapTypes.EntityType.WALL

# Set illumination state
func set_illuminated(illuminated: bool):
	is_illuminated = illuminated

# Get rotation angle in degrees based on direction
func get_rotation_degrees() -> float:
	match direction:
		MapTypes.Direction.NORTH:
			return 0.0
		MapTypes.Direction.EAST:
			return 90.0
		MapTypes.Direction.SOUTH:
			return 180.0
		MapTypes.Direction.WEST:
			return 270.0
		MapTypes.Direction.NORTHEAST:
			return 45.0
		MapTypes.Direction.SOUTHEAST:
			return 135.0
		MapTypes.Direction.SOUTHWEST:
			return 225.0
		MapTypes.Direction.NORTHWEST:
			return 315.0
		_:
			return 0.0

# Convert cell to dictionary for serialization
func to_dict() -> Dictionary:
	return {
		"entity_type": entity_type,
		"direction": direction,
		"laser_color": laser_color,
		"is_placeable": is_placeable,
		"is_moveable": is_moveable
	}

# Create cell from dictionary
static func from_dict(data: Dictionary) -> MapCell:
	var cell = MapCell.new()
	cell.entity_type = data.get("entity_type", MapTypes.EntityType.EMPTY)
	cell.direction = data.get("direction", MapTypes.Direction.NORTH)
	cell.laser_color = data.get("laser_color", MapTypes.LaserColor.WHITE)
	cell.is_placeable = data.get("is_placeable", true)
	cell.is_moveable = data.get("is_moveable", true)
	return cell
