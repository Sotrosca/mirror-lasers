extends Node2D

@onready var layer0 = $Layer0
@onready var layer1 = $Layer1

@export var GridSize: int = 4
var Dic = {}

func _ready() -> void:
	for x in GridSize:
		for y in GridSize:
			var cell_pos = Vector2i(x, y)
			Dic[str(cell_pos)] = {
				"Type" : "Grass"
			}
			layer0.set_cell(cell_pos, 1, Vector2i(0, 0), 0)
	print("Grid initialized: ", Dic)

func _process(_delta):
	var tile_pos = layer1.local_to_map(get_global_mouse_position())

	# Clear the selection layer
	layer1.clear()

	# Draw selection tile if mouse is over the grid
	if Dic.has(str(tile_pos)):
		layer1.set_cell(tile_pos, 2, Vector2i(0, 0), 0)
