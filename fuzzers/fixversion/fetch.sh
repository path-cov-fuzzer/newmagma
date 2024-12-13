#!/bin/bash
set -e

##
# Pre-requirements:
# - env FUZZER: path to fuzzer work dir
##

git clone --branch pathfuzzerreduction https://github.com/path-cov-fuzzer/newpathAFLplusplus.git "$FUZZER/repo"


