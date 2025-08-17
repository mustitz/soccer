extends Control
class_name Board

const Direction = GameTypes.Direction
const Player = GameTypes.Player
const GameStep = GameTypes.GameStep

@export var board_width: int = 20
@export var board_height: int = 30
@export var goal_width: int = 6
@export var free_kick_len: int = 5

@export var cell_width: int = 32
@export var cell_height: int = 32
@export var margin_width: int = 16
@export var margin_height: int = 16

@export var border_thick: int = 3
@export var grid_thick: int = 1
@export var step_thick: int = 5

@export var bg_color: Color = Color.GRAY
@export var grid_color: Color = Color.BLACK

var history: Array[GameStep] = []
var engine: EngineExtension

func _init():
	engine = EngineExtension.new()

func _ready():
	var result = engine.new_game(board_width + 1, board_height + 1, goal_width, free_kick_len)
	if result != OK:
		print("QAZQAZ Error: ", result)
	else:
		print("QAZQAZ OK!")

	var state = engine.get_game_state()
	print("Status: ", state.status)
	print("Result: ", state.result)
	print("Active player: ", state.active_player)
	print("Ball: ", state.ball)
	print("Move state: ", state.move_state)
	print("Possible steps: ", state.possible_steps)

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
	draw_markup()
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

func draw_markup():
	var cx = margin_width + 0.5 * board_width * cell_width
	var cy = margin_height + 0.5 * board_height * cell_height
	var right_x = margin_width + board_width * cell_width
	var bottom_y = margin_height + board_height * cell_height

	draw_circle(Vector2(cx, cy), 2 * border_thick, grid_color)
	draw_line(Vector2(margin_width, cy), Vector2(right_x, cy), grid_color, border_thick)
	print(margin_width, ", ", cy, " - ", right_x, ", ", cy)

	var gw = goal_width * cell_width
	var gx1 = cx - 0.5 * gw

	var top_goalkeeper_rect = Rect2(gx1, margin_height, gw, cell_height)
	draw_rect(top_goalkeeper_rect, grid_color, false, border_thick)

	var bottom_goalkeeper_rect = Rect2(gx1, bottom_y, gw, -cell_height)
	draw_rect(bottom_goalkeeper_rect, grid_color, false, border_thick)

	var halfy = 0.5 * board_height
	if free_kick_len >= halfy:
		return

	var px1 = max(margin_width, gx1 - (free_kick_len - 1) * cell_width)
	var pw = cell_width * (2 * free_kick_len + goal_width - 2)
	var ph = free_kick_len * cell_height
	draw_rect(Rect2(px1, margin_height, pw, ph), grid_color, false, border_thick)
	draw_rect(Rect2(px1, bottom_y, pw, -ph), grid_color, false, border_thick)

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
