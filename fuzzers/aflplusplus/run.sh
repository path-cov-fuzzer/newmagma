#!/bin/bash

##
# Pre-requirements:
# - env FUZZER: path to fuzzer work dir
# - env TARGET: path to target work dir
# - env OUT: path to directory where artifacts are stored
# - env SHARED: path to directory shared with host (to store results)
# - env PROGRAM: name of program to run (should be found in $OUT)
# - env ARGS: extra arguments to pass to the program
# - env FUZZARGS: extra arguments to pass to the fuzzer
##

mkdir -p "$SHARED/findings"

flag_cmplog=(-m none -c "$OUT/cmplog/$PROGRAM")

export AFL_SKIP_CPUFREQ=1
export AFL_NO_AFFINITY=1
export AFL_NO_UI=1
export AFL_MAP_SIZE=256000
export AFL_DRIVER_DONT_DEFER=1

# WHATWEADD: solve the /proc/sys/kernel/core_pattern problem
export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1

"$FUZZER/repo/afl-fuzz" -s 1234 -i "$TARGET/corpus/$PROGRAM" -o "$SHARED/findings" \
    $FUZZARGS -- "$OUT/afl/$PROGRAM" $ARGS 2>&1

#     "${flag_cmplog[@]}" -d \
