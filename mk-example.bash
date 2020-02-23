#!/bin/bash

# Notes:
# 1. We relocate text segment away from default ld64.so.1
#    Otherwise kernel fails to load both interpreter and binary itself.
#    TODO: find a piece of kernel that does it.
# 2. We set dynamic linker to relbc's one

PATH="$PWD/target/bin:$PWD/toolchain/bin:$PATH" \
    ./target/bin/x86_64-unknown-linux-relibc-gcc example.c -o example \
    \
    -Wl,-dynamic-linker,$PWD/target/lib/ld64.so.1 \
    -Wl,-Ttext-segment,0x80000 \
    "$@"
