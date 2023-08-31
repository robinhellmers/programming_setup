[[ -n $GUARD_FILE ]] && return || readonly GUARD_FILE=1

##############################
### Library initialization ###
##############################

init_lib()
{
    find_this_script_path

    local -r LIB_PATH="$this_script_path"

    source "$LIB_PATH/dynamic.bash"
    source "$LIB_PATH/base.bash"
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
        if ! [[ -d "$destination_path" ]]
        then
            mkdir -p "$destination_path"
            if ! [[ -d "$destination_path" ]]
            then
                echo "Could not create destination path:"
                echo "    $destination_path"
                exit 1
            fi
        fi
    else
        destination_path="$source_path"
    fi

    echo -e "Creating backup of:"
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

backup_multiple()
{
    local destination_path="$1"; shift

    echo -e "\nStart backing up files..."
    local file_path file_name

    local dynamic_array_prefix="input_array"
    handle_input_arrays_dynamically "$dynamic_array_prefix" "$@"

    get_dynamic_array "${dynamic_array_prefix}1"
    local arr_file_path=("${dynamic_array[@]}")

    get_dynamic_array "${dynamic_array_prefix}2"
    local arr_file_name=("${dynamic_array[@]}")
    for index in "${!arr_file_name[@]}"
    do
        file_name="${arr_file_name[index]}"
        file_path="${arr_file_path[index]}"
        if ! backup "$file_path/$file_name" "$destination_path"
        then
            echo "Could not backup the file:"
            echo "    $file_path/$file_name"
            echo "to the directory:"
            echo "    $destination_path/"
            exit 1
        fi
    done

    echo "Backups done."
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
    local files_already_exists='true'
    for (( i=0; i<len; i++ ))
    do
        source_file="${arr_source_path[i]}/${arr_source_file_name[i]}"
        dest_file="${arr_destination_path[i]}/${arr_destination_file_name[i]}"

        if ! [[ -f "$dest_file" ]] || \
           ! cmp --silent "$source_file" "$dest_file"
        then
            files_already_exists='false'
            break
        fi
    done

    if [[ "$files_already_exists" == "true" ]]
    then
        echo "All files already copied."
        return_value_export_files_new='already done'
        return 0
    fi

    echo -e "\nStart copying files..."
    for (( i=0; i<len; i++ ))
    do
        source_file="${arr_source_path[i]}/${arr_source_file_name[i]}"
        dest_file="${arr_destination_path[i]}/${arr_destination_file_name[i]}"

        cp "$source_file" "$dest_file"
        eval_cmd "Could not copy file:\n    $source_file\nto\n    $dest_file"

        echo -e "Copied from:\n    $source_file\nCopied to:\n    $dest_file"
    done
    
    echo -e "Copies done."
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
    files_differing_first_arr=()
    files_differing_second_arr=()
    echo -e "\nStart comparing files..."
    for (( i=0; i < len; i++ ))
    do
        file_one="${arr_source_path[i]}/${arr_source_file_name[i]}"
        file_two="${arr_destination_path[i]}/${arr_destination_file_name[i]}"

        if ! cmp --silent "$file_one" "$file_two"
        then
            all_comparisons_equal='false'
            files_differing_first_arr+=("${arr_source_file_name[i]}")
            files_differing_second_arr+=("${arr_destination_file_name[i]}")
            echo "Files not equal:"
            echo "* $file_one"
            echo "* $file_two"
        fi
    done

    if [[ "$all_comparisons_equal" == 'true' ]]
    then
        echo "Comparisons done. All resulted in equal."
        return 0
    fi

    echo "Comparisons done. See mismatches above."
    return 1
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
    local file_content=$(<$1)
    local to_check="$2"
    local dyn_var_prefix="$3"

    declare -g ${dyn_var_prefix}_exists='false'
    
    
    debug_echo 1 -e "\n----------------------------------"
    debug_echo 1 "||| Start checking for content |||"
    debug_echo 1 -e "----------------------------------\n"

    # Remove trailing whitespace
    file_content="$(echo "${file_content}" | sed -e 's/[[:space:]]*$//')"
    # file_content=$(echo "$file_content" | sed 's/\\*$//g')
    # Remove leading and trailing whitespace
    # file_content="$(echo "${file_content}" |  sed 's/^[ \t]*//;s/[ \t]*$//')"

    case "$to_check" in
        *"$NL"*) # CONTENT_TO_CHECK is multiple lines
            _handle_multiline_content "$file_content" "$to_check" "$dyn_var_prefix"
            return
            ;;
        *) # to_check is one line
            _handle_oneline_content "$file_content" "$to_check" "$dyn_var_prefix"
            return
            ;;
    esac
}

