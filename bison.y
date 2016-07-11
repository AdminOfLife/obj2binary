%{
#include <stdio.h>
#include <stdlib.h>
#include <vector>
#include <vector>
#include "type.h"
#include "bison.hpp"

using namespace std;

extern int yylex(void);
extern void yyerror(char *);
#define POLYGON_MAX 8

vector<Vertex> vList;
vector<Normal> vnList;
vector<TextureCoord> vtList;

int polygonCount;
int faceType;
int indexType[POLYGON_MAX];
Index indexTemp[POLYGON_MAX];

vector<InterlacedTriangle> output;

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
        puts("\n*** Face type not consist ");
    for (int i = 1; i < polygonCount; i++) {
        if (first != indexType[i]) {
            puts("Syntax error: Index type not consist");
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
        puts("vi out of range");
        return triangle;
    } else {
        const Vertex & v = vList[idx.vi];
        //printf("v%d(%5f %5f %5f)\n", idx.vi, v.v[0], v.v[1], v.v[2]);
        triangle.v = v;
    }

    if (idx.vni == -1) {
        if (idx.vni >= vnList.size()) {
            puts("vni out of range");
            return triangle;
        } else {
            const Normal & vn = vnList[idx.vni];
            //printf("n%d(%5f %5f %5f)\n", idx.vni, vn.v[0], vn.v[1], vn.v[2]);
            triangle.vn = vn;
        }
    }

    if (idx.vti != -1) {
        if (idx.vti >= vtList.size()) {
            puts("vti out of range");
            return triangle;
        } else {
            const TextureCoord & vt = vtList[idx.vti];
            //printf("vt%d(%5f %5f)\n", idx.vti, vt.v[0], vt.v[1]);
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
    void yyerror(char *);
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
        //printf("v %6f %6f %6f\n", $2, $3, $4);
    }
    ;

normal:
    NORMAL FLOAT FLOAT FLOAT {
        vnList.push_back(Normal{.v={$2, $3, $4}});
        //printf("vn %6f %6f %6f\n", $2, $3, $4);
    }
    ;

texture:
    TEXTURE FLOAT FLOAT FLOAT {
        // don't care the z value
        vtList.push_back(TextureCoord{.v={$2, $3}});
        //printf("vt %6f %6f %6f\n", $2, $3, $4);
    }
    | TEXTURE FLOAT FLOAT {
        vtList.push_back(TextureCoord{.v={$2, $3}});
        //printf("vt %6f %6f\n", $2, $3);
    }
    ;

face:
    face_triangle {
        //printf("P%d ", polygonCount);
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
        //printf("P%d ", polygonCount);
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
        //printf("%d ", $1);
    }
    | INTEGER '/' INTEGER '/' INTEGER {
        indexType[polygonCount] = IT_V_VT_VN;
        indexTemp[polygonCount] = Index{.vi=$1 - 1, .vti=$3 - 1, .vni=$5 - 1};
        polygonCount++;
        //printf("%d/%d/%d ", $1, $3, $5);
    }
    | INTEGER '/' '/' INTEGER {
        indexType[polygonCount] = IT_V_VN;
        indexTemp[polygonCount] = Index{.vi=$1 - 1, .vti=-1, .vni=$4 - 1};
        polygonCount++;
        //printf("%d//%d \n", $1, $4);
    }
    | INTEGER '/' INTEGER {
        indexType[polygonCount] = IT_V_VT;
        indexTemp[polygonCount] = Index{.vi=$1 - 1, .vti=$3 - 1, .vni=-1};
        polygonCount++;
        //printf("%d/%d \n", $1, $3);
    }
    ;

%%

void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}

void usage() {
    printf("\n");
}

void init() {
}

int main(int argc, char ** argv) {
    usage();
    init();
    clear();
    yyparse();
    if (argc == 2) {
        FILE * f = fopen(argv[1], "w");
        if (f == NULL) {
            puts("Fail to open file");
            return -1;
        }
        for (int i = 0; i < output.size(); i++) {
            fwrite(((const float *) (&output[i])), sizeof(InterlacedTriangle), 1, f);
        }
        fclose(f);
        f = NULL;
    }
    return 0;
}


