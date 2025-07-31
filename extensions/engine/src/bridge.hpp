#ifndef ENGINE_CPP_BRIDGE_INCLUDED
#define ENGINE_CPP_BRIDGE_INCLUDED

#include "bridge.h"

#include <utility>

extern "C" {
    void * create_std_geometry(
        const int width,
        const int height,
        const int goal_width,
        const int penalty_len);
    void destroy_geometry(void * handle);

    void * create_state(void * geometry);
    void destroy_state(void * state);
    int state_step(void * state, int direction);

    int c_get_state(void * state, struct StateSnapshot * c_state);
}



class Geometry {
    friend class State;
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



class State {
public:
    State(std::shared_ptr<Geometry> geometry):
        _geometry(geometry),
        _handle(nullptr)
    {
        if (_geometry && _geometry->is_valid()) {
            _handle = create_state(_geometry->_handle);
        }
    }

    ~State() {
        if (_handle) {
            destroy_state(_handle);
        }
    }

    bool is_valid() const { return _handle != nullptr; }

    void write_snapshot(StateSnapshot& snapshot) const {
        int ok = c_get_state(_handle, &snapshot);
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

        int ball = state_step(_handle, direction);
        if (ball == NO_WAY) {
            return false;
        }

        return true;
    }

private:
   std::shared_ptr<Geometry> _geometry;
   void * _handle;
};

#endif
