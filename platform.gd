extends Node

const MOBILE_EMU = false

var os_name: String
var is_mobile: bool
var is_desktop: bool
var dpi: int

func _ready():
	os_name = OS.get_name()
	is_mobile = os_name == "Android" or os_name == "iOS"
	is_desktop = os_name == "macOS" or os_name == "Windows" or os_name == "Linux"
	dpi = get_dpi()

	setup_window_size()

	print("QAZWSX: Platform settings, os_name=", os_name, "; dpi=", dpi, ";")

func get_dpi():
	if is_mobile:
		return DisplayServer.screen_get_dpi()

	var screen_size = DisplayServer.screen_get_size()
	var diagonal_pixels = sqrt(screen_size.x * screen_size.x + screen_size.y * screen_size.y)
	var assumed_diagonal_inches = 17
	return diagonal_pixels / assumed_diagonal_inches

func setup_window_size():
	if is_desktop:
		var k: float = 1.333
		if MOBILE_EMU:
			k = 0.666

		var screen_size = DisplayServer.screen_get_size()
		var height = int(0.8 * screen_size.y)
		var width = int(k * height)
		var wnd = get_window()
		wnd.size = Vector2i(width, height)
		wnd.move_to_center()
