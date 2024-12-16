#!/bin/bash
set -e

##
# Pre-requirements:
# - env FUZZER: path to fuzzer work dir
##

if [ ! -d "$FUZZER/repo" ]; then
    echo "fetch.sh must be executed first."
    exit 1
fi

# libpath_reduction.so should be compiled on host, since it fails in docker container
pushd "$FUZZER/repo"
git submodule update --init fuzzing_support/path-cov/
pushd fuzzing_support/path-cov/
git checkout fx-no-tail-opt
git pull origin fx-no-tail-opt
cargo build --release
cp target/release/libpath_reduction.so ../../
popd
popd

