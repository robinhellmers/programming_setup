#!/bin/bash

# Error handling to get line number of error
# https://unix.stackexchange.com/questions/462156/how-do-i-find-the-line-number-in-bash-when-an-error-occured
# set -eE -o functrace
# failure() {
#   local lineno=$2
#   local fn=$3
#   local exitstatus=$4
#   local msg=$5
#   local lineno_fns=${1% 0}
#   if [[ "$lineno_fns" != "0" ]] ; then
#     lineno="${lineno} ${lineno_fns}"
#   fi
#   echo "${BASH_SOURCE[1]}:${fn}[${lineno}] Failed with status ${exitstatus}: $msg"
# }
# trap 'failure "${BASH_LINENO[*]}" "$LINENO" "${FUNCNAME[*]:-script}" "$?" "$BASH_COMMAND"' ERR

PATH_SCRIPT="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

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

DEBUG_LEVEL=1
#######################
### END OF SETTINGS ###
#######################

main()
{
    debug_echo 0 -e "\nLocation of script:"
    debug_echo 0 -e "$PATH_SCRIPT\n"

    initial_questions

    # Go through every setup, calling their corresponding function if to be done
    TOTAL_RESULTS=true
    for ind_arr_setups in "${!arr_setups[@]}"
    do 
        if [[ $(( ind_arr_setups % 2 )) == 0 ]]
        then
            # SETUP_INDIVIDUAL is used to call the magic variable through double
            # evaluation with ${!SETUP_INDIVIDUAL}
            SETUP_INDIVIDUAL=SETUP_${arr_setups[$ind_arr_setups]^^}
            if $SETUP_EVERYTHING || ${!SETUP_INDIVIDUAL}
            then

                debug_echo 1 -e "\n\n\n\n"
                debug_echo 1 -e "${ORANGE_COLOR}\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\${END_COLOR}"
                debug_echo 1 -e "${ORANGE_COLOR}\\\\\\ Start setup of \"${arr_setups[(($ind_arr_setups + 1))]}\"${END_COLOR}"
                debug_echo 1 -e "${ORANGE_COLOR}\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\${END_COLOR}"
                # Function call
                setup_${arr_setups[$ind_arr_setups]}

                case $return_value in 
                    'success')   # Success
                        END_RESULTS+="[✔️] ";;
                    'already done') # Already done
                        END_RESULTS+="[🔷] ";;
                    *)   # Failure
                        END_RESULTS+="[❌] ";
                        TOTAL_RESULTS=false;;
                esac
                debug_echo 1 -e "${ORANGE_COLOR}//////////////////////////////////////////////////////////////////////////////////////////////////${END_COLOR}"
                debug_echo 1 -e "${ORANGE_COLOR}/// End setup of \"${arr_setups[(($ind_arr_setups + 1))]}\"${END_COLOR}"
                debug_echo 1 -e "${ORANGE_COLOR}//////////////////////////////////////////////////////////////////////////////////////////////////${END_COLOR}"
            else
                # Setup not to be done
                END_RESULTS+="[🟠] "
            fi

            END_RESULTS+="${arr_setups[(($ind_arr_setups + 1))]}\n"
        fi
    done

    # Print end results
    echo -e "\n\n${DEFAULT_UNDERLINE_COLOR}Results:${END_COLOR}"
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

}

NL='
'
DEFAULT_BOLD_COLOR='\033[1;39m'
DEFAULT_UNDERLINE_COLOR='\033[4;39m'
RED_COLOR='\033[0;31m'
GREEN_COLOR='\033[0;32m'
ORANGE_COLOR='\033[0;33m'
MAGENTA_COLOR='\033[0;35m'
END_COLOR='\033[0m'

