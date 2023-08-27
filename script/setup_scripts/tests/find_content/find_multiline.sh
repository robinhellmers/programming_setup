#!/usr/bin/env bash

filename="testfile"

main()
{
    var="        first line
    second line  
third line   "

    file_content=$(<$filename)

    find "$var" "$file_content"
}

find()
{
    local var="$1"
    local file_content="$2"

    local var_no_ws
    # Remove leading whitespace from only the first line
    var_no_ws="${var#"${var%%[![:space:]]*}"}"
    # Remove trailing whitespace from all lines
    var_no_ws=$(sed -E 's/[[:space:]]*$//' <<< "$var_no_ws")

    # Remove trainling whiespace from all lines
    file_content=$(sed -E 's/[[:space:]]*$//' <<< "$file_content")
    
    local first_line_var
    first_line_var="$(sed "1q;d" <<< "$var_no_ws")"

    # Find potential potential matches
    local first_line_matches
    first_line_matches_line_num="$(grep -n "$first_line_var" <<< "$file_content" | cut -d : -f 1)"
    # Store in array
    IFS=$'\n' first_line_matches_line_num=($first_line_matches_line_num)

    echo "first_line_matches_line_num[@]:"
    echo "${first_line_matches_line_num[@]}"

    local matching_starting_line_numbers=()
    for line_num in "${first_line_matches_line_num[@]}"
    do  
        echo "Looking at line number: $line_num"
        local rel_line_num=1
        local content_is_matching='true'
        while IFS= read -r look_for_line
        do
            if (( rel_line_num == 1))
            then
                ((rel_line_num++))
                continue
            elif [[ "$content_is_matching" != 'true' ]]
            then
                continue
            fi
            
            local file_line
            file_line="$(sed "$((line_num + rel_line_num - 1))q;d" <<< "$file_content")"

            echo "file_line:"
            echo "'$file_line'"
            echo "look_for_line:"
            echo "'$look_for_line'"
            echo

            if [[ "$file_line" == "$look_for_line" ]]
            then
                echo "Lines are equal!"
            else
                echo "Lines are NOT equal!"
                content_is_matching='false'
            fi

            echo ""
            
            ((rel_line_num++))
        done <<< "$var_no_ws"

        if [[ "$content_is_matching" == 'true' ]]
        then
            matching_starting_line_numbers+=("$line_num")
            echo -e "Content found starting at line: $line_num\n"
        fi
    done

    echo -e "\n\n"
    echo "All matching content start line numbers:"
    echo "${matching_starting_line_numbers[@]}"
}

main
