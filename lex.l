%{
#include <stdlib.h>
#include "bison.hpp"
void yyerror(char *);
%}

%%
    /* variables */

    /* Vertex */
^v {
    printf("v ");
    return VERTEX;
}

^vn {
    printf("vn ");
    return NORMAL;
}

^vt {
    printf("vt ");
    return TEXTURE;
}

^f {
    printf("f ");
    return FACE;
}

^s.* ;
^g.* ;
^mtllib.* ;
^usemtl.* ;

    /* integers */
[-+]?[0-9]+ {
    printf("i");
    yylval.i = atoi(yytext);
    return INTEGER;
}

    /* float */
[-+]?[0-9]+\.?[0-9]+ {
    printf("f");
    yylval.f = atof(yytext);
    return FLOAT;
}

    /* token */
[0-9\.]*[a-zA-Z_]* {
}
    /* token */
[a-zA-Z_]*[0-9\.]* {
}

    /* token */
\/ {
    printf("/");
    return '/';
}

    /* comment */
#.*\n ;

    /* skip whitespace */
[ \t] ;
\n {
    printf("\n");
};

    /* anything else is an error */
. {
};

%%

int yywrap(void) {
    return 1;
}