_handleArgs(){
    declare -ag debug_echo_optional_args=()
    declare -ag non_optional_args=()
    count=0
    while [ "${1:-}" != "" ]; do
        # NOT optional: neither single dash or double dash
        if ! [[ "${1:0:1}" == "-" ]] && ! [ "${1:0:2}" == "--" ]; then
            non_optional_args+=("${1}")
        else
        # Optional: single dash or double dash
            case "$1" in
            '-e')
                debug_echo_optional_args+=('-e')
                ;;
            '-n')
                debug_echo_optional_args+=('-n')
                ;;
            # "-j" | "--jump-target")
            #     # If number
            #     if [[ $2 =~ ^[0-9]+$ ]]; then
            #         JUMP_TARGET=$(($2))
            #     fi
            #     shift
            #     ;;
            *)
                # Did not find optional, treat as non-optional.
                non_optional_args+=("${1}")
                ;;
            esac
        fi
        shift
    done
    
    # NON_OPTIONAL_ARGS=$(echo $NON_OPTIONAL_ARGS | sed 's/ *$//')
}

debug_echo()
{
    _handleArgs "$@"

    if (( ${#non_optional_args[@]} != 2 ))
    then
        echo "debug_echo: Incorrect number of input variables. Need to be 2, but ${#non_optional_args[@]} were given."
        for i in "${!non_optional_args[@]}"
        do
            echo "non_optional_args[$i]: [${non_optional_args[$i]}]"
        done
        echo ""
        return 1
    fi

    given_level="${non_optional_args[0]}"
    debug_message="${non_optional_args[1]}"

    if ! [[ "$given_level" =~ ^[0-9]+$ ]]
    then
        echo "debug_echo: Input 1 needs to be an integer defining the debug level"
        return 0
    fi

    if (( given_level <= DEBUG_LEVEL ))
    then
        echo ${debug_echo_optional_args[@]} "$debug_message"
    fi
}


# Reads multiline text and inputs to variable
#
# Example usage:
# define VAR <<'EOF'
# abc'asdf"
#     $(dont-execute-this)
# foo"bar"'''
# EOF
define(){ IFS=$'\n' read -r -d '' ${1} || true; }


# Used for dynamic arrays to make it more readable
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
    FILECONTENT=$(<$1)
    CONTENT_TO_CHECK="$2"

    declare -g $3_EXISTS=false
    
    
    debug_echo 1 -e "\n----------------------------------"
    debug_echo 1 "||| Start checking for content |||"
    debug_echo 1 -e "----------------------------------\n"

    # Remove trailing whitespace
    FILECONTENT="$(echo "${FILECONTENT}" | sed -e 's/[[:space:]]*$//')"
    # FILECONTENT=$(echo "$FILECONTENT" | sed 's/\\*$//g')
    # Remove leading and trailing whitespace
    # FILECONTENT="$(echo "${FILECONTENT}" |  sed 's/^[ \t]*//;s/[ \t]*$//')"

    
    case "$CONTENT_TO_CHECK" in
        *"$NL"*) # CONTENT_TO_CHECK is multiple lines
            if $DEBUG
            then
                debug_echo 1 -e "Content to check is MULTIPLE lines\n"
                debug_echo 1 -e "${DEFAULT_UNDERLINE_COLOR}Content to check:${END_COLOR}"
                debug_echo 1 "$CONTENT_TO_CHECK"
                debug_echo 1 " "
            fi
            ;;
        *) # CONTENT_TO_CHECK is one line
            if $DEBUG
            then
                # Remove leading & trailing whitespace
                CONTENT_TO_CHECK_WO_WHITESPACE=$(sed 's/^[ \t]*//;s/[ \t]*$//' <<< "$CONTENT_TO_CHECK")
                # Remove leading (& trailing again without meaning)
                # Grep using content without leading or trailing whitespace
                SED_OUTPUT=$(sed 's/^[ \t]*//;s/[ \t]*$//' <<< "$FILECONTENT")
                GREP_OUTPUT=$(grep -Fxn "$CONTENT_TO_CHECK_WO_WHITESPACE" --color=never <<< "$SED_OUTPUT")

                debug_echo 1 -e "Content to check is ONE line.\n"
                debug_echo 1 -e "${DEFAULT_UNDERLINE_COLOR}Content to check:${END_COLOR}"
                debug_echo 1 "$CONTENT_TO_CHECK"
                debug_echo 1 -e "\n${DEFAULT_UNDERLINE_COLOR}GREP output:${END_COLOR}"
                debug_echo 1 -e "$GREP_OUTPUT\n"
            fi

            # Remove leading (& trailing again without meaning)
            # Grep using content without leading or trailing whitespace
            LINE_NUMBER=$(sed 's/^[ \t]*//;s/[ \t]*$//' <<< "$FILECONTENT" | grep -Fxn "$CONTENT_TO_CHECK_WO_WHITESPACE" | cut -f1 -d:)
            
            if [[ -n "$LINE_NUMBER" ]] ;
            then

                declare -g $3_START=${LINE_NUMBER}
                declare -g $3_END=${LINE_NUMBER}
                # For eval and print within this function
                START=$3_START
                END=$3_END
                declare -g $3_EXISTS=true

                debug_echo 1 -e "${GREEN_COLOR}######################${END_COLOR}"
                debug_echo 1 -e "${GREEN_COLOR}### Found content! ###${END_COLOR}"
                debug_echo 1 -e "${GREEN_COLOR}######################${END_COLOR}\n"
                debug_echo 1 "Content STARTING at line: ${!START}"
                debug_echo 1 -e "Content ENDING at line:   ${!END}\n"
                debug_echo 1 -e "--------------------------------"
                debug_echo 1 "||| END checking for content |||"
                debug_echo 1 -e "--------------------------------\n"
                return 0
            else
                debug_echo 1 -e "${RED_COLOR}#############################${END_COLOR}"
                debug_echo 1 -e "${RED_COLOR}### Did NOT find content! ###${END_COLOR}"
                debug_echo 1 -e "${RED_COLOR}#############################${END_COLOR}\n"
                debug_echo 1 -e "--------------------------------"
                debug_echo 1 "||| END checking for content |||"
                debug_echo 1 -e "--------------------------------\n"
                return -1
            fi ;;
    esac

    # If multiple lines
    REPLACED_CONTENT=${FILECONTENT/"$CONTENT_TO_CHECK"/}
    
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
        declare -g $3_EXISTS=true
        debug_echo 1 -e "${GREEN_COLOR}######################${END_COLOR}"
        debug_echo 1 -e "${GREEN_COLOR}### Found content! ###${END_COLOR}"
        debug_echo 1 -e "${GREEN_COLOR}######################${END_COLOR}\n"
        debug_echo 1 "Content STARTING at line: ${!START}"
        debug_echo 1 -e "Content ENDING at line:   ${!END}\n"
        debug_echo 1 -e "--------------------------------"
        debug_echo 1 "||| END checking for content |||"
        debug_echo 1 -e "--------------------------------\n"
        return 0
    else
        debug_echo 1 -e "${RED_COLOR}#############################${END_COLOR}"
        debug_echo 1 -e "${RED_COLOR}### Did NOT find content! ###${END_COLOR}"
        debug_echo 1 -e "${RED_COLOR}#############################${END_COLOR}\n"
        debug_echo 1 -e "--------------------------------"
        debug_echo 1 "||| END checking for content |||"
        debug_echo 1 -e "--------------------------------\n"
        return -1
    fi
    
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
        debug_echo 100 "$FILE_NAME already exists."

        if exists_in_file "$PATH_FILE/$FILE_NAME" "$CONTENT_TO_ADD" CONTENT_TO_ADD
        then # Content is already in the file
            debug_echo 100 "$FILE_NAME already contains the relevant content."
            return_value='already done'
            return 0
        else # Append content to file
            debug_echo 100 "Append to $FILE_NAME"
            debug_echo 100 " "
            echo "$CONTENT_TO_ADD" >> "$PATH_FILE/$FILE_NAME"
            return_value='success'
            return 0
        fi
    else # Create file with content
        debug_echo 100 -e "Create directory: $PATH_FILE/\n"
        mkdir -p $PATH_FILE
        debug_echo 100 -e "Create file $PATH_FILE/$FILE_NAME\n"
        echo "$CONTENT_TO_ADD" > $PATH_FILE/$FILE_NAME
        return_value='success'
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
            debug_echo 100 "Failed. 'curl' command failed."
            return -1
        fi

        FILE_CONTENT=$(<$PATH_FILE/$FILE_NAME)
        add_content_to_file "$PATH_FILE" "$FILE_NAME" "$URL_CONTENT"
        return
    fi
    debug_echo 100 "Command \"curl\" not available"
    debug_echo 100 " "

    # Use 'wget' if available
    if [[ -n $IS_WGET_AVAILABLE ]]
    then
        URL_CONTENT=$(wget -O- $FILE_URL)

        if [[ $? != 0 ]]
        then
            debug_echo 100 "Failed. 'wget' command failed."
            return -1
        fi

        add_content_to_file "$PATH_FILE" "$FILE_NAME" "$URL_CONTENT"
        return
    fi

    debug_echo 100 "Command \"wget\" not available"
    debug_echo 100 " "
    debug_echo 100 "Failed. Neither 'curl' or 'wget' is availale. Can't fetch content."

    return -1
}

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
    FILE=$1
    IF_LINE_NUMBER=$2
    VAR_NAME=$3
    MAX_LEVEL=$4

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
    local var_name_LNs="${VAR_NAME}_LNs"
    declare -ag "${var_name_LNs}=()"
    declare eval_var_name_LNs="${var_name_LNs}[@]"
    declare eval_index_var_name_LNs="${var_name_LNs}[index]"
    

    # Declare dynamic name array ${VAR_NAME}_type
    local var_name_type="${VAR_NAME}_type"
    declare -ag "${var_name_type}=()"
    declare eval_var_name_type="${var_name_type}[@]"
    declare eval_index_var_name_type="${var_name_type}[index]"

    # declare -ag "${VAR_NAME}_type=()"
    # declare -n var_name_type="${VAR_NAME}_type"
    # eval_var_name_type="${VAR_NAME}_type[@]"
    # declare  eval_index_var_name_type="${VAR_NAME}_type[index]"

    debug_echo 100 "********************************************************"
    debug_echo 100 "***** Update if statement variables ********************"
    debug_echo 100 "********************************************************"

    if_statement_level=0
    line_count=0
    while read -r line; do
        # Get first word of line
        first_word=$(echo "$line" | head -n1 | awk '{print $1;}')
        
        case $first_word in
        'if')
            ((if_statement_level++)) || true # Force true

            if (( if_statement_level <= MAX_LEVEL ))
            then
                append_array $var_name_LNs $((IF_LINE_NUMBER + $line_count))
                append_array $var_name_type 'if'
            fi
            ;;
        'elif')
            if (( if_statement_level <= MAX_LEVEL ))
            then
                append_array $var_name_LNs $((IF_LINE_NUMBER + $line_count))
                append_array $var_name_type 'elif'
            fi
            ;;
        'else')
            if (( if_statement_level <= MAX_LEVEL ))
            then
                append_array $var_name_LNs $((IF_LINE_NUMBER + $line_count))
                append_array $var_name_type 'else'
            fi
            ;;
        'fi')
            ((if_statement_level--))

            if ((if_statement_level <= MAX_LEVEL - 1))
            then
                append_array $var_name_LNs $((IF_LINE_NUMBER + $line_count))
                append_array $var_name_type 'fi'

                if ((if_statement_level == 0))
                then
                    return 0
                fi
            fi
            ;;
        *)
            ;;
        esac
        
        ((line_count++)) || true # Force true
    done < <(tail -n "+$IF_LINE_NUMBER" $FILE)

    return -1
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
                        sed -i "$((tmp_intervals[preferred_index] + 1))i $line" "$FILE_PATH/$FILE_NAME"
                        ;;
                    *)
                        sed -i "$((tmp_intervals[preferred_index + 1]))i $line" "$FILE_PATH/$FILE_NAME"
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
                echo ""
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
    local return_value_create_colorscheme="$return_value"

    create_vimrc
    local return_value_create_vim_rc="$return_value"

    if [[ "$return_value_create_colorscheme" == 'already done' ]] && \
       [[ "$return_value_create_vim_rc" == 'already done' ]]
    then
        return_value='already done'
        return 0
    else
        return_value='success'
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
        then # Could not set the setting
            return_value='could not set the git setting'
            return 255
        fi

        return_value='success'
        return 0
    else # Already set to the wished setting
        return_value='already done'
        return 0
    fi

    RESULTS=$(git config --global --get difftool.prompt)
    if [[ "$RESULTS" != "vimdiff" ]]
    then # Not set to wished setting. Set it.
        git config --global diff.tool vimdiff

        RESULTS=$(git config --global difftool.prompt false)
        if [[ "$RESULTS" != "vimdiff" ]]
        then # Could no set the setting
            return_value='could not set the git setting'
            return 255
        fi

        return_value='success'
        return 0
    else # Already set to the wished setting
        return_value='already done'
        return 0
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
                debug_echo 100 -e "Failed installing 'trash-cli' package.\n"
                return_value='failed installing trash-cli package'
                return 255
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
    #         return_value='success'
    #         ;;
    #     255) # Already done
    #         return_value='already done'
    #         ;;
    #     *)   # Failure
    #         return_value='Could not get internet file git completion bash.'
    #         return -1;;
    # esac

    # # Make it executable
    # sudo chmod +x $PATH_GITCOMPLETIONBASH/$NAME_GITCOMPLETIONBASH
    # RETURN_CHMOD=$?

    # if [[ $RETURN_CHMOD != 0 ]]
    # then
    #     return_value='Chmod of git completion bash failure.'
    #     return -1
    # fi



    # Find if statement to know where to place content (above,in-between,below)
    debug_echo 100 "*****************************************************************************"
    debug_echo 100 "***** Time for finding if statement *****************************************"
    debug_echo 100 "*****************************************************************************"
    IF_STATEMENT='if [ "$color_prompt" = yes ]; then'
    exists_in_file "$PATH_BASHRC/$NAME_BASHRC" "$IF_STATEMENT" IF_STATEMENT
    debug_echo 100 "IF_STATEMENT_EXISTS: $IF_STATEMENT_EXISTS"
    debug_echo 100 "IF_STATEMENT_START: $IF_STATEMENT_START IF_STATEMENT_END: $IF_STATEMENT_END"
    if $IF_STATEMENT_EXISTS
    then
        find_else_elif_fi_statement "$PATH_BASHRC/$NAME_BASHRC" "$IF_STATEMENT_START" if_statement 1
        if [[ "$?" != 0 ]]
        then
            debug_echo 100 "Problem in finding else/elif/fi statement."
            return_value='problem finding else/elif/fi statement'
            return -1
        fi

        debug_echo 100 -e "\nFound if statement at..."
        debug_echo 100 "if_statement_LNs: ${if_statement_LNs[*]}"
        debug_echo 100 -e "if_statement_type: ${if_statement_type[*]}\n"

        everything_already_done=true
        anything_success=false
        anything_failure=false
        #################################################################
        ############################ INPUT 1 ############################
        #################################################################

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

        IF_STATEMENT='if [ "$color_prompt" = yes ]; then'
        declare -a intervals=("${if_statement_LNs[@]}")
        declare -a allowed_intervals=(true false false true)
        declare -a preferred_interval=(true false false false)

        add_single_line_content "$PATH_BASHRC" "$NAME_BASHRC" BASHRC_INPUT1 "INBETWEEN" "END" "${#intervals[@]}" "${intervals[@]}" "${#allowed_intervals[@]}" "${allowed_intervals[@]}" "${#preferred_interval[@]}" "${preferred_interval[@]}"

        case "$return_value" in
            'already done')
                ;;
            'success')
                everything_already_done=false
                anything_success=true
                ;;
            *)
                everything_already_done=false
                anything_failure=true
                ;;
        esac

        #################################################################
        ############################ INPUT 2 ############################
        #################################################################

        # Multi-line needs to be handled as multi-line. Not go through iteration while loop
        define BASHRC_INPUT2 <<'EOF'
