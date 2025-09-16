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

enum View { NORMAL, FLIPPED }
@export var view: View = View.FLIPPED

const DELTA_DIR: Array[Vector2i] = [
	Vector2i(-1, +1),  # DIRECTION_SW = 0
	Vector2i( 0, +1),  # DIRECTION_S  = 1
	Vector2i(+1, +1),  # DIRECTION_SE = 2
	Vector2i(+1,  0),  # DIRECTION_E  = 3
	Vector2i(+1, -1),  # DIRECTION_NE = 4
	Vector2i( 0, -1),  # DIRECTION_N  = 5
	Vector2i(-1, -1),  # DIRECTION_NW = 6
	Vector2i(-1,  0),  # DIRECTION_W  = 7
]

var history: Array[GameStep] = []
var engine: EngineExtension
var free_kick_hints: Array = [null, null, null, null, null, null, null, null]
var goal1: Sprite2D
var goal2: Sprite2D

enum Agent { NONE, USER, AI }
var player1: Agent = Agent.USER
var player2: Agent = Agent.AI

func get_current_agent() -> Agent:
	var state = engine.get_game_state()
	if state.status != engine.GAME_IN_PROGRESS:
		return Agent.NONE

	match state.active_player:
		1:
			return player1
		2:
			return player2
		_:
			return Agent.NONE

func flip_y(y: int) -> int:
	if view == View.FLIPPED:
		return board_height - y
	return y

func get_delta(direction: int) -> Vector2i:
	if direction < 0 or direction >= 8:
		return Vector2i(0, 0)
	return DELTA_DIR[direction]

func _init():
	engine = EngineExtension.new()

func _ready():
	var result = engine.new_game(board_width + 1, board_height + 1, goal_width, free_kick_len)
	if result != OK:
		print("QAZQAZ Error: ", result)
	else:
		print("QAZQAZ OK!")

	var state = engine.get_game_state()
	dump_state(state)

	goal1 = create_goal_sprite(goal_width, false)
	goal2 = create_goal_sprite(goal_width, true)
	add_child(goal1)
	add_child(goal2)

	update_size()

	engine.thinking_done.connect(_on_thinking_done)

	if state.move_state != engine.MOVE_STATE_INACTIVE:
		var agent = get_current_agent()
		if agent == Agent.AI:
			engine.start_thinking()

func dump_state(state):
	print("Status: ", state.status)
	print("Result: ", state.result)
	print("Active player: ", state.active_player)
	print("Ball: ", state.ball)
	print("Move state: ", state.move_state)
	print("Possible steps: ", state.possible_steps)

func update_size():
	var total_width = 2 * margin_width + (board_width + 2) * cell_width
	var total_height = 2 * margin_height + (board_height + 2) * cell_height
	custom_minimum_size = Vector2(total_width, total_height)
	size = Vector2(total_width, total_height)

	const kball = 1 / 64.0
	$Ball.scale = kball * Vector2(cell_width, cell_height)

	var x0 = margin_width + cell_width
	var y0 = margin_height + cell_height
	const kgoal = 1 / 128.0

	if goal1 != null:
		goal1.scale = kgoal * Vector2(cell_width, cell_height)
		goal1.position = Vector2(
			x0 + 0.5 * (board_width - goal_width) * cell_width,
			y0 - cell_height
		)

	if goal2 != null:
		goal2.scale = kgoal * Vector2(cell_width, cell_height)
		goal2.position = Vector2(
			x0 + 0.5 * (board_width - goal_width) * cell_width,
			y0 + board_height * cell_height
		)

	queue_redraw()

func add_step(dir: Direction, length: int, player: Player):
	var step = GameStep.new(dir, length, player)
	history.append(step)

func _draw():
	draw_rect(Rect2(Vector2.ZERO, size), bg_color)
	draw_grid()
	draw_markup()
	draw_history()
	draw_free_kick_hints()
	update_ball_position()

