#!/usr/bin/env zsh

set -ex

source $(dirname ${0})/functions.sh

cleanup

# Update shards
shards_update

# Format code
format_code

# Test code quality
check_quality

# Run spec tests?
run_spec

# Generate docs
gen_docs

# Run with coverage
run_spec_with_coverage

# Run benchmark
bench_mark

# Run examples
run_examples

stage "DONE"
