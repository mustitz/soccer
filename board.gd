extends Control

@export var board_width: int = 20
@export var board_height: int = 30
@export var cell_width: int = 32
@export var cell_height: int = 32
@export var margin_width: int = 16
@export var margin_height: int = 16
@export var border_thick: int = 2
@export var grid_thick: int = 1
@export var bg_color: Color = Color.GRAY
@export var grid_color: Color = Color.BLACK

func _ready():
	update_size()

func update_size():
	var total_width = 2 * margin_width + board_width * cell_width
	var total_height = 2 * margin_height + board_height * cell_height
	custom_minimum_size = Vector2(total_width, total_height)
	size = Vector2(total_width, total_height)
	queue_redraw()

func _draw():
	draw_rect(Rect2(Vector2.ZERO, size), bg_color)
	draw_grid()

func draw_grid():
	var color = grid_color
	var start_x = margin_width
	var start_y = margin_height

	for x in range(board_width + 1):
		var line_x = start_x + x * cell_width
		var from = Vector2(line_x, start_y)
		var to = Vector2(line_x, start_y + board_height * cell_height)
		var thick = border_thick if (x == 0 or x == board_width) else grid_thick
		draw_line(from, to, color, thick)

	for y in range(board_height + 1):
		var line_y = start_y + y * cell_height
		var from = Vector2(start_x, line_y)
		var to = Vector2(start_x + board_width * cell_width, line_y)
		var thick = border_thick if (y == 0 or y == board_height) else grid_thick
		draw_line(from, to, color, thick)
