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

struct BinaryHeader {
    unsigned int vertices;
    unsigned int dataBytes;
    unsigned int format;
    unsigned int hasVT;
    unsigned int vtOffset;  // Not include the header
    unsigned int hasVN;
    unsigned int vnOffset;  // Not include the header
    unsigned int dataOffset;  // the begin of the data
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

enum FormatType {
    FORMAT_NONE = -1,
    FORMAT_V = 0x0,
    FORMAT_V_VN = 0xC00,
    FORMAT_V_VT = 0xC0000,
    FORMAT_V_VT_VN = 0xC1400,
    FORMAT_V_VN_VT = 0x140C00,
    FORMAT_V_MASK = 0xFF,
    FORMAT_VT_MASK = 0xFF0000,
    FORMAT_VN_MASK = 0xFF00,
    FORMAT_VT_SHIFT = 16,
    FORMAT_VN_SHIFT = 8,
    FORMAT_NONINTERLEAVED = 0x1000000
};

#endif  // TYPE_H
