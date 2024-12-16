#!/bin/bash

cd $TARGET/repo
autoreconf -f -i
# make clean &> /dev/null
make clean
# ./configure --prefix=`pwd`/lava-install LIBS="-lacl" &> /dev/null
./configure --prefix=`pwd`/lava-install LIBS="-lacl"
# make -j $(nproc) &> /dev/null
make -j $(nproc) 
cd ..

