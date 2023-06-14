
source lib/common.bash

CONFIG_LOCATION="$HOME/.config"
REPO_GITCONFIG_NAME="gitconfig"


GITCONFIG_DEST="$(realpath $CONFIG_LOCATION/$REPO_GITCONFIG_NAME)"

setup_git_config()
{
    if [[ -f "$CONFIG_LOCATION/$REPO_GITCONFIG_NAME" ]]
    then
        backup "$CONFIG_LOCATION/$REPO_GITCONFIG_NAME"
    fi

    set_gitconfig_key_value include.path "$GITCONFIG_DEST"

}