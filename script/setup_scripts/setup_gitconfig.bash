
SETUP_SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")" # This script's path
LIB_PATH="$SETUP_SCRIPTS_PATH/lib"

source "$LIB_PATH/common.bash"

CONFIG_DEST_PATH="$HOME/.config"
REPO_GITCONFIG_NAME="gitconfig"
REPO_GITCONFIG_SOURCE_REL_PATH="setup_gitconfig"

REPO_GITCONFIG_NAME="gitconfig"
REPO_HIGHLIGHT_AWK_NAME="highlight-commit.awk"
REPO_HIGHLIGHT_SH_NAME="highlight-commit.sh"
REPO_OPTIONAL_PARSER_NAME="optionalParameterParser.sh"

array_export_gitconfig_files=()
array_export_gitconfig_files+=("$REPO_HIGHLIGHT_AWK_NAME")
array_export_gitconfig_files+=("$REPO_HIGHLIGHT_SH_NAME")
array_export_gitconfig_files+=("$REPO_OPTIONAL_PARSER_NAME")

GITCONFIG_DEST="$(realpath $CONFIG_DEST_PATH/$REPO_GITCONFIG_NAME)"

setup_git_config()
{
    [[ -f "$CONFIG_DEST_PATH/$REPO_GITCONFIG_NAME" ]] && \
        backup "$CONFIG_DEST_PATH/$REPO_GITCONFIG_NAME"

    export_files "$REPO_GITCONFIG_SOURCE_REL_PATH" \
                 "$CONFIG_DEST_PATH" \
                 "${array_export_gitconfig_files[@]}"

    set_gitconfig_key_value include.path "$GITCONFIG_DEST"

}