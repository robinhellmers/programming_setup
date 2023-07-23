[[ -n $GUARD_ARRAY ]] && return || readonly GUARD_ARRAY=1

##############################
### Library initialization ###
##############################

init_lib()
{
    find_this_script_path

    local -r LIB_PATH="$this_script_path"

    source "$LIB_PATH/dynamic.bash"
}

find_this_script_path()
{
    local source=${BASH_SOURCE[0]}
    while [ -L "$source" ]; do # resolve $source until the file is no longer a symlink
        this_script_path=$( cd -P "$( dirname "$source" )" >/dev/null 2>&1 && pwd )
        source=$(readlink "$source")
        [[ $source != /* ]] && source=$this_script_path/$source # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    this_script_path=$( cd -P "$( dirname "$source" )" >/dev/null 2>&1 && pwd )
}

init_lib

#####################
### Library start ###
#####################

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

index_exists_in_array()
{
    local index="$1"; shift

    local dynamic_array_prefix="input_array"
    handle_input_arrays_dynamically "$dynamic_array_prefix" "$@"

    get_dynamic_array "${dynamic_array_prefix}1"
    local array=("${dynamic_array[@]}")

    is_number "$index"
    eval_cmd "Given index is not a number: $index"

    [[ "${array[index]+nonexistent}" ]]
}

get_indices_by_array_values()
{
    local dynamic_array_prefix="input_array"
    handle_input_arrays_dynamically "$dynamic_array_prefix" "$@"

    get_dynamic_array "${dynamic_array_prefix}1"
    local array_values_to_find=("${dynamic_array[@]}")

    get_dynamic_array "${dynamic_array_prefix}2"
    local array_to_search=("${dynamic_array[@]}")

    indices_found=()
    for value in "${array_values_to_find[@]}"
    do
        get_index_array_value "$value" "${array_export_destination_files_name[@]}"

        indices_found+=("$index_found")
    done
}

get_values_by_array_indices()
{
    local dynamic_array_prefix="input_array"
    handle_input_arrays_dynamically "$dynamic_array_prefix" "$@"

    get_dynamic_array "${dynamic_array_prefix}1"
    local array_indices=("${dynamic_array[@]}")

    get_dynamic_array "${dynamic_array_prefix}2"
    local array_values=("${dynamic_array[@]}")

    values_found=()
    for index in "${array_indices[@]}"
    do
        index_exists_in_array "$index" "${#array_values[@]}" "${array_values[@]}"

        values_found+=("${array_values[index]}")
    done
}

create_initialized_array()
{
    local len="$1"
    local init_value="$2"

    is_number "$len"
    eval_cmd "Given length is not a number."

    local array=( $(for (( i=0; i<len; i++ )); do echo "$init_value"; done) )
    initialized_array=("${array[@]}")
}
