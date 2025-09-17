extends Control

@export var board: Board
@export var scroll: ScrollContainer
@export var cell_size_in_mm : int = 5

func _ready():
	var mm_to_pixels = Platform.get_dpi() / 25.4
	var cell_size = int(cell_size_in_mm * mm_to_pixels)

	var panel = $VBoxContainer/Panel
	panel.custom_minimum_size.y = 10 * mm_to_pixels

	board.cell_width = cell_size
	board.cell_height = cell_size
	board.update_size()

func _input(event):
	if event is InputEventScreenDrag:
		scroll.scroll_horizontal -= event.relative.x
		scroll.scroll_vertical -= event.relative.y
		return