_handle_oneline_content()
{
    local FILECONTENT="$1"
    local CONTENT_TO_CHECK="$2"

    # Remove leading & trailing whitespace
    local CONTENT_TO_CHECK_WO_WHITESPACE=$(sed 's/^[ \t]*//;s/[ \t]*$//' <<< "$CONTENT_TO_CHECK")
    # Remove leading (& trailing again without meaning)
    # Grep using content without leading or trailing whitespace
    local SED_OUTPUT=$(sed 's/^[ \t]*//;s/[ \t]*$//' <<< "$FILECONTENT")
    local GREP_OUTPUT=$(grep -Fxn "$CONTENT_TO_CHECK_WO_WHITESPACE" --color=never <<< "$SED_OUTPUT")

    debug_echo 1 -e "Content to check is ONE line.\n"
    debug_echo 1 -e "${DEFAULT_UNDERLINE_COLOR}Content to check:${END_COLOR}"
    debug_echo 1 "$CONTENT_TO_CHECK"
    debug_echo 1 -e "\n${DEFAULT_UNDERLINE_COLOR}GREP output:${END_COLOR}"
    debug_echo 1 -e "$GREP_OUTPUT\n"

    if [[ -z "$FILECONTENT" ]]
    then
        debug_echo 1 -e "Given file content is empty."
        return 1
    elif [[ -z "$CONTENT_TO_CHECK" ]]
    then
        debug_echo 1 -e "Given  content to look for is empty."
        return 1
    fi

    # Remove leading (& trailing again without meaning)
    # Grep using content without leading or trailing whitespace
    local LINE_NUMBER=$(sed 's/^[ \t]*//;s/[ \t]*$//' <<< "$FILECONTENT" | grep -Fxn "$CONTENT_TO_CHECK_WO_WHITESPACE" | cut -f1 -d:)

    if [[ -n "$LINE_NUMBER" ]] ;
    then
        local START=${3}_START
        local END=${3}_END
        declare -ag $START
        declare -ag $END

        while IFS= read -r value
        do
            append_array "$START" "$value"
            append_array "$END" "$value"
        done <<< "$LINE_NUMBER"

        declare -g $3_EXISTS='true'

        debug_echo 1 -e "${GREEN_COLOR}######################${END_COLOR}"
        debug_echo 1 -e "${GREEN_COLOR}### Found content! ###${END_COLOR}"
        debug_echo 1 -e "${GREEN_COLOR}######################${END_COLOR}\n"

        local len_found_start="$(get_dynamic_array_len "$START")"
        local len_found_end="$(get_dynamic_array_len "$END")"

        debug_echo 1 "Found $len_found_start number of matching contents"

        for (( i=0; i<len_found_start; i++ ))
        do
            local element_start="$(get_dynamic_element $START $i)"
            local element_end="$(get_dynamic_element $END $i)"
            debug_echo 1 -e "\nMatch $((i + 1)):"
            debug_echo 1 "Between lines $element_start - $element_end"
        done

        debug_echo 1 -e "\n--------------------------------"
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
        return 1
    fi
}

