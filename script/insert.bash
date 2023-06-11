
adjust_interval_linenumbers()
{
    INPUT="$1"
    INDEX_LIMIT="$2"

    # Increment if statement variables as they got shifted
    debug_echo 100 "_intervals before:         ${_intervals[*]}"
    debug_echo 100 "index to change:          $INDEX_LIMIT"
    NUM_LINES=$(echo -n "$INPUT" | grep -c '^')
    debug_echo 100 "number of lines in input: $NUM_LINES"
    for i in "${!_intervals[@]}"
    do
        if (( i >= INDEX_LIMIT ))
        then
            _intervals[$i]=$((_intervals[i] + NUM_LINES))
        fi
    done
    debug_echo 100 "_intervals after:          ${_intervals[*]}"
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
        debug_echo 100 "Function 'add_single_line_content' need at least 5 inputs, you gave $#."
        result_value="Function 'add_single_line_content' need at least 5 inputs, you gave $#."
        return -1
    fi

    FILE_PATH="$1"; shift       # 1
    FILE_NAME="$1"; shift       # 2
    VAR_NAME="$1"; shift        # 3
    REF_TYPE="$1"; shift        # 4
    REF_PLACEMENT="$1"; shift   # 5

    debug_echo 100 -e "\nFILE_PATH: $FILE_PATH"
    debug_echo 100 "FILE_NAME: $FILE_NAME"
    debug_echo 100 "VAR_NAME: $VAR_NAME"
    debug_echo 100 "REF_TYPE: $REF_TYPE"
    debug_echo 100 "REF_PLACEMENT: $REF_PLACEMENT"

    # https://stackoverflow.com/questions/10953833/passing-multiple-distinct-arrays-to-a-shell-function
    
    # Check validity of input: 'REF_TYPE' & 'REF_PLACEMENT'
    case "$REF_TYPE" in
    "INBETWEEN")
        case "$REF_PLACEMENT" in
        "START")
            ;;
        "END")
            ;;
        *)
            debug_echo 100 "Reference placement: $REF_PLACEMENT"
            debug_echo 100 "Reference placement does not have a valid value."
            debug_echo 100 "Options to choose from:"
            debug_echo 100 "- 'START'"
            debug_echo 100 "- 'END'"

            result_value='Reference placement does not have a valid value.'
            return -1
            ;;
        esac
        ;;
    "LINE")
        case "$REF_PLACEMENT" in
        "BEFORE")
            ;;
        "AFTER")
            ;;
        *)
            debug_echo 100 "Reference placement: $REF_PLACEMENT"
            debug_echo 100 "Reference placement does not have a valid value."
            debug_echo 100 "Options to choose from:"
            debug_echo 100 "- 'BEFORE'"
            debug_echo 100 "- 'AFTER'"

            result_value='Reference placement does not have a valid value.'
            return -1
            ;;
        esac
        ;;
    *)
        debug_echo 100 "Reference type: $REF_TYPE"
        debug_echo 100 "Reference type does not have a valid value."
        debug_echo 100 "Options to choose from:"
        debug_echo 100 "- 'INBETWEEN'"
        debug_echo 100 "- 'LINE'"

        result_value='Reference type does not have a valid value.'
        return -1
        ;;
    esac

    #
    ## Following are still function inputs in form of arrays
    #
    if [[ $REF_TYPE == "INBETWEEN" ]]
    then
        declare -i array_num=1 # Extra array for '_intervals'
    else
        declare -i array_num=2 # Start number 2 to skip first array
    fi

    declare -i num_args
    declare -ag _intervals=() # Values may be updated with external function
    declare -a allowed_intervals=()
    declare -a preferred_interval=()

    # Get ending input arrays
    while (( $# )) ; do
        num_args=$1; shift
        while (( num_args-- > 0 )) 
        do
            case $array_num in
            1)
                _intervals+=( "$1" ); shift;;
            2)
                allowed_intervals+=( "$1" ); shift;;
            3)
                preferred_interval+=( "$1" ); shift;;
            *)
                ;;
            esac

        done
        ((array_num++)) || true # Force true
    done
    message="\n_intervals =         [ ${_intervals[@]} ]"
    debug_echo 100 -e "$message"
    message="allowed_intervals =  [ ${allowed_intervals[@]} ]"
    debug_echo 100 "$message"
    message="preferred_interval = [ ${preferred_interval[@]} ]\n"
    debug_echo 100 -e "$message"
    
    # Check validity of input lengths: 'intervals', 'preferred_intervals' & 'allowed_intervals'
    if (( ${#_intervals[@]} < 2 ))
    then
        debug_echo 100 "Length of Intervals: ${#_intervals[@]}"
        debug_echo 100 "Intervals length is too short."
        debug_echo 100 "Intervals should have a length of at least 2."

        result_value='Intervals length is too short.'
        return -1
    elif (( ${#_intervals[@]} + 1 != ${#preferred_interval[@]} ))
    then
        debug_echo 100 "Length of Intervals: ${#_intervals[@]}"
        debug_echo 100 "Length of Preferred intervals: ${#preferred_interval[@]}"
        debug_echo 100 "Preferred intervals is not the right length to match Intervals."
        debug_echo 100 "Preferred intervals should be of length $((${#_intervals[@]} + 1))"
        
        result_value='Preferred intervals is not the right length to match Intervals.'
        return -1
    elif (( ${#_intervals[@]} + 1 != ${#allowed_intervals[@]} ))
    then
        debug_echo 100 "Length of Intervals: ${#_intervals[@]}"
        debug_echo 100 "Length of Allowed intervals: ${#allowed_intervals[@]}"
        debug_echo 100 "Allowed intervals is not the right length to match Intervals."
        debug_echo 100 "Allowed intervals should be of length $((${#_intervals[@]} + 1))"

        result_value='Allowed intervals is not the right length to match Intervals.'
        return -1
    fi

    # Get index of preferred interval
    # Check validity of input matching: 'preferred_interval' & 'allowed_intervals'
    declare -i preferred_index
    declare -i num_preferred=0
    for i in "${!preferred_interval[@]}"
    do
        debug_echo 100 "allowed_intervals[$i]: ${allowed_intervals[$i]}"
        debug_echo 100 "preferred_interval[$i]: ${preferred_interval[$i]}"
        if [[ "${preferred_interval[$i]}" == true ]]
        then
            debug_echo 100 "preferred_interval[$i] is true"
            preferred_index=$i
            ((num_preferred++)) || true # Force true

            if [[ "${allowed_intervals[$i]}" == false ]]
            then
                debug_echo 100 "allowed_intervals[$i] is false"
                debug_echo 100 "Allowed intervals = [ ${allowed_intervals[*]} ]"
                debug_echo 100 "Preferred interval: [ ${preferred_interval[*]} ]"
                debug_echo 100 "Allowed intervals and Preferred interval does not match."
                debug_echo 100 "The Preferred interval must also be an Allowed interval."

                result_value='Allowed intervals and Preferred interval does not match.'
                return -1
            else
                debug_echo 100 "allowed_intervals[$i] is true"
            fi
        else
            debug_echo 100 "preferred_interval[$i] is false"
        fi
    done

    # Check validity of input: 'preferred_interval'
    case "$num_preferred" in
    0)
        debug_echo 100 "Preferred interval: [ ${preferred_interval[*]} ]"
        debug_echo 100 "Preferred interval does not contain valid values."
        debug_echo 100 "Contains 0 true values, should contain exactly 1 true value."
        
        result_value='Preferred interval does not contain valid values.'
        return -1
        ;;
    1)
        ;;
    *)
        debug_echo 100 "Preferred interval: [ ${preferred_interval[*]} ]"
        debug_echo 100 "Preferred interval does not contain valid values."
        debug_echo 100 "Contains $num_preferred true values, should contain exactly 1 true value."

        result_value='Preferred interval does not contain valid values.'
        return -1
        ;;
    esac

    debug_echo 100 "Found preferred interval in index $i."

    EVAL_VAR_NAME=$VAR_NAME # ${!EVAL_VAR_NAME}
    EVAL_VAR_NAME_EXISTS=${VAR_NAME}_EXISTS # ${!EVAL_VAR_NAME_EXISTS}

    debug_echo 1 -e "\n*********************************************************************"
    debug_echo 1 "***** Start input of $VAR_NAME **********************************"
    debug_echo 1 "*********************************************************************"

    declare -g ${VAR_NAME}_EXISTS=true

    # Iterate over every line of VAR_NAME as they are independent
    already_done=true
    while IFS= read -r line
    do
        debug_echo 100 "##################################################################"
        debug_echo 100 "Checking new line of variable. ###################################"
        debug_echo 100 -e "##################################################################\n"
        exists_in_file "$FILE_PATH/$FILE_NAME" "$line" LINE

        if [[ $REF_TYPE == "INBETWEEN" ]]
        then
            debug_echo 100 -e "\nReference type: INBETWEEN\n"
            if ! $LINE_EXISTS
            then
                ADD_TO_PREFERRED_INTERVAL=true
                already_done=false

                file_num_lines=$(wc -l "$FILE_PATH/$FILE_NAME" | cut -f1 -d' ')
                tmp_intervals=(0 ${_intervals[@]} "$file_num_lines")
            else

                # Mark in which intervals the content exists
                declare -i num_items=${#_intervals[@]}
                declare found_in_interval
                declare -a exists_in_intervals=()
                for ((i=0;i<=num_items;i++))
                do
                    case $i in
                    0)
                        if (( LINE_START < _intervals[i] ))
                        then
                            debug_echo 100 "Line number $LINE_START IS in the interval < ${_intervals[$i]}. #####"
                            found_in_interval=true
                        else
                            debug_echo 100 "Line number $LINE_START is NOT in the interval < ${_intervals[$i]}. *****"
                            found_in_interval=false
                        fi;;

                    $num_items)
                        if (( _intervals[i-1] < LINE_START ))
                        then
                            debug_echo 100 "Line number $LINE_START IS in the interval > ${_intervals[$((i-1))]}. #####"
                            found_in_interval=true
                        else
                            debug_echo 100 "Line number $LINE_START is NOT in the interval > ${_intervals[$((i-1))]}. *****"
                            found_in_interval=false
                        fi;;

                    *)
                        if (( _intervals[i-1] <= LINE_START )) && (( LINE_START <= _intervals[i] ))
                        then
                            debug_echo 100 "Line number $LINE_START IS in interval ${_intervals[$((i-1))]} - ${_intervals[$i]}. #####"
                            found_in_interval=true
                        else
                            debug_echo 100 "Line number $LINE_START is NOT in interval ${_intervals[$((i-1))]} - ${_intervals[$i]}. *****"
                            found_in_interval=false
                        fi;;
                    esac
                    debug_echo 100 " "

                    exists_in_intervals+=( $found_in_interval )
                done


                # Compare where it exists with where it is allowed and preferred to exist
                ADD_TO_PREFERRED_INTERVAL=false
                str="exists_in_intervals: [${exists_in_intervals[*]}]"
                debug_echo 100 -e "$str"
                str="allowed_intervals:   [${allowed_intervals[*]}]"
                debug_echo 100 -e "$str"
                str="preferred_interval:  [${preferred_interval[*]}]\n"
                debug_echo 100 -e "$str"
                for ((j=0;j<${#exists_in_intervals[@]};j++))
                do
                    # Add start and end of intervals. _intervals could have been updated
                    # since last calculation
                    file_num_lines=$(wc -l "$FILE_PATH/$FILE_NAME" | cut -f1 -d' ')
                    tmp_intervals=(0 ${_intervals[@]} "$file_num_lines")
                    debug_echo 100 "-------------------------"
                    debug_echo 100 "Checking interval $j"
                    debug_echo 100 -e "-------------------------\n"
                    if ${exists_in_intervals[$j]}
                    then
                        if ${allowed_intervals[$j]}
                        then
                            debug_echo 100 "Exists in allowed interval."
                            if ${preferred_interval[$j]}
                            then
                                debug_echo 100 "Exists in the preferred interval."
                            else
                                debug_echo 100 "Is not in the preferred interval."
                                debug_echo 100 -e "Remove content of line $LINE_START\n"
                                # Remove the line
                                sed -i "${LINE_START}d" "$FILE_PATH/$FILE_NAME"
                                # Insert empty line in its place
                                sed -i "$((LINE_START - 1))a $NL" "$FILE_PATH/$FILE_NAME"
                                already_done=false
                            fi
                        else # Exists in DISALLOWED interval

                            debug_echo 100 "Exists in DISALLOWED interval."
                            debug_echo 100 -e "Remove content of line $LINE_START\n"
                            # Remove the line
                            sed -i "${LINE_START}d" "$FILE_PATH/$FILE_NAME"
                            # Insert empty line in its place
                            sed -i "$((LINE_START - 1))a $NL" "$FILE_PATH/$FILE_NAME"

                            already_done=false
                        fi
                    else # Does NOT exist in interval
                        if ${preferred_interval[$j]}
                        then
                            debug_echo 100 "Does NOT exist in preferred interval"
                            debug_echo 100 "To be added in preferred interval"
                            
                            ADD_TO_PREFERRED_INTERVAL=true
                            ADD_TO_PREFERRED_INTERVAL_INDEX=$j
                            already_done=false
                        fi
                    fi
                    debug_echo 100 "-^-^-^-^-^-^-^-^-^-"
                    debug_echo 100 "DONE with interval"
                    debug_echo 100 -e "-^-^-^-^-^-^-^-^-^-\n"
                done
                debug_echo 100 "-*-*-*-*-*-*-*-*-*-*-*-*-"
                debug_echo 100 "Checked all intervals."
                debug_echo 100 "-*-*-*-*-*-*-*-*-*-*-*-*-"
            fi

            # Done afterwards as it messes with the line numbering when inserting.
            # Only remove content of lines before this line, but don't remove the actual lines.
            if $ADD_TO_PREFERRED_INTERVAL
            then
                debug_echo 100 "Place in preferred interval."
                # If ending with backslash, add another one to behave as wanted with sed
                line=$(echo "$line" | sed -E 's/[\\]$/\\\\/gm')
                
                # Place content in allowed interval
                case "$REF_PLACEMENT" in
                    "START")
                        insert_line_number="$(( tmp_intervals[preferred_index] + 1))"
                        line_to_get_whitespace=$(sed -n  "$((insert_line_number - 1))"p "$FILE_PATH/$FILE_NAME")
                        whitespace_indentation="$(grep -Eo "^\s*" <<< "$line_to_get_whitespace")"
                        debug_echo 100 "line num line_to_get_whitespace: '$((insert_line_number - 1))'"
                        debug_echo 100 "line_to_get_whitespace: '$line_to_get_whitespace'"
                        debug_echo 100 "whitespace_indentation: '$whitespace_indentation'"
                        sed -i "${insert_line_number}i $whitespace_indentation\\\t$line" "$FILE_PATH/$FILE_NAME"
                        ;;
                    *)
                        insert_line_number="$((tmp_intervals[preferred_index + 1]))"
                        line_to_get_whitespace=$(sed -n  "$insert_line_number"p "$FILE_PATH/$FILE_NAME")
                        whitespace_indentation="$(grep -Eo "^\s*" <<< "$line_to_get_whitespace")"
                        debug_echo 100 "insert_line_number: '$insert_line_number'"
                        debug_echo 100 "line_to_get_whitespace: '$line_to_get_whitespace'"
                        debug_echo 100 "whitespace_indentation: '$whitespace_indentation'"
                        sed -i "${insert_line_number}i $whitespace_indentation\\\t$line" "$FILE_PATH/$FILE_NAME"
                        ;;
                esac
                debug_echo 100 "Placed in preferred interval."
                # Update interval numbers
                adjust_interval_linenumbers "$line" $ADD_TO_PREFERRED_INTERVAL_INDEX
                already_done=false
            fi
            debug_echo 100 " "
        fi


    done <<< "${!EVAL_VAR_NAME}"

    debug_echo 1 -e "\n*********************************************************************"
    debug_echo 1 "***** End input of $VAR_NAME ************************************"
    debug_echo 1 "*********************************************************************"

    if $already_done; then
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
        debug_echo 100 "Function 'add_multiline_content' need at least 5 inputs, you gave $#."
        return -1
    fi

    FILE_PATH="$1"; shift       # 1
    FILE_NAME="$1"; shift       # 2
    VAR_NAME="$1"; shift        # 3
    REF_TYPE="$1"; shift        # 4
    REF_PLACEMENT="$1"; shift   # 5

    debug_echo 100 -e "\nFILE_PATH: $FILE_PATH"
    debug_echo 100 "FILE_NAME: $FILE_NAME"
    debug_echo 100 "VAR_NAME: $VAR_NAME"
    debug_echo 100 "REF_TYPE: $REF_TYPE"
    debug_echo 100 "REF_PLACEMENT: $REF_PLACEMENT"

     # Check validity of input: 'REF_TYPE' & 'REF_PLACEMENT'
    case "$REF_TYPE" in
    "INBETWEEN")
        case "$REF_PLACEMENT" in
        "START")
            ;;
        "END")
            ;;
        *)
            debug_echo 100 "Reference placement: $REF_PLACEMENT"
            debug_echo 100 "Reference placement does not have a valid value."
            debug_echo 100 "Options to choose from:"
            debug_echo 100 "- 'START'"
            debug_echo 100 "- 'END'"

            return_value='Reference placement does not have a valid value.s'
            return -1
            ;;
        esac
        ;;
    "LINE")
        case "$REF_PLACEMENT" in
        "BEFORE")
            ;;
        "AFTER")
            ;;
        *)
            debug_echo 100 "Reference placement: $REF_PLACEMENT"
            debug_echo 100 "Reference placement does not have a valid value."
            debug_echo 100 "Options to choose from:"
            debug_echo 100 "- 'BEFORE'"
            debug_echo 100 "- 'AFTER'"

            return_value='Reference placement does not have a valid value.'
            return -1
            ;;
        esac
        ;;
    *)
        debug_echo 100 "Reference type: $REF_TYPE"
        debug_echo 100 "Reference type does not have a valid value."
        debug_echo 100 "Options to choose from:"
        debug_echo 100 "- 'INBETWEEN'"
        debug_echo 100 "- 'LINE'"

        return_value='Reference type does not have a valid value.'
        return -1
        ;;
    esac


    if [[ $REF_TYPE == "INBETWEEN" ]]
    then
        declare -i array_num=1 # Extra array for '_intervals'
    else
        declare -i array_num=2
    fi

    declare -i num_args
    declare -ag _intervals=() # Values may be updated with external function
    declare -a allowed_intervals=()
    declare -a preferred_interval=()

    # Get ending input arrays
    while (( $# )) ; do
        num_args=$1; shift
        while (( num_args-- > 0 )) 
        do
            case $array_num in
            1)
                _intervals+=( "$1" ); shift;;
            2)
                allowed_intervals+=( "$1" ); shift;;
            3)
                preferred_interval+=( "$1" ); shift;;
            *)
                ;;
            esac

        done
        ((array_num++)) || true # Force true
    done

    debug_echo 100 -e "\n_intervals =         [ ${_intervals[*]} ]"
    debug_echo 100 "allowed_intervals =  [ ${allowed_intervals[*]} ]"
    debug_echo 100 -e "preferred_interval = [ ${preferred_interval[*]} ]\n"

    # Check validity of input lengths: 'intervals', 'preferred_intervals' & 'allowed_intervals'
    if (( ${#_intervals[@]} < 2 ))
    then
        debug_echo 100 "Length of Intervals: ${#_intervals[@]}"
        debug_echo 100 "Intervals length is too short."
        debug_echo 100 "Intervals should have a length of at least 2."

        return_value='Intervals length is too short.'
        return -1
    elif (( ${#_intervals[@]} + 1 != ${#preferred_interval[@]} ))
    then
        debug_echo 100 "Length of Intervals: ${#_intervals[@]}"
        debug_echo 100 "Length of Preferred intervals: ${#preferred_interval[@]}"
        debug_echo 100 "Preferred intervals is not the right length to match Intervals."
        debug_echo 100 "Preferred intervals should be of length $((${#_intervals[@]} + 1))"

        return_value="Preferred intervals is not the right length to match Intervals."
        return -1
    elif (( ${#_intervals[@]} + 1 != ${#allowed_intervals[@]} ))
    then
        debug_echo 100 "Length of Intervals: ${#_intervals[@]}"
        debug_echo 100 "Length of Allowed intervals: ${#allowed_intervals[@]}"
        debug_echo 100 "Allowed intervals is not the right length to match Intervals."
        debug_echo 100 "Allowed intervals should be of length $((${#_intervals[@]} + 1))"

        return_value="Allowed intervals is not the right length to match Intervals."
        return -1
    fi

    # Get index of preferred interval
    # Check validity of input matching: 'preferred_interval' & 'allowed_intervals'
    declare -i preferred_index
    declare -i num_preferred=0
    for i in "${!preferred_interval[@]}"
    do
        debug_echo 100 "allowed_intervals[$i]: ${allowed_intervals[$i]}"
        debug_echo 100 "preferred_interval[$i]: ${preferred_interval[$i]}"
        if [[ "${preferred_interval[$i]}" == true ]]
        then
            debug_echo 100 "preferred_interval[$i] is true"
            preferred_index=$i
            ((num_preferred++)) || true # Force true

            if [[ "${allowed_intervals[$i]}" == false ]]
            then
                debug_echo 100 "allowed_intervals[$i] is false"
                debug_echo 100 "Allowed intervals = [ ${allowed_intervals[*]} ]"
                debug_echo 100 "Preferred interval: [ ${preferred_interval[*]} ]"
                debug_echo 100 "Allowed intervals and Preferred interval does not match."
                debug_echo 100 "The Preferred interval must also be an Allowed interval."

                return_value='Allowed intervals and Preferred interval does not match.'
                return -1
            else
                debug_echo 100 "allowed_intervals[$i] is true"
            fi
        else
            debug_echo 100 "preferred_interval[$i] is false"
        fi
    done

    # Check validity of input: 'preferred_interval'
    case "$num_preferred" in
    0)
        debug_echo 100 "Preferred interval: [ ${preferred_interval[*]} ]"
        debug_echo 100 "Preferred interval does not contain valid values."
        debug_echo 100 "Contains 0 true values, should contain exactly 1 true value."

        return_value='Preferred interval does not contain valid values.'
        return -1
        ;;
    1)
        ;;
    *)
        debug_echo 100 "Preferred interval: [ ${preferred_interval[*]} ]"
        debug_echo 100 "Preferred interval does not contain valid values."
        debug_echo 100 "Contains $num_preferred true values, should contain exactly 1 true value."

        return_value='Preferred interval does not contain valid values.'
        return -1
        ;;
    esac

    debug_echo 100 "Found preferred interval in index $i."



    EVAL_VAR_NAME=$VAR_NAME # ${!EVAL_VAR_NAME}
    EVAL_VAR_NAME_EXISTS=${VAR_NAME}_EXISTS # ${!EVAL_VAR_NAME_EXISTS}
    EVAL_VAR_NAME_START=${VAR_NAME}_START # ${!EVAL_VAR_NAME_START}
    EVAL_VAR_NAME_END=${VAR_NAME}_END # ${!EVAL_VAR_NAME_END}

    debug_echo 1 -e "\n*********************************************************************"
    debug_echo 1 "***** Start input of $VAR_NAME **********************************"
    debug_echo 1 "*********************************************************************"

    exists_in_file "$FILE_PATH/$FILE_NAME" "${!EVAL_VAR_NAME}" $VAR_NAME

    EVALUATED_VAR_NAME_START=${!EVAL_VAR_NAME_START}
    EVALUATED_VAR_NAME_END=${!EVAL_VAR_NAME_END}

    already_done=true
    if ! ${!EVAL_VAR_NAME_EXISTS}
    then
        if [[ $REF_TYPE == "INBETWEEN" ]]
        then
            tmp_intervals=(0 ${_intervals[@]} $(wc -l "$FILE_PATH/$FILE_NAME" | cut -f1 -d' '))
            debug_echo 100 "Place in preferred interval."

            # Replace backslashes with double backslashes to have 'sed' insert line at
            # line number later work as expected
            TMP=$(echo "${!EVAL_VAR_NAME}")
            TMP=$(echo "$TMP" | sed 's/\\/\\\\/g')
            # Replace backslash at end of line with an extra backslash to have 'sed' 
            # insert line at line number later work as expected
            TMP=$(echo "$TMP" | sed -E 's/[\\]$/\\\\/gm')

            declare -g "${VAR_NAME}=${TMP}"

            # Place content in allowed interval
            case "$REF_PLACEMENT" in
                "START")
                    sed -i "$((tmp_intervals[preferred_index] + 1))i ${!EVAL_VAR_NAME}" "$FILE_PATH/$FILE_NAME"
                    # Update if statement variables if they got shifted
                    adjust_else_elif_fi_linenumbers "${!EVAL_VAR_NAME}" $((tmp_intervals[preferred_index] + 1))
                    ;;
                *)
                    sed -i "$((tmp_intervals[preferred_index + 1] - 1))i ${!EVAL_VAR_NAME}" "$FILE_PATH/$FILE_NAME"
                    # Update if statement variables if they got shifted
                    adjust_else_elif_fi_linenumbers "${!EVAL_VAR_NAME}" $((tmp_intervals[preferred_index + 1] - 1))
                    ;;
            esac
            debug_echo 100 "Placed in preferred interval."
            
            # Update interval numbers
            adjust_interval_linenumbers "${!EVAL_VAR_NAME}" $ADD_TO_PREFERRED_INTERVAL_INDEX

            declare -g "${VAR_NAME}_EXISTS=false" # EXISTS since before = not true
            already_done=false
        fi
    else    
        if [[ $REF_TYPE == "INBETWEEN" ]]
        then
            debug_echo 100 -e "\nReference type: INBETWEEN\n"

            # Mark in which intervals the content exists
            declare -i num_items=${#_intervals[@]}
            declare found_in_interval
            declare -a exists_in_intervals=()
            for ((i=0;i<=num_items;i++))
            do
                case $i in
                0)
                    if (( EVALUATED_VAR_NAME_START < _intervals[i] )) && \
                       (( EVALUATED_VAR_NAME_END   < _intervals[i] ))
                    then
                        debug_echo 100 "Line number $EVALUATED_VAR_NAME_START-$EVALUATED_VAR_NAME_END ARE in the interval < ${_intervals[$i]}. #####"
                        found_in_interval=true
                    else
                        debug_echo 100 "Line number $EVALUATED_VAR_NAME_START-$EVALUATED_VAR_NAME_END are NOT in the interval < ${_intervals[$i]}. *****"
                        found_in_interval=false
                    fi;;

                $num_items)
                    if (( _intervals[i-1] < EVALUATED_VAR_NAME_START )) && \
                       (( _intervals[i-1] < EVALUATED_VAR_NAME_END   ))
                    then
                        debug_echo 100 "Line numbers $EVALUATED_VAR_NAME_START-$EVALUATED_VAR_NAME_END ARE in the interval > ${_intervals[$((i-1))]}. #####"
                        found_in_interval=true
                    else
                        debug_echo 100 "Line number $EVALUATED_VAR_NAME_START-$EVALUATED_VAR_NAME_END are NOT in the interval > ${_intervals[$((i-1))]}. *****"
                        found_in_interval=false
                    fi;;

                *)
                    if (( _intervals[i-1] <= EVALUATED_VAR_NAME_START )) && (( EVALUATED_VAR_NAME_START <= _intervals[i] )) && \
                       (( _intervals[i-1] <= EVALUATED_VAR_NAME_END   )) && (( EVALUATED_VAR_NAME_END   <= _intervals[i] ))
                    then
                        debug_echo 100 "Line number $EVALUATED_VAR_NAME_START-$EVALUATED_VAR_NAME_END ARE in interval ${_intervals[$((i-1))]} - ${_intervals[$i]}. #####"
                        found_in_interval=true
                    else
                        debug_echo 100 "Line number $EVALUATED_VAR_NAME_START-$EVALUATED_VAR_NAME_END are NOT in interval ${_intervals[$((i-1))]} - ${_intervals[$i]}. *****"
                        found_in_interval=false
                    fi;;
                esac
                debug_echo 100 " "

            exists_in_intervals+=( $found_in_interval )
            done

            # Compare where it exists with where it is allowed and preferred to exist
            ADD_TO_PREFERRED_INTERVAL=false
            str="exists_in_intervals: [${exists_in_intervals[@]}]"
            debug_echo 100 -e "$str"
            str="allowed_intervals:   [${allowed_intervals[@]}]"
            debug_echo 100 -e "$str"
            str="preferred_interval:  [${preferred_interval[@]}]\n"
            debug_echo 100 -e "$str"
            for ((j=0;j<${#exists_in_intervals[@]};j++))
            do
                # Add start and end of intervals. _intervals could have been updated
                # since last calculation
                tmp_intervals=(0 ${_intervals[@]} $(wc -l "$FILE_PATH/$FILE_NAME" | cut -f1 -d' '))
                debug_echo 100 "-------------------------"
                debug_echo 100 "Checking interval $j"
                debug_echo 100 -e "-------------------------\n"
                if ${exists_in_intervals[$j]}
                then
                    if ${allowed_intervals[$j]}
                    then
                        debug_echo 100 "Exists in allowed interval."
                        if ${preferred_interval[$j]}
                        then
                            debug_echo 100 "Exists in the preferred interval."
                        else
                            debug_echo 100 "Is not in the preferred interval."
                            debug_echo 100 -e "Remove content of lines ${EVALUATED_VAR_NAME_START}-${EVALUATED_VAR_NAME_END}\n"
                            # Remove the lines
                            sed -i "${EVALUATED_VAR_NAME_START},${EVALUATED_VAR_NAME_END}d" "$FILE_PATH/$FILE_NAME"
                            # Insert empty lines in its place
                            for ((i=1; i<=(EVALUATED_VAR_NAME_END - EVALUATED_VAR_NAME_START + 1); i++))
                            do
                                sed -i "$((EVALUATED_VAR_NAME_START - 1))a $NL" "$FILE_PATH/$FILE_NAME"
                            done

                            already_done=false
                        fi
                    else # Exists in DISALLOWED interval

                        debug_echo 100 "Exists in DISALLOWED interval."
                        debug_echo 100 -e "Remove content of lines ${EVALUATED_VAR_NAME_START}-${EVALUATED_VAR_NAME_END}\n"
                        # Remove the lines
                        sed -i "${EVALUATED_VAR_NAME_START},${EVALUATED_VAR_NAME_END}d" "$FILE_PATH/$FILE_NAME"
                        # Insert empty lines in its place
                        for ((i=1; i<=(EVALUATED_VAR_NAME_END - EVALUATED_VAR_NAME_START + 1); i++))
                        do
                            sed -i "$((EVALUATED_VAR_NAME_START - 1))a $NL" "$FILE_PATH/$FILE_NAME"
                        done

                        already_done=false
                    fi
                else # Does NOT exist in interval
                    if ${preferred_interval[$j]}
                    then
                        debug_echo 100 "Does NOT exist in preferred interval"
                        debug_echo 100 "To be added in preferred interval"
                        
                        ADD_TO_PREFERRED_INTERVAL=true
                        ADD_TO_PREFERRED_INTERVAL_INDEX=$j
                        
                        already_done=false
                    fi
                fi
                debug_echo 100 "-^-^-^-^-^-^-^-^-^-"
                debug_echo 100 "DONE with interval"
                debug_echo 100 -e "-^-^-^-^-^-^-^-^-^-\n"
            done
            debug_echo 100 "-*-*-*-*-*-*-*-*-*-*-*-*-"
            debug_echo 100 "Checked all intervals."
            debug_echo 100 "-*-*-*-*-*-*-*-*-*-*-*-*-"


            # Done afterwards as it messes with the line numbering when inserting.
            # Only remove content of lines before this line, but don't remove the actual lines.
            if $ADD_TO_PREFERRED_INTERVAL
            then
                debug_echo 100 "Place in preferred interval."

                # Replace backslashes with double backslashes to have 'sed' insert line at
                # line number later work as expected
                TMP=$(echo "${!EVAL_VAR_NAME}")
                TMP=$(echo "$TMP" | sed 's/\\/\\\\/g')
                # Replace backslash at end of line with an extra backslash to have 'sed' 
                # insert line at line number later work as expected
                TMP=$(echo "$TMP" | sed -E 's/[\\]$/\\\\/gm')

                declare -g "${VAR_NAME}=${TMP}"

                # Place content in allowed interval
                case "$REF_PLACEMENT" in
                    "START")
                        sed -i "$((tmp_intervals[preferred_index] + 1))i ${!EVAL_VAR_NAME}" "$FILE_PATH/$FILE_NAME"
                        # Update if statement variables if they got shifted
                        adjust_else_elif_fi_linenumbers "${!EVAL_VAR_NAME}" $((tmp_intervals[preferred_index] + 1))
                        ;;
                    *)
                        sed -i "$((tmp_intervals[preferred_index + 1]))i ${!EVAL_VAR_NAME}" "$FILE_PATH/$FILE_NAME"
                        # Update if statement variables if they got shifted
                        adjust_else_elif_fi_linenumbers "${!EVAL_VAR_NAME}" $((tmp_intervals[preferred_index + 1] - 1))
                        ;;
                esac
                debug_echo 100 "Placed in preferred interval."
                
                # Update interval numbers
                adjust_interval_linenumbers "${!EVAL_VAR_NAME}" $ADD_TO_PREFERRED_INTERVAL_INDEX

                declare -g "${VAR_NAME}_EXISTS=false" # EXISTS since before = not true
                already_done=false
            fi

            debug_echo 1 -e "\n*********************************************************************"
            debug_echo 1  "***** End input of $VAR_NAME ************************************"
            debug_echo 1  "*********************************************************************"
            
        fi


        # if (( ${!EVAL_VAR_NAME_START} < $IF_STATEMENT_START ))
        # then # Line is before if statement
        #     echo -e "Line exists and is before if statement.\n"
        # elif (( $FI_LINE_NUMBER < ${!EVAL_VAR_NAME_START} ))
        # then # Lines are after whole if statement (fi)
        #     # Remove content of that line
        #     echo "Content exists, but is after if statement."
        #     echo "Remove content of lines ${!EVAL_VAR_NAME_START}-${!EVAL_VAR_NAME_END}"
        #     sed -i "${!EVAL_VAR_NAME_START},${!EVAL_VAR_NAME_END}d" "$FILE_PATH/$FILE_NAME"
            
        #     # Commented out below does not work as intended.
        #     # If ending with backslash, but not a backslash before that (double or more)
        #     # then replace with double backslash. Making sure that a single one is 
        #     # replaced with a double
        #     # https://stackoverflow.com/a/9306228/12374737
        #     # "Where (?<!x) means "only if it doesn't have 'x' before this point"."
        #     # BASHRC_INPUT2=$(echo "$BASHRC_INPUT2" | sed 's/(?<!\\)[\\]{1}$/\\\\/gm')

        #     # Replace backslashes with double backslashes to have 'sed' insert line at
        #     # line number later work as expected
        #     TMP=$(echo "${!EVAL_VAR_NAME}")
        #     TMP=$(echo "$TMP" | sed 's/\\/\\\\/g')
        #     # Replace backslash at end of line with an extra backslash to have 'sed' 
        #     # insert line at line number later work as expected
        #     TMP=$(echo "$TMP" | sed -E 's/[\\]$/\\\\/gm')
            
        #     declare -g "${VAR_NAME}=${TMP}"

        #     sed -i "${IF_STATEMENT_START}i ${!EVAL_VAR_NAME}" "$FILE_PATH/$FILE_NAME"
            
        #     # Increment if statement variables as they got shifted
        #     adjust_else_elif_fi_linenumbers "${!EVAL_VAR_NAME}"

        #     declare -g "$VARNAME_EXISTS=false"
        # else
        #     echo "Content found in if statement even though it shouldn't be there."
        #     echo "LINE FOUND:"
        #     echo "${!EVAL_VAR_NAME}"
        #     echo "AT LINES: ${!EVAL_VAR_NAME_START}-${!EVAL_VAR_NAME_END}"
        #     return -1
        # fi
    fi

    if $already_done
    then
        return_value='already done'
    else
        return_value='success'
    fi
}
