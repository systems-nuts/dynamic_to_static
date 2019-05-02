Converts a dynamically compiled binary to a statically compiled binary by removing symbols from the GOT. It requires remill/mcsema, available at https://github.com/trailofbits/mcsema . (Requires IDA Pro or binary Ninja, llvm, and clang.)
Other dependencies: python, binutils.

It supports binaries compiled with clang and musl-gcc.

Just run dynamic_to_static.sh with the path to the binary as an argument.

To see a fully working example just run test.sh
