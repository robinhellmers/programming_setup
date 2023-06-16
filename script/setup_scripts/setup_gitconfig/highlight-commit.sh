#!/bin/bash

SCRIPTS_PATH="${HOME}/.local/bin"

source $SCRIPTS_PATH/optionalParameterParser.sh
_handle_args $*

BRANCHES=""

FIRST_MATCH_LINE_NUM=$(git lg $OPTIONAL_GIT_LOG_ARGS $BRANCHES | grep -n -m 1 "$FIRST_NON_OPTIONAL_ARG" | cut -d : -f 1)
git lg $OPTIONAL_GIT_LOG_ARGS $BRANCHES | awk -v commits="$NON_OPTIONAL_ARGS" -f ${HOME}/.local/bin/highlight-commit.awk | less -XR +$FIRST_MATCH_LINE_NUM -j $JUMP_TARGET