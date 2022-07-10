#!/bin/bash

PATH_SCRIPT="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
echo -e "\nLocation of script:"
echo -e "$PATH_SCRIPT\n"

################
### SETTINGS ###
################

# 2 entries per function
# 1st entry - Suffix of function. Function name should then follow the
#             naming "setup_<suffix>"
# 2nd entry - Description of function.
declare -a arr_setups=(vimdiff "vimdiff"
                       gitdifftool "vimdiff as git difftool"
                       trashcli "trash-cli and alias rm"
                       gitcompletionbash "git completion bash"
                       )

PATH_VIMCOLORSCHEME=~/.vim/colors
NAME_VIMCOLORSCHEME=mycolorscheme.vim

PATH_VIMRC=~
PATH_GITCONFIG=~
PATH_BASHRC=~
NAME_BASHRC=.bashrc

URL_GITCOMPLETIONBASH="https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash"
PATH_GITCOMPLETIONBASH=~
NAME_GITCOMPLETIONBASH=.git-completion.bash

#######################
### END OF SETTINGS ###
#######################

declare -g NL='
'

# Reads multiline text and inputs to variable
#
# Example usage:
# define VAR <<'EOF'
# abc'asdf"
#     $(dont-execute-this)
# foo"bar"'''
# EOF
define(){ IFS=$'\n' read -r -d '' ${1} || true; }

