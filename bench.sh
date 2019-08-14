#!/usr/bin/env bash
set -ex

workdir=$(pwd)
coverage_dir=${HOME}/code/github.com/anykeyh/crystal-coverage

# args=" --debug"
args="--release"

rm -f ./bin/bench*

vanila_bench(){
  echo ""
  echo "Building"
  crystal build ${args} ./spec/performance/bench.cr -o ./bin/bench

  echo ""
  echo "Starting Benchmarking"
  ./bin/bench
}

vanila_bench
