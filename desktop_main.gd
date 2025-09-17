extends Control

@export var cell_size_in_mm : int = 5

func _ready():
	var board = $HSplitContainer/ScrollContainer/CenterContainer/Board
	var mm_to_pixels = Platform.get_dpi() / 25.4
	var cell_size = int(cell_size_in_mm * mm_to_pixels)

	board.cell_width = cell_size
	board.cell_height = cell_size
	board.update_size()
