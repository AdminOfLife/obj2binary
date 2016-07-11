%{
#include <stdio.h>
#include <vector>
#include "bison.hpp"

using namespace std;

extern int yylex(void);
extern void yyerror(char *);
#define POLYGON_MAX 8

struct Vertex {
    float v[3];
};

struct Normal {
    float v[3];
};

struct TextureCoord {
    float v[2];
};

vector<Vertex> v;
vector<Normal> vn;
vector<TextureCoord> vt;

int faceType;
int polygonCount;
int viArray[POLYGON_MAX];
int vtiArray[POLYGON_MAX];
int vniArray[POLYGON_MAX];

void clear() {
    v.clear();
    vn.clear();
    vt.clear();
}

%}

%union
{
    int i;
    float f;
}

%token FLOAT INTEGER VERTEX TEXTURE NORMAL FACE SECTION GROUP USEMTL MTLLIB

%type<i> INTEGER
%type<f> FLOAT

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
        v.push_back(Vertex{.v={$2, $3, $4}});
        printf("v %6f %6f %6f\n", $2, $3, $4);
    }
    ;

normal:
    NORMAL FLOAT FLOAT FLOAT {
        vn.push_back(Vertex{.v={$2, $3, $4}});
        printf("vn %6f %6f %6f\n", $2, $3, $4);
    }
    ;

texture:
    TEXTURE FLOAT FLOAT FLOAT {
        vt.push_back(Vertex{.v={$2, $3}});
        printf("vt %6f %6f %6f\n", $2, $3, $4);
    }
    | TEXTURE FLOAT FLOAT {
        vt.push_back(Vertex{.v={$2, $3}});
        printf("vt %6f %6f\n", $2, $3);
    }
    ;

face:
    face_triangle
    | face_line
    | face_polygon
    ;

face_line:
    FACE index_type index_type {
        printf("L");
    }
    ;

face_triangle:
    FACE index_type index_type index_type {
        printf("T");
    }
    ;

face_polygon:
    FACE index_type index_type index_type index_type {
        printf("P");
    }
    | face_polygon index_type {
    }
    ;

index_type:
    INTEGER {
        printf("%d ", $1);
    }
    | INTEGER '/' INTEGER '/' INTEGER {
        printf("%d/%d/%d ", $1, $3, $5);
    }
    | INTEGER '/' '/' INTEGER {
        printf("%d//%d \n", $1, $4);
    }
    | INTEGER '/' INTEGER {
        printf("%d/%d \n", $1, $3);
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

int main(void) {
    usage();
    init();
    clear();
    yyparse();
    return 0;
}


