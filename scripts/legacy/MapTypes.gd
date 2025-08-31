extends RefCounted
class_name MapTypes

# Entity types that can occupy a cell in the game map
enum EntityType {
	EMPTY,			# Empty cell
	WALL,			# Solid wall that blocks lasers
	LASER,			# Laser emitter
	MIRROR,			# Mirror that reflects lasers
	TARGET,			# Target that needs to be illuminated
	SPLITTER,		# Beam splitter
	PRISM,			# Prism that separates white light into colors
	DETECTOR		# Detector that shows if a laser passes through
}

# Laser directions
enum Direction {
	NORTH,
	EAST,
	SOUTH,
	WEST,
	NORTHEAST,
	SOUTHEAST,
	SOUTHWEST,
	NORTHWEST
}

# Laser colors for advanced gameplay
enum LaserColor {
	WHITE,
	RED,
	GREEN,
	BLUE,
	YELLOW,
	CYAN,
	MAGENTA
}
