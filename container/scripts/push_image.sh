#!/bin/bash
set -e

BUILD_SCRIPT=$1
LABEL=$2
shift 2
# build the image first, with builder script from cmd input
$BUILD_SCRIPT

set -x
docker push $LABEL $@
