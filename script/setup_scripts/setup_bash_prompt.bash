#!/usr/bin/env bash

readonly FILES_DEST_PATH="$HOME/.local/bin/bash_prompt"

readonly REPO_FILES_SOURCE_REL_PATH="$SETUP_SCRIPTS_PATH/setup_bash_prompt"
readonly REPO_GIT_PROMPT_NAME="git-prompt.sh"
readonly REPO_GIT_COMPLETION_NAME="git-completion.bash"
readonly REPO_BASH_PROMPT_NAME="bash-prompt.sh"
readonly REPO_BASHRC_FILE_NAME="bashrc.bash"

readonly MAX_BACKUPS=1000

setup_bash_prompt()
{
    init

    backup "$HOME/$BASHRC_FILE_NAME"

    replace_bashrc

    export_files

    replace_files_sourcing_paths

    return_value='success'
}

init()
{
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

    array_files=()
    array_files+=("$REPO_GIT_COMPLETION_NAME")
    array_files+=("$REPO_GIT_PROMPT_NAME")
    array_files+=("$REPO_BASH_PROMPT_NAME")

    mkdir -p "$FILES_DEST_PATH"
    eval_cmd "Could not create directory:\n    $FILES_DEST_PATH"
}

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

replace_bashrc()
{
    echo -e "\nReplacing"
    echo -e "    $HOME/$BASHRC_FILE_NAME\n"
    cp "$REPO_FILES_SOURCE_REL_PATH/$REPO_BASHRC_FILE_NAME" "$HOME/$BASHRC_FILE_NAME"
}

export_files()
{
    echo "Copying files to '$FILES_DEST_PATH/'..."
    for file in "${array_files[@]}"
    do
        [[ -f "$REPO_FILES_SOURCE_REL_PATH/$file" ]]
        eval_cmd "Necessary file does not exist:\n    $REPO_FILES_SOURCE_REL_PATH/$file"

        cp "$REPO_FILES_SOURCE_REL_PATH/$file" "$FILES_DEST_PATH/$file"
        eval_cmd "Could not copy file:\n    $file\nto $FILES_DEST_PATH/$file"

        echo "Copied '$file'"
    done
    echo ""
}

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