func draw_grid():
	var color = grid_color
	var x0 = margin_width + cell_width
	var y0 = margin_height + cell_height
	var start_x = x0
	var start_y = y0

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
	var x0 = margin_width + cell_width
	var y0 = margin_height + cell_height
	var cx = x0 + 0.5 * board_width * cell_width
	var cy = y0 + 0.5 * board_height * cell_height
	var right_x = x0 + board_width * cell_width
	var bottom_y = y0 + board_height * cell_height

	draw_circle(Vector2(cx, cy), 2 * border_thick, grid_color)
	draw_line(Vector2(x0, cy), Vector2(right_x, cy), grid_color, border_thick)

	var gw = goal_width * cell_width
	var gx1 = cx - 0.5 * gw

	var top_goalkeeper_rect = Rect2(gx1, y0, gw, cell_height)
	draw_rect(top_goalkeeper_rect, grid_color, false, border_thick)

	var bottom_goalkeeper_rect = Rect2(gx1, bottom_y, gw, -cell_height)
	draw_rect(bottom_goalkeeper_rect, grid_color, false, border_thick)

	var halfy = 0.5 * board_height
	if free_kick_len >= halfy:
		return

	var px1 = max(x0, gx1 - (free_kick_len - 1) * cell_width)
	var pw = cell_width * (2 * free_kick_len + goal_width - 2)
	var ph = free_kick_len * cell_height
	draw_rect(Rect2(px1, y0, pw, ph), grid_color, false, border_thick)
	draw_rect(Rect2(px1, bottom_y, pw, -ph), grid_color, false, border_thick)

func draw_history():
	var x0 = margin_width + cell_width
	var y0 = margin_height + cell_height
	var center_x = x0 + 0.5 * board_width * cell_width
	var center_y = y0 + 0.5 * board_height * cell_height
	var current_pos = Vector2(center_x, center_y)

	for step in history:
		var end_pos = get_step_end(current_pos, step)
		var color = Color.RED if step.player == Player.RED else Color.BLUE
		draw_line(current_pos, end_pos, color, step_thick)
		current_pos = end_pos

func clear_free_kick_hints():
	for i in range(8):
		if free_kick_hints[i] != null:
			free_kick_hints[i].queue_free()
			free_kick_hints[i] = null

func draw_free_kick_hints():
	var state = engine.get_game_state()
	if state.status != engine.GAME_IN_PROGRESS or get_current_agent() != Agent.USER or state.move_state != engine.MOVE_STATE_FREE_KICK:
		clear_free_kick_hints()
		return

	var ball_pos = state.ball
	var x0 = margin_width + cell_width
	var y0 = margin_height + cell_height

	for direction in range(8):
		if direction not in state.possible_steps:
			if free_kick_hints[direction] != null:
				free_kick_hints[direction].queue_free()
				free_kick_hints[direction] = null
			continue

		var delta = free_kick_len * get_delta(direction)

		var dest_x = ball_pos.x + delta.x
		var dest_y = ball_pos.y + delta.y

		var y1 = -0.5
		var y2 = board_height + 0.5

		if dest_y < y1 or dest_y > y2:
			var k: float
			if dest_y < y1:
				k = (y1 - ball_pos.y) / (dest_y - ball_pos.y)
			else:
				k = (y2 - ball_pos.y) / (dest_y - ball_pos.y)
			dest_x = ball_pos.x + k * delta.x
			dest_y = ball_pos.y + k * delta.y

		var screen_x = x0 + (dest_x - 1.6) * cell_width
		var flipped_y = dest_y
		if view == View.FLIPPED:
			flipped_y = board_height - dest_y
		var screen_y = y0 + (flipped_y - 1.6) * cell_height

		if free_kick_hints[direction] == null:
			var hint_ball = $Ball.duplicate()
			hint_ball.modulate = Color(1.0, 1.0, 1.0, 0.5)
			hint_ball.frame_coords = Vector2i(randi() % 8, randi() % 8)
			add_child(hint_ball)
			free_kick_hints[direction] = hint_ball

		free_kick_hints[direction].position = Vector2(screen_x, screen_y)

