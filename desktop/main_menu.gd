extends Control

func _on_new_game_btn_pressed():
	DesktopMain.set_scene("res://desktop/new_game_dlg.tscn")

func _on_exit_btn_pressed():
	DesktopMain.set_scene("res://desktop/exit_dlg.tscn")
