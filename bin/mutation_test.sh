#!/bin/sh
set -ue

PATTERN=${1:-ValueSemantics*}

bundle exec mutant \
    --include lib \
    --require value_semantics \
    --use rspec "$PATTERN" \
    # Mutant 0.8.24 introduces new mutations that cause infinite recursion inside
    # #method_missing. These --ignore-subject lines prevent that from happening
    #--ignore-subject "ValueSemantics::DSL#method_missing" \
    #--ignore-subject "ValueSemantics::DSL#respond_to_missing?" \
    #--ignore-subject "ValueSemantics::DSL#def_attr" \
