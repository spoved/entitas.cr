#!/usr/bin/env zsh
source ~/.zshrc

crystal tool format
crystal spec && shards build
