#ifndef ENGINE_CPP_BRIDGE_INCLUDED
#define ENGINE_CPP_BRIDGE_INCLUDED

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include "bridge.h"

#include <memory>
#include <thread>
#include <atomic>
#include <semaphore>

using namespace godot;

extern "C" {
    void * create_std_geometry(
        const int width,
        const int height,
        const int goal_width,
        const int penalty_len);
    void destroy_geometry(void * handle);

    void * create_ai(void * geometry, const char * ai_type_name);
    void destroy_ai(void * ai);
    int ai_get_snapshot(void * ai, struct Snapshot * c_state);
    int ai_step(void * ai, int direction);
    int ai_undo(void * ai, int count);
    int ai_go(void * ai);

    int ai_set_param_u32(void *ai_handle, const char *name, uint32_t value);
    int ai_set_param_i32(void *ai_handle, const char *name, int32_t value);
    int ai_set_param_f32(void *ai_handle, const char *name, float value);
}

static Error status_to_error(int status, Error def) {
    switch (status) {
        case 0: return OK;
        case ENOMEM: return ERR_OUT_OF_MEMORY;
        case EINVAL: return ERR_INVALID_PARAMETER;
        default: return def;
    }
}



class Geometry {
    friend class AI;
public:
    Geometry() : _handle(nullptr) {}
    virtual ~Geometry() {
        if (_handle != nullptr) {
            auto tmp = _handle;
            _handle = nullptr;
            destroy_geometry(tmp);
        }
    }

    bool is_valid() const { return _handle != nullptr; }

    virtual std::pair<int, int> get_ball_coords(int pos) = 0;

protected:
    void reset(void * handle = nullptr) {
        if (_handle != nullptr) {
            auto tmp = _handle;
            _handle = nullptr;
            destroy_geometry(tmp);
        }
        _handle = handle;
    }

private:
    void * _handle;
};



class StdGeometry: public Geometry {
public:
    StdGeometry(int width, int height, int goal_width, int free_kick_len):
        Geometry(),
        _width(-1),
        _height(-1),
        _goal_width(-1),
        _free_kick_len(-1)
    {
        void * handle = create_std_geometry(width, height, goal_width, free_kick_len);
        if (handle == nullptr) {
            return;
        }

        _width = width;
        _height = height;
        _goal_width = goal_width;
        _free_kick_len = free_kick_len;
        reset(handle);
    }

    std::pair<int, int> get_ball_coords(int pos) override {
        return { pos % _width, pos / _width };
    }

private:
    int _width;
    int _height;
    int _goal_width;
    int _free_kick_len;
};



class AI : public std::enable_shared_from_this<AI> {
public:
    static std::shared_ptr<AI> create(uint64_t owner_id) {
        auto ai = std::shared_ptr<AI>(new AI(owner_id));
        ai->start_thread();
        return ai;
    }

    Error load(std::shared_ptr<Geometry> geometry, const Dictionary& profile);

private:
    AI(uint64_t owner_id) : _geometry(nullptr), _handle(nullptr), _owner_id(owner_id) {}

public:

    ~AI() {
        if (_handle) {
            destroy_ai(_handle);
        }
    }

    bool is_valid() const { return _handle != nullptr; }

    void write_snapshot(Snapshot& snapshot) const {
        int ok = ai_get_snapshot(_handle, &snapshot);
        if (!ok) {
            snapshot.status = GAME_FAILED;
            return;
        }

        auto coords = _geometry->get_ball_coords(snapshot.ball);
        snapshot.ball_coords[0] = coords.first;
        snapshot.ball_coords[1] = coords.second;
    }

    Error step(int direction) {
        if (!is_valid()) {
            return ERR_UNCONFIGURED;
        }
        if (thinking.load()) {
            return ERR_BUSY;
        }

        return status_to_error(ai_step(_handle, direction), FAILED);
    }

    Error undo(int count = 1) {
        if (!is_valid()) {
            return ERR_UNCONFIGURED;
        }
        if (thinking.load()) {
            return ERR_BUSY;
        }

        return status_to_error(ai_undo(_handle, count), FAILED);
    }

    bool go() {
        if (!is_valid()) {
            return false;
        }
        if (thinking.exchange(true)) {
            return false;
        }
        sem.release();
        return true;
    }

    bool set_param_u32(const char *name, uint32_t value) {
        if (!is_valid()) {
            return false;
        }
        return ai_set_param_u32(_handle, name, value) == 0;
    }

    bool set_param_i32(const char *name, int32_t value) {
        if (!is_valid()) {
            return false;
        }
        return ai_set_param_i32(_handle, name, value) == 0;
    }

    bool set_param_f32(const char *name, float value) {
        if (!is_valid()) {
            return false;
        }
        return ai_set_param_f32(_handle, name, value) == 0;
    }

    Error load_profile(const Dictionary& profile);

    void start_thread() {
        auto self = shared_from_this();
        std::thread([self]() { self->thread_loop(); }).detach();
    }

    void detach() {
        zombie.store(true, std::memory_order_relaxed);
        sem.release();
    }

private:
    std::shared_ptr<Geometry> _geometry;
    void * _handle;

    std::atomic<bool> zombie{false};
    std::atomic<bool> thinking{false};
    std::binary_semaphore sem{0};
    uint64_t _owner_id;

    void thread_loop() {
        while (true) {
            sem.acquire();
            if (zombie.load(std::memory_order_relaxed)) {
                return;
            }
            if (thinking.load()) {
                int result = ai_go(_handle);
                thinking.store(false);
                if (!zombie.load(std::memory_order_relaxed)) {
                    notify_engine(result);
                }
            }
        }
    }

    void notify_engine(int result) {
        Object* owner = ObjectDB::get_instance(_owner_id);
        if (owner) {
            owner->call_deferred("emit_signal", "thinking_done", result);
        }
    }
};

#endif
