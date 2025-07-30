extends Control

@export var board: Board
@export var scroll: ScrollContainer
@export var cell_size_in_mm : int = 5

func _ready():
	var mm_to_pixels = get_dpi() / 25.4
	var cell_size = int(cell_size_in_mm * mm_to_pixels)

	board.cell_width = cell_size
	board.cell_height = cell_size
	board.update_size()

	board.add_step(GameTypes.Direction.NE, 3, GameTypes.Player.RED)
	board.add_step(GameTypes.Direction.S, 1, GameTypes.Player.BLUE)
	board.add_step(GameTypes.Direction.SW, 2, GameTypes.Player.BLUE)

func _input(event):
	if event is InputEventScreenDrag:
		scroll.scroll_horizontal -= event.relative.x
		scroll.scroll_vertical -= event.relative.y
		return

func get_dpi():
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		return DisplayServer.screen_get_dpi()

	var screen_size = DisplayServer.screen_get_size()
	var diagonal_pixels = sqrt(screen_size.x * screen_size.x + screen_size.y * screen_size.y)
	var assumed_diagonal_inches = 17
	return diagonal_pixels / assumed_diagonal_inches
