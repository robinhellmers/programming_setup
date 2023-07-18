[[ -n $GUARD_ARRAY ]] && return || readonly GUARD_ARRAY=1

get_index_array_value()
{
    local value_to_search="$1"; shift
    local array_to_search=("$@")

    for i in "${!array_to_search[@]}"; do
        if [[ "${array_to_search[i]}" == "$value_to_search" ]]
        then
            index_found="$i"
            return 0
        fi
    done

    return 1
}

create_initialized_array()
{
    local len="$1"
    local init_value="$2"

    # Ensure 'len' is a number
    case $len in
        ''|*[!0-9]*)
            echo "First parameter is not a number."
            return 1
            ;;
        *) ;;
    esac

    local array=( $(for (( i=0; i<len; i++ )); do echo "$init_value"; done) )

    echo "${array[@]}"
}
