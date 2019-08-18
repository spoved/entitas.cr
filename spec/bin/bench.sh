#!/usr/bin/env bash
set -ex

workdir=$(pwd)
test_dir=${workdir}/test
coverage_dir=${HOME}/code/github.com/anykeyh/crystal-coverage

source="./spec/performance/bench.cr"
# source="./examples/hello_world/hello_world.cr"
target="./bin/bench"
args="--release --error-trace"
args="${args} -Ddisable_logging"

# args="${args} -Dbenchmark"

export BENCHER_DATA_DIR=${test_dir}
export BENCHER_RAW_FILE=${test_dir}/bencher_raw.json
# export BENCHER_REPORT=${test_dir}/bencher.json
# export BENCHER_FORMAT=json

export BENCHER_REPORT=${test_dir}/bencher.csv
export BENCHER_FORMAT=csv

# export BENCHER_MATCH=Entitas
export BENCHER_DEBUG=true

cleanup(){
  if [ -d ${test_dir} ];then
    rm -rf ${test_dir}/*
  fi

  mkdir -p ${test_dir}

  rm -f ./bin/bench*
}

build_bench(){
  echo ""
  echo "Building"
  crystal build ${args} ${source} -o ${target}
}

run_bench(){
  echo ""
  echo "Starting Benchmarking"
  ./bin/bench
}

cleanup
build_bench
run_bench
