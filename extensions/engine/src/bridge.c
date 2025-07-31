#include "paper-football.h"
#include "bridge.h"

int c_get_state(struct state * state, struct StateSnapshot * c_state) {
    if (!state || !c_state) {
        return 0;
    }

    enum state_status status = state_status(state);
    c_state->status = status == IN_PROGRESS ? GAME_IN_PROGRESS : GAME_INACTIVE;

    switch (status) {
        case WIN_1 : c_state->result = +1; break;
        case WIN_2 : c_state->result = -1; break;
        default: c_state->result = 0; break;
    }

    c_state->active_player = state->active;
    c_state->ball = state->ball;

    if (status == IN_PROGRESS) {
        if (state->step1 == INVALID_STEP) {
            c_state->move_state = state->step12 ? MOVE_STATE_1 : MOVE_STATE_FREE_KICK;
        } else {
            c_state->move_state = state->step2 == INVALID_STEP ? MOVE_STATE_2 : MOVE_STATE_3;
        }
    } else {
        c_state->move_state = MOVE_STATE_INACTIVE;
    }

    steps_t steps = state_get_steps(state);
    int qsteps = 0;
    enum MoveDirection * restrict output = c_state->possible_steps;
    while (steps != 0) {
        const enum step step = extract_step(&steps);
        output[qsteps++] = (enum MoveDirection) step;
    }
    c_state->qpossible_steps = qsteps;

    return 1;
}
