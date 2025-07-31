#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>

#define restrict __restrict

extern "C" {
    struct geometry * c_create_std_geometry(int w, int h, int gw, int fkl);
    void c_destroy_geometry(struct geometry* g);
}

using namespace godot;

static Error from_errno(Error def)
{
   switch (errno) {
        case ENOMEM: return ERR_OUT_OF_MEMORY;
        case EINVAL: return ERR_INVALID_PARAMETER;
        default: return def;
    }
}

class EngineExtension : public RefCounted {
    GDCLASS(EngineExtension, RefCounted)

public:
    EngineExtension() : geometry(nullptr) {}
    ~EngineExtension() {
        if (geometry) {
            c_destroy_geometry(geometry);
        }
    }

    Error new_game(
        const int width,
        const int height,
        const int goal_width,
        const int free_kick_len
    ) {
        struct geometry * new_geometry = c_create_std_geometry(width, height, goal_width, free_kick_len);
        if (new_geometry == NULL) {
            return from_errno(ERR_CANT_CREATE);
        }

        if (geometry) {
            c_destroy_geometry(geometry);
        }

        geometry = new_geometry;
        return OK;
    }

    static void _bind_methods() {
        ClassDB::bind_method(D_METHOD(
            "new_game", "width", "height", "goal_width", "free_kick_len"),
        &EngineExtension::new_game);
    }

private:
    struct geometry * geometry;
};

void initialize_engine_extension_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) return;
    ClassDB::register_class<EngineExtension>();
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
