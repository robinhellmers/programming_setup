
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
