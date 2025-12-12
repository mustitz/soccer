extends Control
class_name Protocol

var board: Board

@onready var undo_btn: Button = $MarginContainer/VBoxContainer/Tail/UndoBtn
@onready var first_btn: Button = $MarginContainer/VBoxContainer/Navigator/FirstBtn
@onready var prev_move_btn: Button = $MarginContainer/VBoxContainer/Navigator/PrevMoveBtn
@onready var prev_step_btn: Button = $MarginContainer/VBoxContainer/Navigator/PrevStepBtn
@onready var next_step_btn: Button = $MarginContainer/VBoxContainer/Navigator/NextStepBtn
@onready var next_move_btn: Button = $MarginContainer/VBoxContainer/Navigator/NextMoveBtn
@onready var last_btn: Button = $MarginContainer/VBoxContainer/Navigator/LastBtn
@onready var move_grid: MoveGrid = $MarginContainer/VBoxContainer/Panel2/ScrollContainer/MoveGrid

func _ready():
	add_to_group("protocol")
	update()

static func get_protocol() -> Protocol:
	return GameTypes.get_singleton_from_group("protocol") as Protocol

func update_board() -> bool:
	if not is_instance_valid(board) or not board.is_inside_tree():
		board = Board.get_board()
	return board != null

func update():
	undo_btn.disabled = false
	first_btn.disabled = false
	last_btn.disabled = false
	prev_move_btn.disabled = false
	prev_step_btn.disabled = false
	next_step_btn.disabled = false
	next_move_btn.disabled = false

	if not update_board():
		return

	undo_btn.disabled = is_undo_disabled()
	first_btn.disabled = board.ihistory == 0
	last_btn.disabled = board.ihistory == -1
	prev_move_btn.disabled = board.ihistory == 0
	prev_step_btn.disabled = board.ihistory == 0
	next_step_btn.disabled = board.ihistory == -1
	next_move_btn.disabled = board.ihistory == -1

	move_grid.update()

func set_ihistory(new_ihistory: int) -> void:
	board.ihistory = new_ihistory
	board.queue_redraw()
	update()

func is_undo_disabled() -> bool:
	var agent = board.get_current_agent()
	if agent != GameTypes.Agent.USER:
		return true

	var qsteps = board.history.size()
	if qsteps == 0:
		return true

	var state = board.engine.get_game_state()
	var player = GameTypes.Player.RED if state.active_player == 1 else GameTypes.Player.BLUE

	var last_step = board.history[qsteps - 1]
	return last_step.player != player

func _on_undo_btn_pressed() -> void:
	if not update_board():
		return
	board._cancel_move()

func _on_first_btn_pressed() -> void:
	if not update_board():
		return

	set_ihistory(0)

func _on_last_btn_pressed() -> void:
	if not update_board():
		return

	set_ihistory(-1)

func _on_prev_move_btn_pressed() -> void:
	if not update_board():
		return

	if board.ihistory == 0:
		push_error("Cannot go to previous move: already at first position")
		return

	var current_idx: int = board.ihistory - 1 if board.ihistory != -1 else board.history.size() - 1
	if current_idx < 0:
		push_error("Cannot go to previous move: history is empty")
		return

	var current_player: GameTypes.Player = board.history[current_idx].player

	while current_idx > 0 and board.history[current_idx - 1].player == current_player:
		current_idx -= 1

	set_ihistory(current_idx)

func _on_prev_step_btn_pressed() -> void:
	if not update_board():
		return

	if board.ihistory == 0:
		push_error("Cannot go to previous step: already at first position")
		return

	if board.ihistory == -1:
		set_ihistory(board.history.size() - 1)
	else:
		set_ihistory(board.ihistory - 1)

func _on_next_step_btn_pressed() -> void:
	if not update_board():
		return

	if board.ihistory == -1:
		push_error("Cannot go to next step: already at current position")
		return

	var new_ihistory: int = board.ihistory + 1
	if new_ihistory >= board.history.size():
		new_ihistory = -1

	set_ihistory(new_ihistory)

func _on_next_move_btn_pressed() -> void:
	if not update_board():
		return

	if board.ihistory == -1:
		push_error("Cannot go to next move: already at current position")
		return

	var current_idx: int = board.ihistory
	var current_player: GameTypes.Player = board.history[current_idx].player

	while current_idx < board.history.size() - 1 and board.history[current_idx + 1].player == current_player:
		current_idx += 1

	current_idx += 1
	if current_idx >= board.history.size():
		current_idx = -1

	set_ihistory(current_idx)

func _on_debug_btn_pressed() -> void:
	if not update_board():
		return

	board.ihistory = 0 if board.ihistory != 0 else -1
	board.queue_redraw()
