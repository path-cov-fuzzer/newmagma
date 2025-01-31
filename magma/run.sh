#!/bin/bash
set -e

##
# Pre-requirements:
# - env FUZZER: path to fuzzer work dir
# - env TARGET: path to target work dir
# - env OUT: path to directory where artifacts are stored
# - env SHARED: path to directory shared with host (to store results)
# - env PROGRAM: name of program to run (should be found in $OUT)
# - env ARGS: extra arguments to pass to the program
# - env FUZZARGS: extra arguments to pass to the fuzzer
# - env POLL: time (in seconds) to sleep between polls
# - env TIMEOUT: time to run the campaign
# - env MAGMA: path to Magma support files
# + env LOGSIZE: size (in bytes) of log file to generate (default: 1 MiB)
##

# set default max log size to 1 MiB
LOGSIZE=${LOGSIZE:-$[1 << 20]}

export MONITOR="$SHARED/monitor"
mkdir -p "$MONITOR"

# WHATWEADD: filter CFG for pathfuzzer
echo "========================== out of this branch ==================="
echo "FUZZER = $FUZZER"
if [[ "$FUZZER" =~ "fixversion" ]]; then
    echo "========================== in this branch ==================="
    (
        # copy everything of /magma_out/afl to /magma_shared/afl
        cp -r "$OUT/afl" "$SHARED/afl"
        # generate CFG of PROGRAM to /magma_shared/afl
        export OUT="$SHARED/afl"
        g++ -I"$FUZZER/repo/fuzzing_support" "$FUZZER/repo/fuzzing_support/convert.cpp" -o "$OUT/convert"
        bash $FUZZER/generateCFG.sh
    )
    # copy FG back to /magma_out/afl
    cp $SHARED/afl/${PROGRAM}_cfg.bin $OUT/afl/${PROGRAM}_cfg.bin
    # sth like cfg_${PROGRAM}.txt has been copied to $SHARED already
fi

# change working directory to somewhere accessible by the fuzzer and target
cd "$SHARED"

# WHATWEADD: skip seeds-filtering for LAVAM PUTs ----------------------------------------------- start
if [[ "$TARGET" != *"base64"* ]] && [[ "$TARGET" != *"md5sum"* ]] && [[ "$TARGET" != *"uniq"* ]] && [[ "$TARGET" != *"who"* ]]; then
	# prune the seed corpus for any fault-triggering test-cases
	for seed in "$TARGET/corpus/$PROGRAM"/*; do
		out="$("$MAGMA"/runonce.sh "$seed")"
		code=$?

		if [ $code -ne 0 ]; then
			echo "$seed: $out"
			rm "$seed"
		fi
	done
fi
# WHATWEADD: skip seeds-filtering for LAVAM PUTs ----------------------------------------------- end

shopt -s nullglob
seeds=("$1"/*)
shopt -u nullglob
if [ ${#seeds[@]} -eq 0 ]; then
    echo "No seeds remaining! Campaign will not be launched."
    exit 1
fi


# launch the fuzzer in parallel with the monitor
rm -f "$MONITOR/tmp"*
polls=("$MONITOR"/*)
if [ ${#polls[@]} -eq 0 ]; then
    counter=0
else
    timestamps=($(sort -n < <(basename -a "${polls[@]}")))
    last=${timestamps[-1]}
    counter=$(( last + POLL ))
fi

while true; do
    "$OUT/monitor" --dump row > "$MONITOR/tmp"
    if [ $? -eq 0 ]; then
        mv "$MONITOR/tmp" "$MONITOR/$counter"
    else
        rm "$MONITOR/tmp"
    fi
    counter=$(( counter + POLL ))
    sleep $POLL
done &

echo "Campaign launched at $(date '+%F %R')"

export TIMEOUT=$TIMEOUT
timeout $TIMEOUT "$FUZZER/run.sh" | \
    multilog n2 s$LOGSIZE "$SHARED/log"

if [ -f "$SHARED/log/current" ]; then
    cat "$SHARED/log/current"
fi

echo "Campaign terminated at $(date '+%F %R')"

kill $(jobs -p)
