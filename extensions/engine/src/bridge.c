#include "paper-football.h"
#include "bridge.h"

void * create_ai(void * geometry, const char * ai_type_name) {
    if (!geometry || !ai_type_name) {
        return NULL;
    }

    const struct ai_desc * ptr = ai_list;
    for (; ptr->name; ++ptr) {
        if (strcmp(ptr->name, ai_type_name) == 0) {
            struct ai * ai = (struct ai *)malloc(sizeof(struct ai));
            if (!ai) {
                return NULL;
            }
            if (ptr->init_ai(ai, (struct geometry *)geometry) != 0) {
                free(ai);
                return NULL;
            }
            return ai;
        }
    }

    return NULL;
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

int ai_undo(void * ai_handle, int count) {
    if (!ai_handle) {
        return -1;
    }

    struct ai * ai = (struct ai *)ai_handle;
    return ai->undo_steps(ai, count);
}

int ai_go(void * ai_handle) {
    if (!ai_handle) {
        return -1;
    }

    struct ai * ai = (struct ai *)ai_handle;
    enum step result = ai->go(ai, NULL);
    return (int)result;
}

int ai_set_param_u32(void *ai_handle, const char *name, uint32_t value) {
    if (!ai_handle || !name) {
        return -1;
    }
    struct ai * ai = (struct ai *)ai_handle;
    if (!ai->set_param) {
        return -1;
    }
    return ai->set_param(ai, name, &value);
}

int ai_set_param_i32(void *ai_handle, const char *name, int32_t value) {
    if (!ai_handle || !name) {
        return -1;
    }
    struct ai * ai = (struct ai *)ai_handle;
    if (!ai->set_param) {
        return -1;
    }
    return ai->set_param(ai, name, &value);
}

int ai_set_param_f32(void *ai_handle, const char *name, float value) {
    if (!ai_handle || !name) {
        return -1;
    }
    struct ai * ai = (struct ai *)ai_handle;
    if (!ai->set_param) {
        return -1;
    }
    return ai->set_param(ai, name, &value);
}
