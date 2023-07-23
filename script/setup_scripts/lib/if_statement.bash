[[ -n $GUARD_IF_STATEMENT ]] && return || readonly GUARD_IF_STATEMENT=1

# Look for else/elif/fi statement
# 1 - File
# 2 - If statement start line number
# 3 - Variable name. Function will create the following
#     array ${VAR_NAME}_LNs  - Contains line numbers of 'if', 'elif', 'else', 'fi'
#     array ${VAR_NAME}_type - Contains info about whether it is an if', 'elif', 'else' or 'fi'
#                              for the same index in ${VAR_NAME}_LNs
# 4 - Max number of if statements/Max if statement level.
#     E.g. 2 levels of if statement:
#     if ...
#         if ...
#         fi
#     else
#         if ...
#         fi
#     fi
#     E.g. 3 levels of if statement:
#     if ...
#         if ...
#             if ...
#             fi
#         fi
#     fi
#
find_else_elif_fi_statement()
{
    local -r FILE="$1"
    local -r IF_STATEMENT_START_LINE_NUM="$2"
    local -r VAR_NAME_PREFIX="$3"
    local -r MAX_LEVEL="$4"

    # Declare dynamic name for array ${VAR_NAME}_LNs
    # https://stackoverflow.com/questions/4582137/bash-indirect-array-addressing
    # Assign with: append_array(), insert_array()
    ## Example Usage inside of function ##
    # value=9
    # append_array $var_name_LNs $value
    # value=8
    # append_array $var_name_LNs $value
    # value=7
    # append_array $var_name_LNs $value
    # value=6
    # index=1
    # insert_array $var_name_LNs $value $index
    #
    # index=0
    # echo "${!eval_index_var_name_LNs}"
    # index=1
    # echo "${!eval_index_var_name_LNs}"
    # echo "${!eval_var_name_LNs}"
    #
    local var_name_LNs="${VAR_NAME_PREFIX}_LNs"
    declare -ag "${var_name_LNs}=()"
    declare eval_var_name_LNs="${var_name_LNs}[@]"
    declare eval_index_var_name_LNs="${var_name_LNs}[index]"
    

    # Declare dynamic name array ${VAR_NAME_PREFIX}_type
    local var_name_type="${VAR_NAME_PREFIX}_type"
    declare -ag "${var_name_type}=()"
    declare eval_var_name_type="${var_name_type}[@]"
    declare eval_index_var_name_type="${var_name_type}[index]"

    # Declare dynamic name array ${VAR_NAME_PREFIX}_level
    local var_name_level="${VAR_NAME_PREFIX}_level"
    declare -ag "${var_name_type}=()"
    declare eval_var_name_type="${var_name_type}[@]"
    declare eval_index_var_name_type="${var_name_type}[index]"

    # declare -ag "${VAR_NAME_PREFIX}_type=()"
    # declare -n var_name_type="${VAR_NAME_PREFIX}_type"
    # eval_var_name_type="${VAR_NAME_PREFIX}_type[@]"
    # declare  eval_index_var_name_type="${VAR_NAME_PREFIX}_type[index]"

    debug_echo 10 "************************************************"
    debug_echo 10 "***** Update if statement variables ************"
    debug_echo 10 "************************************************"

    debug_echo 100 "MAX LEVEL: $MAX_LEVEL"
    debug_echo 100 "Arrays to update:"
    debug_echo 100 "* $var_name_LNs[]"
    debug_echo 100 "* $var_name_type[]"
    debug_echo 100 -e "* $var_name_level[]\n"

    local level=0
    local line_count=0
    while read -r line || [[ -n "$line" ]]
    do
        current_line_number=$((IF_STATEMENT_START_LINE_NUM + $line_count))

        # Get first word of line
        first_word=$(echo "$line" | head -n1 | awk '{print $1;}')

        debug_echo 100 "first word: $first_word"

        [[ "$first_word" == 'if' ]] && ((level++))
        [[ "$first_word" == 'fi' ]] && ((level--))

        case $first_word in
        'if'|'elif'|'else')
            debug_echo 100 "level: $level"

            if (( level <= MAX_LEVEL ))
            then
                debug_echo 100 "Appending data to arrays."
                debug_echo 100 "Line number: $current_line_number"
                debug_echo 100 "Type: $first_word"
                debug_echo 100 "Level: $level"

                append_array $var_name_LNs $current_line_number
                append_array $var_name_type "$first_word"
                append_array $var_name_level "$level"
            fi
            ;;
        'fi')
            debug_echo 100 "level: $level"

            if ((level <= MAX_LEVEL - 1))
            then
                debug_echo 100 "Appending data to arrays."
                debug_echo 100 "Line number: $current_line_number"
                debug_echo 100 "Type: $first_word"
                debug_echo 100 "Level: $level"

                append_array $var_name_LNs $current_line_number
                append_array $var_name_type "$first_word"
                append_array $var_name_level "$level"

                if ((level == 0))
                then
                    debug_echo 100 "************************************************"
                    debug_echo 100 "***** Done updating if statement variables *****"
                    debug_echo 100 "************************************************"
                    return 0
                fi
            fi
            ;;
        *)
            debug_echo 100 "Discard line."
            ;;
        esac

        debug_echo 100 "-"
        
        ((line_count++)) || true # Force true
    done < <(tail -n "+$IF_STATEMENT_START_LINE_NUM" $FILE)

    debug_echo 1 -e "\nReturning with error, if statement level never became 0.\n"
    debug_echo 10 "************************************************"
    debug_echo 10 "***** Done updating if statement variables *****"
    debug_echo 10 "************************************************"

    return 1
}


