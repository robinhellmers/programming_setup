#!/bin/bash




main()
{
    func bla
    echo "bla_LNs: ${bla_LNs[@]}"
}




func()
{
    var_name="$1"

    # Declare dynamic name for array ${var_name}_LNs
    # https://stackoverflow.com/questions/4582137/bash-indirect-array-addressing
    local var_name_LNs="${var_name}_LNs"
    declare -ag "${var_name_LNs}=(1 2 3)"
    # Assign with: append_array(), insert_array()
    eval "eval_var_name_LNs=\${${var_name_LNs}[@]}"
    echo "eval_var_name_LNs: ${eval_var_name_LNs}"

    # declare  eval_index_var_name_LNs="${VAR_NAME}_LNs[index]"
    local index=1
    eval "eval_index_var_name_LNs=\${${var_name_LNs}[index]}"
    echo "eval_index_var_name_LNs: $eval_index_var_name_LNs"
    # Get length of array
    eval eval "local len=\${#${var_name_LNs}[@]}"
    echo "len: $len"

    # declare  eval_index_var_name_LNs="${var_name}_LNs[index]"
}






main