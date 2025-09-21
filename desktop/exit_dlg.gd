extends Control

func _on_yes_btn_pressed():
	get_tree().quit()

func _on_no_btn_pressed():
	DesktopMain.set_scene("res://desktop/main_menu.tscn")
