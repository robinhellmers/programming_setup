[[ -n $GUARD_INSERT ]] && return || readonly GUARD_INSERT=1

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

adjust_interval_linenumbers()
{
    local -r INPUT="$1"
    local -r INDEX_LIMIT="$2"

    # Increment if statement variables as they got shifted
    local -r NUM_LINES=$(echo -n "$INPUT" | grep -c '^')
    for i in "${!_intervals[@]}"
    do
        if (( i >= INDEX_LIMIT ))
        then
            _intervals[$i]=$((_intervals[i] + NUM_LINES))
        fi
    done
}



# 1 - File path
# 2 - File name
# 3 - Name of variable with content
# 4 - Reference type. One 'LINE' or 'INBETWEEN' lines
#
# Reference type: 'INBETWEEN':
# 5 - Reference placement 'START' or 'END' of interval
# 6 - Line number of interval start
# 7 - Line number of interval end
# 8 - Length of array in next input - ${#allowed_intervals[@]}
# 9 - Array with allowed areas marked with true or false. ${allowed_intervals[@]}
#     Example 1:
#     (Before Interval After)
#     (true   false    true) indicating not to allow content inside of the interval
#     Example 2:
#     (Before Interval1 Interval2 After)
#     (false  true      false     false) indicating only to allow content inside
#                                        interval 2.
# 10 - Length of array in next input - ${#preferred_interval[@]}
# 11 - Array with preferred areas marked with true or false. ${preferred_interval[@]}
#      Only one area can be marked true.
#      Example 1:
#      (Before Interval After)
#      (true   false    false) indicating not to allow content inside of the interval
#      Example 2:
#      (Before Interval1 Interval2 After)
#      (false  true      false     false) indicating only to allow content inside
#                                         interval 2.
# Reference type: 'LINE'
# 5 - Reference placement 'BEFORE' or 'AFTER' the interval
# 6 - as 8 above.
# 7 - As 9 above.
# 8 - As 10 above.
# 9 - As 11 above.
add_single_line_content()
{
    if (( $# < 5 ))
    then
        result_value="Function 'add_single_line_content' need at least 5 inputs, you gave $#."
        return -1
    fi

    local -r FILE_PATH="$1"; shift       # 1
    local -r FILE_NAME="$1"; shift       # 2
    local -r VAR_NAME_PREFIX="$1"; shift        # 3
    local -r REF_TYPE="$1"; shift        # 4
    local -r REF_PLACEMENT="$1"; shift   # 5

    local dynamic_array_prefix="input_array"
    handle_input_arrays_dynamically "$dynamic_array_prefix" "$@"

    get_dynamic_array "${dynamic_array_prefix}1"
    allowed_intervals=("${dynamic_array[@]}")

    get_dynamic_array "${dynamic_array_prefix}2"
    preferred_interval=("${dynamic_array[@]}")

    get_dynamic_array "${dynamic_array_prefix}3"
    _intervals=("${dynamic_array[@]}")

    _check_valid_ref "$REF_TYPE" "$REF_PLACEMENT" || return $?

    _check_valid_intervals || return $?

    eval_var_name=$VAR_NAME_PREFIX # ${!eval_var_name}
    eval_var_name_exists=${VAR_NAME_PREFIX}_exists # ${!eval_var_name_exists}
    declare -g ${VAR_NAME_PREFIX}_exists='true'

    # Iterate over every line of VAR_NAME_PREFIX as they are independent
    already_done='true'
    while IFS= read -r line
    do
        exists_in_file "$FILE_PATH/$FILE_NAME" "$line" line
        # Returns: line_exists / line_start / line_end

        if [[ $REF_TYPE == "INBETWEEN" ]]
        then
            if ! $line_exists
            then
                add_to_preferred_interval='true'
                already_done='false'

                file_num_lines=$(wc -l "$FILE_PATH/$FILE_NAME" | cut -f1 -d' ')
                tmp_intervals=(0 ${_intervals[@]} "$file_num_lines")
            else
                _find_line_in_intervals
                # Returns: exists_in_intervals[]

                _check_line_in_valid_intervals_del_invalid
                # Returns: already_done / add_to_preferred_interval / add_to_preferred_interval_INDEX
            fi

            # Done afterwards as it messes with the line numbering when inserting.
            # Only remove content of lines before this line, but don't remove the actual lines.
            if [[ "$add_to_preferred_interval" = 'true' ]]
            then
                _insert_preferred_interval

                # Update interval numbers
                adjust_interval_linenumbers "$line" $add_to_preferred_interval_INDEX
                already_done='false'
            fi
        fi
    done <<< "${!eval_var_name}"

    if [[ "$already_done" = 'true' ]]; then
        return_value='already done'
    else
        return_value='success'
    fi
    return 0
}

add_multiline_content()
{
    if (( $# < 5 ))
    then
        return -1
    fi

    local -r FILE_PATH="$1"; shift       # 1
    local -r FILE_NAME="$1"; shift       # 2
    local -r VAR_NAME_PREFIX="$1"; shift        # 3
    local -r REF_TYPE="$1"; shift        # 4
    local -r REF_PLACEMENT="$1"; shift   # 5

    local dynamic_array_prefix="input_array"
    handle_input_arrays_dynamically "$dynamic_array_prefix" "$@"

    get_dynamic_array "${dynamic_array_prefix}1"
    allowed_intervals=("${dynamic_array[@]}")

    get_dynamic_array "${dynamic_array_prefix}2"
    preferred_interval=("${dynamic_array[@]}")

    get_dynamic_array "${dynamic_array_prefix}3"
    _intervals=("${dynamic_array[@]}")

    _check_valid_ref "$REF_TYPE" "$REF_PLACEMENT" || return $?

    _check_valid_intervals || return $?

    eval_var_name=$VAR_NAME_PREFIX # ${!eval_var_name}
    eval_var_name_exists=${VAR_NAME_PREFIX}_exists # ${!eval_var_name_exists}
    eval_var_name_start=${VAR_NAME_PREFIX}_start # ${!eval_var_name_start}
    eval_var_name_end=${VAR_NAME_PREFIX}_end # ${!eval_var_name_end}

    exists_in_file "$FILE_PATH/$FILE_NAME" "${!eval_var_name}" $VAR_NAME_PREFIX

    evaluated_var_name_start=${!eval_var_name_start}
    evaluated_var_name_end=${!eval_var_name_end}

    already_done='true'
    if ! ${!eval_var_name_exists}
    then
        if [[ $REF_TYPE == "INBETWEEN" ]]
        then
            _insert_preferred_interval_multiline
            
            # Update if statement variables if they got shifted
            adjust_else_elif_fi_linenumbers "${!eval_var_name}" $insert_line_number

            # Update interval numbers
            adjust_interval_linenumbers "${!eval_var_name}" $add_to_preferred_interval_INDEX

            declare -g "${VAR_NAME_PREFIX}_exists=false" # EXISTS since before = not true
            already_done='false'
        fi
    else    
        # The text already exists in the file

        if [[ $REF_TYPE == "INBETWEEN" ]]
        then

            _find_multiline_in_intervals

            _check_multiline_in_valid_intervals_del_invalid
            # Returns: already_done / add_to_preferred_interval / add_to_preferred_interval_INDEX

            # Done afterwards as it messes with the line numbering when inserting.
            # Only remove content of lines before this line, but don't remove the actual lines.
            if [[ "$add_to_preferred_interval" == 'true' ]]
            then
                _insert_preferred_interval_multiline

                # Update if statement variables if they got shifted
                adjust_else_elif_fi_linenumbers "${!eval_var_name}" $insert_line_number
                
                # Update interval numbers
                adjust_interval_linenumbers "${!eval_var_name}" $add_to_preferred_interval_INDEX

                declare -g "${VAR_NAME_PREFIX}_exists=false" # EXISTS since before = not true
                already_done='false'
            fi

        fi


        # if (( ${!eval_var_name_start} < $IF_STATEMENT_START ))
        # then # Line is before if statement
        #     echo -e "Line exists and is before if statement.\n"
        # elif (( $FI_LINE_NUMBER < ${!eval_var_name_start} ))
        # then # Lines are after whole if statement (fi)
        #     # Remove content of that line
        #     echo "Content exists, but is after if statement."
        #     echo "Remove content of lines ${!eval_var_name_start}-${!eval_var_name_end}"
        #     sed -i "${!eval_var_name_start},${!eval_var_name_end}d" "$FILE_PATH/$FILE_NAME"
            
        #     # Commented out below does not work as intended.
        #     # If ending with backslash, but not a backslash before that (double or more)
        #     # then replace with double backslash. Making sure that a single one is 
        #     # replaced with a double
        #     # https://stackoverflow.com/a/9306228/12374737
        #     # "Where (?<!x) means "only if it doesn't have 'x' before this point"."
        #     # BASHRC_INPUT2=$(echo "$BASHRC_INPUT2" | sed 's/(?<!\\)[\\]{1}$/\\\\/gm')

        #     # Replace backslashes with double backslashes to have 'sed' insert line at
        #     # line number later work as expected
        #     TMP=$(echo "${!eval_var_name}")
        #     TMP=$(echo "$TMP" | sed 's/\\/\\\\/g')
        #     # Replace backslash at end of line with an extra backslash to have 'sed' 
        #     # insert line at line number later work as expected
        #     TMP=$(echo "$TMP" | sed -E 's/[\\]$/\\\\/gm')
            
        #     declare -g "${VAR_NAME_PREFIX}=${TMP}"

        #     sed -i "${IF_STATEMENT_START}i ${!eval_var_name}" "$FILE_PATH/$FILE_NAME"
            
        #     # Increment if statement variables as they got shifted
        #     adjust_else_elif_fi_linenumbers "${!eval_var_name}"

        #     declare -g "$VARNAME_exists=false"
        # else
        #     echo "Content found in if statement even though it shouldn't be there."
        #     echo "LINE FOUND:"
        #     echo "${!eval_var_name}"
        #     echo "AT LINES: ${!eval_var_name_start}-${!eval_var_name_end}"
        #     return -1
        # fi
    fi

    if [[ "$already_done" == 'true' ]]
    then
        return_value='already done'
    else
        return_value='success'
    fi
}

_check_valid_ref()
{
    local REF_TYPE="$1"
    local REF_PLACEMENT="$2"

    # Check validity of input: 'REF_TYPE' & 'REF_PLACEMENT'
    case "$REF_TYPE" in
    "INBETWEEN")
        case "$REF_PLACEMENT" in
        "START"|"END")
            ;;
        *)

            result_value='Reference placement does not have a valid value.'
            return 1
            ;;
        esac
        ;;
    "LINE")
        case "$REF_PLACEMENT" in
        "BEFORE"|"AFTER")
            ;;
        *)

            result_value='Reference placement does not have a valid value.'
            return 1
            ;;
        esac
        ;;
    *)

        result_value='Reference type does not have a valid value.'
        return 1
        ;;
    esac
}

