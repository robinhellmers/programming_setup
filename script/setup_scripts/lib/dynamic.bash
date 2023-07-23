[[ -n $GUARD_DYNAMIC ]] && return || readonly GUARD_DYNAMIC=

##############################
### Library initialization ###
##############################

init_lib()
{
    find_this_script_path

    readonly LIB_PATH="$this_script_path"
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

#Used for dynamic arrays to make it more readable
append_array()
{
    local var_name="$1"
    local value="$2"
    # Get length of array
    eval eval "local len=\${#${var_name}[@]}"

    # Append to array
    read -r "${var_name}[${len}]" <<< "$value"
}

# Used for dynamic arrays to make it more readable
insert_array()
{
    local var_name="$1"
    local value="$2"
    local index="$3"

    # Append to array
    read -r "${var_name}[${index}]" <<< "$value"
}

# Used for handling arrays as function parameters
# Creates dynamic arrays from the input
# 1: Dynamic array name prefix e.g. 'input_arr'
#    Creates dynamic arrays 'input_arr1', 'input_arr2', ...
# 2: Length of array e.g. "${#arr[@]}"
# 3: Array content e.g. "${arr[@]}"
# 4: Length of the next array
# 5: Content of the next array
# 6: ...
handle_input_arrays_dynamically()
{
    local dynamic_array_prefix="$1"; shift
    local array_suffix=1

    local is_number_regex='^[0-9]+$'

    while (( $# )) ; do
        local num_array_elements=$1; shift

        if ! [[ "$num_array_elements" =~ $is_number_regex ]]
        then
            echo "Given number of array elements is not a number: $num_array_elements"
            exit 1
        fi
        
        eval "$dynamic_array_prefix$array_suffix=()";
        while (( num_array_elements-- > 0 )) 
        do

            if ((num_array_elements == 0)) && ! [[ "${1+nonexistent}" ]]
            then
                # Last element is not set
                echo "Given array contains less elements than the explicit array size given."
                exit 1
            fi
            eval "$dynamic_array_prefix$array_suffix+=(\"\$1\")"; shift
        done
        ((array_suffix++))
    done
}

get_dynamic_element()
{
    local array_name="$1"
    local index="$2"

    dynamic_array_element=$(eval "echo \"\${$array_name[$index]}\"")
    echo "$dynamic_array_element"
}

get_dynamic_array()
{
    local array_name="$1"

    dynamic_array=()
    dynamic_array_len="$(get_dynamic_array_len $array_name)"
    for (( i=0; i < dynamic_array_len; i++ ))
    do
        dynamic_array+=("$(get_dynamic_element $array_name $i)")
    done
}

get_dynamic_array_len()
{
    local array_name="$1"

    dynamic_array_len=$(eval "echo \${#$array_name[@]}")
    echo "$dynamic_array_len"
}
