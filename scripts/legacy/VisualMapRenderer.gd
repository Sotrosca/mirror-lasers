extends Node2D

# Visual map renderer using Godot nodes
class_name VisualMapRenderer

var cell_size: int = 64
var grid_offset: Vector2 = Vector2(100, 100)
var cell_nodes: Array = []  # 2D array of visual nodes

# Colors for visual elements
var color_empty: Color = Color(0.9, 0.9, 0.9)
var color_wall: Color = Color(0.3, 0.3, 0.3)
var color_laser: Color = Color(1.0, 0.2, 0.2)
var color_mirror: Color = Color(0.2, 0.8, 1.0)
var color_target: Color = Color(1.0, 1.0, 0.2)
var color_target_lit: Color = Color(0.2, 1.0, 0.2)
var color_illuminated: Color = Color(1.0, 1.0, 0.0, 0.4)

func setup_visual_grid(game_map: GameMap):
	# Clear existing nodes
	clear_visual_grid()
	
	# Create visual grid
	cell_nodes.clear()
	cell_nodes.resize(game_map.height)
	
	for y in range(game_map.height):
		cell_nodes[y] = []
		cell_nodes[y].resize(game_map.width)
		
		for x in range(game_map.width):
			var cell_node = create_cell_visual(Vector2i(x, y))
			add_child(cell_node)
			cell_nodes[y][x] = cell_node

func create_cell_visual(grid_pos: Vector2i) -> Control:
	var cell_container = Control.new()
	cell_container.name = "Cell_" + str(grid_pos.x) + "_" + str(grid_pos.y)
	cell_container.position = grid_to_world(grid_pos)
	cell_container.size = Vector2(cell_size, cell_size)
	
	# Background
	var background = ColorRect.new()
	background.name = "Background"
	background.size = Vector2(cell_size, cell_size)
	background.color = color_empty
	cell_container.add_child(background)
	
	# Border
	var border = ColorRect.new()
	border.name = "Border"
	border.position = Vector2(0, 0)
	border.size = Vector2(cell_size, cell_size)
	border.color = Color.TRANSPARENT
	border.add_theme_stylebox_override("normal", create_border_style())
	cell_container.add_child(border)
	
	# Entity icon/symbol
	var entity_label = Label.new()
	entity_label.name = "EntityLabel"
	entity_label.size = Vector2(cell_size, cell_size)
	entity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	entity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	entity_label.add_theme_font_size_override("font_size", 24)
	cell_container.add_child(entity_label)
	
	# Illumination overlay
	var illumination = ColorRect.new()
	illumination.name = "Illumination"
	illumination.position = Vector2(4, 4)
	illumination.size = Vector2(cell_size - 8, cell_size - 8)
	illumination.color = color_illuminated
	illumination.visible = false
	cell_container.add_child(illumination)
	
	return cell_container

func create_border_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color.GRAY
	style.bg_color = Color.TRANSPARENT
	return style

func update_cell_visual(grid_pos: Vector2i, cell: MapCell):
	if not is_valid_grid_position(grid_pos):
		return
	
	var cell_node = cell_nodes[grid_pos.y][grid_pos.x]
	var background = cell_node.get_node("Background")
	var entity_label = cell_node.get_node("EntityLabel")
	var illumination = cell_node.get_node("Illumination")
	
	# Update background color and entity symbol
	match cell.entity_type:
		MapTypes.EntityType.EMPTY:
			background.color = color_empty
			entity_label.text = ""
			
		MapTypes.EntityType.WALL:
			background.color = color_wall
			entity_label.text = "█"
			entity_label.add_theme_color_override("font_color", Color.WHITE)
			
		MapTypes.EntityType.LASER:
			background.color = color_laser
			entity_label.text = get_direction_arrow(cell.direction)
			entity_label.add_theme_color_override("font_color", Color.WHITE)
			
		MapTypes.EntityType.MIRROR:
			background.color = color_mirror
			entity_label.text = get_mirror_symbol(cell.direction)
			entity_label.add_theme_color_override("font_color", Color.BLACK)
			
		MapTypes.EntityType.TARGET:
			if cell.is_illuminated:
				background.color = color_target_lit
				entity_label.text = "✓"
				entity_label.add_theme_color_override("font_color", Color.WHITE)
			else:
				background.color = color_target
				entity_label.text = "◉"
				entity_label.add_theme_color_override("font_color", Color.BLACK)
	
	# Update illumination overlay
	illumination.visible = cell.is_illuminated and cell.entity_type != MapTypes.EntityType.WALL

func get_direction_arrow(direction: MapTypes.Direction) -> String:
	match direction:
		MapTypes.Direction.NORTH: return "↑"
		MapTypes.Direction.EAST: return "→"
		MapTypes.Direction.SOUTH: return "↓"
		MapTypes.Direction.WEST: return "←"
		MapTypes.Direction.NORTHEAST: return "↗"
		MapTypes.Direction.SOUTHEAST: return "↘"
		MapTypes.Direction.SOUTHWEST: return "↙"
		MapTypes.Direction.NORTHWEST: return "↖"
		_: return "?"

func get_mirror_symbol(direction: MapTypes.Direction) -> String:
	match direction:
		MapTypes.Direction.NORTH, MapTypes.Direction.SOUTH: return "|"
		MapTypes.Direction.EAST, MapTypes.Direction.WEST: return "—"
		MapTypes.Direction.NORTHEAST, MapTypes.Direction.SOUTHWEST: return "\\"
		MapTypes.Direction.NORTHWEST, MapTypes.Direction.SOUTHEAST: return "/"
		_: return "M"

func update_entire_grid(game_map: GameMap):
	for y in range(game_map.height):
		for x in range(game_map.width):
			var grid_pos = Vector2i(x, y)
			var cell = game_map.get_cell(grid_pos)
			if cell:
				update_cell_visual(grid_pos, cell)

func clear_visual_grid():
	for child in get_children():
		child.queue_free()
	cell_nodes.clear()

func is_valid_grid_position(grid_pos: Vector2i) -> bool:
	return (grid_pos.y >= 0 and grid_pos.y < cell_nodes.size() and 
			grid_pos.x >= 0 and grid_pos.x < cell_nodes[grid_pos.y].size())

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * cell_size, grid_pos.y * cell_size) + grid_offset

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var adjusted_pos = world_pos - grid_offset
	return Vector2i(int(adjusted_pos.x / cell_size), int(adjusted_pos.y / cell_size))
