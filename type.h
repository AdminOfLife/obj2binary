#ifndef TYPE_H
#define TYPE_H
struct Vertex {
    float v[3];
};

struct Normal {
    float v[3];
};

struct TextureCoord {
    float v[2];
};

struct InterlacedTriangle {
    Vertex v;
    TextureCoord vt;
    Normal vn;
};

struct Index {
    int vi;
    int vti;
    int vni;
};

enum IndexType {
    IT_NONE = -1,
    IT_V,
    IT_V_VN,
    IT_V_VT,
    IT_V_VT_VN,
};

#endif  // TYPE_H
