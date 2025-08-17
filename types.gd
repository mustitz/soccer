class_name GameTypes

enum Direction { SW, S, SE, E, NE, N, NW, W }
enum Player { RED, BLUE }

class GameStep:
	var direction: Direction
	var length: int
	var player: Player

	func _init(_direction: Direction, _length: int, _player: Player):
		direction = _direction
		length = _length
		player = _player
