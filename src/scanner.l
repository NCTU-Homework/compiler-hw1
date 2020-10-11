%{
#include <stdint.h>
#include <string.h>

/*
#define LIST()                strCat(yytext)
#define TOKEN(t)            { LIST; if (opt_tok) printf("<%s>\n", #t); }
#define TOKEN_CHAR(t)       { LIST; if (opt_tok) printf("<%c>\n", (t)); }
#define TOKEN_STRING(t, s)  { LIST; if (opt_tok) printf("<%s: %s>\n", #t, (s)); }
*/
#define ls { if (opt_src) strcat(buffer, yytext); }
#define printtok(...) if (opt_tok) { printf( __VA_ARGS__); }

#define tokoct(t)       { ls;  printtok("<oct_integer: %s>\n", t); }
#define tokdec(t)       { ls;  printtok("<integer: %s>\n", t); }
#define tokfloat(t)     { ls;  printtok("<float: %s>\n", t); }
#define toksc(t)        { ls;  printtok("<scientific: %s>\n", t); }

#define tokid(t)        { ls;  printtok("<id: %s>\n", t); }
#define tokkw(t)        { ls;  printtok("<KW%s>\n", t); }  
#define tokdelim(t)     { ls;  printtok("<%s>\n", t); }
#define tokoper(t)      { ls;  printtok("<%s>\n", t); }
#define tokstr(t)       { ls;  printstr(t); }
 
#define MAX_LINE_LENG 4096
uint32_t line_num = 1;
char buffer[MAX_LINE_LENG];

static int opt_src = 1;
static int opt_tok = 1;

static void printstr(const char *t);

%}

%x C_COMMENT

%%

\n {
    if (opt_src) {
        printf("%d: %s\n", line_num, buffer);
    }
    ++line_num;
    buffer[0] = '\0';
}

"/*" { ls; BEGIN(C_COMMENT); }
<C_COMMENT>"*/" { ls; BEGIN(INITIAL); }
<C_COMMENT>. { ls; }
<C_COMMENT>\n { 
    if (opt_src) {
        printf("%d: %s\n", line_num, buffer);
    }
    ++line_num;
    buffer[0] = '\0';
 }

\/\/&S\+.* { opt_src = 1; ls; }
\/\/&S\-.* { opt_src = 0; ls; }
\/\/&T\+.* { opt_tok = 1; ls; }
\/\/&T\-.* { opt_tok = 0; ls; } 
\/\/.* { ls; }

array|begin|boolean|def|do|else|end|false|for|integer|if|of|print|read|real|string|then|to|true|return|var|while { tokkw(yytext); }
[,;:\(\)\[\]] { tokdelim(yytext); }
[+\-/*<>=]|<=|>=|<>|:=|and|or|not|mod { tokoper(yytext); }

[1-9][0-9]*(\.(0|0*[1-9]+))?[Ee][+-]?(0|[1-9][0-9]*) { toksc(yytext); }
(0|[1-9][0-9]*)\.(0|0*[1-9]+) { tokfloat(yytext); }
0[0-7]+ { tokoct(yytext); }
0|[1-9][0-9]* { tokdec(yytext); }

\"([\t !#-~]|(\"\"))*\" { tokstr(yytext); }
[a-zA-Z][1-9a-zA-Z]* { tokid(yytext); }
[ \t] { ls; }

    /* Catch the character which is not accepted by rules above */
. {
    printf("Error at line %d: bad character \"%s\"\n", line_num, yytext);
    exit(-1);
}
 
%%

static void printstr(const char* t) {
    static char buf[MAX_LINE_LENG];
    if (!opt_tok) return;
    
    t++;
    char *p = buf;
    while (*t) {
        if (*t == '\"') { if(*(t + 1) == '\"') { *p = '\"'; t += 2; p++; } else { t++; } }
        else { *p = *t; t++; p++; }
    }
    *p = '\0';
    printf("<string: %s>\n", buf); 
}

/*
static void strCat(const char *Text) {
    while (*Text) {
        *buffer_ptr++ = *Text++;
    }
    *buffer_ptr = '\0';
}
*/

int main(int argc, const char **argv) {
    if (argc != 2) {
        fprintf(stderr, "Usage: ./scanner [filename]\n");
        exit(-1);
    }

    yyin = fopen(argv[1], "r");
    if (yyin == NULL) {
        fprintf(stderr, "Open file error\n");
        exit(-1);
    }

    yylex();

    return 0;
}
