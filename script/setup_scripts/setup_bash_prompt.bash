#!/usr/bin/env bash

SETUP_SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")" # This script's path
LIB_PATH="$SETUP_SCRIPTS_PATH/lib"

source "$LIB_PATH/config.bash"
source "$LIB_PATH/common.bash"
source "$LIB_PATH/base.bash"

############
### MAIN ###
############
main()
{
    handle_args "$@"

    init

    backup "$HOME/$BASHRC_FILE_NAME"

    replace_bashrc

    export_files "$REPO_FILES_SOURCE_REL_PATH" \
                 "$FILES_DEST_PATH" \
                 "${array_export_files[@]}"

    replace_files_sourcing_paths

    return_value='success'
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
}
##########################
### END OF HANDLE ARGS ###
##########################

############
### INIT ###
############
init()
{

    readonly FILES_DEST_PATH="$LOCAL_BIN_PATH/bash_prompt"

    readonly REPO_FILES_SOURCE_REL_PATH="$SETUP_SCRIPTS_PATH/setup_bash_prompt"
    readonly REPO_GIT_PROMPT_NAME="git-prompt.sh"
    readonly REPO_GIT_COMPLETION_NAME="git-completion.bash"
    readonly REPO_BASH_PROMPT_NAME="bash-prompt.sh"
    readonly REPO_BASHRC_FILE_NAME="bashrc.bash"

    array_export_files=()
    array_export_files+=("$REPO_GIT_COMPLETION_NAME")
    array_export_files+=("$REPO_GIT_PROMPT_NAME")
    array_export_files+=("$REPO_BASH_PROMPT_NAME")

    readonly MAX_BACKUPS=1000

    os_info="$(grep PRETTY_NAME /etc/os-release | awk -F= '{ print $2 }')"
    if grep -qi 'Ubuntu' <<< "$os_info"
    then
        echo -e "Found Ubuntu system.\n"
        readonly BASHRC_FILE_NAME=".bashrc"
    else
        echo "Found unsupported system OS."
        echo "Exiting."
        exit 1
    fi

    mkdir -p "$FILES_DEST_PATH"
    eval_cmd "Could not create directory:\n    $FILES_DEST_PATH"
}
###################
### END OF INIT ###
###################

######################
### REPLACE BASHRC ###
######################
replace_bashrc()
{
    echo -e "\nReplacing"
    echo -e "    $HOME/$BASHRC_FILE_NAME\n"
    cp "$REPO_FILES_SOURCE_REL_PATH/$REPO_BASHRC_FILE_NAME" "$HOME/$BASHRC_FILE_NAME"
}
#############################
### END OF REPLACE BASHRC ###
#############################

####################################
### REPLACE FILES SOURCING PATHS ###
####################################
replace_files_sourcing_paths()
{
    local id
    local file

    file="$FILES_DEST_PATH/$REPO_BASH_PROMPT_NAME"
    echo "Replacing source paths in:"
    echo "    $file"

    id="git-prompt"

    sed -i "s|\
source .*# ID $id|\
source \"$FILES_DEST_PATH/$REPO_GIT_PROMPT_NAME\" # ID $id|g" "$file"

    file="$HOME/$BASHRC_FILE_NAME"

    echo "Replacing source paths in:"
    echo "    $file"

    id="git-completion"

    sed -i "s|\
source .*# ID $id|\
source \"$FILES_DEST_PATH/$REPO_GIT_COMPLETION_NAME\" # ID $id|g" "$file"

    id="bash-prompt"

    sed -i "s|\
source .*# ID $id|\
source \"$FILES_DEST_PATH/$REPO_BASH_PROMPT_NAME\" # ID $id|g" "$file"
}
###########################################
### END OF REPLACE FILES SOURCING PATHS ###
###########################################

#
### Call main
#
main "$@"
#
###
#