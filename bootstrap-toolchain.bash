#!/bin/bash

# here is out process:
# 0. set build tree layout
# 1. install binutils
# 2. install gcc without libc support
# 3. install libc
# 4. install gcc with libc support

# Notes/hacks:
# 0. No need to patch external projects :)
# 1. Add a crt1.o -> crt0.o symlink to mimic glibc's interface for CSU against gcc
# 2. add a target/$TARGET -> . link for gcc to discover libc headers

set -e

# Assumptions:
# sources of gcc are in ~/dev/git/gcc
# sources on binutils are in ~/dev/git/binutils-gdb
# result toolchain and root is in ./target
# 'rustup' has 'nightly' toolchain available

BINUTILS_SOURCE_TREE=${HOME}/dev/git/binutils-gdb
GCC_SOURCE_TREE=${HOME}/dev/git/gcc
# where cross-compilers and target libraries/binaries live
# linked against both host and target
TARGET_PREFIX=${PWD}/target

     TARGET=x86_64-unknown-linux-relibc
RUST_TARGET=x86_64-unknown-linux-gnu

# speed up rebuilds
export CCACHE_DIR=${PWD}/ccache
mkdir -p "${CCACHE_DIR}"
export PATH="$(portageq envvar EPREFIX)/usr/lib/ccache/bin:${PATH}"
echo "PATH=$PATH"

# 0. set build tree layout

mkdir -p "${TARGET_PREFIX}"

# as we build gcc as a cross-compiler it searches headers and libs in $prefix/$target
# but we are lazy and install relibc to $prefix
[[ -L "${TARGET_PREFIX}/${TARGET}" ]] ||
ln -svf . "${TARGET_PREFIX}/${TARGET}"

# 1. binutils
[[ -f binutils-build.done ]] ||
(
    mkdir -p binutils-build
    pushd    binutils-build
    "${BINUTILS_SOURCE_TREE}"/configure \
        --target=$TARGET \
        --prefix="${TARGET_PREFIX}" \
        \
        --disable-gdb
    make -j $(nproc)
    make -j $(nproc) install
    popd
    touch binutils-build.done
)

export PATH="${TARGET_PREFIX}/bin:$PATH"
echo "PATH=$PATH"

# 2. install gcc without libc support

[[ -f gcc-no-libc.done ]] ||
(
    mkdir -p gcc-no-libc
    pushd    gcc-no-libc
    "${GCC_SOURCE_TREE}"/configure \
        --target=$TARGET \
        --prefix="${TARGET_PREFIX}" \
        --disable-bootstrap \
        --without-multilib \
        --disable-libgomp \
        --without-isl \
        --disable-libsanitizer \
        --disable-nls \
        --with-system-zlib \
        --disable-libstdcxx-pch \
        --disable-libssp \
        --disable-libquadmath \
        \
        --enable-languages=c \
        --disable-shared \
        --disable-threads \
        --without-headers \
        --disable-libatomic \
        --disable-libstdcxx-pch
    make -j $(nproc)
    make -j $(nproc) install
    popd
    touch gcc-no-libc.done
)

# 3. install libc

[[ -f relibc.done ]] ||
(
    [[ -d relibc ]] ||
    git clone --recurse-submodules https://gitlab.redox-os.org/redox-os/relibc
    pushd relibc
    ~/.cargo/bin/rustup run nightly \
    make install \
        DESTDIR=${TARGET_PREFIX} \
        CC="${TARGET_PREFIX}"/bin/${TARGET}-gcc \
        AR="${TARGET_PREFIX}"/bin/${TARGET}-ar \
        LD="${TARGET_PREFIX}"/bin/${TARGET}-ld \
        TARGET=${RUST_TARGET}
    popd
    touch relibc.done
)

# gcc assumes crt1.o to provide _start symbol, but relibc has it only in crt0.o.
ln -svf crt0.o "${TARGET_PREFIX}/lib/crt1.o"

# 4. install gcc with libc support

[[ -f gcc-with-libc.done ]] ||
(
    mkdir -p gcc-with-libc
    pushd    gcc-with-libc
    "${GCC_SOURCE_TREE}"/configure \
        --target=$TARGET \
        --prefix="${TARGET_PREFIX}" \
        --disable-bootstrap \
        --without-multilib \
        --disable-libgomp \
        --without-isl \
        --disable-libsanitizer \
        --disable-nls \
        --with-system-zlib \
        --disable-libstdcxx-pch \
        --disable-libssp \
        --disable-libquadmath \
        \
        --enable-languages=c \
        --disable-libstdcxx-pch \
        --with-multilib-list=m64 \
        \
        --disable-libatomic \
        --disable-libstdcxx-pch
    make -j $(nproc)
    make -j $(nproc) install
    popd
    touch gcc-with-libc.done
)

# 5. gdb
[[ -f gdb-build.done ]] ||
(
    mkdir -p gdb-build
    pushd    gdb-build
    "${BINUTILS_SOURCE_TREE}"/configure \
        --target=$TARGET \
        --prefix="${TARGET_PREFIX}" \
        \
        --enable-gdb
    make -j $(nproc)
    make -j $(nproc) install
    popd
    touch gdb-build.done
)