# Checks if variable content exists in file
# Input: 2 arguments
# 1 - Filename
# 2 - Multiline variable. Must be quoted
# 3 - Variable name to create results from. Creates:
#     $3_EXISTS=true/false - Tells whether if $2 where found in $1
#     $3_START - Start line number of where $2 where found in $1
#     $3_END - End line number of where $2 where found in $1
exists_in_file()
{
    DEBUG=true
    FILECONTENT=$(<$1)
    CONTENT_TO_CHECK="$2"

    declare -g $3_EXISTS=false

    # Remove trailing whitespace
    FILECONTENT="$(echo "${FILECONTENT}" | sed -e 's/[[:space:]]*$//')"
    # FILECONTENT=$(echo "$FILECONTENT" | sed 's/\\*$//g')
    # Remove leading and trailing whitespace
    # FILECONTENT="$(echo "${FILECONTENT}" |  sed 's/^[ \t]*//;s/[ \t]*$//')"

    
    case "$CONTENT_TO_CHECK" in
        *"$NL"*) # CONTENT_TO_CHECK is multiple lines
            if $DEBUG
            then
                echo "CONTENT_TO_CHECK: More than one line"
                echo "CONTENT_TO_CHECK:"
                echo "$CONTENT_TO_CHECK"
                echo ""
            fi
            ;;
        *) # CONTENT_TO_CHECK is one line
            if $DEBUG
            then
                echo "CONTENT_TO_CHECK: Is one line"
                echo "CONTENT_TO_CHECK:"
                echo "$CONTENT_TO_CHECK"
                # Remove leading & trailing whitespace
                CONTENT_TO_CHECK_WO_WHITESPACE=$(sed 's/^[ \t]*//;s/[ \t]*$//' <<< "$CONTENT_TO_CHECK")
                echo -e "\nGREP output:"
                # Remove leading (& trailing again without meaning)
                # Grep using content without leading or trailing whitespace
                sed 's/^[ \t]*//;s/[ \t]*$//' <<< "$FILECONTENT" | grep -Fxn "$CONTENT_TO_CHECK_WO_WHITESPACE" --color
                echo ""
            fi

            # Remove leading (& trailing again without meaning)
            # Grep using content without leading or trailing whitespace
            LINE_NUMBER=$(sed 's/^[ \t]*//;s/[ \t]*$//' <<< "$FILECONTENT" | grep -Fxn "$CONTENT_TO_CHECK_WO_WHITESPACE" | cut -f1 -d:)
            
            if [[ -n "$LINE_NUMBER" ]] ;
            then

                if $DEBUG; then echo "TRUE. Did find the content at line $LINE_NUMBER"; fi
                declare -g $3_START=${LINE_NUMBER}
                declare -g $3_END=${LINE_NUMBER}
                # For eval and print within this function
                START=$3_START
                END=$3_END
                declare -g $3_EXISTS=true

                if $DEBUG; then echo "START: ${!START}, END: ${!END}"; fi
                return 0
            else
                if $DEBUG; then echo "FALSE. Did not find the content."; fi
                return -1
            fi ;;
    esac

    # If multiple lines
    REPLACED_CONTENT=${FILECONTENT/"$CONTENT_TO_CHECK"/}

    if $DEBUG
    then
        # echo "Grep Start"
        # echo "$2" | grep 'if \[ "\$color_prompt" = yes \];'
        # RETURN=$?
        # echo "Grep End"
        # echo "RETURN $RETURN"
        if [[ "$RETURN" == 0 ]]
        then
            vimdiff <(echo "$FILECONTENT") <(echo "$REPLACED_CONTENT")
            echo -e "\n\nSTART DIFF:"
            diff <(echo "$FILECONTENT") <(echo "$REPLACED_CONTENT")
            echo -e "END DIFF\n\n"
        fi
    fi
    
    if [[ "$FILECONTENT" != "$REPLACED_CONTENT" ]]
    then # Content to find where found and replaced

        # Find between which line numbers the diff is (find where the content where replaced)
        LINE_NUMBERS=$(diff <(echo "$FILECONTENT") <(echo "$REPLACED_CONTENT") | grep -E '^\s*[0-9]+')
        # Split them up into an array
        IFS=',cd' read -r -a line_numbers <<< "$LINE_NUMBERS"
        # Sort the array, from min to max
        IFS=$'\n' sorted_line_numbers=($(sort <<<"${line_numbers[*]}"))

        declare -g $3_START=${sorted_line_numbers[0]}
        declare -g $3_END=${sorted_line_numbers[${#sorted_line_numbers[@]} - 1]}
        # For eval and print within this function
        START=$3_START
        END=$3_END
        echo "START: ${!START}, END: ${!END}"
        declare -g $3_EXISTS=true
        return 0
    else
        echo "Did not find multiline content"
    fi

    return -1
}

# Makes sure file exists with the exact content given. If not, it creates or
# appends it
# 1 - Path to file
# 2 - File name
# 3 - Content to add to file
add_content_to_file()
{
    PATH_FILE=$1
    FILE_NAME=$2
    CONTENT_TO_ADD=$3

    if [[ -f $PATH_FILE/$FILE_NAME ]]
    then # File already exists
        echo -e "$FILE_NAME already exists."

        if exists_in_file "$PATH_FILE/$FILE_NAME" "$CONTENT_TO_ADD" CONTENT_TO_ADD
        then # Content is already in the file
            echo -e "$FILE_NAME already contains the relevant content.\n"
            return 255
        else # Append content to file
            echo -e "Append to $FILE_NAME\n"
            echo "$CONTENT_TO_ADD" >> "$PATH_FILE/$FILE_NAME"
            return 0;
        fi
    else # Create file with content
        echo -e "Create directory: $PATH_FILE/\n"
        mkdir -p $PATH_FILE
        echo -e "Create file $PATH_FILE/$FILE_NAME\n"
        echo "$CONTENT_TO_ADD" > $PATH_FILE/$FILE_NAME
        return 0
    fi
}

# Fetches file from URL using either curl or wget. Saves into given file.
# 1 - Path to file
# 2 - File name
# 3 - URL with text content
get_internet_file()
{
    
    PATH_FILE=$1
    FILE_NAME=$2
    FILE_URL=$3

    IS_CURL_AVAILABLE="$(command -v curl)"
    IS_WGET_AVAILABLE="$(command -v wget)"

    # Use 'curl' if available
    if [[ -z $IS_CURL_AVAILABLE ]]
    then
        URL_CONTENT=$(curl -L $FILE_URL)

        if [[ $? != 0 ]]
        then
            echo "Failed. 'curl' command failed."
            return -1
        fi

        FILE_CONTENT=$(<$PATH_FILE/$FILE_NAME)
        add_content_to_file "$PATH_FILE" "$FILE_NAME" "$URL_CONTENT"
        return
    fi
    echo -e "Command \"curl\" not available\n"

    # Use 'wget' if available
    if [[ -n $IS_WGET_AVAILABLE ]]
    then
        URL_CONTENT=$(wget -O- $FILE_URL)

        if [[ $? != 0 ]]
        then
            echo "Failed. 'wget' command failed."
            return -1
        fi

        add_content_to_file "$PATH_FILE" "$FILE_NAME" "$URL_CONTENT"
        return
    fi

    echo -e "Command \"wget\" not available\n"
    echo "Failed. Neither 'curl' or 'wget' is availale. Can't fetch content."

    return -1
}

# Look for else/elif/fi statement
# 1 - File
# 2 - If statement start line number
# 3 - Max lines to check through
# Creates ELSE_ELIF_LINE_NUMBER containing the line number of the first else/elif/fi 
# statement after the given line number $2
#
# Does not support nested if statements yet. Needs to count number of found if cases
find_else_elif_fi_statement()
{
    FILE=$1
    IF_LINE_NUMBER=$2
    MAX_COUNT=$3

    echo ""
    echo "FILE: $FILE"
    echo "IF_LINE_NUMBER: $IF_LINE_NUMBER"
    echo "COUNT: $COUNT"
    echo ""
    
    declare -g ELSE_ELIF_EXISTS=false
    COUNT=1
    while read line; do
        # Get first word of line
        FIRST_WORD=$(echo "$line" | head -n1 | awk '{print $1;}')

        if [[ "$FIRST_WORD" == "fi" ]]
        then
            declare -g FI_LINE_NUMBER=$(($IF_LINE_NUMBER + $COUNT))
            echo "Found fi at line: $FI_LINE_NUMBER"
            return 0
        elif [[ "$FIRST_WORD" == "else" ]] || [[ "$FIRST_WORD" == "elif" ]]
        then # Found it 
            # PROBLEM: Will overwrite if e.g. both elif and else exists. Or if multiple elif exists
            # Line number of else/elif/fi
            declare -g ELSE_ELIF_LINE_NUMBER=$(($IF_LINE_NUMBER + $COUNT))
            declare -g ELSE_ELIF_EXISTS=true
            echo "Found else/elif at line: $ELSE_ELIF_LINE_NUMBER"
        fi
        
        if [[ $COUNT == $MAX_COUNT ]]; then break; fi
        COUNT=$((COUNT + 1))
    done < <(tail -n "+$((IF_LINE_NUMBER + 1))" $FILE)

    return -1
}


adjust_else_elif_fi_linenumbers()
{
    INPUT="$1"

    # Increment if statement variables as they got shifted
    echo "IF_STATEMENT_START before:        $IF_STATEMENT_START"
    NUM_LINES=$(echo -n "$INPUT" | grep -c '^')
    echo "NUM_LINES:                        $NUM_LINES"
    IF_STATEMENT_START=$((IF_STATEMENT_START + NUM_LINES))
    IF_STATEMENT_END=$((IF_STATEMENT_END + NUM_LINES))
    ELSE_ELIF_LINE_NUMBER=$((ELSE_ELIF_LINE_NUMBER + NUM_LINES))
    FI_LINE_NUMBER=$((FI_LINE_NUMBER + NUM_LINES))

    echo "IF_STATEMENT_START updated to:    $IF_STATEMENT_START"
    echo "IF_STATEMENT_END updated to:      $IF_STATEMENT_END"
    echo "ELSE_ELIF_LINE_NUMBER updated to: $ELSE_ELIF_LINE_NUMBER"
    echo "FI_LINE_NUMBER updated to:        $FI_LINE_NUMBER"
}

adjust_interval_linenumbers()
{
    INPUT="$1"
    INDEX_LIMIT="$2"

    # Increment if statement variables as they got shifted
    echo "_intervals before:         ${_intervals[@]}"
    echo "index to change:          $INDEX_LIMIT"
    NUM_LINES=$(echo -n "$INPUT" | grep -c '^')
    echo "number of lines in input: $NUM_LINES"
    for i in "${!_intervals[@]}"
    do
        if (( i >= INDEX_LIMIT ))
        then
            _intervals[$i]=$((_intervals[i] + NUM_LINES))
        fi
    done
    echo "_intervals after:          ${_intervals[@]}"
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
        echo "Function 'add_single_line_content' need at least 5 inputs, you gave $#."
        return -1
    fi

    FILE_PATH="$1"; shift       # 1
    FILE_NAME="$1"; shift       # 2
    VAR_NAME="$1"; shift        # 3
    REF_TYPE="$1"; shift        # 4
    REF_PLACEMENT="$1"; shift   # 5

    echo "FILE_PATH: $FILE_PATH"
    echo "FILE_NAME: $FILE_NAME"
    echo "VAR_NAME: $VAR_NAME"
    echo "REF_TYPE: $REF_TYPE"
    echo "REF_PLACEMENT: $REF_PLACEMENT"

    # https://stackoverflow.com/questions/10953833/passing-multiple-distinct-arrays-to-a-shell-function
    


    if ! ( [[ $REF_TYPE == "INBETWEEN" ]] || [[ $REF_TYPE == "LINE" ]] )
    then
        echo "Input 4, reference type, have an invalid input."
        return -1
    fi

    if ! ( [[ "$REF_PLACEMENT" == "BEFORE" ]] || [[ $REF_PLACEMENT == "AFTER" ]] \
        || [[ $REF_PLACEMENT == "START" ]]    || [[ $REF_PLACEMENT == "END" ]] )
    then
        echo "Input 5, reference placement, have an invalid input."
        return -1
    fi



    if [[ $REF_TYPE == "INBETWEEN" ]]
    then
        declare -i array_num=1 # Extra array for '_intervals'
    else
        declare -i array_num=2
    fi

    declare -i num_args
    declare -ag _intervals=()
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
        ((array_num++))
    done

    echo ""
    echo "_intervals =          [ ${_intervals[@]} ]"
    echo "allowed_intervals =  [ ${allowed_intervals[@]} ]"
    echo "preferred_interval = [ ${preferred_interval[@]} ]"
    echo ""
    

    declare -i preferred_index
    for i in "${!preferred_interval[@]}"
    do
        if ${preferred_interval[i]}
        then
            echo "Found preferred interval in index $i."
            preferred_index=$i
        fi
    done


    EVAL_VAR_NAME=$VAR_NAME # ${!EVAL_VAR_NAME}
    EVAL_VAR_NAME_EXISTS=${VAR_NAME}_EXISTS # ${!EVAL_VAR_NAME_EXISTS}
    echo -e "\n********************************************************************************************"
    echo "***** Time for input of $VAR_NAME ******************************************************"
    echo "********************************************************************************************"
    exists_in_file "$FILE_PATH/$FILE_NAME" "${!EVAL_VAR_NAME}" $VAR_NAME

    if ! ${!EVAL_VAR_NAME_EXISTS}
    then
        declare -g ${VAR_NAME}_EXISTS=true

        # Iterate over every line of VAR_NAME as they are independent
        # These are assument to be above if statement
        while IFS= read -r line
        do
            exists_in_file "$FILE_PATH/$FILE_NAME" "$line" LINE
            # if $LINE_EXISTS
            # then
                if [[ $REF_TYPE == "INBETWEEN" ]]
                then
                    echo "INBETWEEN"
                    # [1 2]
                    # x x x
                    # [1 2 3]
                    # x x x x
                    declare -i num_items=${#_intervals[@]}
                    declare -i end_loop=$((num_items))
                    
                    declare found_in_interval
                    declare -a exists_in_intervals=()
                    for ((i=0;i<=num_items;i++))
                    do
                        case $i in
                            0)
                                if (( LINE_START < _intervals[i] ))
                                then
                                    echo "Line number $LINE_START IS in the interval < ${_intervals[$i]}. #####"
                                    found_in_interval=true
                                else
                                    echo "Line number $LINE_START is NOT in the interval < ${_intervals[$i]}. *****"
                                    found_in_interval=false
                                fi;;

                            $num_items)
                                if (( _intervals[i-1] < LINE_START ))
                                then
                                    echo "Line number $LINE_START IS in the interval > ${_intervals[$((i-1))]}. #####"
                                    found_in_interval=true
                                else
                                    echo "Line number $LINE_START is NOT in the interval > ${_intervals[$((i-1))]}. *****"
                                    found_in_interval=false
                                fi;;

                            *)
                                if (( _intervals[i-1] <= LINE_START )) && (( LINE_START <= _intervals[i] ))
                                then
                                    echo "Line number $LINE_START IS in interval ${_intervals[$((i-1))]} - ${_intervals[$i]}. #####"
                                    found_in_interval=true
                                else
                                    echo "Line number $LINE_START is NOT in interval ${_intervals[$((i-1))]} - ${_intervals[$i]}. *****"
                                    found_in_interval=false
                                fi;;
                        esac
                        echo ""

                        exists_in_intervals+=( $found_in_interval )
                        

                        # if (( i == 0 ))
                        # then
                        #     if (( LINE_START < intervals[i] ))
                        #     then
                        #         echo "Line number $LINE_START IS in the interval < ${intervals[$i]}. #####"
                        #     else
                        #         echo "Line number $LINE_START is NOT in the interval < ${intervals[$i]}. *****"
                        #     fi
                        # elif (( i == num_items ))
                        # then
                        #     if (( intervals[i-1] < LINE_START ))
                        #     then
                        #         echo "Line number $LINE_START IS in the interval > ${intervals[$((i-1))]}. #####"
                        #     else
                        #         echo "Line number $LINE_START is NOT in the interval > ${intervals[$((i-1))]}. *****"
                        #     fi
                        # else
                        #     if (( intervals[i-1] <= LINE_START )) && (( LINE_START <= intervals[i] ))
                        #     then 
                        #         echo "Line number $LINE_START IS in interval ${intervals[$((i-1))]} - ${intervals[$i]}. #####"
                        #     else
                        #         echo "Line number $LINE_START is NOT in interval ${intervals[$((i-1))]} - ${intervals[$i]}. *****"
                        #     fi
                        # fi
                    done


                    
                    
                    # [1 2]
                    # x x x
                    # [1 2 3]
                    # x x x x
                    ADD_TO_PREFERRED_INTERVAL=false
                    echo "exists_in_intervals: [${exists_in_intervals[@]}]"
                    echo "allowed_intervals:   [${allowed_intervals[@]}]"
                    echo "preferred_interval: [${preferred_interval[@]}]"
                    echo "----------------------------------------------------"
                    for ((j=0;j<${#exists_in_intervals[@]};j++))
                    do
                        # Add start and end of intervals
                        tmp_intervals=(0 ${_intervals[@]} $(wc -l ~/.bashrc | cut -f1 -d' '))
                        # [1 2]
                        # [0 1 2 3]
                        # x x x
                        # [1 2 3]
                        # [0 1 2 3 4]
                        # x x x x
                        echo "Checking interval $j **********************************************"
                        if ${exists_in_intervals[$j]}
                        then
                            if ${allowed_intervals[$j]}
                            then
                                echo "Exists in allowed interval."
                                if ${preferred_interval[$j]}
                                then
                                    echo "Exists in the preferred interval."
                                else
                                    echo "Is not in the preferred interval."
                                    echo -e "Remove content of line $LINE_START\n"
                                    # Remove the content of the line, but keeping the line
                                    sed -i "${LINE_START},${LINE_END}d" "$FILE_PATH/$FILE_NAME"
                                fi
                            else # Exists in DISALLOWED interval

                                echo "Exists in DISALLOWED interval."
                                echo -e "Remove content of line $LINE_START\n"
                                # Remove the content of the line, but keeping the line
                                sed -i "${LINE_START},${LINE_END}d" "$FILE_PATH/$FILE_NAME"
                            fi
                        else # Does NOT exist in interval
                            if ${preferred_interval[$j]}
                            then
                                echo "Does NOT exist in preferred interval"
                                echo "To be added in preferred interval"
                                
                                ADD_TO_PREFERRED_INTERVAL=true
                                
                            fi
                        fi
                    done
                    echo "Checked all intervals *********************************************"


                    if $ADD_TO_PREFERRED_INTERVAL
                    then
                        echo "Place in preferred interval."
                        # If ending with backslash, add another one to behave as wanted with sed
                        line=$(echo "$line" | sed -E 's/[\\]$/\\\\/gm')
                        
                        # Place content in allowed interval
                        case "$REF_PLACEMENT" in
                            "START")
                                sed -i "$((tmp_intervals[preferred_index] + 1))i $line" "$FILE_PATH/$FILE_NAME"
                                ;;
                            *)
                                sed -i "$((tmp_intervals[preferred_index + 1] - 1))i $line" "$FILE_PATH/$FILE_NAME"
                                ;;
                        esac
                        echo "Placed in preferred interval."
                        # Update interval numbers
                        adjust_interval_linenumbers "$line" $j
                    fi
                    echo ""
                fi

                # if (( $LINE_START < $IF_STATEMENT_START ))
                # then # Line is before if statement
                #     echo -e "Line exists and is before if statement.\n"
                # elif (( $FI_LINE_NUMBER < $LINE_START ))
                # then # Line is after whole if statement (fi)
                #     # Remove content of that line
                #     echo "Line exists, but is after if statement."
                #     echo -e "Remove content of line $LINE_START\n"
                #     sed -i "${LINE_START},${LINE_END}d" "$FILE_PATH/$FILE_NAME" # Remove the line
                    
                #     # If ending with backslash, add another one to behave as wanted with sed
                #     line=$(echo "$line" | sed -E 's/[\\]$/\\\\/gm')
                #     # Place content before if statement
                #     sed -i "${IF_STATEMENT_START}i $line" "$FILE_PATH/$FILE_NAME"

                #     # Increment if statement variables as they got shifted down
                #     adjust_else_elif_fi_linenumbers "$line"

                #     declare -g ${VAR_NAME}_EXISTS=false
                # else
                #     echo "Content found in if statement even though it shouldn't be there."
                #     echo -e "LINE FOUND:\n$line\n AT LINE: $LINE_START"
                #     return -1
                # fi

            # else # Content doesn't exist
            #     # If ending with backslash, add another one to behave as wanted with sed
            #     line=$(echo "$line" | sed -E 's/[\\]$/\\\\/gm')
            #     # line=$(echo "$line" | sed 's/[][\\*.%$]/\\&/g') # Alternative way of above
            #     # Place content before if statement
            #     echo "Insert the following line into line number $IF_STATEMENT_START"
            #     sed -i "${IF_STATEMENT_START}i ${line}" "$FILE_PATH/$FILE_NAME"

            #     # Increment if statement variables as they got shifted
            #     adjust_else_elif_fi_linenumbers "$line"

            #     declare -g ${VAR_NAME}_EXISTS=false
            # fi
        done <<< "${!EVAL_VAR_NAME}"
    fi
}




















# add_single_line_content()
# {
#     if (( $# < 5 ))
#     then
#         echo "Function 'add_single_line_content' need at least 5 inputs, you gave $#."
#         return -1
#     fi

#     FILE_PATH="$1"
#     FILE_NAME="$2"
#     VAR_NAME="$3"
#     REF_TYPE="$4"
#     REF_PLACEMENT="$5"

#     # https://stackoverflow.com/questions/10953833/passing-multiple-distinct-arrays-to-a-shell-function
    


#     if ! ( [[ $REF_TYPE == $REF_LINE ]] || [[ $REF_TYPE == $REF_INBETWEEN ]] )
#     then
#         echo "Input 4, reference type, have an invalid input."
#         return -1
#     fi

#     if ! ( [[ "$REF_PLACEMENT" == "$REF_START" ]] || [[ $REF_PLACEMENT == "$REF_END" ]] )
#     then
#         echo "Input 5, reference placement, have an invalid input."
#         return -1
#     fi

    
#     declare num_args;
#     declare array_num=1
#     declare -a allowed_intervals
#     declare -a preferred_interval

#     # Shift previous arguments
#     for i in {1..5}
#     do
#         shift
#     done

#     while (( $# )) ; do
#         curr_args=( )
#         num_args=$1; shift
#         while (( num_args-- > 0 )) ; do
#             if (( $array_num == 1 ))
#             then
#                 allowed_intervals+=( "$1" ); shift
#             elif (( $array_num == 2 ))
#             then
#                 preferred_interval+=( "$1" ); shift
#             fi
#         done
#         ((array_num++))
#     done

#     echo ""
#     echo "allowed_intervals=[ ${allowed_intervals[0]} ${allowed_intervals[1]} ${allowed_intervals[2]} ]"
#     echo "preferred_interval=[ ${preferred_interval[0]} ${preferred_interval[1]} ${preferred_interval[2]} ]"


#     EVAL_VAR_NAME=$VAR_NAME # ${!EVAL_VAR_NAME}
#     EVAL_VAR_NAME_EXISTS=${VAR_NAME}_EXISTS # ${!EVAL_VAR_NAME_EXISTS}
#     echo -e "\n********************************************************************************************"
#     echo "***** Time for input of $VAR_NAME ******************************************************"
#     echo "********************************************************************************************"
#     exists_in_file "$FILE_PATH/$FILE_NAME" "${!EVAL_VAR_NAME}" $VAR_NAME

#     if ! ${!EVAL_VAR_NAME_EXISTS}
#     then
#         declare -g ${VAR_NAME}_EXISTS=true

#         # Iterate over every line of VAR_NAME as they are independent
#         # These are assument to be above if statement
#         while IFS= read -r line
#         do
#             exists_in_file "$FILE_PATH/$FILE_NAME" "$line" LINE
#             if $LINE_EXISTS
#             then
#                 if (( $LINE_START < $IF_STATEMENT_START ))
#                 then # Line is before if statement
#                     echo -e "Line exists and is before if statement.\n"
#                 elif (( $FI_LINE_NUMBER < $LINE_START ))
#                 then # Line is after whole if statement (fi)
#                     # Remove content of that line
#                     echo "Line exists, but is after if statement."
#                     echo -e "Remove content of line $LINE_START\n"
#                     sed -i "${LINE_START},${LINE_END}d" "$FILE_PATH/$FILE_NAME" # Remove the line
                    
#                     # If ending with backslash, add another one to behave as wanted with sed
#                     line=$(echo "$line" | sed -E 's/[\\]$/\\\\/gm')
#                     # Place content before if statement
#                     sed -i "${IF_STATEMENT_START}i $line" "$FILE_PATH/$FILE_NAME"

#                     # Increment if statement variables as they got shifted down
#                     adjust_else_elif_fi_linenumbers "$line"

#                     declare -g ${VAR_NAME}_EXISTS=false
#                 else
#                     echo "Content found in if statement even though it shouldn't be there."
#                     echo -e "LINE FOUND:\n$line\n AT LINE: $LINE_START"
#                     return -1
#                 fi
#             else # Content doesn't exist
#                 # If ending with backslash, add another one to behave as wanted with sed
#                 line=$(echo "$line" | sed -E 's/[\\]$/\\\\/gm')
#                 # line=$(echo "$line" | sed 's/[][\\*.%$]/\\&/g') # Alternative way of above
#                 # Place content before if statement
#                 echo "Insert the following line into line number $IF_STATEMENT_START"
#                 sed -i "${IF_STATEMENT_START}i ${line}" "$FILE_PATH/$FILE_NAME"

#                 # Increment if statement variables as they got shifted
#                 adjust_else_elif_fi_linenumbers "$line"

#                 declare -g ${VAR_NAME}_EXISTS=false
#             fi
#         done <<< "${!EVAL_VAR_NAME}"
#     fi
# }















add_multiline_content()
{
    FILE_PATH="$1"
    FILE_NAME="$2"
    VAR_NAME="$3"

    EVAL_VAR_NAME=$VAR_NAME # ${!EVAL_VAR_NAME}
    EVAL_VAR_NAME_EXISTS=${VAR_NAME}_EXISTS # ${!EVAL_VAR_NAME_EXISTS}
    EVAL_VAR_NAME_START=${VAR_NAME}_START # ${!EVAL_VAR_NAME_START}
    EVAL_VAR_NAME_END=${VAR_NAME}_END # ${!EVAL_VAR_NAME_END}
    echo -e "\n*****************************************************************************************"
    echo "***** Time for INPUT $VAR_NAME ******************************************************"
    echo "*****************************************************************************************"
    exists_in_file "$FILE_PATH/$FILE_NAME" "${!EVAL_VAR_NAME}" $VAR_NAME

    if ${!EVAL_VAR_NAME_EXISTS}
    then
        if (( ${!EVAL_VAR_NAME_START} < $IF_STATEMENT_START ))
        then # Line is before if statement
            echo -e "Line exists and is before if statement.\n"
        elif (( $FI_LINE_NUMBER < ${!EVAL_VAR_NAME_START} ))
        then # Lines are after whole if statement (fi)
            # Remove content of that line
            echo "Content exists, but is after if statement."
            echo "Remove content of lines ${!EVAL_VAR_NAME_START}-${!EVAL_VAR_NAME_END}"
            sed -i "${!EVAL_VAR_NAME_START},${!EVAL_VAR_NAME_END}d" "$FILE_PATH/$FILE_NAME"
            
            # Commented out below does not work as intended.
            # If ending with backslash, but not a backslash before that (double or more)
            # then replace with double backslash. Making sure that a single one is 
            # replaced with a double
            # https://stackoverflow.com/a/9306228/12374737
            # "Where (?<!x) means "only if it doesn't have 'x' before this point"."
            # BASHRC_INPUT2=$(echo "$BASHRC_INPUT2" | sed 's/(?<!\\)[\\]{1}$/\\\\/gm')

            # Replace backslashes with double backslashes to have 'sed' insert line at
            # line number later work as expected
            TMP=$(echo "${!EVAL_VAR_NAME}")
            TMP=$(echo "$TMP" | sed 's/\\/\\\\/g')
            # Replace backslash at end of line with an extra backslash to have 'sed' 
            # insert line at line number later work as expected
            TMP=$(echo "$TMP" | sed -E 's/[\\]$/\\\\/gm')
            
            declare -g "${VAR_NAME}=${TMP}"

            sed -i "${IF_STATEMENT_START}i ${!EVAL_VAR_NAME}" "$FILE_PATH/$FILE_NAME"
            
            # Increment if statement variables as they got shifted
            adjust_else_elif_fi_linenumbers "${!EVAL_VAR_NAME}"

            declare -g "$VARNAME_EXISTS=false"
        else
            echo "Content found in if statement even though it shouldn't be there."
            echo "LINE FOUND:"
            echo "${!EVAL_VAR_NAME}"
            echo "AT LINES: ${!EVAL_VAR_NAME_START}-${!EVAL_VAR_NAME_END}"
            return -1
        fi
    else
        echo "$VAR_NAME:"
        echo "${!EVAL_VAR_NAME}"
        # Replace backslashes with double backslashes to have 'sed' insert line at
        # line number later work as expected
        TMP=$(echo "${!EVAL_VAR_NAME}")
        TMP=$(echo "$TMP" | sed 's/\\/\\\\/g')
        # Replace backslash at end of line with an extra backslash to have 'sed' 
        # insert line at line number later work as expected
        TMP=$(echo "$TMP" | sed -E 's/[\\]$/\\\\/gm')

        declare -g "${VAR_NAME}=${TMP}"

        echo "$VAR_NAME after adding extra backslashes:"
        echo "${!EVAL_VAR_NAME}"

        sed -i "${IF_STATEMENT_START}i ${!EVAL_VAR_NAME}" "$FILE_PATH/$FILE_NAME"
        
        # Increment if statement variables as they got shifted
        adjust_else_elif_fi_linenumbers "${!EVAL_VAR_NAME}"
    fi
}


#############################
### YESNO QUESTION HELPER ###
#############################
# Input: 2 arguments
# 1 - Variable name
# 2 - Description for question and results
# 
yesno_question()
{

    read -p "Setup $2? [y/n]: " -n 1 -r
    echo

    case ${REPLY,,} in
        y|yes)
            declare -g SETUP_${1^^}=true
            INIT_RESULTS+="[  ] ";;
        *)
            declare -g SETUP_${1^^}=false
            INIT_RESULTS+="[🟠] ";;
    esac
    INIT_RESULTS+="$2\n"
}
####################################
### END OF YESNO QUESTION HELPER ###
####################################

