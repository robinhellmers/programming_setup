
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

backup()
{
    local file="$1"

    [[ -f "$file" ]] || return

    echo -e "\nCreating backup of:"
    echo "    $file"
    for (( i=1; i<=MAX_BACKUPS; i++ ))
    do
        local suffix=".backup-$i"
        local backup="$file$suffix"
        [[ -f "$backup" ]] && continue

        cp "$file" "$backup"
        eval_cmd "Could not backup file:\n    $file\nto:\n    $backup"

        echo "Created backup file:"
        echo "    $backup"
        break
    done
}