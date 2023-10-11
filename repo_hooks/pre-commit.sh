#!/usr/bin/env bash

main()
{
    check_git_repo

    init

    create_dbg_files

    remove_lines

    check_staged_files

    [[ "$created_dbg_file" == 'true' ]] && exit 1
    [[ "$did_remove_lines" == 'true' ]] && exit 1

    echo
    exit 0
}

init()
{
    # Remove all of the following lines from <file>.dbg and store in <file>
    lines_to_remove='
^[\s]*debug_echo [0-9]+
'

    exclude_files='

'
    exclude_files="$exclude_files
$(basename ${BASH_SOURCE[0]})
$(git check-ignore $(find $top_path -not -path '*/.*' -type f -print))
"
}

check_git_repo()
{
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1
    then
        echo "Not in git repository."
        echo "Exiting."
        exit 1
    fi

    top_path=$(git rev-parse --show-toplevel)
}


create_dbg_files()
{
    created_dbg_file='false'
    echo "*** Check if debug files need to be created ***"
    while IFS= read -r line_to_remove
    do
        [[ "$line_to_remove" == '' ]] && continue

        # For each file containing matching line to remove
        while read -r file_with_line
        do
            # Skip excluded files
            grep -qP "^${file_with_line}$" <<< "$exclude_files" && continue

            # Skip files with .dbg suffix
            grep -qP ".+.dbg$" <<< "$file_with_line" && continue

            echo -e "\nMatch: ${file_with_line}"

            # Only create .dbg if not existing
            if ! [[ -f "${file_with_line}.dbg" ]]
            then
                cp "$file_with_line" "${file_with_line}.dbg"
                echo "Created ${file_with_line}.dbg"
                created_dbg_file='true'
            fi
        done <<< "$(grep -rPol --exclude-dir=.*[/.git/] "$line_to_remove" "$top_path")"
    done <<< "$lines_to_remove"

    [[ "$created_dbg_file" == 'false' ]] && echo "None created."
    echo ''
}

