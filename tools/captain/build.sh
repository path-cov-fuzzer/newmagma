#!/bin/bash -e

##
# Pre-requirements:
# - env FUZZER: fuzzer name (from fuzzers/)
# - env TARGET: target name (from targets/)
# + env MAGMA: path to magma root (default: ../../)
# + env ISAN: if set, build the benchmark with ISAN/fatal canaries (default:
#       unset)
# + env HARDEN: if set, build the benchmark with hardened canaries (default:
#       unset)
##

if [ -z $FUZZER ] || [ -z $TARGET ]; then
    echo '$FUZZER and $TARGET must be specified as environment variables.'
    exit 1
fi
IMG_NAME="magma/$FUZZER/$TARGET"
MAGMA=${MAGMA:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" >/dev/null 2>&1 \
    && pwd)"}
source "$MAGMA/tools/captain/common.sh"

CANARY_MODE=${CANARY_MODE:-1}

case $CANARY_MODE in
1)
    mode_flag="--build-arg canaries=1"
    ;;
2)
    mode_flag=""
    ;;
3)
    mode_flag="--build-arg fixes=1"
    ;;
esac

if [ ! -z $ISAN ]; then
    isan_flag="--build-arg isan=1"
fi
if [ ! -z $HARDEN ]; then
    harden_flag="--build-arg harden=1"
fi

set -x

# WHATWEADD: our fuzzers are based on LLVM17
# fuzzers which does not need path_reduction
if [ "$FUZZER" == "aflplusplus" ] || [ "$FUZZER" == "onlyinstrument" ] || [ "$FUZZER" == "writetoshm" ] || [ "$FUZZER" == "pathfuzzerfullpath" ]; then

docker build -t "$IMG_NAME" \
    --build-arg fuzzer_name="$FUZZER" \
    --build-arg target_name="$TARGET" \
    --build-arg USER_ID=$(id -u $USER) \
    --build-arg GROUP_ID=$(id -g $USER) \
    --network=host \
    $mode_flag $isan_flag $harden_flag \
    -f "$MAGMA/docker/Dockerfile.llvm17" "$MAGMA"

# fuzzers which need path_reduction comes below branch
elif [ "$FUZZER" == "pathfuzzerreduction" ] || [ "$FUZZER" == "fixversion" ] || [ "$FUZZER" == "fxnotailopt" ]; then

# WHATWEADD: compile things that cannot be compiled in docker containers --------- start
export STORED_FUZZER=$FUZZER
export FUZZER="$MAGMA/fuzzers/$STORED_FUZZER"
# delete repo
rm -rf $FUZZER/repo
# git clone pathfuzzers
bash $FUZZER/fetch.sh
# compile libpath_reduction.so
bash $FUZZER/getpathlib.sh
export FUZZER=$STORED_FUZZER
# WHATWEADD: compile things that cannot be compiled in docker containers --------- end

docker build -t "$IMG_NAME" \
    --build-arg fuzzer_name="$FUZZER" \
    --build-arg target_name="$TARGET" \
    --build-arg USER_ID=$(id -u $USER) \
    --build-arg GROUP_ID=$(id -g $USER) \
    --network=host \
    $mode_flag $isan_flag $harden_flag \
    -f "$MAGMA/docker/Dockerfile.llvm17.path" "$MAGMA"

else

docker build -t "$IMG_NAME" \
    --build-arg fuzzer_name="$FUZZER" \
    --build-arg target_name="$TARGET" \
    --build-arg USER_ID=$(id -u $USER) \
    --build-arg GROUP_ID=$(id -g $USER) \
    --network=host \
    $mode_flag $isan_flag $harden_flag \
    -f "$MAGMA/docker/Dockerfile" "$MAGMA"

fi

set +x

echo "$IMG_NAME"