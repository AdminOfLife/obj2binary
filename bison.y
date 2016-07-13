%{
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <vector>
#include "type.h"
#include "bison.hpp"

using namespace std;

extern int yylex(void);
extern void yyerror(const char *);
extern int yylineno;

#define LOGV(args...) if (verbose) printf(args)

unsigned int maxPolygon;
bool invertX;
bool invertY;
bool verbose;
bool interleaved;
bool needHeader;
FormatType dataFormat;

vector<Vertex> vList;
vector<Normal> vnList;
vector<TextureCoord> vtList;

int polygonCount;
int faceType;
int * indexType;
Index * indexTemp;

vector<InterlacedTriangle> output;
BinaryHeader header;

void clear() {
    vList.clear();
    vnList.clear();
    vtList.clear();
    faceType = IT_NONE;
}

void checkConsist() {
    int first = indexType[0];
    if (faceType == IT_NONE)
        faceType = first;
    if (faceType != first)
        printf("\n*** Face type not consist at line %d\n", yylineno+1);
    if (polygonCount > maxPolygon)
        printf("*** Too many polygon (%d > MAX%d)\n", polygonCount, maxPolygon );
    for (int i = 1; i < polygonCount; i++) {
        if (first != indexType[i]) {
            printf("\n*** Obj syntax error: Index type not consist at line %d\n", yylineno+1);
            exit(-1);
        }
    }
}

InterlacedTriangle getTriangle(Index idx) {
    InterlacedTriangle triangle = {
            .v = {0,0,0},
            .vt = {0,0},
            .vn = {0,0,0}
        };
    if (idx.vi >= vList.size()) {
        printf("*** vi out of range at line %d\n", yylineno+1);
        return triangle;
    } else {
        const Vertex & v = vList[idx.vi];
        LOGV("v%d(%5f %5f %5f)\n", idx.vi, v.v[0], v.v[1], v.v[2]);
        triangle.v = v;
    }

    if (idx.vni != -1) {
        if (idx.vni >= vnList.size()) {
            printf("*** vni out of range at line %d\n", yylineno+1);
            return triangle;
        } else {
            const Normal & vn = vnList[idx.vni];
            LOGV("n%d(%5f %5f %5f)\n", idx.vni, vn.v[0], vn.v[1], vn.v[2]);
            triangle.vn = vn;
        }
    }

    if (idx.vti != -1) {
        if (idx.vti >= vtList.size()) {
            printf("*** vti out of range at line %d\n", yylineno+1);
            return triangle;
        } else {
            const TextureCoord & vt = vtList[idx.vti];
            LOGV("vt%d(%5f %5f)\n", idx.vti, vt.v[0], vt.v[1]);
            triangle.vt = vt;
        }
    }
}

%}

%union
{
    int i;
    float f;
    Index id;
}

%token FLOAT INTEGER VERTEX TEXTURE NORMAL FACE SECTION GROUP USEMTL MTLLIB

%type<i> INTEGER
%type<f> FLOAT
%type<id> index_type

%{
    void yyerror(const char *);
    int yylex(void);
%}

%%
obj:
    objcmd
    | obj objcmd
    ;

objcmd:
    vertex
    | normal
    | texture
    | face
    ;
    
vertex:
    VERTEX FLOAT FLOAT FLOAT {
        vList.push_back(Vertex{.v={$2, $3, $4}});
        LOGV("%d:v %6f %6f %6f\n", yylineno+1, $2, $3, $4);
    }
    ;

normal:
    NORMAL FLOAT FLOAT FLOAT {
        vnList.push_back(Normal{.v={$2, $3, $4}});
        LOGV("%d:vn %6f %6f %6f\n", yylineno+1, $2, $3, $4);
    }
    ;

texture:
    TEXTURE FLOAT FLOAT FLOAT {
        // don't care the z value
        vtList.push_back(TextureCoord{.v={
            invertX ? 1.0f - $2 : $2,
            invertY ? 1.0f - $3 : $3}});
        LOGV("%d:vt %6f %6f %6f\n", yylineno+1, $2, $3, $4);
    }
    | TEXTURE FLOAT FLOAT {
        vtList.push_back(TextureCoord{.v={
            invertX ? 1.0f - $2 : $2,
            invertY ? 1.0f - $3 : $3}});
        LOGV("%d:vt %6f %6f\n", yylineno+1, $2, $3);
    }
    ;

