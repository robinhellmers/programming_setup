
eval_cmd()
{
    local returned_status=$?
    local error_output="$1"

    if (( returned_status != 0 ))
    then
        echo -e "$error_output"
        echo -e "Exiting with code $returned_status.\n"
        exit $returned_status
    fi
}

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

export_files()
{
    local source_path="$1"
    local dest_path="$2"
    shift 2
    local array_files=("$@")

    echo "Copying files from '$source_path/' to '$dest_path/'..."
    for file in "${array_files[@]}"
    do
        [[ -f "$source_path/$file" ]]
        eval_cmd "Necessary file does not exist:\n    $source_path/$file"

        cp "$source_path/$file" "$dest_path/$file"
        eval_cmd "Could not copy file:\n    $source_path/$file\nto\n    $dest_path/$file"

        echo "Copied '$file'"
    done
    echo ""
}
