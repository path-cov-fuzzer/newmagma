#!/bin/bash
set -e

##
# Pre-requirements:
# - env FUZZER: path to fuzzer work dir
# - env TARGET: path to target work dir
# - env MAGMA: path to Magma support files
# - env OUT: path to directory where artifacts are stored
# - env CFLAGS and CXXFLAGS must be set to link against Magma instrumentation
##

export CC="$FUZZER/repo/afl-clang-fast"
export CXX="$FUZZER/repo/afl-clang-fast++"
export AS="llvm-as"

export LIBS="$LIBS -lc++ -lc++abi $FUZZER/repo/utils/aflpp_driver/libAFLDriver.a"

# AFL++'s driver is compiled against libc++
export CXXFLAGS="$CXXFLAGS -stdlib=libc++"

# Build the AFL-only instrumented version
(
    export OUT="$OUT/afl"
    export LDFLAGS="$LDFLAGS -L$OUT"

    # WHATWEADD: add my own environment variable -------------- start
    export BBIDFILE="$OUT/bbid.txt"
    export CALLMAPFILE="$OUT/callmap.txt"
    export CFGFILE="$OUT/cfg.txt"
    export AFL_LLVM_CALLER=1
    export AFL_USE_ASAN=1
    export LD_LIBRARY_PATH="$FUZZER/repo/"
    # WHATWEADD: add my own environment variable -------------- end

    "$MAGMA/build.sh"
    "$TARGET/build.sh"
)

# Build the CmpLog instrumented version

(
    export OUT="$OUT/cmplog"
    export LDFLAGS="$LDFLAGS -L$OUT"
    # export CFLAGS="$CFLAGS -DMAGMA_DISABLE_CANARIES"

    # WHATWEADD: add my own environment variable -------------- start
    export AFL_LLVM_CALLER=1
    export LD_LIBRARY_PATH="$FUZZER/repo/"
    # WHATWEADD: add my own environment variable -------------- end

    export AFL_LLVM_CMPLOG=1

    "$MAGMA/build.sh"
    "$TARGET/build.sh"
)

# NOTE: We pass $OUT directly to the target build.sh script, since the artifact
#       itself is the fuzz target. In the case of Angora, we might need to
#       replace $OUT by $OUT/fast and $OUT/track, for instance.

# generate CFG of PROGRAM
(
    export OUT="$OUT/afl"
    g++ -I"$FUZZER/repo/fuzzing_support" "$FUZZER/repo/fuzzing_support/convert.cpp" -o "$OUT/convert"
    bash $FUZZER/generateCFG.sh
)

