#!/usr/bin/env bash


versions=(
  "0.30.1"
  "0.31.0"
  "0.31.1"
)

run_spec() {
  ver=$1
  docker run --rm -ti -v $(pwd):/app -w /app crystallang/crystal:$ver sh -c "shards install && crystal spec"
}

for ver in "${versions[@]}"
do
  echo "Testing ${ver}"
  run_spec ${ver}
done
