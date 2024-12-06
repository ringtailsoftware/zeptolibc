#ifndef TERMINAL_H
#define TERMINAL_H 1
#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdarg.h>

#define ssize_t int

typedef struct {
    int errno;
} FILE;

static int errno = 0;

static FILE stdin_file;
static FILE stdout_file;
static FILE stderr_file;

#define stdin &stdin_file
#define stdout &stdout_file
#define stderr &stderr_file

extern void *zepto_memcpy(void *dst, const void *src, size_t n);
extern void *zepto_memset(void *dst, char val, size_t n);
extern void zepto_print(char *s);
extern void *zepto_memmove(void *dst, const void *src, size_t n);
extern void *zepto_malloc(size_t n);
extern void zepto_free(void *p);
extern void *zepto_realloc(void *p, size_t n);
extern size_t zepto_strlen(const char *s);
extern char *zepto_strchr(const char *s, int c);
extern int zepto_snprintf(char * str, size_t size, const char *format,...);
extern int zepto_abs(int a);
extern int zepto_strncmp(const char *s1, const char *s2, size_t n);
extern int zepto_vsnprintf(char * str, size_t size, const char * format, va_list ap);
extern int zepto_fprintf(FILE *, const char * format, ...);
extern void zepto_abort(void);
extern void zepto_exit(int e);
extern char *zepto_strncpy(char * dst, const char * src, size_t len);
extern void *zepto_calloc(size_t n, size_t c);
extern double zepto_sin(double x);
extern double zepto_floor(double x);
extern double zepto_cos(double x);
extern double zepto_fabs(double x);
extern double zepto_sqrt(double x);
extern double zepto_pow(double x, double y);

extern int printf(const char * format, ...);

#define memcpy zepto_memcpy
#define memset zepto_memset
#define memmove zepto_memmove
#define malloc zepto_malloc
#define calloc zepto_calloc
#define free zepto_free
#define realloc zepto_realloc
#define strlen zepto_strlen
#define memcmp zepto_memcmp
#define mbrtowc zepto_mbrtowc
#define strchr zepto_strchr
#define atoi zepto_atoi
#define strcat zepto_strcat
#define strcpy zepto_strcpy
#define snprintf zepto_snprintf
#define abs zepto_abs
#define strncmp zepto_strncmp
#define vsnprintf zepto_vsnprintf
#define fprintf zepto_fprintf
#define abort zepto_abort
#define exit zepto_exit
#define strncpy zepto_strncpy
#define sin zepto_sin
#define floor zepto_floor
#define cos zepto_cos
#define fabs zepto_fabs
#define sqrt zepto_sqrt
#define pow zepto_pow

#endif

