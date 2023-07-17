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