#########################
### INITIAL QUESTIONS ###
#########################
initial_questions()
{
    # List what this script will setup
    echo "This script have the options to setup:"
    for i in "${!arr_setups[@]}"
    do 
        if [[ $(( i % 2 )) != 0 ]]
        then
            echo "[  ] ${arr_setups[$i]}"
        fi
    done
    echo ""

    # Ask about setting up everything
    read -p "Setup everything given above? [y/n]: " -n 1 -r 
    echo -e "\n"
    case ${REPLY,,} in
        y|yes)
            SETUP_EVERYTHING=true;;
        *)
            SETUP_EVERYTHING=false;;
    esac

    if $SETUP_EVERYTHING; then return 0; fi


    # Ask about individual setups
    ASK_INDIVIDUAL_SETUPS=true
    while $ASK_INDIVIDUAL_SETUPS
    do
        echo -e "Choose which individual setups to do:"
        for i in "${!arr_setups[@]}"
        do 
            if [[ $(( i % 2 )) == 0 ]]
            then
                yesno_question "${arr_setups[$i]}" "${arr_setups[(($i + 1))]}"
            fi
        done

        # Ask if happy with choices and to continue
        echo -e "\nSetups to be done:"
        echo -e " 🟠 = Not to be done"
        echo -e "$INIT_RESULTS"
        read -p "Start the setup with the choices above? [y/n/q]: " -n 1 -r
        echo -e "\n"
        case ${REPLY,,} in
            y|yes)
                ASK_INDIVIDUAL_SETUPS=false;;
            q|quit|exit)
                echo "Exiting script."; exit;;
            *)
                echo -e "Doesn't seem like you were happy with your choices.\n";
                INIT_RESULTS="";;
        esac
    done
}
################################
### END OF INITIAL QUESTIONS ###
################################