_find_multiline_content()
{
    local file_content="$1"
    local to_find="$2"

    local to_find_wo_ws
    # Remove leading whitespace from only the first line
    to_find_wo_ws="${to_find#"${to_find%%[![:space:]]*}"}"
    # Remove trailing whitespace from all lines
    to_find_wo_ws=$(sed -E 's/[[:space:]]*$//' <<< "$to_find_wo_ws")

    # Remove trainling whiespace from all lines
    file_content=$(sed -E 's/[[:space:]]*$//' <<< "$file_content")
    
    local first_line_to_find
    first_line_to_find="$(sed "1q;d" <<< "$to_find_wo_ws")"

    # Find potential potential matches
    local first_line_matches
    first_line_matches="$(grep -n "$first_line_to_find" <<< "$file_content" | cut -d : -f 1)"
    # Store in array
    IFS=$'\n' first_line_matches=($first_line_matches)

    local matches_line_numbers_start=()
    for line_num in "${first_line_matches[@]}"
    do
        # For each first line match, start checking rest of lines to match
        local rel_line_num=1
        local content_is_matching='true'
        while IFS= read -r look_for_line # <<< "$to_find_wo_ws"
        do
            (( rel_line_num == 1)) && { ((rel_line_num++)); continue; }

            [[ "$content_is_matching" != 'true' ]] && break

            local file_line
            file_line="$(sed "$((line_num + rel_line_num - 1))q;d" <<< "$file_content")"

            [[ "$file_line" != "$look_for_line" ]] && content_is_matching='false'

            ((rel_line_num++))
        done <<< "$to_find_wo_ws"

        if [[ "$content_is_matching" == 'true' ]]
        then
            matching_starting_line_numbers+=("$line_num")
        fi
    done

    echo "${matching_starting_line_numbers[@]}"
}

_handle_multiline_content()
{
    local file_content="$1"
    local to_find="$2"
    local dyn_var_prefix="$3"

    local matches_line_nums
    matches_line_nums=($(_find_multiline_content "$file_content" "$to_find"))

    if [[ -z "${matches_line_nums[@]}" ]]
    then
        return 1
    fi
    
    declare -g ${dyn_var_prefix}_exists='true'

    local dyn_var_start=${dyn_var_prefix}_start
    local dyn_var_end=${dyn_var_prefix}_end
    declare -ag $dyn_var_start
    declare -ag $dyn_var_end

    local num_lines=$(echo -n "$to_find" | grep -c '^')

    for line_num in "${matches_line_nums[@]}"
    do
        append_array "$dyn_var_start" "$line_num"
        append_array "$dyn_var_end" "$((line_num + num_lines - 1))"
    done

    debug_echo 1 -e "${GREEN_COLOR}######################${END_COLOR}"
    debug_echo 1 -e "${GREEN_COLOR}### Found content! ###${END_COLOR}"
    debug_echo 1 -e "${GREEN_COLOR}######################${END_COLOR}\n"

    local len_found_start="$(get_dynamic_array_len "$dyn_var_start")"
    local len_found_end="$(get_dynamic_array_len "$dyn_var_end")"

    debug_echo 1 "Found $len_found_start number of matching contents"

    for (( i=0; i<len_found_start; i++ ))
    do
        local element_start="$(get_dynamic_element $dyn_var_start $i)"
        local element_end="$(get_dynamic_element $dyn_var_end $i)"
        debug_echo 1 -e "\nMatch $((i + 1)):"
        debug_echo 1 "Between lines $element_start - $element_end"
    done

    debug_echo 1 -e "\n--------------------------------"
    debug_echo 1 "||| END checking for content |||"
    debug_echo 1 -e "--------------------------------\n"
    return 0
}

