#include "zeptolibc.h"

void cmain(void) {
    uint8_t *buf;
    const char *greeting = "Hello world\n";

    buf = malloc(128);
    if (buf == NULL) {
        fprintf(stderr, "Out of memory\n");
        return;
    }

    strncpy(buf, greeting, strlen(greeting)+1);

    printf("%s\n", buf);
    free(buf);
}
