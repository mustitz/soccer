#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>

#include "bridge.hpp"

using namespace godot;

static Error from_errno(Error def) {
   switch (errno) {
        case ENOMEM: return ERR_OUT_OF_MEMORY;
        case EINVAL: return ERR_INVALID_PARAMETER;
        default: return def;
    }
}

VARIANT_ENUM_CAST(GameStatus);
VARIANT_ENUM_CAST(MoveState);
VARIANT_ENUM_CAST(MoveDirection);

class State : public RefCounted {
   GDCLASS(State, RefCounted)

private:
    Snapshot snapshot;

public:
    State() {
        snapshot = { GAME_INACTIVE };
    }

    void update(const AI& ai) {
        ai.write_snapshot(snapshot);
    }

    int get_status() const { return snapshot.status; }
    int get_result() const { return snapshot.result; }
    int get_active_player() const { return snapshot.active_player; }
    int get_move_state() const { return snapshot.move_state; }

    Vector2i get_ball_coords() const {
        return Vector2i(snapshot.ball_coords[0], snapshot.ball_coords[1]);
    }

    PackedInt32Array get_possible_steps() const {
        PackedInt32Array result;

        result.resize(snapshot.qpossible_steps);
        for (int i = 0; i < snapshot.qpossible_steps; i++) {
            result[i] = snapshot.possible_steps[i];
        }

        return result;
    }

    static void _bind_methods() {
        ClassDB::bind_method(D_METHOD("get_status"), &State::get_status);
        ClassDB::bind_method(D_METHOD("get_result"), &State::get_result);
        ClassDB::bind_method(D_METHOD("get_active_player"), &State::get_active_player);
        ClassDB::bind_method(D_METHOD("get_ball_coords"), &State::get_ball_coords);
        ClassDB::bind_method(D_METHOD("get_move_state"), &State::get_move_state);
        ClassDB::bind_method(D_METHOD("get_possible_steps"), &State::get_possible_steps);

        ADD_PROPERTY(PropertyInfo(Variant::INT, "status"), "", "get_status");
        ADD_PROPERTY(PropertyInfo(Variant::INT, "result"), "", "get_result");
        ADD_PROPERTY(PropertyInfo(Variant::INT, "active_player"), "", "get_active_player");
        ADD_PROPERTY(PropertyInfo(Variant::VECTOR2I, "ball"), "", "get_ball_coords");
        ADD_PROPERTY(PropertyInfo(Variant::INT, "move_state"), "", "get_move_state");
        ADD_PROPERTY(PropertyInfo(Variant::PACKED_INT32_ARRAY, "possible_steps"), "", "get_possible_steps");
    }
};

class EngineExtension : public RefCounted {
    GDCLASS(EngineExtension, RefCounted)

public:
    EngineExtension() : ai(nullptr) {
        thinker = std::thread(&EngineExtension::think_loop, this);
    }

    ~EngineExtension() {
        {
            std::lock_guard<std::mutex> lock(mutex);
            basta = true;
        }
        cv.notify_one();
        thinker.join();

        release();
    }

    void release() {
        geometry = nullptr;
        ai = nullptr;
    }

    Error new_game(
        const int width,
        const int height,
        const int goal_width,
        const int free_kick_len
    ) {
        auto new_geometry = std::make_shared<StdGeometry>(width, height, goal_width, free_kick_len);
        if (!new_geometry->is_valid()) {
            return from_errno(ERR_CANT_CREATE);
        }

        auto new_ai = std::make_unique<AI>(new_geometry);
        if (!new_ai->is_valid()) {
            return ERR_OUT_OF_MEMORY;
        }

        release();

        geometry = std::move(new_geometry);
        ai = std::move(new_ai);
        return OK;
    }

    Ref<State> get_game_state() {
        Ref<State> game_state;
        game_state.instantiate();
        game_state->update(*ai);
        return game_state;
    }

