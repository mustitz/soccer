extends Control
class_name Protocol

var board: Board

@onready var undo_btn: Button = $MarginContainer/VBoxContainer/Tail/UndoBtn

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

	if not update_board():
		return

	undo_btn.disabled = is_undo_disabled()

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
