#!/usr/bin/env bash

SETUP_SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")" # This script's path
LIB_PATH="$SETUP_SCRIPTS_PATH/lib"

source "$LIB_PATH/config.bash"
source "$LIB_PATH/common.bash"
source "$LIB_PATH/base.bash"
source "$LIB_PATH/file.bash"

############
### MAIN ###
############
main()
{
    handle_args "$@"

    init

    local bashrc_source_file="$REPO_FILES_SOURCE_REL_PATH/$REPO_BASHRC_FILE_NAME"
    local bashrc_destination_file="$tmp_workspace_dir/$BASHRC_FILE_NAME"


    # TODO: Create replace_sourcing_path()
    cp "$bashrc_source_file" "$bashrc_destination_file"
    export_files "$REPO_FILES_SOURCE_REL_PATH" \
                 "$tmp_workspace_dir" \
                 "${array_export_files[@]}"

    replace_files_sourcing_paths "$tmp_workspace_dir"

    if equal_files "$tmp_workspace_dir" \
                   "$tmp_workspace_dir" \
                   "${array_export_files[@]}"
    then

    fi

    backup "$HOME/$BASHRC_FILE_NAME"

    replace_bashrc
    # return_value_replace_bashrc

    # export_files "$REPO_FILES_SOURCE_REL_PATH" \
    #              "$FILES_DEST_PATH" \
    #              "${array_export_files[@]}"
    # return_value_export_files

    replace_files_sourcing_paths
    # return_value_replace_files_sourcing_paths

    if [[ "$return_value_replace_bashrc" == 'already done' ]] && \
       [[ "$return_value_replace_files_sourcing_paths" == 'already done' ]]
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
        _exit 1 'Found unsupported system OS.'
    fi

    mkdir -p "$FILES_DEST_PATH"
    eval_cmd "Could not create directory:\n    $FILES_DEST_PATH"

    tmp_workspace_dir="$(mktemp -d)"
    eval_cmd "Could not create directory:\n    $tmp_workspace_dir"
    echo "tmp_workspace_dir: $tmp_workspace_dir"
}
###################
### END OF INIT ###
###################

######################
### REPLACE BASHRC ###
######################
replace_bashrc()
{
    local to_replace_with="$REPO_FILES_SOURCE_REL_PATH/$REPO_BASHRC_FILE_NAME"
    local to_replace="$HOME/$BASHRC_FILE_NAME"

    if cmp --silent "$to_replace_with" "$to_replace"
    then
        return_value_replace_bashrc='already done'
        return 0
    fi
    echo -e "\nReplacing"
    echo -e "    $to_replace\n"
    cp "$to_replace_with" "$to_replace"
}
#############################
### END OF REPLACE BASHRC ###
#############################

####################################
### REPLACE FILES SOURCING PATHS ###
####################################
replace_files_sourcing_paths()
{
    local given_path="$1"
    local id
    local file
    local path

    [[ -n "$given_path" ]] && path="$given_path" || path="$FILES_DEST_PATH"
    file="$path/$REPO_BASH_PROMPT_NAME"
    id="git-prompt"

    if grep -qE "source .*# ID $id" "$file"
    then
        if grep -qE "source \"$FILES_DEST_PATH/$REPO_GIT_PROMPT_NAME\" # ID $id" "$file"
        then
            local replace_files_sourcing_paths_git_prompt='already done'
        else
            echo "Replacing source paths in:"
            echo "    $file"

            sed -i "s|\
source .*# ID $id|\
source \"$FILES_DEST_PATH/$REPO_GIT_PROMPT_NAME\" # ID $id|g" "$file"
        fi
    fi



    [[ -n "$given_path" ]] && path="$given_path" || path="$HOME"
    file="$path/$BASHRC_FILE_NAME"
    id="git-completion"

    if grep -qE "source .*# ID $id" "$file"
    then
        if grep -qE "source \"$FILES_DEST_PATH/$REPO_GIT_COMPLETION_NAME\" # ID $id" "$file"
        then
            local replace_files_sourcing_paths_git_completion='already done'
        else
            echo "Replacing source paths in:"
            echo "    $file"

            sed -i "s|\
source .*# ID $id|\
source \"$FILES_DEST_PATH/$REPO_GIT_COMPLETION_NAME\" # ID $id|g" "$file"
        fi
    fi



    [[ -n "$given_path" ]] && path="$given_path" || path="$HOME"
    file="$path/$BASHRC_FILE_NAME"
    id="bash-prompt"

    if grep -qE "source .*# ID $id" "$file"
    then
        if grep -qE "source \"$FILES_DEST_PATH/$REPO_BASH_PROMPT_NAME\" # ID $id" "$file"
        then
            local replace_files_sourcing_paths_bash_prompt='already done'
        else
            echo "Replacing source paths in:"
            echo "    $file"

            sed -i "s|\
source .*# ID $id|\
source \"$FILES_DEST_PATH/$REPO_BASH_PROMPT_NAME\" # ID $id|g" "$file"
        fi
    fi

    echo "replace_files_sourcing_paths_git_prompt: $replace_files_sourcing_paths_git_prompt"
    echo "replace_files_sourcing_paths_git_completion: $replace_files_sourcing_paths_git_completion"
    echo "replace_files_sourcing_paths_bash_prompt: $replace_files_sourcing_paths_bash_prompt"

    if [[ "$replace_files_sourcing_paths_git_prompt" == 'already done' ]] && \
       [[ "$replace_files_sourcing_paths_git_completion" == 'already done' ]] && \
       [[ "$replace_files_sourcing_paths_bash_prompt" == 'already done' ]]
    then
        return_value_replace_files_sourcing_paths='already done'
    fi
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