####################
### VIM COLORING ###
####################
setup_vimdiff() {
    
    create_colorscheme
    RETURN_COLORSCHEME=$?

    create_vimrc
    RETURN_VIMRC=$?

    if [[ $RETURN_COLORSCHEME == 255 && $RETURN_VIMRC == 255 ]]
    then
        return 255
    else
        return 0
    fi
    
}
###########################
### END OF VIM COLORING ###
###########################

##########################
### CREATING COLORSCHEME ###
##########################
create_colorscheme()
{
    define VIMCOLORSCHEME << 'EOF'
highlight DiffAdd    cterm=bold ctermfg=15 ctermbg=22 gui=none guifg=bg guibg=Red
highlight DiffDelete cterm=bold ctermfg=15 ctermbg=88 gui=none guifg=bg guibg=Red
highlight DiffChange cterm=bold ctermfg=15 ctermbg=17 gui=none guifg=bg guibg=Red
highlight DiffText   cterm=bold ctermfg=15 ctermbg=130 gui=none guifg=bg guibg=Red
EOF

    add_content_to_file "$PATH_VIMCOLORSCHEME" "$NAME_VIMCOLORSCHEME" "$VIMCOLORSCHEME"
    
}
###################################
### END OF CREATING COLORSCHEME ###
###################################

