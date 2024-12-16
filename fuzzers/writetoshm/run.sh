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
# WHATWEADD: pathfuzz relative settings
export CFG_BIN_FILE="$OUT/afl/${PROGRAM}_cfg.bin"
export LD_LIBRARY_PATH="$FUZZER/repo/"
# zekun says 42 is a new algorithm
export K=42

# copy cfg.txt for debugging purpose
cp $OUT/afl/cfg_${PROGRAM}.txt $SHARED/cfg_${PROGRAM}.txt 
cp $OUT/afl/callmap_${PROGRAM}.txt $SHARED/callmap_${PROGRAM}.txt 
cp $OUT/afl/${PROGRAM}_function_list.txt $SHARED/${PROGRAM}_function_list.txt 
cp $OUT/afl/${PROGRAM}_cfg.bin $SHARED/${PROGRAM}_cfg.bin

"$FUZZER/repo/afl-fuzz" -i "$TARGET/corpus/$PROGRAM" -o "$SHARED/findings" \
    $FUZZARGS -M Master -- "$OUT/afl/$PROGRAM" $ARGS 2>&1 &

"$FUZZER/repo/afl-fuzz" -i "$TARGET/corpus/$PROGRAM" -o "$SHARED/findings" \
    $FUZZARGS -S Slave1 -- "$OUT/afl/$PROGRAM" $ARGS 2>&1 &

"$FUZZER/repo/afl-fuzz" -i "$TARGET/corpus/$PROGRAM" -o "$SHARED/findings" \
    $FUZZARGS -S Slave2 -- "$OUT/afl/$PROGRAM" $ARGS 2>&1 &

sleep $TIMEOUT
pkill afl-fuzz
 


#     "${flag_cmplog[@]}" -d \



