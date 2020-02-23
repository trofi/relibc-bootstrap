This repository is an attempt to quickly build a toolchain and minimal environment to run binaries against relibc.

Quick start
-----------

0. Get `rustup` and fetch `nightly` toolchain.
1. Get binutils-gdb into ~/dev/binutils-gdb
2. Get gcc into ~/dev/gcc
3. Bootstrap toolchain in `./target/` with `./bootstrap-toolchain.bash`
4. Build example: `./mk-example.bash`
5. Run example: `./run-example.bash`
