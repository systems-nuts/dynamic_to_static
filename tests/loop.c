/* ghidra test with integers only */

#include <stdio.h>
#include <unistd.h>

#define A 'a'
#define FIVE 5
#define PI 3

int total =3;
static int average =PI;

long long int mypow(long x, long y) {
    return x*y;
}

int bob(int a, long b, char c) {
    a++;
    b+=a; 
    char string[200];
    sprintf(string, "a=%d, b=%ld, c=%c\n", a, b, c);
    printf(string);
    total++;
    average /= total;
    fprintf(stderr, "total=%d average=%d\n", total, average);
    return a;
}

int hello() {
    printf("Hello World!\n");
    bob(42, PI, A);
    return FIVE;
}

float goodbye() {
    printf("Goodbye World!\n");
    bob(42, PI, A);
    return FIVE;
}

int main () {
    int i = 0;
    int looper = 0;
    hello();
    for (; i < 5; ++i) {
        printf("\ti = %d\n", i);
    }
    goodbye();
    bob(42, 2, 'x');
    printf("mypow: %lld\n", mypow(2,3));
    for (int j =0; j< 5; j++) {
        printf("sleep looper=%d\n", ++looper);
        sleep(1);
    }
    return 1;
}
