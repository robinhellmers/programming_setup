[[ -n $GUARD_FILE ]] && return || readonly GUARD_FILE=1

source "$LIB_PATH/dynamic.bash"

backup()
{
    local file="$1"
    local destination_path="$2"
    local suffix backup file_name

    [[ -f "$file" ]] || return
    source_path="$(dirname $file)"
    file_name="$(basename $file)"

    if [[ -n "$destination_path" ]]
    then
        [[ -d "$destination_path" ]] || return
    else
        destination_path="$source_path"
    fi

    echo -e "\nCreating backup of:"
    echo "    ${source_path}${file_name}"
    for (( i=1; i<=MAX_BACKUPS; i++ ))
    do
        suffix=".backup-$i"

        backup="${destination_path}${file_name}${suffix}"
        [[ -f "$backup" ]] && continue

        cp "$file" "$backup"
        eval_cmd "Could not backup file:\n    $file\nto:\n    $backup"

        echo "Created backup file:"
        echo "    $backup"
        break
    done
}

export_files()
{
    local source_path="$1"
    local dest_path="$2"
    shift 2
    local array_files=("$@")

    # Check if source files exists
    for file in "${array_files[@]}"
    do
        [[ -f "$source_path/$file" ]]
        eval_cmd "Necessary file does not exist:\n    $source_path/$file"
    done

    # Check if all existing dest files equal source files
    local files_already_exists=true
    for file in "${array_files[@]}"
    do
        if ! [[ -f "$dest_path/$file" ]] || \
           ! cmp "$source_path/$file" "$dest_path/$file"
        then
            files_already_exists=false
            break
        fi
    done

    if [[ "$files_already_exists" == "true" ]]
    then
        return_value_export_files='already done'
        return 0
    fi

    echo "Copying files from '$source_path/' to '$dest_path/'..."
    for file in "${array_files[@]}"
    do
        cp "$source_path/$file" "$dest_path/$file"
        eval_cmd "Could not copy file:\n    $source_path/$file\nto\n    $dest_path/$file"

        echo "Copied '$file'"
    done
    echo ""
}

export_files_new()
{
    local source_file dest_dir dest_file

    local dynamic_array_prefix="input_array"
    handle_input_arrays_dynamically "$dynamic_array_prefix" "$@"

    get_dynamic_array "${dynamic_array_prefix}1"
    local arr_source_path=("${dynamic_array[@]}")

    get_dynamic_array "${dynamic_array_prefix}2"
    local arr_source_file_name=("${dynamic_array[@]}")

    get_dynamic_array "${dynamic_array_prefix}3"
    local arr_destination_path=("${dynamic_array[@]}")

    get_dynamic_array "${dynamic_array_prefix}4"
    local arr_destination_file_name=("${dynamic_array[@]}")

    get_dynamic_array_len "${dynamic_array_prefix}1" > /dev/null
    local len="$dynamic_array_len"

    for (( i=0; i<len; i++ ))
    do  
        source_file="${arr_source_path[i]}/${arr_source_file_name[i]}"
        [[ -f "$source_file" ]]
        eval_cmd "Necessary file does not exist:\n    $source_file"

        dest_dir="${arr_destination_path[i]}"
        [[ -d "$dest_dir" ]]
        eval_cmd "Destination directory does not exist:\n    $dest_dir"

        dest_file_name="${arr_destination_file_name[i]}"
        [[ -n "$dest_file_name" ]]
        eval_cmd "Destination file name is empty for source file:\n    $source_file"
    done

    # Check if all existing dest files equal source files
    local files_already_exists=true
    for (( i=0; i<len; i++ ))
    do
        source_file="${arr_source_path[i]}/${arr_source_file_name[i]}"
        dest_file="${arr_destination_path[i]}/${arr_destination_file_name[i]}"

        if ! [[ -f "$dest_file" ]] || \
           ! cmp --silent "$source_file" "$dest_file"
        then
            files_already_exists=false
            break
        fi
    done

    if [[ "$files_already_exists" == "true" ]]
    then
        echo "All files already copied."
        return_value_export_files_new='already done'
        return 0
    fi

    echo "Copying files..."
    for (( i=0; i<len; i++ ))
    do
        source_file="${arr_source_path[i]}/${arr_source_file_name[i]}"
        dest_file="${arr_destination_path[i]}/${arr_destination_file_name[i]}"

        cp "$source_file" "$dest_file"
        eval_cmd "Could not copy file:\n    $source_file\nto\n    $dest_file"

        echo -e "\nCopied:\n    $source_file\nto\n    $dest_file"
    done
    echo ""

    return 0
}

files_equal()
{
    local file_one="$1"
    local file_two="$2"

    [[ -f "$file_one" ]]
    eval_cmd "Necessary file does not exist:\n    $file_one"

    [[ -f "$file_two" ]]
    eval_cmd "Necessary file does not exist:\n    $file_two"

    if cmp --silent "$file_one" "$file_two"
    then
        echo -e "\nFiles are equal:"
        return_value_files_equal='true'
    else
        echo -e "\nFiles are NOT equal:"
        return_value_files_equal='false'
    fi
    echo "* $file_one"
    echo "* $file_two"

    [[ "$return_value_files_equal" == 'true' ]]
    return
}

files_equal_multiple()
{
    local return_code file_one file_two

    local dynamic_array_prefix="input_array"
    handle_input_arrays_dynamically "$dynamic_array_prefix" "$@"

    get_dynamic_array "${dynamic_array_prefix}1"
    local arr_source_path=("${dynamic_array[@]}")

    get_dynamic_array "${dynamic_array_prefix}2"
    local arr_source_file_name=("${dynamic_array[@]}")

    get_dynamic_array "${dynamic_array_prefix}3"
    local arr_destination_path=("${dynamic_array[@]}")

    get_dynamic_array "${dynamic_array_prefix}4"
    local arr_destination_file_name=("${dynamic_array[@]}")

    get_dynamic_array_len "${dynamic_array_prefix}2" > /dev/null
    local len="$dynamic_array_len"

    all_comparisons_equal='true'
    echo ""
    for (( i=0; i < len; i++ ))
    do
        file_one="${arr_source_path[i]}/${arr_source_file_name[i]}"
        file_two="${arr_destination_path[i]}/${arr_destination_file_name[i]}"

        if ! cmp --silent "$file_one" "$file_two"
        then
            all_comparisons_equal='false'
            echo "Files not equal:"
            echo "* $file_one"
            echo "* $file_two"
        fi
    done

    [[ "$all_comparisons_equal" == 'true' ]]
    return
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
