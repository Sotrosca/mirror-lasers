extends Node2D

# LEVEL 1 USING MODULAR GAMEBOARD TEMPLATE
# All code/comments in ENGLISH.

@onready var board: Control = $GameBoardTemplate

var level_finished: bool = false

func _ready():
	# Connect signals from board
	board.cell_clicked.connect(_on_cell_clicked)
	board.victory_achieved.connect(_on_victory)
	_initialize_level()

func _initialize_level():
	# Create border walls
	for x in range(board.grid_width):
		board.set_cell(x, 0, board.CellType.WALL)
		board.set_cell(x, board.grid_height - 1, board.CellType.WALL)
	for y in range(board.grid_height):
		board.set_cell(0, y, board.CellType.WALL)
		board.set_cell(board.grid_width - 1, y, board.CellType.WALL)
	# Place laser
	board.set_cell(1, 1, board.CellType.LASER, board.Direction.RIGHT)
	# Place target
	board.set_cell(6, 4, board.CellType.TARGET)
	# Place a mirror example
	board.set_cell(3, 3, board.CellType.MIRROR, board.Direction.RIGHT)

func _on_cell_clicked(x: int, y: int, button_index: int):
	if level_finished:
		return
	var type = board.get_cell_type(x, y)
	match button_index:
		MOUSE_BUTTON_LEFT:
			if type == board.CellType.EMPTY:
				board.set_cell(x, y, board.CellType.MIRROR, board.Direction.RIGHT)
		MOUSE_BUTTON_RIGHT:
			if type == board.CellType.MIRROR:
				# Only need two states: 0(or even)= "\\", 1(or odd)= "/". Toggle parity.
				var new_dir = (board.directions[y][x] + 1) % 2
				board.set_cell(x, y, board.CellType.MIRROR, new_dir)
		MOUSE_BUTTON_MIDDLE:
			if type == board.CellType.MIRROR:
				board.set_cell(x, y, board.CellType.EMPTY)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				level_finished = false
				board.reset_board()
				_initialize_level()

func _on_victory():
	level_finished = true
	print("LEVEL COMPLETED!")
