#!/bin/bash

export CFLAGS="$CFLAGS -Wno-error=implicit-function-declaration"
export CXXFLAGS="$CXXFLAGS -Wno-error=implicit-function-declaration"

cd $TARGET/repo
autoreconf -f -i
# make clean &> /dev/null
make clean
# ./configure --prefix=`pwd`/lava-install LIBS="-lacl" &> /dev/null
./configure --prefix=`pwd`/lava-install LIBS="-lacl"
# make -j $(nproc) &> /dev/null
make -j $(nproc)
cd ..

cp src/who $OUT/who

