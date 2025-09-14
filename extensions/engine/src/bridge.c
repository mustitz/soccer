#include "paper-football.h"
#include "bridge.h"

void * create_ai(void * geometry) {
    if (!geometry) {
        return NULL;
    }

    struct ai * ai = malloc(sizeof(struct ai));
    if (!ai) {
        return NULL;
    }

    if (init_mcts_ai(ai, (struct geometry *)geometry) != 0) {
        free(ai);
        return NULL;
    }

    return ai;
}

void destroy_ai(void * ai_handle) {
    if (!ai_handle) {
        return;
    }

    struct ai * ai = (struct ai *)ai_handle;
    ai->free(ai);
    free(ai);
}

int ai_get_snapshot(void * ai_handle, struct Snapshot * snapshot) {
    if (!ai_handle || !snapshot) {
        return 0;
    }

    struct ai * ai = (struct ai *)ai_handle;
    const struct state * state = ai->get_state(ai);

    if (!state) {
        return 0;
    }

    enum state_status status = state_status(state);
    snapshot->status = status == IN_PROGRESS ? GAME_IN_PROGRESS : GAME_INACTIVE;

    switch (status) {
        case WIN_1 : snapshot->result = +1; break;
        case WIN_2 : snapshot->result = -1; break;
        default: snapshot->result = 0; break;
    }

    snapshot->active_player = state->active;
    snapshot->ball = state->ball;

    if (status == IN_PROGRESS) {
        if (state->step1 == INVALID_STEP) {
            snapshot->move_state = state->step12 ? MOVE_STATE_1 : MOVE_STATE_FREE_KICK;
        } else {
            snapshot->move_state = state->step2 == INVALID_STEP ? MOVE_STATE_2 : MOVE_STATE_3;
        }
    } else {
        snapshot->move_state = MOVE_STATE_INACTIVE;
    }

    steps_t steps = state_get_steps(state);
    int qsteps = 0;
    enum MoveDirection * restrict output = snapshot->possible_steps;
    while (steps != 0) {
        const enum step step = extract_step(&steps);
        output[qsteps++] = (enum MoveDirection) step;
    }
    snapshot->qpossible_steps = qsteps;

    return 1;
}

int ai_step(void * ai_handle, int direction) {
    if (!ai_handle) {
        return -1;
    }

    struct ai * ai = (struct ai *)ai_handle;
    return ai->do_step(ai, direction);
}
