extends Node2D

# Level1 - Versión simplificada que FUNCIONA
var cell_size = 64
var board_start = Vector2(100, 100)
var grid_width = 8
var grid_height = 6

# Tablero simple usando arrays
var board_data = []
var cell_nodes = []

# Tipos de entidades (simplificado)
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
	print("🚀 Iniciando Level1...")
	
	# Inicializar datos del tablero
	initialize_board()
	
	# Crear tablero visual
	create_visual_board()
	
	# Crear nivel de prueba
	setup_test_level()
	
	# Crear instrucciones
	create_instructions()
	
	print("✅ ¡Tablero creado exitosamente!")
	print("🖱️ Usa click izquierdo para colocar espejos")
	print("🖱️ Usa click derecho para rotar espejos")

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

func create_visual_board():
	# Crear contenedor del tablero
	var board_container = Control.new()
	board_container.name = "BoardContainer"
	add_child(board_container)
	
	# Crear grid
	var grid = GridContainer.new()
	grid.name = "GameGrid"
	grid.columns = grid_width
	grid.position = board_start
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	board_container.add_child(grid)
	
	# Crear celdas visuales
	cell_nodes.clear()
	for y in range(grid_height):
		var row = []
		for x in range(grid_width):
			var cell_rect = ColorRect.new()
			cell_rect.name = "Cell_%d_%d" % [x, y]
			cell_rect.custom_minimum_size = Vector2(cell_size, cell_size)
			cell_rect.color = Color.WHITE
			
			# Agregar label para símbolos
			var label = Label.new()
			label.name = "Label"
			label.size = Vector2(cell_size, cell_size)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 32)
			cell_rect.add_child(label)
			
			grid.add_child(cell_rect)
			row.append(cell_rect)
		cell_nodes.append(row)

func setup_test_level():
	# Crear bordes
	for x in range(grid_width):
		set_cell(x, 0, EntityType.WALL)
		set_cell(x, grid_height - 1, EntityType.WALL)
	
	for y in range(grid_height):
		set_cell(0, y, EntityType.WALL)
		set_cell(grid_width - 1, y, EntityType.WALL)
	
	# Colocar láser
	set_cell(1, 1, EntityType.LASER, Direction.EAST)
	
	# Colocar objetivo
	set_cell(6, 1, EntityType.TARGET)
	
	# Colocar un espejo de ejemplo
	set_cell(4, 1, EntityType.MIRROR, Direction.NORTH)
	
	# Obstáculos
	set_cell(3, 2, EntityType.WALL)
	set_cell(3, 3, EntityType.WALL)
	
	update_visuals()
	simulate_lasers()

func set_cell(x: int, y: int, type: EntityType, direction: Direction = Direction.NORTH):
	if is_valid_position(x, y):
		board_data[y][x]["type"] = type
		board_data[y][x]["direction"] = direction

func get_cell_data(x: int, y: int):
	if is_valid_position(x, y):
		return board_data[y][x]
	return null

func is_valid_position(x: int, y: int) -> bool:
	return x >= 0 and x < grid_width and y >= 0 and y < grid_height

func update_visuals():
	for y in range(grid_height):
		for x in range(grid_width):
			var cell_data = board_data[y][x]
			var cell_node = cell_nodes[y][x]
			var label = cell_node.get_node("Label")
			
			# Actualizar color y símbolo
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
			
			# Overlay de iluminación
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
	# Limpiar iluminación
	for y in range(grid_height):
		for x in range(grid_width):
			board_data[y][x]["illuminated"] = false
	
	# Encontrar láseres
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
		
		# Mover en la dirección actual
		match current_dir:
			Direction.NORTH: current_y -= 1
			Direction.EAST: current_x += 1
			Direction.SOUTH: current_y += 1
			Direction.WEST: current_x -= 1
		
		# Verificar límites
		if not is_valid_position(current_x, current_y):
			break
		
		var cell_data = board_data[current_y][current_x]
		
		# Procesar celda
		match cell_data["type"]:
			EntityType.EMPTY, EntityType.TARGET:
				cell_data["illuminated"] = true
			EntityType.WALL:
				break  # El láser se detiene
			EntityType.MIRROR:
				cell_data["illuminated"] = true
				# Reflejar el láser (simplificado)
				current_dir = reflect_laser(current_dir, cell_data["direction"])
			EntityType.LASER:
				cell_data["illuminated"] = true
				break

