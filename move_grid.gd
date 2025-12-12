extends Control
class_name MoveGrid

const ROW_HEIGHT_MULTIPLIER = 1.0
const BOTTOM_MARGIN = 0.25
const TEXT_COLOR = Color.WHITE
const HIGHLIGHT_COLOR = Color.YELLOW

var board: Board
var steps: Array[Dictionary] = []  # {row: int, is_red: bool, name: String, width: float, idx: int, rect: Rect2}

var font: Font
var font_size: int
var em_width: float
var dots_width: float
var row_height: float
var move_max_width: float
var num_width: float

func _ready():
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(480, 2048)
	update_board()
	queue_redraw()

func update_board() -> bool:
	if not is_instance_valid(board) or not board.is_inside_tree():
		board = Board.get_board()
	return board != null

func update():
	update_board()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for step in steps:
			if step.rect != null and step.rect.has_point(event.position):
				set_ihistory(step.idx + 1)
				accept_event()
				return

func set_ihistory(new_ihistory: int) -> void:
	if not update_board():
		return
	board.ihistory = new_ihistory
	board.queue_redraw()
	Protocol.get_protocol().update()

func str_width(text: String) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

func text_out(x: float, y: float, text: String, is_highlight: bool = false):
	var color = HIGHLIGHT_COLOR if is_highlight else TEXT_COLOR
	draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func init_context():
	font = get_theme_font("font", "Label")
	font_size = get_theme_font_size("font_size", "Label")
	row_height = font.get_height(font_size) * ROW_HEIGHT_MULTIPLIER
	em_width = str_width("m")
	dots_width = str_width("...")

	var max_num = str_width("888")
	num_width = 2 * em_width + max_num
	move_max_width = (size.x - num_width) / 2 - 2 * em_width

func move_display_width(lstep: int, rstep: int, qhidden: int) -> float:
	var qsteps = rstep - lstep
	var width = steps[lstep].width + steps[rstep - 1].width + em_width
	for i in range(lstep + 1, rstep - qhidden - 1):
		width += steps[i].width + em_width
	if qhidden > 0:
		width += dots_width + em_width
	return width

func find_hidden(lstep: int, rstep: int) -> int:
	var qsteps = rstep - lstep
	if qsteps <= 2:
		return 0
	for qhidden in range(qsteps - 2):
		var width = move_display_width(lstep, rstep, qhidden)
		if width <= move_max_width:
			return qhidden
	return qsteps - 2

func draw_move(lstep: int, rstep: int, x: float, y: float, row: int, ihistory: int) -> int:
	if lstep >= rstep:
		return -1

	var qhidden: int = find_hidden(lstep, rstep)
	var qsteps: int = rstep - lstep
	var lhidden: int = rstep
	var rhidden: int = rstep

	if qhidden > 0:
		lhidden = lstep + qsteps - qhidden - 1
		rhidden = lstep + qsteps - 2

	var was_current: bool = false
	var is_current: bool = false

	for i in range(lstep, rstep):
		var step: Dictionary = steps[i]

		is_current = is_current or step.idx + 1 == ihistory
		was_current = was_current or is_current

		if i >= lhidden and i < rhidden:
			continue

		var text: String = step.name
		var width: float = step.width

		if i == rhidden:
			text = "..."
			width = dots_width

		var rect: Rect2 = Rect2(x, row * row_height, width, row_height)
		step.rect = rect

		text_out(x, y, text, is_current)
		x += width + em_width
		is_current = false

	return row if was_current else -1

func _draw():
	init_context()

	if not update_board():
		text_out(10, 30, "Board not found")
		return

	var history = board.history
	var history_size: int = history.size()

	if history_size == 0:
		custom_minimum_size.y = row_height
		text_out(10, 30, "No moves yet")
		return

	var qmoves: int = 0
	var prev_player: GameTypes.Player = GameTypes.Player.INACTIVE

	for step in history:
		if step.player != prev_player:
			qmoves += 1
			prev_player = step.player

	var qrows: int = (qmoves + 1) / 2

	var state = board.engine.get_game_state()
	var game_finished: bool = state.status != board.engine.GAME_IN_PROGRESS
	var total_rows: int = qrows + (1 if game_finished else 0)
	custom_minimum_size.y = total_rows * row_height + BOTTOM_MARGIN * row_height

	var cx: float = num_width + (size.x - num_width) / 2
	draw_line(Vector2(num_width, 0), Vector2(num_width, qrows * row_height), Color.WHITE, 1.0)
	draw_line(Vector2(cx, 0), Vector2(cx, qrows * row_height), Color.WHITE, 1.0)

	steps.clear()
	var istep: int = 0
	var imove: int = -1
	prev_player = GameTypes.Player.INACTIVE

	while istep < history_size:
		var step = history[istep]

		if step.player != prev_player:
			imove += 1
			prev_player = step.player

		var name: String = GameTypes.step_name(step.direction)
		steps.append({
			"row": int(imove / 2),
			"is_red": (imove % 2) == 0,
			"name": name,
			"width": str_width(name),
			"idx": istep,
			"rect": null
		})

		istep += 1

	var font_height = font.get_height(font_size)
	for i in range(qrows):
		var text: String = str(i + 1) + "."
		var x: float = num_width - em_width - str_width(text)
		var y: float = i * row_height + (row_height + font_height) / 2
		text_out(x, y, text)

	var ihistory = board.ihistory if board.ihistory != -1 else history_size

	var current_row: int = -1
	var i = 0
	while i < steps.size():
		var step = steps[i]
		var row: int = step.row
		var is_red: bool = step.is_red

		var lstep: int = i
		while i < steps.size() and steps[i].row == row and steps[i].is_red == is_red:
			i += 1
		var rstep: int = i

		var x: float = (num_width if is_red else cx) + em_width
		var y: float = row * row_height + (row_height + font_height) / 2

		var result: int = draw_move(lstep, rstep, x, y, row, ihistory)
		if result >= 0:
			current_row = result

	if current_row >= 0:
		var scroller = get_parent()
		if scroller is ScrollContainer:
			var target_y: float = current_row * row_height
			var visible_height: float = scroller.size.y
			var scroll_y: float = scroller.scroll_vertical

			if target_y < scroll_y or target_y + 2 * row_height > scroll_y + visible_height:
				scroller.set_deferred("scroll_vertical", target_y)

	if game_finished:
		var text: String = "1-0" if state.result > 0 else "0-1"
		var width: float = str_width(text)
		var x: float = (size.x - width) / 2
		var y: float = qrows * row_height + (row_height + font_height) / 2
		text_out(x, y, text)