_handle_multiline_content_old()
{
    local FILECONTENT="$1"
    local CONTENT_TO_CHECK="$2"

    debug_echo 1 -e "Content to check is MULTIPLE lines\n"
    debug_echo 1 -e "${DEFAULT_UNDERLINE_COLOR}Content to check:${END_COLOR}"
    debug_echo 1 "$CONTENT_TO_CHECK"
    debug_echo 1 " "

    if [[ -z "$FILECONTENT" ]]
    then
        debug_echo 1 -e "Given file content is empty."
        return 1
    elif [[ -z "$CONTENT_TO_CHECK" ]]
    then
        debug_echo 1 -e "Given  content to look for is empty."
        return 1
    fi

    local CONTENT_TO_CHECK_WO_WHITESPACE
    # Remove leading whitespace from only the first line
    CONTENT_TO_CHECK_WO_WHITESPACE="${CONTENT_TO_CHECK#"${CONTENT_TO_CHECK%%[![:space:]]*}"}"
    # Remove trailing whitespace from all lines
    CONTENT_TO_CHECK_WO_WHITESPACE=$(sed 's/[ \t]*$//' <<< "$CONTENT_TO_CHECK_WO_WHITESPACE")

    echo "CONTENT_TO_CHECK_WO_WHITESPACE:"
    echo "$CONTENT_TO_CHECK_WO_WHITESPACE"
    echo ""

    echo GREP START
    awk -v RS='^$' -v ORS= -v content="$CONTENT_TO_CHECK" '$0 ~ content {print}' <<< "$FILECONTENT"
    exit

    # REPLACED_CONTENT=${FILECONTENT/"$CONTENT_TO_CHECK"/}
    FILECONTENT_PREVIOUS="$FILECONTENT"
    CONTENT_REMOVED=${FILECONTENT_PREVIOUS/"$CONTENT_TO_CHECK"/}
    THEDIFF=$(diff <(echo "$FILECONTENT_PREVIOUS") <(echo "$CONTENT_REMOVED"))
    debug_echo 100 -e "THEDIFF:\n$THEDIFF\n"

    FILECONTENT_PREVIOUS=${FILECONTENT_PREVIOUS/"$CONTENT_TO_CHECK"/"DUMMY TEXT $CONTENT_TO_CHECK"}

    CONTENT_REMOVED=${FILECONTENT_PREVIOUS/"$CONTENT_TO_CHECK"/}
    THEDIFF=$(diff <(echo "$FILECONTENT_PREVIOUS") <(echo "$CONTENT_REMOVED"))
    debug_echo 100 -e "THEDIFF:\n$THEDIFF\n"

    exit 1
    # REPLACED_CONTENT=$(sed "s|$CONTENT_TO_CHECK||g" <<< "$FILECONTENT")
    # echo "REPLACED_CONTENT"
    # echo "$REPLACED_CONTENT"
    # echo 
    THEDIFF=$(diff <(echo "$FILECONTENT") <(echo "$REPLACED_CONTENT"))
    debug_echo 100 -e "THEDIFF:\n$THEDIFF\n"
    REPLACED_CONTENT=${REPLACED_CONTENT/"$CONTENT_TO_CHECK"/"DUMMY TEXT $CONTENT_TO_CHECK"}
    THEDIFF=$(diff <(echo "$FILECONTENT") <(echo "$REPLACED_CONTENT"))
    debug_echo 100 -e "THEDIFF:\n$THEDIFF\n"
    REPLACED_CONTENT=${REPLACED_CONTENT/"$CONTENT_TO_CHECK"/"DUMMY TEXT $CONTENT_TO_CHECK"}
    THEDIFF=$(diff <(echo "$FILECONTENT") <(echo "$REPLACED_CONTENT"))
    debug_echo 100 -e "THEDIFF:\n$THEDIFF\n"
    
    if [[ "$FILECONTENT" != "$REPLACED_CONTENT" ]]
    then # Content to find where found and replaced

        # Find between which line numbers the diff is (find where the content where replaced)
        LINE_NUMBERS=$(diff <(echo "$FILECONTENT") <(echo "$REPLACED_CONTENT") | grep -E '^\s*[0-9]+')
        THEDIFF=$(diff <(echo "$FILECONTENT") <(echo "$REPLACED_CONTENT"))
        debug_echo 100 -e "THEDIFF:\n$THEDIFF\n"
        debug_echo 100 -e "LINE_NUMBERS:\n$LINE_NUMBERS\n"
        # Split them up into an array
        IFS=',cd' read -r -a line_numbers <<< "$LINE_NUMBERS"
        # Sort the array, from min to max
        IFS=$'\n' sorted_line_numbers=($(sort <<<"${line_numbers[*]}"))
        debug_echo 100 "sorted_line_numbers:"
        for element in "${line_numbers[@]}"
        do
            debug_echo 100 "element: $element"
        done
        

        declare -g $3_START=${sorted_line_numbers[0]}
        declare -g $3_END=${sorted_line_numbers[${#sorted_line_numbers[@]} - 1]}
        # For eval and print within this function
        START=$3_START
        END=$3_END
        declare -g $3_EXISTS='true'
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
