#!/usr/bin/env bash
set -e

workdir=$(pwd)
test_dir=${workdir}/test
bin_dir=${workdir}/bin

: ${DISABLE_LOGGING:=true}
: ${LOG_FILE:=${workdir}/debug.log}

set_vars(){
  coverage_dir=${HOME}/code/github.com/anykeyh/crystal-coverage

  source="${workdir}/spec/performance/bench.cr"
  target="${bin_dir}/bench"
  args="--release"
  args="${args} --error-trace"

  if [ -n "${DISABLE_LOGGING}" ]; then
    args="${args} -Ddisable_logging"
  fi

  if [ -n "${USE_BENCHER}" ]; then
    args="${args} -Dbenchmark"

    set_bencher_env
  fi
}

stage(){
  local str=${1}
  echo ""
  echo "${str}"
}

sub_stage(){
  local str=${1}
  echo ""
  echo "  -> ${str}"
}

cleanup(){
  stage "Cleanup"

  # Cleanup test dir
  if [ -z "${test_dir}" ]; then
    echo "EMPTY TEST DIR!"
    exit 1
  fi

  if [ -d ${test_dir} ];then
    rm -rf ${test_dir}
  fi
  mkdir -p ${test_dir}

  # Cleanup bench execs
  if [ -e ${bin_dir}/bench ]; then
    rm -f ${bin_dir}/bench*
  fi


  # Cleanup docs
  if [ -d ${workdir}/docs ];then
    rm -r ${workdir}/docs
  fi

  # Cleanup coverage
  if [ -d ${workdir}/coverage ];then
    rm -r ${workdir}/coverage
  fi

  if [ -e ${test_dir}/coverage.cr ];then
    rm ${test_dir}/coverage.cr
  fi
}

shards_update(){
  stage "Updating shards"

  shards update >> ${LOG_FILE}
}

format_code(){
  stage "Format"

  crystal tool format >> ${LOG_FILE}
}

check_quality() {
  stage "Ameba"
  ${bin_dir}/ameba >> ${LOG_FILE}
}

gen_docs() {
  stage "Generating docs"
  # Generate docs
  if [ -d ${workdir}/docs ];then
    rm -r ${workdir}/docs
  fi

  crystal doc ${workdir}/spec/fixtures/* >> ${LOG_FILE}
}

########################
# Spec functions
########################

run_spec() {
  stage "Running specs"
  crystal spec --error-trace >> ${LOG_FILE}
}

run_spec_with_coverage() {
  stage "Running specs with coverage"

  cd ${workdir}

  # Generate coverage
  if [ -d ${workdir}/coverage ];then
    rm -rf ${workdir}/coverage
  fi

  if [ -e ${test_dir}/coverage.cr ];then
    rm ${test_dir}/coverage.cr
  fi

  ${bin_dir}/crystal-coverage -p ${workdir}/spec/entitas/*.cr ${workdir}/spec/entitas/**/*.cr > ${test_dir}/coverage.cr

  crystal run ${test_dir}/coverage.cr >> ${LOG_FILE}
}

########################
# Benchmark functions
########################

set_bencher_env(){

  if [ -n "${BENCHER_DATA_DIR}" ]; then
    export BENCHER_DATA_DIR=${test_dir}
  fi

  if [ -n "${BENCHER_RAW_FILE}" ]; then
    export BENCHER_RAW_FILE=${test_dir}/bencher_raw.json
  fi

  if [ -n "${BENCHER_REPORT}" ]; then
    if [ -n "${BENCHER_FORMAT}" ]; then
      export BENCHER_REPORT=${test_dir}/bencher.csv
      export BENCHER_FORMAT=csv
    elif [ "${BENCHER_FORMAT}" = "csv" ]; then
      export BENCHER_REPORT=${test_dir}/bencher.csv
      export BENCHER_FORMAT=csv
    elif [ "${BENCHER_FORMAT}" = "json" ]; then
      export BENCHER_REPORT=${test_dir}/bencher.json
      export BENCHER_FORMAT=json
    fi
  fi

  # export BENCHER_MATCH=Entitas
  # export BENCHER_DEBUG=true
}

bench_mark(){
  stage "Benchmark"
  set_vars

  if [ "${TARGET}" = "linux" ]; then
    build_bench_for_linux
  else
    build_bench_for_local
    run_bench
  fi
}

build_bench_for_local(){
  sub_stage "Building for local"

  set_bencher_env

  eval "crystal build ${args} ${source} -o ${target} >> ${LOG_FILE}"
}

build_bench_for_linux(){
  sub_stage "Cross-Compile for linux"

  eval "crystal build ${args} ${source} -o ${target} --cross-compile --target x86_64-unknown-linux-gnu >> ${LOG_FILE}"

  # scp ./bin/bench.o 192.168.1.206:
  # On linux
  # cc './bench.o' -o './bench'  -rdynamic  -lpcre \
  #   -lm /home/linuxbrew/.linuxbrew/Cellar/crystal/0.30.1/embedded/lib/libgc.a \
  #   -lpthread /home/linuxbrew/.linuxbrew/Cellar/crystal/0.30.1/src/ext/libcrystal.a \
  #   -levent -lrt -ldl \
  #   -L/home/linuxbrew/.linuxbrew/Cellar/crystal/0.30.1/embedded/lib -L/usr/lib -L/usr/local/lib
}

run_bench(){
  sub_stage "Starting Benchmarking"

  ${bin_dir}/bench >> ${LOG_FILE}
}