func _gui_input(event):
	if event is InputEventMouseButton:
		if not event.pressed:
			return
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		return try_step(event.position)

func try_goal(p) -> bool:
	var x0 = margin_width + cell_width
	var y0 = margin_height + cell_height

	if y0 <= p.y and p.y <= y0 + board_height * cell_height:
		return false

	var x1 = x0 + 0.5 * (board_width - goal_width) * cell_width
	var x2 = x0 + 0.5 * (board_width + goal_width) * cell_width

	if p.x < x1 or p.x > x2:
		return false

	if p.y < y0 - 1.5 * cell_height:
		return false

	if p.y > y0 + (board_height + 1.5) * cell_height:
		return false

	var state = engine.get_game_state()
	var min_dist = INF
	var best = -1

	for direction in state.possible_steps:
		var length = 1
		if state.move_state == engine.MOVE_STATE_FREE_KICK:
			length = free_kick_len

		var delta = length * get_delta(direction)
		var dest_x = state.ball.x + delta.x
		var dest_y = state.ball.y + delta.y

		var k: float
		if dest_y < 0:
			k = (-0.5 - state.ball.y) / delta.y
		elif dest_y > board_height:
			k = (board_height + 0.5 - state.ball.y) / delta.y
		else:
			continue

		dest_x = state.ball.x + k * delta.x
		dest_y = state.ball.y + k * delta.y

		var flipped_y = dest_y
		if view == View.FLIPPED:
			flipped_y = board_height - dest_y

		var screen_pos = Vector2(
			x0 + dest_x * cell_width,
			y0 + flipped_y * cell_height
		)

		if abs(screen_pos.y - p.y) > 2 * cell_height:
			continue

		var dist = p.distance_to(screen_pos)
		if dist < min_dist:
			min_dist = dist
			best = direction

	if best == -1:
		return false

	do_move(best)
	return true

func find_nearest_option(p: Vector2, options: Array):
	var min_dist = INF
	var closest = null
	for option in options:
		var dist = p.distance_to(option["pos"])
		if dist < min_dist:
			min_dist = dist
			closest = option
	return closest

func try_step(p):
	var agent = get_current_agent()
	if agent == Agent.NONE:
		print("Ignore click, game over")
		return

	if agent == Agent.AI:
		print("Ignore click, AI is thinking")
		return

	var state = engine.get_game_state()
	var x0 = margin_width + cell_width
	var y0 = margin_height + cell_height

	if try_goal(p):
		return

	var sx = (p.x - x0) / cell_width
	var sy = (p.y - y0) / cell_height

	var frac_sx = sx - floor(sx)
	var frac_sy = sy - floor(sy)

	var bad_sx: bool = frac_sx > 0.33 and frac_sx < 0.66
	var bad_sy: bool= frac_sy > 0.33 and frac_sy < 0.66
	if bad_sx or bad_sy:
		print("Ignore fuzzy click: frac_sx=", frac_sx, "; frac_sy=", frac_sy, ";")
		return

	var x: int = int(round(sx))
	var y: int = int(round(sy))

	if x < 0 or x > board_width or y < 0 or y > board_height:
		print("Ignore click outsied board: x=", x, "; y=", y, ";")
		return

	if state.move_state == engine.MOVE_STATE_INACTIVE:
		print("Ignore click in inactive move state")
		return

	var ball_pos = state.ball

	var dx: int = x - ball_pos.x
	var dy: int = flip_y(y) - ball_pos.y
	if dx == 0 and dy == 0:
		print("Ignore click on ball")
		return

	var delta: int = 1
	if state.move_state == engine.MOVE_STATE_FREE_KICK:
		delta = free_kick_len

	var bad_dx = dx != 0 and abs(dx) != delta
	var bad_dy = dy != 0 and abs(dy) != delta
	if bad_dx or bad_dy:
		print("Ignore bad delta click: dx=", dx, "; dy=", dy, ";")
		return

	var direction: int = calc_direction(dx, dy)
	if direction == engine.DIRECTION_NONE:
		print("QAZQAZ: unexpected bad direction from calc_direction: dx=", dx, "; dy=", dy, ";")
		return

	if not direction in state.possible_steps:
		print("Ignore forbidden move click")
		return

	do_move(direction)

