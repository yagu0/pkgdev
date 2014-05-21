# Functions to assert that a condition is true or false in C tests

# Macros to pass file name and line number (in user files [TOFIX])
#define ASSERT_TRUE(x,y) assertTrue(__FILE__,__LINE__,x,y)
#define ASSERT_FALSE(x,y) assertFalse(__FILE__,__LINE__,x,y)

CunitTestsMacros = '
#include <stdlib.h>
#include <stdio.h>

// Functions to assert that a condition is true or false [to be extended]
void assertTrue(char* fileName, int lineNumber, int condition, char* message) {
    if (!condition) {
        printf(">>> Failure in file %s at line %i: %s\\n", fileName, lineNumber, message);
    }
}

void assertFalse(char* fileName, int lineNumber, int condition, char* message) {
    assertTrue(fileName, lineNumber, !condition, message);
}
'
