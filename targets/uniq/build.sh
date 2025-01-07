#!/bin/bash
set -e

##
# Pre-requirements:
# - env TARGET: path to target work dir
# - env OUT: path to directory where artifacts are stored
# - env CC, CXX, FLAGS, LIBS, etc...
##

if [ ! -d "$TARGET/repo" ]; then
    echo "fetch.sh must be executed first."
    exit 1
fi

# store env varialbes
export CCAUX=$CC
export CXXAUX=$CXX
export FLAGSAUX=$FLAGS
export LIBSAUX=$LIBS

# configure 
pushd "$TARGET/repo"
autoreconf -f -i
# make clean &> /dev/null
make clean
# ./configure --prefix=`pwd`/lava-install LIBS="-lacl" &> /dev/null
./configure --prefix=`pwd`/lava-install LIBS="-lacl"
popd

# restore env varialbes
export CC=$CCAUX
export CXX=$CXXAUX
export FLAGS=$FLAGSAUX
export LIBS=$LIBSAUX

# compile code
pushd "$TARGET/repo"
make clean
# rm src/uniq
export CFLAGS="$CFLAGS -I. -I./lib -Ilib -I./lib -Isrc -I./src -O2 -Wno-error=implicit-function-declaration"
export CXXFLAGS="$CXXFLAGS -I. -I./lib -Ilib -I./lib -Isrc -I./src -O2 -Wno-error=implicit-function-declaration"
make -e -j $(nproc)
cp src/uniq $OUT/uniq
popd