#####################
### CREATNG VIMRC ###
#####################
create_vimrc()
{
    # Create vimrc with colorscheme, word wrapping and line numbering
    define VIMRC_CONTENT << 'EOF'
set number
if &diff
        colorscheme mycolorscheme
        au VimEnter * | execute 'windo set wrap' |
endif
EOF

    add_content_to_file "$PATH_VIMRC" ".vimrc" "$VIMRC_CONTENT"
    
}
############################
### END OF CREATNG VIMRC ###
############################

############################
### GIT DIFFTOOL VIMDIFF ###
############################
setup_gitdifftool()
{
    cd $PATH_GITCONFIG
    RESULTS=$(git config --global --get diff.tool)
    if [[ "$RESULTS" != "vimdiff" ]]
    then # Not set to wished setting. Set it.
        git config --global diff.tool vimdiff

        RESULTS=$(git config --global --get diff.tool)
        if [[ "$RESULTS" != "vimdiff" ]]
        then # Could no set the setting
            return -1
        fi

        return 0
    else # Already set to the wished setting
        return 255
    fi

    RESULTS=$(git config --global --get difftool.prompt)
    if [[ "$RESULTS" != "vimdiff" ]]
    then # Not set to wished setting. Set it.
        git config --global diff.tool vimdiff

        RESULTS=$(git config --global difftool.prompt false)
        if [[ "$RESULTS" != "vimdiff" ]]
        then # Could no set the setting
            return -1
        fi

        return 0
    else # Already set to the wished setting
        return 255
    fi
    
    cd $PATH_SCRIPT
}
###############################
### END OF DIFFTOOL VIMDIFF ###
###############################

