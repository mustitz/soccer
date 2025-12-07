class_name GameTypes

enum Direction { SW, S, SE, E, NE, N, NW, W }
enum Player { RED, BLUE }
enum Agent { NONE, USER, AI }

const STEP_NAMES = ["SW", "S", "SE", "E", "NE", "N", "NW", "W"]

static func step_name(direction: Direction) -> String:
	if direction < STEP_NAMES.size():
		return STEP_NAMES[direction]
	return "Step(%d)" % direction

static func get_singleton_from_group(group_name: String):
	var nodes = Engine.get_main_loop().get_nodes_in_group(group_name)

	var valid_nodes = []
	for n in nodes:
		if is_instance_valid(n) and n.is_inside_tree():
			valid_nodes.append(n)

	if valid_nodes.size() > 1:
		push_warning("Multiple instances in group '%s' detected: %d" % [group_name, valid_nodes.size()])

	if valid_nodes.size() > 0:
		return valid_nodes[0]

	return null

class GameStep:
	var direction: Direction
	var length: int
	var player: Player
	var ball: Vector2i

	func _init(_direction: Direction, _length: int, _player: Player, _ball: Vector2i):
		direction = _direction
		length = _length
		player = _player
		ball = _ball