face:
    face_triangle {
        LOGV("\n%d:Collect P%d\n", yylineno+1, polygonCount);
        checkConsist();
        for (int i = 0; i < 3; i++) {
            Index idx = indexTemp[i];
            InterlacedTriangle triangle = getTriangle(idx);
            output.push_back(triangle);
        }
        polygonCount = 0;
    }
    | face_line {
        checkConsist();
        polygonCount = 0;
    }
    | face_polygon {
        LOGV("\n%d:Collect P%d\n", yylineno+1, polygonCount);
        checkConsist();
        InterlacedTriangle triangle0 = getTriangle(indexTemp[0]);
        InterlacedTriangle triangle1 = getTriangle(indexTemp[1]);
        InterlacedTriangle triangle2;
        for (int i = 2; i < polygonCount; i++) {
            Index idx = indexTemp[i];
            triangle2 = getTriangle(idx);
            output.push_back(triangle0);
            output.push_back(triangle1);
            output.push_back(triangle2);

            triangle1 = triangle2;
        }
        polygonCount = 0;
    }
    ;

face_line:
    FACE index_type index_type
    ;

face_triangle:
    FACE index_type index_type index_type
    ;

face_polygon:
    face_triangle index_type
    | face_polygon index_type
    ;

index_type:
    INTEGER {
        indexType[polygonCount] = IT_V;
        indexTemp[polygonCount] = Index{.vi=$1 - 1, .vti=-1, .vni=-1};
        polygonCount++;
        LOGV("%d ", $1);
    }
    | INTEGER '/' INTEGER '/' INTEGER {
        indexType[polygonCount] = IT_V_VT_VN;
        indexTemp[polygonCount] = Index{.vi=$1 - 1, .vti=$3 - 1, .vni=$5 - 1};
        polygonCount++;
        LOGV("%d/%d/%d ", $1, $3, $5);
    }
    | INTEGER '/' '/' INTEGER {
        indexType[polygonCount] = IT_V_VN;
        indexTemp[polygonCount] = Index{.vi=$1 - 1, .vti=-1, .vni=$4 - 1};
        polygonCount++;
        LOGV("%d//%d \n", $1, $4);
    }
    | INTEGER '/' INTEGER {
        indexType[polygonCount] = IT_V_VT;
        indexTemp[polygonCount] = Index{.vi=$1 - 1, .vti=$3 - 1, .vni=-1};
        polygonCount++;
        LOGV("%d/%d \n", $1, $3);
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "%s\n", s);
}

void usage() {
    printf(
"Parsing an obj file and save as a binary for opengl fast reading.\n"
"if no pipeline input, it blocked.  If no argument, work quietly.\n"
"\n"
"Usage: cat one.obj | obj2binary [OPTION...] [-o <output.bin>]\n"
"\n"
"OPTION:\n"
"    -h             This help message.\n"
"    -x             Invert object texture x coord by (1.0f - x)\n"
"    -y             Invert object texture y coord by (1.0f - y)\n"
"                   NOTE: OpenGL need invert y for my object file.\n"
"    -o <filename>  output file to the following filename.\n"
"    -v             show more log.\n"
"ADVANCED OPTION:\n"
"    -p <polygons>  The max number of polygons can have.\n"
"    -i <format>    Decide how the data is interleaved.\n"
"                   <format> can be: vtn vnt vt vn v\n"
"                   default is \"vtn\".  Means Vertex3Texture2Normal3.\n"
"    -I <format>    No interleaved data.  This will ignore the -i setting.\n"
"    -H             Enable header with format and size.  Default has no header.\n"
"                   The header struct will be descripted below.\n"
"    -b             Use -b to specify the header with big-endian for java.\n"
"EXAMPLE:\n"
"    For Android app,\n"
"        cat one.obj | obj2binary -H -b -i vtx -y -p 30 -o one.bin\n"
    );
}

enum FormatType parseFormat(const char * format) {
    if (strncmp(format, "vtn", 3) == 0)
        return FORMAT_V_VT_VN;
    else if (strncmp(format, "vnt", 3) == 0)
        return FORMAT_V_VN_VT;
    else if (strncmp(format, "vn", 2) == 0)
        return FORMAT_V_VN;
    else if (strncmp(format, "vt", 2) == 0)
        return FORMAT_V_VT;
    else if (strncmp(format, "v",1) == 0)
        return FORMAT_V;

    printf("Not supported format %3s\n", format);
    exit(-1);
}

size_t bytesByFormat(enum FormatType f) {
    switch (f) {
    case FORMAT_V:
        return 3 * sizeof(float);
    case FORMAT_V_VT:
        return (3+2) * sizeof(float);
    case FORMAT_V_VN:
        return (3+3) * sizeof(float);
    case FORMAT_V_VT_VN:
        return (3+2+3) * sizeof(float);
    case FORMAT_V_VN_VT:
        return (3+3+2) * sizeof(float);
    default:
        return 0;
    }
}

