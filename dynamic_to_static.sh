#!/bin/bash

# simple script to process from dyamically linked binary to statically linked
# binary, it supports clang, gcc, and musl-gcc
#
# Antonio Barbalace, Stevens 2019


#remill/mcsema parameters
DISASSEMBLER=~/ida-7.2/idat64
MCSEMA_DIS="mcsema-disass"
MCSEMA_LIFT="mcsema-lift-4.0"

arch_name()
{
  ARCH_NAME_ARG1=$1
  #extract homogeneous names for architectures
  case "$ARCH_NAME_ARG1" in
    arm*) ARCH_NAME="arm" ;;
    aarch64*) ARCH_NAME="aarch64" ;;
    i?86*) ARCH_NAME="i386" ;;
    x86-64*|x86_64*|amd64*) ARCH_NAME="amd64" ;;
    unknown) echo "target selection ERROR $ARCH_NAME_ARG1" ; exit 1 ; ;;
    *) echo "unknown or unsupported target ERROR $ARCH_NAME_ARG1" ; exit 1 ; ;;
  esac
}

#the compiler for the static linking
DEFAULT_COMPILER="clang"
#the triple for the static linking
DEFAULT_TARGET_TRIPLE=`clang -dumpmachine`


###############################################################################
# main
###############################################################################

usage()
{
  echo "Usage: $0 [-C sourceCompiler] [-t targetTriple] [-c targetCompiler] binary"
  exit 0
}

#check the number of arguments, at least one
[ $# -le 0 ] && usage

#parse command line arguments
while getopts "ht:C:c:" OPT ; do
  case ${OPT} in
    t) TARGET_TRIPLE=$OPTARG ;;
    C) SRC_COMPILER=$OPTARG ;;
    c) TARGET_COMPILER=$OPTARG ;;
    *) usage ;;
  esac
done
shift "$((OPTIND -1))"
INPUT_FILE="$@"

#check if the file exists
if [ ! -f "$INPUT_FILE" ] ; then
  echo "file ERROR: ${INPUT_FILE} doesn't exist"
  exit 1
fi

#detect input file architecture from the binary, and create a copy
ARCH=`file $INPUT_FILE`
ARCH=${ARCH#*,}
ARCH=${ARCH%%,*}
if [ -z "$ARCH" ] ; then
  echo "arch ERROR: ${INPUT_FILE} cannot identify architecture"
  exit 1
fi
arch_name ${ARCH}
ARCH=${ARCH_NAME}
PATH_FILE=${INPUT_FILE}.${ARCH}
cp -a ${INPUT_FILE} ${PATH_FILE}

#check if the input file is a dynamically linked binary
if [ -z "`file ${PATH_FILE} | grep "dynamically linked"`" ] ; then
  echo "file ERROR: ${PATH_FILE} is not a dynamically linked binary"
  exit 1
fi

#heuristic to identify the compiler
COMPILERS="clang GCC"
LIBRARIES="musl"
for COMP in $COMPILERS ; do
  if [ ! -z "`readelf -p .comment ${PATH_FILE} | grep ${COMP}`" ] ; then
    AUTO_COMP=${COMP}
    for LIB in $LIBRARIES ; do
      if [ ! -z "`grep ${LIB} ${PATH_FILE}`" ] ; then
        AUTO_COMP=${LIB}-${AUTO_COMP}
      fi
    done
    break
  fi
done
AUTO_COMP=`echo $AUTO_COMP | tr '[:upper:]' '[:lower:]'`
#if heuristic search failed use default compiler
if [ -z "${AUTO_COMP}" ] ; then
  AUTO_COMP=$DEFAULT_COMPILER
  echo "Default src compiler: ${AUTO_COMP}" #cannot detect compiler
else
  echo "Detected src compiler: ${AUTO_COMP}"
fi
#check if the user declared what compiler he used
if [ -z "${SRC_COMPILER}" ] || [ ! -f "`which ${SRC_COMPILER}`" ] ; then
  SRC_COMPILER=${AUTO_COMP}
fi

#check target triple
if [ -z "${TARGET_TRIPLE}" ] ; then
  TARGET_TRIPLE=${DEFAULT_TARGET_TRIPLE}
fi
arch_name $TARGET_TRIPLE
TARGET_ARCH=$ARCH_NAME

#check target compiler
if [ -z "${TARGET_COMPILER}" ] ; then
  TARGET_COMPILER=${DEFAULT_COMPILER}
fi
  
  
###############################################################################
# Disassembling, lifting, fixing got/plt
###############################################################################

#then disassemble
OUTPUT=$( ${MCSEMA_DIS} --disassembler ${DISASSEMBLER} --os linux --arch ${ARCH} --output ${PATH_FILE}.cfg --binary ${PATH_FILE} --entrypoint main --log_file ${PATH_FILE}.log 2>&1 )
if [ $? != 0 ] ; then
  echo "disassembler ERROR: $OUTPUT"
  exit 1
fi

#then lifting
OUTPUT=$( ${MCSEMA_LIFT} --os linux --arch ${ARCH} --cfg ${PATH_FILE}.cfg --output ${PATH_FILE}.bc --explicit_args 2>&1)
if [ $? != 0 ] ; then
  echo "lifter ERROR: $OUTPUT"
  exit 1
fi

#now need to look for the GOT table in order to extract the functions
OUTPUT=$( llvm-dis ${PATH_FILE}.bc 2>&1 )
if [ $? != 0 ] ; then
  echo "llvm-dis ERROR: $OUTPUT"
  exit 1
fi
#saving the old files so that they can be accessed later
mv ${PATH_FILE}.bc ${PATH_FILE}.bc-orig
mv ${PATH_FILE}.ll ${PATH_FILE}.ll-orig

#fixing the got table
SCRIPT_PATH=$( readlink -f $0 )
${SCRIPT_PATH%/*}/fix_got_plt.py ${SRC_COMPILER} ${PATH_FILE}.ll-orig &> ${PATH_FILE}.ll 
if [ $? != 0 ] ; then
  echo "fixer ERROR: " `cat ${PATH_FILE}.ll`
  rm ${PATH_FILE}.ll
  exit 1
fi

#compiling back to bitcode (I am doing that because I had errors without doing this ...)
OUTPUT=$( llvm-as ${PATH_FILE}.ll 2>&1 )
if [ $? != 0 ] ; then
  echo "llvm-as ERROR: $OUTPUT"
  exit 1
fi

###############################################################################
# Recompiling to native
###############################################################################

echo Static compilation to ${TARGET_ARCH}

#recompile it to TARGET_ARCH
OUTPUT=$( clang -c -v ${PATH_FILE}.bc -target ${TARGET_TRIPLE} -o ${PATH_FILE}.${TARGET_ARCH}.o 2>&1 ) 
if [ $? != 0 ] ; then
  echo "llc ERROR: $OUTPUT"
  exit 1
fi

#static linking to TARGET_ARCH
OUTPUT=$( ${TARGET_COMPILER} -v -o ${PATH_FILE}-${TARGET_ARCH} -target ${TARGET_TRIPLE} ${PATH_FILE}.${TARGET_ARCH}.o -static 2>&1 )
if [ $? != 0 ] ; then
  echo "compiler ERROR: $OUTPUT"
  exit 1
fi

echo Output ${PATH_FILE}-${TARGET_ARCH}
