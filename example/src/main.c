#include <zeptolibc/zeptolibc.h>

void cmain(void) {
    uint8_t *buf;
    const char *greeting = "Hello world\n";

    fprintf(stderr, "At the start\n");
    fprintf(stderr, "Printf test (10,foo,0xDEADBEEF) = (%d,%s,%x)\n", 10, "foo", 0xDEADBBEF);

    buf = malloc(128);
    if (buf == NULL) {
        fprintf(stderr, "Out of memory\n");
        return;
    }

    strncpy(buf, greeting, strlen(greeting)+1);

    printf("%s\n", buf);

    snprintf(buf, 128, "'The answer is: %d'\n", 42);
    printf("snprintf: %s\n", buf);

    free(buf);
}
