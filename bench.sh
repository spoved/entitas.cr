#!/usr/bin/env bash
set -e

workdir=$(pwd)
args=" --debug"


echo ""
echo "Building"

crystal build ${args} ./spec/performance/bench.cr -o ./bin/bench

echo ""
echo "Starting Benchmarking"
./bin/bench
