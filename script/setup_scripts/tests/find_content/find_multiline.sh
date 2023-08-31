#!/usr/bin/env bash

filename="testfile"

main()
{
    local to_find file_content

    to_find="        first line
    second line  
third line   "

    file_content=$(<$filename)


    matches=($(find "$file_content" "$to_find"))

    echo "matches:"
    for ((i=0; i<${#matches[@]}; i++))
    do
        echo "$i: ${matches[i]}"
    done
}

find()
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

main