adjust_else_elif_fi_linenumbers()
{
    INPUT="$1"
    INPUT_LINE_START="$2"
    
    # Increment if statement variables as they got shifted
    debug_echo 100 "IF_STATEMENT_START before:        $IF_STATEMENT_START"
    debug_echo 100 "IF_STATEMENT_END before:          $IF_STATEMENT_END"
    debug_echo 100 "ELSE_ELIF_LINE_NUMBER before:     $ELSE_ELIF_LINE_NUMBER"
    debug_echo 100 "FI_LINE_NUMBER before:            $FI_LINE_NUMBER"
    NUM_LINES=$(echo -n "$INPUT" | grep -c '^')
    debug_echo 100 "NUM_LINES:                        $NUM_LINES"

    if (( INPUT_LINE_START < IF_STATEMENT_START ))
    then
        IF_STATEMENT_START=$((IF_STATEMENT_START + NUM_LINES))
        IF_STATEMENT_END=$((IF_STATEMENT_END + NUM_LINES))
        ELSE_ELIF_LINE_NUMBER=$((ELSE_ELIF_LINE_NUMBER + NUM_LINES))
        FI_LINE_NUMBER=$((FI_LINE_NUMBER + NUM_LINES))

    elif (( INPUT_LINE_START < ELSE_ELIF_LINE_NUMBER ))
    then
        ELSE_ELIF_LINE_NUMBER=$((ELSE_ELIF_LINE_NUMBER + NUM_LINES))
        FI_LINE_NUMBER=$((FI_LINE_NUMBER + NUM_LINES))

    elif (( INPUT_LINE_START < FI_LINE_NUMBER ))
    then
        FI_LINE_NUMBER=$((FI_LINE_NUMBER + NUM_LINES))
    fi
    
    debug_echo 100 "IF_STATEMENT_START updated to:    $IF_STATEMENT_START"
    debug_echo 100 "IF_STATEMENT_END updated to:      $IF_STATEMENT_END"
    debug_echo 100 "ELSE_ELIF_LINE_NUMBER updated to: $ELSE_ELIF_LINE_NUMBER"
    debug_echo 100 "FI_LINE_NUMBER updated to:        $FI_LINE_NUMBER"
}
