extends Control
class_name Board

const Direction = GameTypes.Direction
const Player = GameTypes.Player
const GameStep = GameTypes.GameStep

@export var board_width: int = 20
@export var board_height: int = 30
@export var cell_width: int = 32
@export var cell_height: int = 32
@export var margin_width: int = 16
@export var margin_height: int = 16

@export var border_thick: int = 2
@export var grid_thick: int = 1
@export var step_thick: int = 5

@export var bg_color: Color = Color.GRAY
@export var grid_color: Color = Color.BLACK

var history: Array[GameStep] = []

func _ready():
	update_size()

func update_size():
	var total_width = 2 * margin_width + board_width * cell_width
	var total_height = 2 * margin_height + board_height * cell_height
	custom_minimum_size = Vector2(total_width, total_height)
	size = Vector2(total_width, total_height)
	queue_redraw()

func add_step(dir: Direction, length: int, player: Player):
	var step = GameStep.new(dir, length, player)
	history.append(step)

func _draw():
	draw_rect(Rect2(Vector2.ZERO, size), bg_color)
	draw_grid()
	draw_history()

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

func draw_history():
	var center_x = margin_width + 0.5 * board_width * cell_width
	var center_y = margin_height + 0.5 * board_height * cell_height
	var current_pos = Vector2(center_x, center_y)

	for step in history:
		var end_pos = get_step_end(current_pos, step)
		var color = Color.RED if step.player == Player.RED else Color.BLUE
		draw_line(current_pos, end_pos, color, step_thick)
		current_pos = end_pos

func get_step_end(start: Vector2, step: GameStep) -> Vector2:
	var direction_vectors = {
		Direction.N:  Vector2( 0, -1),
		Direction.NE: Vector2(+1, -1),
		Direction.E:  Vector2(+1,  0),
		Direction.SE: Vector2(+1, +1),
		Direction.S:  Vector2( 0, +1),
		Direction.SW: Vector2(-1, +1),
		Direction.W:  Vector2(-1,  0),
		Direction.NW: Vector2(-1, -1),
	}
	var dir_vec = direction_vectors[step.direction]
	return start + dir_vec * step.length * cell_width
