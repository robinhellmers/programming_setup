[[ -n $GUARD_IF_STATEMENT ]] && return || readonly GUARD_IF_STATEMENT=1

##############################
### Library initialization ###
##############################

init_lib()
{
    find_this_script_path

    local -r LIB_PATH="$this_script_path"
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

    local level=0
    local line_count=0
    while read -r line || [[ -n "$line" ]]
    do
        current_line_number=$((IF_STATEMENT_START_LINE_NUM + $line_count))

        # Get first word of line
        first_word=$(echo "$line" | head -n1 | awk '{print $1;}')

        [[ "$first_word" == 'if' ]] && ((level++))
        [[ "$first_word" == 'fi' ]] && ((level--))

        case $first_word in
        'if'|'elif'|'else')

            if (( level <= MAX_LEVEL ))
            then

                append_array $var_name_LNs $current_line_number
                append_array $var_name_type "$first_word"
                append_array $var_name_level "$level"
            fi
            ;;
        'fi')

            if ((level <= MAX_LEVEL - 1))
            then

                append_array $var_name_LNs $current_line_number
                append_array $var_name_type "$first_word"
                append_array $var_name_level "$level"

                if ((level == 0))
                then
                    return 0
                fi
            fi
            ;;
        *)
            ;;
        esac

        ((line_count++)) || true # Force true
    done < <(tail -n "+$IF_STATEMENT_START_LINE_NUM" $FILE)

    return 1
}


adjust_else_elif_fi_linenumbers()
{
    INPUT="$1"
    INPUT_LINE_START="$2"
    
    # Increment if statement variables as they got shifted
    NUM_LINES=$(echo -n "$INPUT" | grep -c '^')

    if (( INPUT_LINE_START < if_statement_start ))
    then
        if_statement_start=$((if_statement_start + NUM_LINES))
        if_statement_end=$((if_statement_end + NUM_LINES))
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

}
