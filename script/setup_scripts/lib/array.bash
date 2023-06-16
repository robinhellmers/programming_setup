
#Used for dynamic arrays to make it more readable
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