#################
### TRASH-CLI ###
#################
setup_trashcli()
{

    # See if package isn't installed
    if ! (dpkg -l | grep -q trash-cli)
    then
        sudo apt install trash-cli
        
        if [[ $? != 0 ]]
            then
                echo -e "Failed installing 'trash-cli' package.\n"
                return -1
            fi
    fi

    TRASHCLI_CONTENT="alias rm=trash"

    add_content_to_file "$PATH_BASHRC" "$NAME_BASHRC" "$TRASHCLI_CONTENT"
    
}
########################
### END OF TRASH-CLI ###
########################

############################
### GIT COMPLETION SETUP ###
############################
setup_gitcompletionbash()
{
    # get_internet_file "$PATH_GITCOMPLETIONBASH" "$NAME_GITCOMPLETIONBASH" "$URL_GITCOMPLETIONBASH"
    # RETURN_GET_INTERNET_FILE=$?
    
    # case $RETURN_GET_INTERNET_FILE in 
    #     0)   # Success
    #         ;;
    #     255) # Already done
    #         ;;
    #     *)   # Failure
    #         return -1;;
    # esac

    # # Make it executable
    # sudo chmod +x $PATH_GITCOMPLETIONBASH/$NAME_GITCOMPLETIONBASH
    # RETURN_CHMOD=$?

    # if [[ $RETURN_CHMOD != 0 ]]; then return -1; fi

    # Variable expansion line
    BASHRC_INPUT1_1="$PATH_GITCOMPLETIONBASH/$NAME_GITCOMPLETIONBASH"
    # Doesn't include any variable expansion
    define BASHRC_INPUT1_2 <<'EOF'
export PROMPT_DIRTRIM=3
export GIT_PS1_SHOWCOLORHINTS=true
export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export GIT_PS1_SHOWUPSTREAM="auto"
EOF
# Concat the two above. OBS don't use \n for newline, seems good when doing diff
# but doesn't work the same when doing the check in 'exists_in_file'
    BASHRC_INPUT1="${BASHRC_INPUT1_1}
${BASHRC_INPUT1_2}"
    # Multi-line needs to be handled as multi-line. Not go through iteration while loop
    define BASHRC_INPUT2 <<'EOF'
PS1_custom='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u\[\033[00m\]:\['\
'\033[01;34m\]\w\[\033[00m\]\$ '
EOF
    define BASHRC_INPUT3 <<'EOF'
PS1_original='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m'\
'\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
EOF
    define BASHRC_INPUT4 <<'EOF'
if [ "$color_prompt" = yes ]; then
    PS1=$PS1_custom
EOF
    define BASHRC_INPUT5 <<'EOF'
PROMPT_COMMAND=$(sed -r 's|^(.+)(\\\$\s*)$|__git_ps1 "\1" "\2"|' <<< $PS1)
EOF


    # Find if statement to know where to place content (above,in-between,below)
    echo "*****************************************************************************"
    echo "***** Time for finding if statement *****************************************"
    echo "*****************************************************************************"
    IF_STATEMENT='if [ "$color_prompt" = yes ]; then'
    exists_in_file "$PATH_BASHRC/$NAME_BASHRC" "$IF_STATEMENT" IF_STATEMENT
    echo "IF_STATEMENT_EXISTS: $IF_STATEMENT_EXISTS"
    echo "IF_STATEMENT_START: $IF_STATEMENT_START IF_STATEMENT_END: $IF_STATEMENT_END"
    if $IF_STATEMENT_EXISTS
    then
        find_else_elif_fi_statement "$PATH_BASHRC/$NAME_BASHRC" "$IF_STATEMENT_END" 100
        if [[ "$?" != 0 ]]
        then
            echo "Problem in finding else/elif/fi statement."
            return -1
        fi

        #################################################################
        ############################ INPUT 1 ############################
        #################################################################
        declare -a intervals=($IF_STATEMENT_START $FI_LINE_NUMBER)
        declare -p intervals
        declare -a allowed_intervals=(true false true)
        declare -a preferred_interval=(true false false)
        # add_single_line_content "$PATH_BASHRC" "$NAME_BASHRC" BASHRC_INPUT1 "LINE" "BEFORE" "${#allowed_intervals[@]}" "${allowed_intervals[@]}" "${#preferred_interval[@]}" "${preferred_interval[@]}"
        add_single_line_content "$PATH_BASHRC" "$NAME_BASHRC" BASHRC_INPUT1 "INBETWEEN" "END" "${#intervals[@]}" "${intervals[@]}" "${#allowed_intervals[@]}" "${allowed_intervals[@]}" "${#preferred_interval[@]}" "${preferred_interval[@]}"

        if $BASHRC_INPUT1_EXISTS
        then
            echo -e "BASHRC_INPUT1 already done.\n"
        fi

        #################################################################
        ############################ INPUT 2 ############################
        #################################################################
        
        add_multiline_content "$PATH_BASHRC" "$NAME_BASHRC" BASHRC_INPUT2

        #################################################################
        ############################ INPUT 3 ############################
        #################################################################
        
        add_multiline_content "$PATH_BASHRC" "$NAME_BASHRC" BASHRC_INPUT3

        #################################################################
        ############################ INPUT 4 ############################
        #################################################################
        echo "*****************************************************************************"
        echo "***** Time for INPUT 4 ******************************************************"
        echo "*****************************************************************************"
        exists_in_file "$PATH_BASHRC/$NAME_BASHRC" "$BASHRC_INPUT4" BASHRC_INPUT4

        if ! $BASHRC_INPUT4_EXISTS
        then
            if $IF_STATEMENT_EXISTS
            then
                BASHRC_INPUT_PS1='\    PS1=$PS1_custom'
                # Insert relevant line
                if $ELSE_ELIF_EXISTS
                then # Insert before 'else'/'elif'
                    sed -i "${ELSE_ELIF_LINE_NUMBER}i $BASHRC_INPUT_PS1" "$PATH_BASHRC/$NAME_BASHRC"
                else # Insert before 'fi' instead
                    sed -i "${FI_LINE_NUMBER}i $BASHRC_INPUT_PS1" "$PATH_BASHRC/$NAME_BASHRC"
                fi
            else
                echo "Insert somewhere else"
            fi
        fi
        echo ""

        #################################################################
        ############################ INPUT 5 ############################
        #################################################################
        echo "*****************************************************************************"
        echo "***** Time for INPUT 5 ******************************************************"
        echo "*****************************************************************************"
        exists_in_file "$PATH_BASHRC/$NAME_BASHRC" "$BASHRC_INPUT5" BASHRC_INPUT5


    fi

    


    if $BASHRC_INPUT1_EXISTS && $BASHRC_INPUT2_EXISTS && $BASHRC_INPUT3_EXISTS
    then
        echo "All the content already exists."
        return 255
    fi





    # # Read file, line by line
    # # Start line to search for:
    # SEARCH_FOR_CONTENT="if [ \"\$color_prompt\" = yes ]; then"
    # FOUND=false
    # PREVIOUSLY_SET=false
    # LINE_COUNTER=1
    # arr_with_line_numbers=()
    # while IFS= read -r line; do

    #     # Remove leading and trailing whitespace
    #     line="$(echo -e "${line}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    #     # If found previous loop
    #     if $FOUND
    #     then
    #         if [[ "$line" == "PS1=\$PS1_custom" ]]
    #         then
    #             PREVIOUSLY_SET=true
    #         else
    #             PREVIOUSLY_SET=false
    #         fi

    #         # Find line interval to replace
    #         FOUND=false
    #         SEARCH_FOR_CONTENT="fi" # End of if statement
    #     fi

    #     if [[ "$line" == "$SEARCH_FOR_CONTENT" ]]
    #     then
    #         FOUND=true
    #         echo "Found at line: $LINE_COUNTER"
    #         arr_with_line_numbers+=("$LINE_COUNTER")

    #         if [[ ${#arr_with_line_numbers[@]} == 2 ]]
    #         then # Got start and ending line number
    #             break
    #         fi
    #     fi

    #     LINE_COUNTER=$((LINE_COUNTER + 1))
    # done < $PATH_BASHRC/$NAME_BASHRC

    # # Probably empty bashrc file
    # if ! $FOUND
    # then
    #     echo "haaa" # Append to file
    # fi

    # if $FOUND
    # then
    #     echo "Between line ${arr_with_line_numbers[0]} and ${arr_with_line_numbers[1]}"

    #     sed -i "${arr_with_line_numbers[0]}i 
    #     " "$PATH_BASHRC/$NAME_BASHRC"
    # fi

}
###################################
### END OF GIT COMPLETION SETUP ###
###################################