PS1_custom='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u\[\033[00m\]:\['\
'\033[01;34m\]\w\[\033[00m\]\$ '
EOF

        # Update if statement variables with new line numbers
        IF_STATEMENT='if [ "$color_prompt" = yes ]; then'
        exists_in_file "$PATH_BASHRC/$NAME_BASHRC" "$IF_STATEMENT" IF_STATEMENT
        find_else_elif_fi_statement "$PATH_BASHRC/$NAME_BASHRC" "$IF_STATEMENT_START" if_statement 1
        declare -a intervals=("${if_statement_LNs[@]}")
        declare -a allowed_intervals=(true false false false)
        declare -a preferred_interval=(true false false false)
        
        add_multiline_content "$PATH_BASHRC" "$NAME_BASHRC" BASHRC_INPUT2 "INBETWEEN" "END" "${#intervals[@]}" "${intervals[@]}" "${#allowed_intervals[@]}" "${allowed_intervals[@]}" "${#preferred_interval[@]}" "${preferred_interval[@]}"

        case "$return_value" in
            'already done')
                ;;
            'success')
                everything_already_done=false
                anything_success=true
                ;;
            *)
                everything_already_done=false
                anything_failure=true
                ;;
        esac
        #################################################################
        ############################ INPUT 3 ############################
        #################################################################

        define BASHRC_INPUT3 <<'EOF'
