#!/bin/bash



main()
{
    find_else_elif_fi_statement "./ja" 4 if_statement 2
    echo "if_statement_LNs: ${if_statement_LNs[@]}"
    echo "if_statement_type: ${if_statement_type[@]}"
}

find_else_elif_fi_statement()
{
    FILE=$1
    IF_LINE_NUMBER=$2
    VAR_NAME=$3
    MAX_LEVEL=$4

    # Declare dynamic name for array ${VAR_NAME}_LNs
    # https://stackoverflow.com/questions/4582137/bash-indirect-array-addressing
    declare -ag "${VAR_NAME}_LNs=()"
    declare -n var_name_LNs="${VAR_NAME}_LNs"
    eval_var_name_LNs="${VAR_NAME}_LNs[@]"
    declare  eval_index_var_name_LNs="${VAR_NAME}_LNs[index]"
    ## Example Usage inside of function ##
    # var_name_LNs+=(1)
    # var_name_LNs+=(2)
    # var_name_LNs[2]=4
    # index=0
    # echo "${!eval_index_var_name_LNs}"
    # index=1
    # echo "${!eval_index_var_name_LNs}"
    # echo "${!eval_var_name_LNs}"

    # Declare dynamic name array ${VAR_NAME}_type
    declare -ag "${VAR_NAME}_type=()"
    declare -n var_name_type="${VAR_NAME}_type"
    eval_var_name_type="${VAR_NAME}_type[@]"
    declare  eval_index_var_name_type="${VAR_NAME}_type[index]"

    if_statement_level=0
    line_count=0
    while read -r line; do
        # Get first word of line
        first_word=$(echo "$line" | head -n1 | awk '{print $1;}')
        
        case $first_word in
        'if')
            ((if_statement_level++))

            if (( if_statement_level <= MAX_LEVEL ))
            then
                var_name_LNs+=( $((IF_LINE_NUMBER + $line_count)) )
                var_name_type+=( 'if' )
            fi
            ;;
        'elif')
            if (( if_statement_level <= MAX_LEVEL ))
            then
                var_name_LNs+=( $((IF_LINE_NUMBER + $line_count)) )
                var_name_type+=( 'elif' )
            fi
            ;;
        'else')
            if (( if_statement_level <= MAX_LEVEL ))
            then
                var_name_LNs+=( $((IF_LINE_NUMBER + $line_count)) )
                var_name_type+=( 'else' )
            fi
            ;;
        'fi')
            ((if_statement_level--))

            if ((if_statement_level <= MAX_LEVEL - 1))
            then
                var_name_LNs+=( $((IF_LINE_NUMBER + $line_count)) )
                var_name_type+=( 'fi' )
            fi
            ;;
        *)
            ;;
        esac
        
        ((line_count++))
    done < <(tail -n "+$IF_LINE_NUMBER" $FILE)

    return -1
}

main