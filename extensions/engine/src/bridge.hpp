#ifndef ENGINE_CPP_BRIDGE_INCLUDED
#define ENGINE_CPP_BRIDGE_INCLUDED

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include "bridge.h"

#include <utility>
#include <thread>
#include <mutex>
#include <condition_variable>

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



class AI {
public:
    AI() : _geometry(nullptr), _handle(nullptr) {}

    Error load(std::shared_ptr<Geometry> geometry, const Dictionary& profile);

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

    bool step(int direction) {
        if (!is_valid()) {
            return false;
        }

        return ai_step(_handle, direction) == 0;
    }

    bool undo(int count = 1) {
        if (!is_valid()) {
            return false;
        }

        return ai_undo(_handle, count) == 0;
    }

    int go() {
        if (!is_valid()) {
            return -1;
        }

        return ai_go(_handle);
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

private:
    std::shared_ptr<Geometry> _geometry;
    void * _handle;
};

#endif
