#!/bin/bash

_handle_args(){
    OPTIONAL_GIT_LOG_ARGS=""
    NON_OPTIONAL_ARGS=""
    FIRST_NON_OPTIONAL_ARG=""
    JUMP_TARGET=0
    while [ "${1:-}" != "" ]; do
        # NOT optional: neither single dash or double dash
        if ! [[ "${1:0:1}" == "-" ]] && ! [[ "${1:0:2}" == "--" ]]; then
            echo "1: ${1} 1:0:1: ${1:0:1}"
            NON_OPTIONAL_ARGS+=" ${1} "
        else
        # Optional: single dash or double dash
            case "$1" in
                "-a" | "--all")
                    OPTIONAL_GIT_LOG_ARGS+=" --all"
                    ;;
                "-j" | "--jump-target")
                    # If number
                    if [[ $2 =~ ^[0-9]+$ ]]; then
                        JUMP_TARGET=$(($2))
                    fi
                    shift
                    ;;
            esac
        fi
        shift
    done

    NON_OPTIONAL_ARGS=$(echo $NON_OPTIONAL_ARGS | sed 's/ *$//')
    FIRST_NON_OPTIONAL_ARG=$(echo $NON_OPTIONAL_ARGS | awk '{print $1;}')
    export OPTIONAL_GIT_LOG_ARGS
    export NON_OPTIONAL_ARGS
    export FIRST_NON_OPTIONAL_ARG
    export JUMP_TARGET
}
export -f _handle_args