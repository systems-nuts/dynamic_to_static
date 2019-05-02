#!/bin/bash

# simple example to test compilation
#
# Antonio Barbalace, Stevens 2019

INPUT_FILE="tests/loop.c"
#INPUT_FILE="tests/hello.c"
PATH_FILE=${INPUT_FILE%.*}

#config parameters
DISASSEMBLER=~/ida-7.2/idat64
ARCH="amd64"
#COMPILER="musl-gcc"
COMPILER="clang"
TARGET="aarch64-linux-gnu"

#compile first
${COMPILER} -o ${PATH_FILE}.${ARCH} ${INPUT_FILE}

#then disassemble
mcsema-disass --disassembler ${DISASSEMBLER} --os linux --arch ${ARCH} --output ${PATH_FILE}.${ARCH}.cfg --binary ${PATH_FILE}.${ARCH} --entrypoint main --log_file ${PATH_FILE}.${ARCH}.log

#then lifting
mcsema-lift-4.0 --os linux --arch ${ARCH} --cfg ${PATH_FILE}.${ARCH}.cfg --output ${PATH_FILE}.${ARCH}.bc --explicit_args

#now need to look for the GOT table in order to extract the functions
llvm-dis ${PATH_FILE}.${ARCH}.bc
mv ${PATH_FILE}.${ARCH}.bc ${PATH_FILE}.${ARCH}.bc-orig
mv ${PATH_FILE}.${ARCH}.ll ${PATH_FILE}.${ARCH}.ll-orig
./fix_got_plt.py ${COMPILER} ${PATH_FILE}.${ARCH}.ll-orig > ${PATH_FILE}.${ARCH}.ll
llvm-as ${PATH_FILE}.${ARCH}.ll

#recompile it to ARCH 
clang -o ${PATH_FILE}.${ARCH}.o -c -v ${PATH_FILE}.${ARCH}.bc 
${COMPILER} -o ${PATH_FILE}.${ARCH}-${ARCH} ${PATH_FILE}.${ARCH}.o -static

#recompile it to TARGET
clang -o ${PATH_FILE}.${ARCH}-aarch64.o -c -v ${PATH_FILE}.${ARCH}.bc -target ${TARGET}
${COMPILER} -o ${PATH_FILE}.${ARCH}-aarch64 ${PATH_FILE}.${ARCH}-aarch64.o -static -target ${TARGET}

#run the ARCH binary
echo "RUNNING on ${ARCH}"
${PATH_FILE}.${ARCH}-${ARCH}

#run the TARGET binary
echo "RUNNING on aarch64"
qemu-aarch64 ${PATH_FILE}.${ARCH}-aarch64
