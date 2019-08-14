#!/usr/bin/env bash
set -e

workdir=$(pwd)
# args=" --debug"
args="--release"

rm -f ./bin/bench*

echo ""
echo "Building"
crystal build ${args} ./spec/performance/bench.cr -o ./bin/bench


echo ""
echo "Starting Benchmarking"
./bin/bench