func reflect_laser(laser_dir: Direction, mirror_dir: Direction) -> Direction:
	# Reflexión simplificada
	match mirror_dir:
		Direction.NORTH, Direction.SOUTH:  # Espejo vertical |
			match laser_dir:
				Direction.EAST: return Direction.WEST
				Direction.WEST: return Direction.EAST
				_: return laser_dir
		Direction.EAST, Direction.WEST:   # Espejo horizontal —
			match laser_dir:
				Direction.NORTH: return Direction.SOUTH
				Direction.SOUTH: return Direction.NORTH
				_: return laser_dir
	return laser_dir

func create_instructions():
	var instructions_panel = Control.new()
	instructions_panel.name = "InstructionsPanel"
	instructions_panel.position = Vector2(20, 20)
	instructions_panel.size = Vector2(300, 300)
	add_child(instructions_panel)
	
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.8)
	background.size = instructions_panel.size
	instructions_panel.add_child(background)
	
	var instructions_text = [
		"🎮 MIRROR LASERS",
		"",
		"🖱️ Click Izquierdo: Colocar espejo",
		"🖱️ Click Derecho: Rotar espejo",
		"🖱️ Click Medio: Remover espejo",
		"",
		"🎯 OBJETIVO:",
		"Redirige el láser → para",
		"iluminar el objetivo ◉",
		"",
		"⚡ El objetivo se pondrá",
		"verde ✓ cuando esté iluminado"
	]
	
	var y_pos = 10
	for text in instructions_text:
		var label = Label.new()
		label.text = text
		label.position = Vector2(10, y_pos)
		label.size = Vector2(280, 20)
		
		if text.begins_with("🎮"):
			label.add_theme_color_override("font_color", Color.YELLOW)
			label.add_theme_font_size_override("font_size", 16)
		elif text.begins_with("🎯") or text.begins_with("🖱️"):
			label.add_theme_color_override("font_color", Color.CYAN)
			label.add_theme_font_size_override("font_size", 12)
		else:
			label.add_theme_color_override("font_color", Color.WHITE)
			label.add_theme_font_size_override("font_size", 11)
		
		instructions_panel.add_child(label)
		y_pos += 22

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var adjusted_pos = world_pos - board_start
	return Vector2i(int(adjusted_pos.x / (cell_size + 2)), int(adjusted_pos.y / (cell_size + 2)))

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var grid_pos = world_to_grid(event.position)
		var x = grid_pos.x
		var y = grid_pos.y
		
		if is_valid_position(x, y):
			var cell_data = board_data[y][x]
			
			if event.button_index == MOUSE_BUTTON_LEFT:
				# Colocar espejo si la celda está vacía
				if cell_data["type"] == EntityType.EMPTY:
					set_cell(x, y, EntityType.MIRROR, Direction.NORTH)
					update_visuals()
					simulate_lasers()
					update_visuals()
					print("Espejo colocado en (", x, ", ", y, ")")
			
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				# Rotar espejo
				if cell_data["type"] == EntityType.MIRROR:
					var new_dir = (cell_data["direction"] + 1) % 4
					set_cell(x, y, EntityType.MIRROR, new_dir)
					update_visuals()
					simulate_lasers()
					update_visuals()
					print("Espejo rotado en (", x, ", ", y, ")")
			
			elif event.button_index == MOUSE_BUTTON_MIDDLE:
				# Remover entidad
				if cell_data["type"] == EntityType.MIRROR:
					set_cell(x, y, EntityType.EMPTY)
					update_visuals()
					simulate_lasers()
					update_visuals()
					print("Espejo removido de (", x, ", ", y, ")")

func _unhandled_key_input(event):
	if event.pressed:
		match event.keycode:
			KEY_R:
				setup_test_level()
				print("Nivel reseteado")
			KEY_P:
				print_board_state()

func print_board_state():
	print("Estado del tablero:")
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
