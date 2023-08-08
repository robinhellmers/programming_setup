#!/usr/bin/env bash

sourceable_script='false'

if [[ "$sourceable_script" != 'true' && ! "${BASH_SOURCE[0]}" -ef "$0" ]]
then
    echo "Do not source this script! Execute it with bash instead."
    return 1
fi
unset sourceable_script

########################
### Library sourcing ###
########################

library_sourcing()
{
    local -r THIS_SCRIPT_PATH="$(find_script_path)"

    # Store $THIS_SCRIPT_PATH as unique or local variables
    local -r LIB_PATH="$THIS_SCRIPT_PATH/lib"

    source "$LIB_PATH/common.bash"
    source "$LIB_PATH/config.bash"
    source "$LIB_PATH/base.bash"
    source "$LIB_PATH/file.bash"
}

# Only store output in multi-file unique readonly global variables or
# local variables to avoid variable values being overwritten in e.g.
# sourced library files.
# Recommended to always call the function when to use it
find_script_path()
{
    local this_script_path
    local bash_source="${BASH_SOURCE[0]}"

    while [ -L "$bash_source" ]; do # resolve $bash_source until the file is no longer a symlink
        this_script_path=$( cd -P "$( dirname "$bash_source" )" >/dev/null 2>&1 && pwd )
        bash_source=$(readlink "$bash_source")
        # If $bash_source was a relative symlink, we need to resolve it relative
        # to the path where the symlink file was located
        [[ $bash_source != /* ]] && bash_source=$this_script_path/$bash_source 
    done
    this_script_path=$( cd -P "$( dirname "$source" )" >/dev/null 2>&1 && pwd )

    echo "$this_script_path"
}

library_sourcing

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