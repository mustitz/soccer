#ifndef ENGINE_BRIDGE_INCLUDED
#define ENGINE_BRIDGE_INCLUDED

#define GOAL_1   -1
#define GOAL_2   -2
#define NO_WAY   -3

enum GameStatus {
    GAME_FAILED = 0,
    GAME_IN_PROGRESS = 1,
    GAME_INACTIVE = 2,
};

enum MoveState {
   MOVE_STATE_INACTIVE  = 0,
   MOVE_STATE_1         = 1,
   MOVE_STATE_2         = 2,
   MOVE_STATE_3         = 3,
   MOVE_STATE_FREE_KICK = 4,
};

/* Reversed top/bottom */
enum MoveDirection {
    DIRECTION_NONE = -1,
    DIRECTION_SW = 0,
    DIRECTION_S  = 1,
    DIRECTION_SE = 2,
    DIRECTION_E  = 3,
    DIRECTION_NE = 4,
    DIRECTION_N  = 5,
    DIRECTION_NW = 6,
    DIRECTION_W  = 7,
    QDIRECTIONS = 8
};

struct StateSnapshot {
   enum GameStatus status;
   int result;
   int active_player;
   int ball;
   int ball_coords[2];
   enum MoveState move_state;
   enum MoveDirection possible_steps[8];
   int qpossible_steps;
};

#endif // ENGINE_WRAPPER_INCLUDED