func calc_direction(dx: int, dy: int) -> int:
	if dx < 0 and dy < 0: return engine.DIRECTION_NW
	if dx == 0 and dy < 0: return engine.DIRECTION_N
	if dx > 0 and dy < 0: return engine.DIRECTION_NE
	if dx > 0 and dy == 0: return engine.DIRECTION_E
	if dx > 0 and dy > 0: return engine.DIRECTION_SE
	if dx == 0 and dy > 0: return engine.DIRECTION_S
	if dx < 0 and dy > 0: return engine.DIRECTION_SW
	if dx < 0 and dy == 0: return engine.DIRECTION_W
	return engine.DIRECTION_NONE

func get_step_end(start: Vector2, step: GameStep) -> Vector2:
	var delta = get_delta(step.direction)
	if view == View.FLIPPED:
		delta.y = -delta.y

	var length = step.length
	var result = start + Vector2(delta) * length * cell_width

	var y0 = margin_height + cell_height
	var y1 = y0 - 0.5 * cell_height
	var y2 = y0 + (board_height + 0.5) * cell_height

	if result.y >= y1 and result.y <= y2:
		return result

	var k: float
	if result.y < y1:
		k = (y1 - start.y) / (result.y - start.y)
	else:
		k = (y2 - start.y) / (result.y - start.y)

	return start + k * Vector2(delta) * length * cell_width

func update_ball_position():
	var state = engine.get_game_state()
	if state.status != engine.GAME_IN_PROGRESS:
		return

	put_ball(state.ball.x, state.ball.y)

func _on_ball_animation_timeout() -> void:
	$Ball.frame_coords.x = ($Ball.frame_coords.x + 1) % 8

func put_ball(x: float, y: float):
	if view == View.FLIPPED:
		y = board_height - y

	var x0 = margin_width + cell_width
	var y0 = margin_height + cell_height

	$Ball.position = Vector2(
		x0 + (x - 1.6) * cell_width,
		y0 + (y - 1.6) * cell_height
	)

func put_ball_into_net(pre_state, direction: int, length: int):
	var ball_pos = pre_state.ball
	var delta = get_delta(direction)

	for i in range(length):
		var next_x = ball_pos.x + delta.x
		var next_y = ball_pos.y + delta.y
		if next_y < 0 or next_y > board_height:
			break
		ball_pos = Vector2i(next_x, next_y)

	put_ball(ball_pos.x + 0.5 * delta.x, ball_pos.y + 0.5 * delta.y)

func do_move(direction: int):
	var pre_state = engine.get_game_state()
	var length = 1
	if pre_state.move_state == engine.MOVE_STATE_FREE_KICK:
		length = free_kick_len
	var player = Player.RED if pre_state.active_player == 1 else Player.BLUE

	var status = engine.step(direction)
	if status != OK:
		print("Invalid move!")
		return

	add_step(direction, length, player)

	var state = engine.get_game_state()
	if state.status == engine.GAME_IN_PROGRESS:
		update_ball_position()
	else:
		put_ball_into_net(pre_state, direction, length)
	queue_redraw()

	if state.move_state != engine.MOVE_STATE_INACTIVE:
		var agent = get_current_agent()
		if agent == Agent.AI:
			engine.start_thinking()

func _on_thinking_done(direction: int):
	do_move(direction)

func create_goal_sprite(width: int, flipped: bool) -> Sprite2D:
	var path = "res://assets/goal/goal_%02d.png" % width
	var texture = load(path)
	if texture == null:
		print("Error: Could not load goal texture: ", path)
		return null

	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	sprite.centered = false
	if flipped:
		sprite.flip_v = true
	return sprite
