#include "paper-football.h"

struct geometry * c_create_std_geometry(int w, int h, int gw, int fkl) {
    return create_std_geometry(w, h, gw, fkl);
}

void c_destroy_geometry(struct geometry * g) {
    destroy_geometry(g);
}