remove_lines()
{
    did_remove_lines='false'
    echo "*** Check if any lines shall be removed ***"
    # For each file with .dbg suffix
    while IFS= read -r file
    do
        # Skip excluded files
        grep -qP "^${file}$" <<< "$exclude_files" && continue

        tmp_new_file="$(mktemp)" || exit
        cp -p "$file" "$tmp_new_file"

        updated_lines_to_remove=()

        removed_line='false'
        while IFS= read -r line_to_remove
        do
            [[ "$line_to_remove" == '' ]] && continue

            # Check if line exists in file
            local grep_out
            grep_out=$(grep -Pn "$line_to_remove" "$tmp_new_file") || continue

            IFS=$'\n' line_nums=($(cut -d: -f1 <<< "$grep_out"))

            convert_to_relative "${line_nums[@]}"

            # In:
            # relative_lines_start[]
            # relative_lines_num[]
            relative_lines_add_surrounding_ws_lines
            # Out:
            # updated_lines_to_remove[]
        done <<< "$lines_to_remove"

        # Prepare 'sed' input line for removing lines
        sed_input=()
        for ((i=0; i < ${#relative_lines_start[@]}; i++))
        do
            local start_seq end_seq seq_output sed_input
            start_seq=${relative_lines_start[i]}
            end_seq=$((start_seq + ${relative_lines_num[i]} - 1))
            # Add sed removal d; between every number
            seq_output="$(seq -s 'd;' $start_seq $end_seq)"

            # Removal d; was only set inbetween each number and not at the end,
            # need to add the final line instruction depending on if an empty
            # line should be left behind or not
            if [[ "${any_line_with_ws_arr[i]}" == 'true' ]]
            then
                # Last line should be replaced with an empty line instead of
                # removing it as there was at least one whitespace line before 
                # or after
                sed_input="${sed_input}${seq_output}s/.*//;"
            else
                # Last line should be removed
                sed_input="${sed_input}${seq_output}d;"
            fi
        done

        # New file without .dbg suffix
        file_removed_lines="$(dirname $file)/$(basename --suffix=.dbg $file)"

        # Possibly create tmp file with the same permissions, look back on how I
        # did before removing it in this file. Then rename the file
        # to $file_Removed_lines

        # Remove lines
        sed -e "$sed_input" "$file" > "$tmp_new_file"

        # Check if any new changes to final file $file_removed_lines
        if ! cmp --silent "$tmp_new_file" "$file_removed_lines"
        then # New changes to $file_removed_lines
            mv "$tmp_new_file" "$file_removed_lines" | exit
            echo -e "\nCopied '$file'"
            echo "    to '$file_removed_lines'"
            echo -e "And removed debug lines."
            did_remove_lines='true'
        else
            rm "$tmp_new_file"
        fi

    done <<< $(find "$top_path" -not -path '*/.*' -type f -name "*.dbg")

    [[ "$did_remove_lines" == 'false' ]] && echo "None removed."
    echo ''
}

check_staged_files()
{
    echo "*** Check that corresponding dbg/non-dbg files are staged ***"
    # Get a list of all staged files
    local staged_files=$(git diff --cached --name-only)

    # Iterate over all staged files
    local file
    local not_staged_files=()
    for file in $staged_files
    do
        echo "Check staged file: '$file'"
        # If the file is not a .dbg file, check for corresponding .dbg file
        if [[ ! "$file" =~ \.dbg$ ]]
        then
            local dbg_file="${file}.dbg"
            if [[ -f "$dbg_file" ]]
            then
                if ! git diff --cached --name-only | grep -q "^${dbg_file}$"
                then
                    not_staged_files+=("$dbg_file")
                    dbg_not_staged='true'
                    echo "ABORT: Corresponding dbg file exists but is not \
staged"
                fi
            fi
        else
            # If the file is a .dbg file, check for corresponding non-.dbg file
            local original_file="${file%.dbg}"
            if [[ -f "$original_file" ]]
            then
                if ! git diff --cached --name-only | grep -q "^${original_file}$"
                then
                    not_staged_files+=("$original_file")
                    echo "ABORT: Corresponding non-dbg file exists but is \
not staged"
                    non_dbg_not_staged='true'
                fi
            fi
        fi
    done

    if [[ "$dbg_not_staged" == 'true' || "$non_dbg_not_staged" == 'true' ]]
    then
        local file
        echo
        echo "Files should be staged:"
        for file in "${not_staged_files[@]}"
        do
            echo "- $file"
        done

        cat << EOF >&2

        The dbg file should be the file which is changed and this pre-commit
        hook generates the corresponding non-dbg file changes. Both files must
        be staged for the commit.

EOF
        exit 1
    fi
}

# Returns:
# relative_lines_start[]
#     - First number of consecutive numbers (E.g. 41 if next number is 42 in
#       the given array of numbers)
# relative_lines_num[]
#     - Number of consecutive numbers from corresponding index in
#       relative_lines_start[]
# Example input:
# (37 39 41 42 43 56 58 59 65)
# Output:
# relative_lines_start = (41 58)
# relative_lines_num  = (3 2)
# Explanation:
# (41 42 43) = 3 numbers
# (58 59) = 2 numbers
convert_to_relative()
{
    local arr=("$@")

    (( ${#arr[@]} == 0 )) && return 1

    iter=1
    consecutive='false'
    prev_consecutive='false'
    relative_lines_start=()
    relative_lines_num=()

    # 1 2 3 5 7 
    for ((i=0; i<${#arr[@]}; i++))
    do
        current=${arr[i]}
        next=${arr[i+1]}

        (( i == ${#arr[@]} - 1 )) && break

        re='^[0-9]+$' # Is a number
        [[ $current =~ $re ]] || continue
        [[ $next =~ $re ]] || continue

        if (( next == current + 1 ))
        then # Consecutive
            if [[ "$prev_consecutive" == 'true' ]]
            then
                # Continous consecutive
                ((consecutive_num_lines++))
            else
                # Start of consecutive with 2 lines
                relative_lines_start+=($current)
                consecutive_num_lines=2
            fi
            
            prev_consecutive='true'
        else
            # Not consecutive

            if [[ "$prev_consecutive" == 'true' ]]
            then
                # End of consecutive
                relative_lines_num+=($consecutive_num_lines)
            else
                # Single line
                relative_lines_start+=($current)
                consecutive_num_lines=1
                relative_lines_num+=($consecutive_num_lines)
            fi

            prev_consecutive='false'
        fi
    done

    # Handle edge case of last iteration
    if [[ "$prev_consecutive" == 'true' ]]
    then
        # End of consecutive
        relative_lines_num+=($consecutive_num_lines)
    else
        # Single line
        relative_lines_start+=($current)
        consecutive_num_lines=1
        relative_lines_num+=($consecutive_num_lines)
    fi

    if (( ${#relative_lines_start[@]} != \
            ${#relative_lines_num[@]} ))
    then
        echo "ERROR: Consecutive calculations wrong."
        echo "relative_lines_start[@] length: ${#relative_lines_start[@]}"
        echo "relative_lines_num[@] length: ${#relative_lines_num[@]}"
        exit 1
    fi
}
# Returns:
# relative_lines_start[] updated
#     - Updated
# relative_lines_num[]
#     - Updated
# any_line_with_ws_arr[]
#     - Contains 'true'/'false' if relative set contains whitespace line
#       indicating whether to keep one empty line or just remove all lines
relative_lines_add_surrounding_ws_lines()
{
    any_line_with_ws_arr=()
    for (( i=0; i < ${#relative_lines_start[@]}; i++ ))
    do
        local relative_start
        local relative_num
        local line_to_check_line_num
        local num_lines_whitespace_before num_lines_whitespace_after
        local line_to_check
        local is_whitespace
        local num_lines_file
        local any_line_with_ws
        relative_start=${relative_lines_start[i]}
        relative_num=${relative_lines_num[i]}

        # Check empty lines before $relative_start
        line_to_check_line_num=$((relative_start - 1))
        num_lines_whitespace_before=0
        any_line_with_ws='false'
        while (( line_to_check_line_num > 0 ))
        do
            line_to_check=$(sed "${line_to_check_line_num}q;d" "$file")
            is_whitespace='false'

            # Check if empty or whitespace
            case "$line_to_check" in
                *[![:blank:]]*) ;;
                *) is_whitespace='true' ;;
            esac

            [[ "$is_whitespace" == 'true' ]] || break

            any_line_with_ws='true'
            ((num_lines_whitespace_before++))
            ((line_to_check_line_num--))
        done

        # Check empty lines from & after
        # $relative_start + $relative_lines_num
        line_to_check_line_num=$((relative_start + relative_num))
        num_lines_whitespace_after=0
        num_lines_file=$(wc -l "$file" | awk '{ print $1 }')
        while (( line_to_check_line_num <= num_lines_file ))
        do
            next_line=$(sed "${line_to_check_line_num}q;d" "$file")
            is_whitespace='false'

            # Check if empty or whitespace
            case "$next_line" in
                *[![:blank:]]*) ;;
                *) is_whitespace='true' ;;
            esac

            [[ "$is_whitespace" == 'true' ]] || break

            any_line_with_ws='true'
            ((num_lines_whitespace_after++))
            ((line_to_check_line_num++))
        done

        # Update arrays
        local start num
        start=$((${relative_lines_start[i]} - num_lines_whitespace_before))
        num=$((num_lines_whitespace_before + ${relative_lines_num[i]} + num_lines_whitespace_after))
        relative_lines_start[$i]=$start
        relative_lines_num[$i]=$num
        any_line_with_ws_arr+=("$any_line_with_ws")
    done
}

main
