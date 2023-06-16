
_handle_args()
{
    declare -ag debug_echo_optional_args=()
    declare -ag output_text_append_optional_args=()
    declare -ag exit_optional_args=()
    script_return_file_arg=
    declare -ag non_optional_args=()
    count=0
    while [ "${1:-}" != "" ]; do
        # NOT optional: neither single dash or double dash
        if ! [[ "${1:0:1}" == "-" ]] && ! [ "${1:0:2}" == "--" ]; then
            non_optional_args+=("${1}")
        else
        # Optional: single dash or double dash
            case "$1" in
            '-e')
                debug_echo_optional_args+=('-e')
                output_text_append_optional_args+=('-e')
                ;;
            '-n')
                debug_echo_optional_args+=('-n')
                ;;
            '-o')
                shift
                script_return_file_arg="$1"
                ;;
            # "-j" | "--jump-target")
            #     # If number
            #     if [[ $2 =~ ^[0-9]+$ ]]; then
            #         JUMP_TARGET=$(($2))
            #     fi
            #     shift
            #     ;;
            *)
                # Did not find optional, treat as non-optional.
                non_optional_args+=("${1}")
                ;;
            esac
        fi
        shift
    done
    
    # NON_OPTIONAL_ARGS=$(echo $NON_OPTIONAL_ARGS | sed 's/ *$//')
}

_output_text_append()
{
    _handle_args "$@"
    local input="${non_optional_args[0]}"

    [[ -z "$script_return_file_arg" ]] && script_return_file_arg=/dev/null
    echo ${output_text_append_optional_args[@]} "$input" >> "$script_return_file_arg"
}

_exit()
{
    _handle_args "$@"
    local exit_code="${non_optional_args[0]}"
    local exit_output="${non_optional_args[1]}"

    _output_text_append "return_value=$exit_output"
    exit "$exit_code"
}

debug_echo()
{
    _handle_args "$@"

    if (( ${#non_optional_args[@]} != 2 ))
    then
        echo "debug_echo: Incorrect number of input variables. Need to be 2, but ${#non_optional_args[@]} were given."
        for i in "${!non_optional_args[@]}"
        do
            echo "non_optional_args[$i]: [${non_optional_args[$i]}]"
        done
        echo ""
        return 1
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
        echo ${debug_echo_optional_args[@]} "$debug_message"
    fi
}


# Reads multiline text and inputs to variable
#
# Example usage:
# define VAR <<'EOF'
# abc'asdf"
#     $(dont-execute-this)
# foo"bar"'''
# EOF
define(){ IFS=$'\n' read -r -d '' ${1} || true; }

eval_cmd()
{
    local returned_status=$?
    local error_output="$1"

    if (( returned_status != 0 ))
    then
        echo -e "$error_output"
        echo -e "Exiting with code $returned_status.\n"
        exit $returned_status
    fi
}