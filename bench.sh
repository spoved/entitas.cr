#!/usr/bin/env bash
set -e

workdir=$(pwd)
# args=" --debug"
args="--release"

if [ -e ./bin/bench ];then
  rm ./bin/bench
fi

echo ""
echo "Building"
crystal build ${args} ./spec/performance/bench.cr -o ./bin/bench


echo ""
echo "Starting Benchmarking"
./bin/bench
#
# crystal build --release ./spec/performance/context_bench.cr -o ./bin/bench && ./bin/bench
# crystal build --release ./spec/performance/entity_bench.cr -o ./bin/bench && ./bin/bench
