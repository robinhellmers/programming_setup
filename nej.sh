#!/bin/bash


DEBUG_LEVEL=1

main()
{
    echo ""
    echo "1 ********************************************************"
    debug_echo 1 "Hello"
    echo ""
    echo "2 ********************************************************"
    debug_echo 1 "Hello 1 with newlines\n\n\n\n"
    echo ""
    echo "3 ********************************************************"
    debug_echo 1 -e "Hello 2 with newlines\n\n\n\n"
    echo ""
    echo "4 ********************************************************"
    debug_echo 1 "Hello world"
}

_handleArgs(){
    declare -g DEBUG_ECHO_OPTIONAL_ECHO=""
    # declare -g NON_OPTIONAL_ARGS=""
    declare -ag non_optional_args=()
    count=0
    while [ "${1:-}" != "" ]; do
        ((count++))
        echo "count: $count"
        echo "Arg: ${1}"
        echo ""
        # NOT optional: neither single dash or double dash
        if ! [[ "${1:0:1}" == "-" ]] && ! [ "${1:0:2}" == "--" ]; then
            non_optional_args+=("${1}")
        else
        # Optional: single dash or double dash
            echo "optional: ${1} #########"
            case "$1" in
                "-e")
                    DEBUG_ECHO_OPTIONAL_ECHO+="-e "
                    echo "OPTIONAL_ECHO updated to: $DEBUG_ECHO_OPTIONAL_ECHO"
                    echo ""
                    ;;
                # "-j" | "--jump-target")
                #     # If number
                #     if [[ $2 =~ ^[0-9]+$ ]]; then
                #         JUMP_TARGET=$(($2))
                #     fi
                #     shift
                #     ;;
            esac
        fi
        shift
    done
    
    # NON_OPTIONAL_ARGS=$(echo $NON_OPTIONAL_ARGS | sed 's/ *$//')
}

debug_echo()
{
    _handleArgs "$@"

    if (( ${#non_optional_args[@]} != 2 ))
    then
        echo "debug_echo: Incorrect number of input variables. Need to be 2, but ${#non_optional_args[@]} were given."
        echo "non_optional_args:"
        echo "${non_optional_args[@]}"
        return 0
    fi

    given_level="${non_optional_args[0]}"
    debug_message="${non_optional_args[1]}"

    if ! [[ "$given_level" =~ ^[0-9]+$ ]]
    then
        echo "debug_echo: Input 1 needs to be an integer defining the debug level"
        return 0
    fi

    if (( given_level <= DEBUG_LEVEL ))
    then
        echo $DEBUG_ECHO_OPTIONAL_ECHO "$debug_message"
    fi
}

main