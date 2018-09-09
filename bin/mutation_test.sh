#!/bin/sh
set -ue

PATTERN=${1:-ValueSemantics*}

bundle exec mutant --include lib --require value_semantics --use rspec "$PATTERN"
