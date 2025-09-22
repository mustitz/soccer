extends Control

var player1_index: int = 0
var user1: TextureButton
var engine1: TextureButton
var atlas1: AtlasTexture
var tshirt1: TextureButton

var player2_index: int = 1
var user2: TextureButton
var engine2: TextureButton
var atlas2: AtlasTexture
var tshirt2: TextureButton

var alpha_min: float
var alpha_max: float
var left_first: bool = true
var random_btn: TextureButton

func _ready():
	var grid_texture = preload("res://assets/tshirt_grid.png")

	random_btn = find_child("RandomBtn", true, false)

	atlas1 = AtlasTexture.new()
	atlas1.atlas = grid_texture
	atlas1.region = Rect2(0, 0, 64, 80)

	atlas2 = AtlasTexture.new()
	atlas2.atlas = grid_texture
	atlas2.region = Rect2(64, 80, 64, 80)

	user1 = find_child("User1", true, false)
	engine1 = find_child("Engine1", true, false)
	tshirt1 = find_child("TShirt1", true, false)

	user2 = find_child("User2", true, false)
	engine2 = find_child("Engine2", true, false)
	tshirt2 = find_child("TShirt2", true, false)

	tshirt1.texture_normal = atlas1
	tshirt2.texture_normal = atlas2

	var group1 = ButtonGroup.new()
	var group2 = ButtonGroup.new()

	user1.button_group = group1
	engine1.button_group = group1

	user2.button_group = group2
	engine2.button_group = group2

	alpha_min = min(user1.modulate.a, engine1.modulate.a, user2.modulate.a, engine2.modulate.a)
	alpha_max = max(user1.modulate.a, engine1.modulate.a, user2.modulate.a, engine2.modulate.a)

func _on_user_1_toggled(toggled_on: bool) -> void:
	user1.modulate.a = alpha_max if toggled_on else alpha_min

func _on_engine_1_toggled(toggled_on: bool) -> void:
	engine1.modulate.a = alpha_max if toggled_on else alpha_min

func _on_user_2_toggled(toggled_on: bool) -> void:
	user2.modulate.a = alpha_max if toggled_on else alpha_min

func _on_engine_2_toggled(toggled_on: bool) -> void:
	engine2.modulate.a = alpha_max if toggled_on else alpha_min

func update_t_shirt():
	if random_btn.button_pressed:
		if left_first:
			atlas1.region = Rect2(player1_index * 64, player2_index * 80, 64, 80)
			atlas2.region = Rect2(player2_index * 64, player1_index * 80, 64, 80)
		else:
			atlas1.region = Rect2(player2_index * 64, player1_index * 80, 64, 80)
			atlas2.region = Rect2(player1_index * 64, player2_index * 80, 64, 80)
	else:
		if left_first:
			atlas1.region = Rect2(player1_index * 64, player1_index * 80, 64, 80)
			atlas2.region = Rect2(player2_index * 64, player2_index * 80, 64, 80)
		else:
			atlas1.region = Rect2(player2_index * 64, player2_index * 80, 64, 80)
			atlas2.region = Rect2(player1_index * 64, player1_index * 80, 64, 80)

func _on_t_shirt_1_pressed() -> void:
	left_first = !left_first
	update_t_shirt()

func _on_t_shirt_2_pressed() -> void:
	left_first = !left_first
	update_t_shirt()

func _on_random_btn_toggled(_toggled_on: bool) -> void:
	update_t_shirt()

func _on_start_btn_pressed() -> void:
	var player1_type = GameTypes.Agent.USER if user1.button_pressed else GameTypes.Agent.AI
	var player2_type = GameTypes.Agent.USER if user2.button_pressed else GameTypes.Agent.AI

	if not left_first:
		var temp = player1_type
		player1_type = player2_type
		player2_type = temp

	if random_btn.button_pressed:
		if randf() < 0.5:
			var temp = player1_type
			player1_type = player2_type
			player2_type = temp

	DesktopMain.new_game(player1_type, player2_type)
