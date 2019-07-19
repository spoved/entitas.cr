#!/usr/bin/env zsh
source ~/.zshrc

set -e


# Format code
crystal tool format

# Test code quality
./bin/ameba

# Generate coverage
if [ -d ./coverage ];then
  rm -r ./coverage
fi
./bin/crystal-coverage spec/entitas/*.cr spec/entitas/**/*.cr

# Run spec tests?
# crystal spec --error-trace

# Generate docs
if [ -d ./docs ];then
  rm -r ./docs
fi
crystal doc
