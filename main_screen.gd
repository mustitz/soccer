extends Control

func _ready():
	setup_adaptive_ui()

func _on_new_game_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://game.tscn")

func _on_exit_btn_pressed() -> void:
	get_tree().quit()

func _on_resized() -> void:
	setup_adaptive_ui()

func setup_adaptive_ui():
	var screen_size = get_viewport().get_visible_rect().size
	var font_size = 0.04 * screen_size.y

	var button_width = 0.70 * screen_size.x
	var button_height = 0.08 * screen_size.y

	var vbox = $CenterContainer/VBoxContainer
	vbox.add_theme_constant_override("margin_bottom", int(screen_size.y * 0.50))

	var spacer = $CenterContainer/VBoxContainer/Spacer
	spacer.custom_minimum_size.y = screen_size.y * 0.2

	var custom_theme = Theme.new()
	custom_theme.set_font_size("font_size", "Button", font_size)
	custom_theme.set_font_size("font_size", "Label", int(font_size * 1.2))
	vbox.theme = custom_theme

	for child in vbox.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(button_width, button_height)
			child.add_theme_font_size_override("font_size", font_size)
		if child is Label:
			child.add_theme_font_size_override("font_size", font_size)
