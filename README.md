Enables the conversion of a dynamically linked binary to a statically linked binary by removing symbols from the GOT. It requires remill/mcsema, available at https://github.com/trailofbits/mcsema, to lift the dynamically linked binary to LLVM IR.  

Dependencies: IDA Pro or binary Ninja, llvm, clang, python, binutils

It supports binaries compiled with clang and musl-gcc.

Just run dynamic_to_static.sh with the path to the binary as an argument.

To see a fully working example just run test.sh after installing the dependencies.