############
### MAIN ###
############

initial_questions

# Go through every setup, calling their corresponding function if to be done
TOTAL_RESULTS=true
for i in "${!arr_setups[@]}"
do 
    if [[ $(( i % 2 )) == 0 ]]
    then
        # SETUP_INDIVIDUAL is used to call the magic variable through double
        # evaluation with ${!SETUP_INDIVIDUAL}
        SETUP_INDIVIDUAL=SETUP_${arr_setups[$i]^^}
        if $SETUP_EVERYTHING || ${!SETUP_INDIVIDUAL}
        then
            echo -e "****************************************"
            echo -e "Start setup of \"${arr_setups[(($i + 1))]}\""
            echo -e "****************************************\n"
            # Function call
            setup_${arr_setups[$i]}
            case $? in 
                0)   # Success
                    END_RESULTS+="[✔️] ";;
                255) # Already done
                    END_RESULTS+="[🔷] ";;
                *)   # Failure
                    END_RESULTS+="[❌] ";
                    TOTAL_RESULTS=false;;
            esac
            echo -e "****************************************"
            echo "End setup of \"${arr_setups[(($i + 1))]}\""
            echo -e "****************************************\n"
        else
            # Setup not to be done
            END_RESULTS+="[🟠] "
        fi

        END_RESULTS+="${arr_setups[(($i + 1))]}\n"
    fi
done

# Print end results
echo -e "Results:\n"
echo -e " 🟠 = Not to be done"
echo -e " ✔️ = Success"
echo -e " ❌ = Failure"
echo -e " 🔷 = Already setup\n"
echo -e "$END_RESULTS\n"
echo -e "****************************************"
TOTAL_RESULTS_PRINT="Total results: "
if $TOTAL_RESULTS
then
    TOTAL_RESULTS_PRINT+="✔️ - SUCCESS"
else
    TOTAL_RESULTS_PRINT+="❌ - FAILURE"
fi
echo -e "$TOTAL_RESULTS_PRINT"
echo -e "****************************************\n"


