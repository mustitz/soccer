class_name DesktopMain
extends Control

@export var cell_size_in_mm : int = 5

func _ready():
	add_to_group("desktop_main")

	var board = $HSplitContainer/ScrollContainer/CenterContainer/Board
	var mm_to_pixels = Platform.get_dpi() / 25.4
	var cell_size = int(cell_size_in_mm * mm_to_pixels)

	board.cell_width = cell_size
	board.cell_height = cell_size
	board.update_size()

	set_scene("res://desktop/main_menu.tscn")

static func new_game(first_player: GameTypes.Agent, second_player: GameTypes.Agent):
	var desktop_main = Engine.get_main_loop().get_first_node_in_group("desktop_main")
	var board = desktop_main.get_node("HSplitContainer/ScrollContainer/CenterContainer/Board")

	board.player1 = first_player
	board.player2 = second_player
	board.new_game()

	set_scene("res://desktop/main_menu.tscn")

static func set_scene(scene_path: String):
	var desktop_main = Engine.get_main_loop().get_first_node_in_group("desktop_main")
	var panel = desktop_main.get_node("HSplitContainer/Right")
	for child in panel.get_children():
		child.queue_free()

	var scene = load(scene_path)
	var instance = scene.instantiate()
	panel.call_deferred("add_child", instance)
