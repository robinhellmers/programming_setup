#!/bin/bash


# Avoid using name ref -n as of being a later bash version ~4.3?
main()
{
    test bla
    echo "bla_LNs: ${bla_LNs[@]}"
}

# Used for dynamic arrays to make it more readable
append_array()
{
    local var__name="$1"
    local value="$2"
    # Get length of array
    eval eval "local len=\${#${var__name}[@]}"

    # Append to array
    read -r "${var__name}[${len}]" <<< "$value"
}

# Used for dynamic arrays to make it more readable
insert_array()
{
    local var_name="$1"
    local value="$2"
    local index="$3"

    # Insert into array
    read -r "${var_name}[${index}]" <<< "$value"
}

eval_array()
{
    local var_name="$1"

    eval "echo \${${var_name}[@]}"
}

eval_index_array()
{
    local var_name="$1"
    local index="$2"

    eval "echo \${${var_name}[$index]}"
}


test()
{
    var_name=$1

    var_name_LNs="${var_name}_LNs"
    declare -ag "${var_name_LNs}=(1 2 3)"

    for i in {0..2}; do
        append_array "$var_name_LNs" "$((25 + 5))"
    done

    local index=2
    insert_array "$var_name_LNs" "$((90 + 9))" $index
    
    evaluated_index=$(eval_index_array "$var_name_LNs" "$index")
    evaluated_array=$(eval_array "$var_name_LNs")

    echo "evaluated_array: ${evaluated_array}"
    echo "evaluated_index: ${evaluated_index}"
}


main