extends Node

const MOBILE_EMU = false
const DEBUG = true

var os_name: String
var is_mobile: bool
var is_desktop: bool
var dpi: int = -1

func _ready():
	os_name = OS.get_name()
	is_mobile = os_name == "Android" or os_name == "iOS"
	is_desktop = os_name == "macOS" or os_name == "Windows" or os_name == "Linux"
	dpi = get_dpi()

	setup_window_size()

	print("QAZWSX: Platform settings, os_name=", os_name, "; dpi=", dpi, ";")

func get_dpi():
	if dpi > 0:
		return dpi

	var real_dpi = DisplayServer.screen_get_dpi()
	print("QAZWSX: DisplayServer.screen_get_dpi() = ", real_dpi)
	if real_dpi > 0:
		print("QAZWSX: DPI = ", real_dpi, " (based on screen_get_dpi)")
		dpi = real_dpi
		return dpi

	var screen_size = DisplayServer.screen_get_size()
	print("QAZWSX: DisplayServer.screen_get_size() = ", screen_size)
	if screen_size.x == 0 or screen_size.y == 0:
		print("QAZWSX: DPI = 96 (default)")
		dpi = 96
		return dpi

	var diagonal_pixels = sqrt(screen_size.x * screen_size.x + screen_size.y * screen_size.y)
	var assumed_diagonal_inches = 17
	var calculated_dpi = int(diagonal_pixels / assumed_diagonal_inches)
	print("QAZWSX: DPI = ", calculated_dpi, " (based on screen_get_size)")
	dpi = calculated_dpi
	return dpi

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