_check_valid_intervals()
{
    # Check validity of input lengths: 'intervals', 'preferred_intervals' & 'allowed_intervals'
    if (( ${#_intervals[@]} < 2 ))
    then

        result_value='Intervals length is too short.'
        return 1
    elif (( ${#_intervals[@]} + 1 != ${#preferred_interval[@]} ))
    then

        result_value='Preferred intervals is not the right length to match Intervals.'
        return 1
    elif (( ${#_intervals[@]} + 1 != ${#allowed_intervals[@]} ))
    then

        result_value='Allowed intervals is not the right length to match Intervals.'
        return 1
    fi

    # Get index of preferred interval
    # Check validity of input matching: 'preferred_interval' & 'allowed_intervals'
    declare -i preferred_index
    declare -i num_preferred=0
    for i in "${!preferred_interval[@]}"
    do
        if [[ "${preferred_interval[$i]}" == 'true' ]]
        then
            preferred_index=$i
            ((num_preferred++)) || true # Force true

            if [[ "${allowed_intervals[$i]}" == 'false' ]]
            then

                result_value='Allowed intervals and Preferred interval does not match.'
                return 1
            else
            fi
        else
        fi
    done

    # Check validity of input: 'preferred_interval'
    case "$num_preferred" in
    0)

        result_value='Preferred interval does not contain valid values.'
        return 1
        ;;
    1)
        ;;
    *)

        result_value='Preferred interval does not contain valid values.'
        return 1
        ;;
    esac

}

_find_line_in_intervals()
{
    # Mark in which intervals the content exists
    local num_items=${#_intervals[@]}
    local found_in_interval
    exists_in_intervals=()
    for ((i=0;i<=num_items;i++))
    do
        case $i in
        0)
            if (( line_start < _intervals[i] ))
            then
                found_in_interval='true'
            else
                found_in_interval='false'
            fi;;

        $num_items)
            if (( _intervals[i-1] < line_start ))
            then
                found_in_interval='true'
            else
                found_in_interval='false'
            fi;;

        *)
            if (( _intervals[i-1] <= line_start )) && (( line_start <= _intervals[i] ))
            then
                found_in_interval='true'
            else
                found_in_interval='false'
            fi;;
        esac

        exists_in_intervals+=( "$found_in_interval" )
    done
}

_find_multiline_in_intervals()
{
    # Mark in which intervals the content exists
    declare -i num_items=${#_intervals[@]}
    declare found_in_interval
    declare -a exists_in_intervals=()
    for ((i=0;i<=num_items;i++))
    do
        case $i in
        0)
            if (( evaluated_var_name_start < _intervals[i] )) && \
                (( evaluated_var_name_end   < _intervals[i] ))
            then
                found_in_interval='true'
            else
                found_in_interval='false'
            fi;;

        $num_items)
            if (( _intervals[i-1] < evaluated_var_name_start )) && \
                (( _intervals[i-1] < evaluated_var_name_end   ))
            then
                found_in_interval='true'
            else
                found_in_interval='false'
            fi;;

        *)
            if (( _intervals[i-1] <= evaluated_var_name_start )) && (( evaluated_var_name_start <= _intervals[i] )) && \
                (( _intervals[i-1] <= evaluated_var_name_end   )) && (( evaluated_var_name_end   <= _intervals[i] ))
            then
                found_in_interval='true'
            else
                found_in_interval='false'
            fi;;
        esac

    exists_in_intervals+=( $found_in_interval )
    done
}

_check_line_in_valid_intervals_del_invalid()
{
    # Compare where it exists with where it is allowed and preferred to exist
    add_to_preferred_interval='false'

    for ((j=0;j<${#exists_in_intervals[@]};j++))
    do
        # Add start and end of intervals. _intervals could have been updated
        # since last calculation
        file_num_lines=$(wc -l "$FILE_PATH/$FILE_NAME" | cut -f1 -d' ')
        tmp_intervals=(0 ${_intervals[@]} "$file_num_lines")
        if [[ "${exists_in_intervals[$j]}" = 'true' ]]
        then
            if ${allowed_intervals[$j]}
            then
                if ${preferred_interval[$j]}
                then
                else
                    # Remove the line
                    sed -i "${line_start}d" "$FILE_PATH/$FILE_NAME"
                    # Insert empty line in its place
                    sed -i "$((line_start - 1))a $NL" "$FILE_PATH/$FILE_NAME"
                    already_done='false'
                fi
            else # Exists in DISALLOWED interval

                # Remove the line
                sed -i "${line_start}d" "$FILE_PATH/$FILE_NAME"
                # Insert empty line in its place
                sed -i "$((line_start - 1))a $NL" "$FILE_PATH/$FILE_NAME"

                already_done='false'
            fi
        else # Does NOT exist in interval
            if ${preferred_interval[$j]}
            then

                add_to_preferred_interval='true'
                add_to_preferred_interval_INDEX=$j
                already_done='false'
            fi
        fi
    done
}

_check_multiline_in_valid_intervals_del_invalid()
{
    # Compare where it exists with where it is allowed and preferred to exist
    add_to_preferred_interval='false'

    for ((j=0;j<${#exists_in_intervals[@]};j++))
    do
        # Add start and end of intervals. _intervals could have been updated
        # since last calculation
        tmp_intervals=(0 ${_intervals[@]} $(wc -l "$FILE_PATH/$FILE_NAME" | cut -f1 -d' '))
        if ${exists_in_intervals[$j]}
        then
            if ${allowed_intervals[$j]}
            then
                if ${preferred_interval[$j]}
                then
                else
                    # Remove the lines
                    sed -i "${evaluated_var_name_start},${evaluated_var_name_end}d" "$FILE_PATH/$FILE_NAME"
                    # Insert empty lines in its place
                    for ((i=1; i<=(evaluated_var_name_end - evaluated_var_name_start + 1); i++))
                    do
                        sed -i "$((evaluated_var_name_start - 1))a $NL" "$FILE_PATH/$FILE_NAME"
                    done

                    already_done='false'
                fi
            else # Exists in DISALLOWED interval

                # Remove the lines
                sed -i "${evaluated_var_name_start},${evaluated_var_name_end}d" "$FILE_PATH/$FILE_NAME"
                # Insert empty lines in its place
                for ((i=1; i<=(evaluated_var_name_end - evaluated_var_name_start + 1); i++))
                do
                    sed -i "$((evaluated_var_name_start - 1))a $NL" "$FILE_PATH/$FILE_NAME"
                done

                already_done='false'
            fi
        else # Does NOT exist in interval
            if ${preferred_interval[$j]}
            then

                add_to_preferred_interval='true'
                add_to_preferred_interval_INDEX=$j
                
                already_done='false'
            fi
        fi
    done
}

_insert_preferred_interval()
{
    # If ending with backslash, add another one to behave as wanted with sed
    line=$(echo "$line" | sed -E 's/[\\]$/\\\\/gm')
    
    # Place content in allowed interval
    case "$REF_PLACEMENT" in
        "START")
            insert_line_number="$(( tmp_intervals[preferred_index] + 1))"
            line_to_get_whitespace=$(sed -n  "$((insert_line_number - 1))"p "$FILE_PATH/$FILE_NAME")
            whitespace_indentation="$(grep -Eo "^\s*" <<< "$line_to_get_whitespace")"
            sed -i "${insert_line_number}i $whitespace_indentation\\\t$line" "$FILE_PATH/$FILE_NAME"
            ;;
        *)
            insert_line_number="$((tmp_intervals[preferred_index + 1]))"
            line_to_get_whitespace=$(sed -n  "$insert_line_number"p "$FILE_PATH/$FILE_NAME")
            whitespace_indentation="$(grep -Eo "^\s*" <<< "$line_to_get_whitespace")"
            sed -i "${insert_line_number}i $whitespace_indentation\\\t$line" "$FILE_PATH/$FILE_NAME"
            ;;
    esac
}

_insert_preferred_interval_multiline()
{
    tmp_intervals=(0 ${_intervals[@]} $(wc -l "$FILE_PATH/$FILE_NAME" | cut -f1 -d' '))

    # Replace backslashes with double backslashes to have 'sed' insert line at
    # line number later work as expected
    TMP=$(echo "${!eval_var_name}" | sed 's/\\/\\\\/g')
    # Replace backslash at end of line with an extra backslash to have 'sed' 
    # insert line at line number later work as expected
    TMP=$(echo "$TMP" | sed -E 's/[\\]$/\\\\/gm')

    declare -g "${VAR_NAME_PREFIX}=${TMP}"

    # Place content in allowed interval
    case "$REF_PLACEMENT" in
        "START")
            insert_line_number="((tmp_intervals[preferred_index] + 1))"
            line_to_get_whitespace=$(sed -n  "$((insert_line_number - 1))"p "$FILE_PATH/$FILE_NAME")
            whitespace_indentation="$(grep -Eo "^\s*" <<< "$line_to_get_whitespace")"

            sed -i "${insert_line_number}i ${whitespace_indentation}${!eval_var_name}" "$FILE_PATH/$FILE_NAME"
            ;;
        *)
            insert_line_number="$((tmp_intervals[preferred_index + 1] - 1))"
            line_to_get_whitespace=$(sed -n  "$((insert_line_number - 1))"p "$FILE_PATH/$FILE_NAME")
            whitespace_indentation="$(grep -Eo "^\s*" <<< "$line_to_get_whitespace")"
            sed -i "${insert_line_number}i ${whitespace_indentation}${!eval_var_name}" "$FILE_PATH/$FILE_NAME"
            ;;
    esac
}