/* write a 32 bit little-endian integer */
void write32(FILE *out, unsigned int p)
{
	unsigned char q[4];
	q[0] = (p >> 24) & 0xFF;
	q[1] = (p >> 16) & 0xFF;
	q[2] = (p >> 8) & 0xFF;
	q[3] = p & 0xFF;
	fwrite(q, 1, 4, out);
	return;
}

int main(int argc, char ** argv) {
    puts("obj2binary");
    int opt;
    const char * outputfile = NULL;
    invertX = false;
    invertY = false;
    interleaved = true;
    needHeader = false;
    maxPolygon = 16;
    bool littleEndian = true;

    dataFormat = FORMAT_V_VT_VN;

    while ((opt = getopt(argc, argv, "i:I:hbHp:vxyo:")) != -1) {
        switch (opt) {
        case 'x':
            invertX = true;
            printf("invertX\n");
            break;
        case 'y':
            invertY = true;
            printf("invertY\n");
            break;
        case 'o':
            outputfile = optarg;
            printf("output to %s\n", outputfile);
            break;
        case 'v':
            verbose = true;
            break;
        case 'i':
            dataFormat = parseFormat(optarg);
            printf("Interleaved format is %s (%X)\n", optarg, dataFormat);
            break;
        case 'I':
            dataFormat = parseFormat(optarg);
            interleaved = false;
            printf("Non interleaved format is %s (%X)\n", optarg, dataFormat);
            break;
        case 'h':
            usage();
            exit(0);
            break;
        case 'p':
            maxPolygon = atoi(optarg);
            printf("Max polygon size is %d\n", maxPolygon);
            if (maxPolygon < 4 || maxPolygon > 2560) {
                printf("Please let the max polygon, p: \" 4 <= p <= 2560\"\n");
                exit(-1);
            }
            break;
        case 'b':
            littleEndian = false;
            printf("Header is Big-Endian\n");
            break;
        case 'H':
            needHeader = true;
            printf("Header is enabled.\n");
            break;
        default:
            break;
        }
    }

    indexType = new int [maxPolygon];
    indexTemp = new Index [maxPolygon];

    clear();
    yyparse();
    printf("\n\nWrite to file: %s\n", outputfile);
    if (outputfile != NULL) {
        FILE * f = fopen(outputfile, "w");
        if (f == NULL) {
            puts("Fail to open file");
            return -1;
        }
        header.vertices = output.size();
        header.dataBytes = output.size() * bytesByFormat(dataFormat);
        header.format = dataFormat | (interleaved ? 0x0 : FORMAT_NONINTERLEAVED);
        header.hasVT = !!(dataFormat & FORMAT_VT_MASK);
        header.vtOffset = (dataFormat & FORMAT_VT_MASK) >> FORMAT_VT_SHIFT;
        header.hasVN = !!(dataFormat & FORMAT_VN_MASK);
        header.vnOffset = (dataFormat & FORMAT_VN_MASK) >> FORMAT_VN_SHIFT;
        header.dataOffset = sizeof(BinaryHeader);

        printf("Object Infomation:\n");
        printf("  Vertics:  %lu\n", vList.size());
        printf("  Normals:  %lu\n", vnList.size());
        printf("  TexCoords: %lu\n", vtList.size());
        printf("  Triangles: %u\n", header.vertices);
        printf("  dataBytes: %u\n", header.dataBytes);
        if (needHeader) {
            if (littleEndian) {
                fwrite(((const void*) &header), sizeof(header), 1, f);
            } else {
                write32(f, header.vertices);
                write32(f, header.dataBytes);
                write32(f, header.format);
                write32(f, header.hasVT);
                write32(f, header.vtOffset);
                write32(f, header.hasVN);
                write32(f, header.vnOffset);
                write32(f, header.dataOffset);
            }
        }

        if (interleaved) {
            for (int i = 0; i < output.size(); i++) {
                // Interleaved
                const InterlacedTriangle& t = output[i];

                // Vertex
                fwrite(&t.v, sizeof(Vertex), 1, f);

                // TextureCoord
                if (header.hasVT && (dataFormat != FORMAT_V_VN_VT))
                    fwrite(&t.vt, sizeof(TextureCoord), 1, f);

                // Normal
                if (header.hasVN)
                    fwrite(&t.vn, sizeof(Normal), 1, f);

                // TextureCoord for V_VN_VT
                if (header.hasVT && (dataFormat == FORMAT_V_VN_VT))
                    fwrite(&t.vt, sizeof(TextureCoord), 1, f);
            }
        } else {
            // TODO
            // NonInterleaved
            printf("Sorry, We don't support non-interleaved format now.\n");
        }
        fclose(f);
        f = NULL;
    }
//    delete [] indexType;
//    indexType = NULL;
//    delete [] indexTemp;
//    indexTemp = NULL;
    return 0;
}


