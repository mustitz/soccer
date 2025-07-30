class_name GameTypes

enum Direction { N, NE, E, SE, S, SW, W, NW }
enum Player { RED, BLUE }

class GameStep:
	var direction: Direction
	var length: int
	var player: Player

	func _init(_direction: Direction, _length: int, _player: Player):
		direction = _direction
		length = _length
		player = _player
