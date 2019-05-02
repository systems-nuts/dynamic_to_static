#!/bin/bash

# simple script to process from dyamically linked binary to statically linked
# binary, it supports clang, gcc, and musl-gcc
#
# Antonio Barbalace, Stevens 2019

#config parameters
DISASSEMBLER=~/ida-7.2/idat64
ARCH="amd64"
#COMPILER="musl-gcc"
DEFAULT_COMPILER="clang"
TARGET="aarch64-linux-gnu"

MCSEMA_DIS="mcsema-disass"
MCSEMA_LIFT="mcsema-lift-4.0"



### input arguments
#echo "Usage: $0 [-I inputArch] [-O outputArch] [-C input_compiler] [-T target compiler] binary"
# TODO here get a binary in, chek if it is a binary or not
# with input params you can enforce what is automatically discover by ... 
# TODO autoidentify inputArch
# TODO heuristic to identify the compiler, a compiler for recompilation can be enforced 


INPUT_FILE="tests/loop.c"
# TODO check file extension
PATH_FILE=${INPUT_FILE%.*}

${COMPILER} -o ${PATH_FILE}.${ARCH} ${INPUT_FILE}
# TODO check if error



#heuristic to identify the compiler
COMPILERS="clang GCC"
LIBRARIES="musl"
for COMP in $COMPILERS ; do
  if [ readelf -p .comment hello.clang

  
  NOOOOOOOOOOOOOOOOOOOO WE DON'T USE THE PROGRAM NOTATION IN THIS ANYMORE!!! :-(

  
  echo " hiogeqhwHOHOIHO" | tr '[:upper:]' '[:lower:]'

  
  

# TODO this must be overwritten by the input command line

# fix the ARCH naming thingy


#then disassemble
OUTPUT=$( ${MCSEMA_DIS} --disassembler ${DISASSEMBLER} --os linux --arch ${ARCH} --output ${PATH_FILE}.${ARCH}.cfg --binary ${PATH_FILE}.${ARCH} --entrypoint main --log_file ${PATH_FILE}.${ARCH}.log 2>&1 )
if [ $? != 0 ] ; then
  echo "disassembler ERROR: $OUTPUT"
  exit 1
fi

#then lifting
OUTPUT=$( ${MCSEMA_LIFT} --os linux --arch ${ARCH} --cfg ${PATH_FILE}.${ARCH}.cfg --output ${PATH_FILE}.${ARCH}.bc --explicit_args 2>&1)
if [ $? != 0 ] ; then
  echo "lifter ERROR: $OUTPUT"
  exit 1
fi

#now need to look for the GOT table in order to extract the functions
OUTPUT=$( llvm-dis ${PATH_FILE}.${ARCH}.bc 2>&1 )
if [ $? != 0 ] ; then
  echo "llvm-dis ERROR: $OUTPUT"
  exit 1
fi
#saving the old files so that they can be accessed later
mv ${PATH_FILE}.${ARCH}.bc ${PATH_FILE}.${ARCH}.bc-orig
mv ${PATH_FILE}.${ARCH}.ll ${PATH_FILE}.${ARCH}.ll-orig

#fixing the got table
./fix_got_plt.py ${COMPILER} ${PATH_FILE}.${ARCH}.ll-orig &> ${PATH_FILE}.${ARCH}.ll 
if [ $? != 0 ] ; then
  echo "fixer ERROR: " `cat ${PATH_FILE}.${ARCH}.ll`
  rm ${PATH_FILE}.${ARCH}.ll
  exit 1
fi

#compiling back to bitcode (I am doing that because I had errors without doing this ...)
OUTPUT=$( llvm-as ${PATH_FILE}.${ARCH}.ll 2>&1 )
if [ $? != 0 ] ; then
  echo "llvm-as ERROR: $OUTPUT"
  exit 1
fi

#recompile it to ARCH and TARGET
OUTPUT=$( clang -c -v ${PATH_FILE}.${ARCH}.bc -o ${PATH_FILE}.${ARCH}.o 2>&1 )
if [ $? != 0 ] ; then
  echo "llvm-as ERROR: $OUTPUT"
  exit 1
fi



${COMPILER} -o ${PATH_FILE}.${ARCH}-${ARCH} ${PATH_FILE}.${ARCH}.o -static

# TODO as names I suggest .lifted[*] and .lifted-amd64 and .lifted-aarch64

# TODO not sure how to handle multiple compilers 
clang -o ${PATH_FILE}.${ARCH}-target -c -v ${PATH_FILE}.${ARCH}.bc -target ${TARGET}
${COMPILER} -o ${PATH_FILE}.${ARCH}-aarch64 ${PATH_FILE}.${ARCH}-target -target ${TARGET} -static
# TODO fix the above based on this one
