
CONFIG_LOCATION="$HOME/.config"
REPO_GITCONFIG_NAME="gitconfig"


GITCONFIG_DEST="$(realpath $CONFIG_LOCATION/$REPO_GITCONFIG_NAME)"

setup_git_config()
{
    if [[ -f "$CONFIG_LOCATION/$REPO_GITCONFIG_NAME" ]]
    then
        backup "$CONFIG_LOCATION/$REPO_GITCONFIG_NAME"
    fi

    local extra_gitconfig_path=$(git config --global --get include.path)

    if [[ -z "$extra_gitconfig_path" ]]
    then # Not set; set it
        git config --global include.path "$GITCONFIG_DEST"

        extra_gitconfig_path=$(git config --global --get include.path)

        if [[ "$extra_gitconfig_path" != "$GITCONFIG_DEST" ]]
        then
            return_value='could not set the git setting'
            return 255
        fi

        return_value='success'
        return 0
    else
        # Already set
        if [[ "$extra_gitconfig_path" != "$CONFIG_LOCATION/$REPO_GITCONFIG_NAME" ]]
        then # Already set to the wished setting
            
        else

        fi
    fi


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