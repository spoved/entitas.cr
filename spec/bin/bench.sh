#!/usr/bin/env bash
set -e

workdir=$(pwd)
test_dir=${workdir}/test
coverage_dir=${HOME}/code/github.com/anykeyh/crystal-coverage

source="./spec/performance/bench.cr"
# source="./examples/hello_world/hello_world.cr"
target="./bin/bench"
args="--release"
args="${args} --error-trace"
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

build_for_linux(){
  crystal build ${args} ${source} -o ${target} --cross-compile --target "x86_64-unknown-linux-gnu"

  # On linux
  # cc './bench.o' -o './bench'  -rdynamic  -lpcre \
  #   -lm /home/linuxbrew/.linuxbrew/Cellar/crystal/0.30.1/embedded/lib/libgc.a \
  #   -lpthread /home/linuxbrew/.linuxbrew/Cellar/crystal/0.30.1/src/ext/libcrystal.a \
  #   -levent -lrt -ldl \
  #   -L/home/linuxbrew/.linuxbrew/Cellar/crystal/0.30.1/embedded/lib -L/usr/lib -L/usr/local/lib
}

run_bench(){
  echo ""
  echo "Starting Benchmarking"
  ./bin/bench
}

cleanup
build_bench
run_bench
# build_for_linux