    Error step(int direction) {
        if (!ai) return ERR_UNCONFIGURED;

        return ai->step(direction) ? OK : ERR_INVALID_PARAMETER;
    }

    Error undo() {
        if (!ai) return ERR_UNCONFIGURED;

        return ai->undo() ? OK : ERR_INVALID_PARAMETER;
    }

    int go() {
        if (!ai) return -1;

        return ai->go();
    }

    void start_thinking() {
        if (!ai) return;

        std::lock_guard<std::mutex> lock(mutex);
        if (busy) return;

        busy = true;
        cv.notify_one();
    }

    static void _bind_methods() {
        ADD_SIGNAL(MethodInfo("thinking_done", PropertyInfo(Variant::INT, "direction")));

        BIND_ENUM_CONSTANT(GAME_FAILED);
        BIND_ENUM_CONSTANT(GAME_IN_PROGRESS);
        BIND_ENUM_CONSTANT(GAME_INACTIVE);

        BIND_ENUM_CONSTANT(MOVE_STATE_INACTIVE);
        BIND_ENUM_CONSTANT(MOVE_STATE_1);
        BIND_ENUM_CONSTANT(MOVE_STATE_2);
        BIND_ENUM_CONSTANT(MOVE_STATE_3);
        BIND_ENUM_CONSTANT(MOVE_STATE_FREE_KICK);

        BIND_ENUM_CONSTANT(DIRECTION_NW);
        BIND_ENUM_CONSTANT(DIRECTION_N);
        BIND_ENUM_CONSTANT(DIRECTION_NE);
        BIND_ENUM_CONSTANT(DIRECTION_E);
        BIND_ENUM_CONSTANT(DIRECTION_SE);
        BIND_ENUM_CONSTANT(DIRECTION_S);
        BIND_ENUM_CONSTANT(DIRECTION_SW);
        BIND_ENUM_CONSTANT(DIRECTION_W);
        BIND_ENUM_CONSTANT(DIRECTION_NONE);
        BIND_ENUM_CONSTANT(QDIRECTIONS);

        ClassDB::bind_method(D_METHOD(
            "new_game", "width", "height", "goal_width", "free_kick_len"),
            &EngineExtension::new_game);
        ClassDB::bind_method(D_METHOD("get_game_state"), &EngineExtension::get_game_state);
        ClassDB::bind_method(D_METHOD("step", "direction"), &EngineExtension::step);
        ClassDB::bind_method(D_METHOD("undo"), &EngineExtension::undo);
        ClassDB::bind_method(D_METHOD("go"), &EngineExtension::go);
        ClassDB::bind_method(D_METHOD("start_thinking"), &EngineExtension::start_thinking);
    }

private:
    std::shared_ptr<Geometry> geometry;
    std::unique_ptr<AI> ai;

    std::thread thinker;
    std::condition_variable cv;
    std::mutex mutex;
    bool busy{false};
    bool basta{false};

    void think_loop() {
        for (;;) {
            {
                std::unique_lock<std::mutex> lock(mutex);
                cv.wait(lock, [this]{ return busy || basta; });
                if (basta) break;
            }

            int result = ai->go();

            {
                std::lock_guard<std::mutex> lock(mutex);
                busy = false;
            }

            call_deferred("emit_signal", "thinking_done", result);
        }
    }
};

void initialize_engine_extension_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) return;
    ClassDB::register_class<EngineExtension>();
    ClassDB::register_class<State>();
}

void uninitialize_engine_extension_module(ModuleInitializationLevel p_level) {}

extern "C" {
    GDExtensionBool GDE_EXPORT engine_extension_library_init(
        GDExtensionInterfaceGetProcAddress p_get_proc_address,
        const GDExtensionClassLibraryPtr p_library,
        GDExtensionInitialization *r_initialization
    ) {
        GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
        init_obj.register_initializer(initialize_engine_extension_module);
        init_obj.register_terminator(uninitialize_engine_extension_module);
        init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
        return init_obj.init();
    }
}
