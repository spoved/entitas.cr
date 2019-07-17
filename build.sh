#!/usr/bin/env zsh
source ~/.zshrc

set -e

crystal tool format

./bin/ameba
./bin/crystal-coverage spec/entitas/*.cr spec/entitas/**/*.cr

# crystal spec --error-trace