PS1_original='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m'\
'\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
EOF
        # Update if statement variables with new line numbers
        IF_STATEMENT='if [ "$color_prompt" = yes ]; then'
        exists_in_file "$PATH_BASHRC/$NAME_BASHRC" "$IF_STATEMENT" IF_STATEMENT
        find_else_elif_fi_statement "$PATH_BASHRC/$NAME_BASHRC" "$IF_STATEMENT_START" if_statement 1
        declare -a intervals=("${if_statement_LNs[@]}")
        declare -a allowed_intervals=(true false false false)
        declare -a preferred_interval=(true false false false)
        
        add_multiline_content "$PATH_BASHRC" "$NAME_BASHRC" BASHRC_INPUT3 "INBETWEEN" "END" "${#intervals[@]}" "${intervals[@]}" "${#allowed_intervals[@]}" "${allowed_intervals[@]}" "${#preferred_interval[@]}" "${preferred_interval[@]}"

        case "$return_value" in
            'already done')
                ;;
            'success')
                everything_already_done=false
                anything_success=true
                ;;
            *)
                everything_already_done=false
                anything_failure=true
                ;;
        esac

        #################################################################
        ############################ INPUT 4 ############################
        #################################################################

        # Update if statement variables with new line numbers
        IF_STATEMENT='if [ "$color_prompt" = yes ]; then'
        exists_in_file "$PATH_BASHRC/$NAME_BASHRC" "$IF_STATEMENT" IF_STATEMENT
        find_else_elif_fi_statement "$PATH_BASHRC/$NAME_BASHRC" "$IF_STATEMENT_START" if_statement 1
        declare -a intervals=("${if_statement_LNs[@]}")
        declare -a allowed_intervals=(false true false false)
        declare -a preferred_interval=(false true false false)
        
        BASHRC_INPUT4='PS1=$PS1_custom'
        add_single_line_content "$PATH_BASHRC" "$NAME_BASHRC" BASHRC_INPUT4 "INBETWEEN" "START" "${#intervals[@]}" "${intervals[@]}" "${#allowed_intervals[@]}" "${allowed_intervals[@]}" "${#preferred_interval[@]}" "${preferred_interval[@]}"

        case "$return_value" in
            'already done')
                ;;
            'success')
                everything_already_done=false
                anything_success=true
                ;;
            *)
                everything_already_done=false
                anything_failure=true
                ;;
        esac

        #################################################################
        ############################ INPUT 5 ############################
        #################################################################
        
        define BASHRC_INPUT5 <<'EOF'
PROMPT_COMMAND=$(sed -r 's|^(.+)(\\\$\s*)$|__git_ps1 "\1" "\2"|' <<< $PS1)
EOF
        if $anything_failure
        then
            return_value='failure'
            return 0
        elif $anything_success
        then
            return_value='success'
        elif $everything_already_done
        then
            return_value='already done'
        else
            return_value='unknown'


            return 0
        fi

        return 0
    fi
}
###################################
### END OF GIT COMPLETION SETUP ###
###################################



#################
### CALL MAIN ###
#################
main
#################
#################