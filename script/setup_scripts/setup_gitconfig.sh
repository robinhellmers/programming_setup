
SETUP_SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")" # This script's path
LIB_PATH="$SETUP_SCRIPTS_PATH/lib"

source "$LIB_PATH/common.bash"
source "$LIB_PATH/config.bash"
source "$LIB_PATH/base.bash"
source "$LIB_PATH/file.bash"

############
### MAIN ###
############
main()
{
    handle_args "$@"

    init

    [[ -f "$CONFIG_DEST_PATH/$REPO_GITCONFIG_NAME" ]] && \
        backup "$CONFIG_DEST_PATH/$REPO_GITCONFIG_NAME"

    export_files "$REPO_GITCONFIG_SOURCE_PATH" \
                 "$CONFIG_DEST_PATH" \
                 "${array_export_gitconfig_files[@]}"
    # return_value_export_files

    set_gitconfig_key_value include.path "$GITCONFIG_DEST"
    # return_value_set_gitconfig_key_value

    if [[ "$return_value_export_files" == 'already done' ]] && \
       [[ "$return_value_set_gitconfig_key_value" == 'already done' ]]
    then
        _exit 0 'already done'
    fi

    _exit 0 'success'
}
###################
### END OF MAIN ###
###################

###################
### HANDLE ARGS ###
###################
handle_args()
{
    _handle_args "$@"
    script_return_file="$script_return_file_arg"
}
##########################
### END OF HANDLE ARGS ###
##########################

############
### INIT ###
############
init()
{
    CONFIG_DEST_PATH="$HOME/.config"
    REPO_GITCONFIG_SOURCE_PATH="$SETUP_SCRIPTS_PATH/setup_gitconfig"


    REPO_GITCONFIG_NAME="gitconfig"
    REPO_HIGHLIGHT_AWK_NAME="highlight-commit.awk"
    REPO_HIGHLIGHT_SH_NAME="highlight-commit.sh"
    REPO_OPTIONAL_PARSER_NAME="optionalParameterParser.sh"

    array_export_gitconfig_files=()
    array_export_gitconfig_files+=("$REPO_HIGHLIGHT_AWK_NAME")
    array_export_gitconfig_files+=("$REPO_HIGHLIGHT_SH_NAME")
    array_export_gitconfig_files+=("$REPO_OPTIONAL_PARSER_NAME")
    array_export_gitconfig_files+=("$REPO_GITCONFIG_NAME")

    GITCONFIG_DEST="$(realpath $CONFIG_DEST_PATH/$REPO_GITCONFIG_NAME)"
}
###################
### END OF INIT ###
###################

#
### Call main
#
main "$@"
#
###
#