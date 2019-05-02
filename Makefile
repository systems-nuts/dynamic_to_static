#!/bin/bash

# execute the whole process from compilation 
#
# Antonio Barbalace, Stevens 2019

INPUT_FILE="loop.c"
# TODO check file extension
PATH_FILE=${INPUT_FILE%.*}



Configure your compiler
first
support both clang and musl -libc




#compile first
${COMPILER} -o ${PATH_FILE}.${ARCH} ${INPUT_FILE}
# TODO check if error




TODO this should be a makefile
