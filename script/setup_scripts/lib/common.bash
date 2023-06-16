
set_gitconfig_key_value()
{
    local key value current_value

    key="$1"
    value="$2"

    current_value="$(git config --global --get $key)"

    if [[ "$current_value" == "$value" ]]
    then
        return_value='already done'
        return 0
    fi

    # Set key value pair
    git config --global "$key" "$value"

    current_value="$(git config --global --get $key)"

    if [[ "$current_value" != "$value" ]]
    then # Could not set the setting
        return_value='could not set the git setting'
        return 255
    fi

    return_value='success'
    return 0
}

