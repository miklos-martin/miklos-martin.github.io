#!/bin/bash

aspell --lang=en create master ./spell/words.rws < ./spell/words || exit 1

errors=$(find . -type f | grep .md | xargs cat | aspell --add-extra-dicts=./spell/words.rws list)
if [ ! -z "$errors" ];then
    cat <<EOF
Mispelled words detected, run aspell interactively to fix them, or include the words in your dict.
Listed by aspell:

$errors
EOF
    exit 1
else
    echo "All is well"
fi
