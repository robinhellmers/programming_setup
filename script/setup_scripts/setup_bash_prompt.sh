#!/usr/bin/env bash

if ! [[ "${BASH_SOURCE[0]}" -ef "$0" ]]
then
    echo "Do not source this script! Execute it with bash instead."
    return 1
fi

########################
### Library sourcing ###
########################

library_sourcing()
{
    find_this_script_path

    local -r LIB_PATH="$this_script_path/lib"
    SETUP_SCRIPTS_PATH="${SETUP_SCRIPTS_PATH:-"$this_script_path"}"

    source "$LIB_PATH/config.bash"
    source "$LIB_PATH/common.bash"
    source "$LIB_PATH/base.bash"
    source "$LIB_PATH/file.bash"
    source "$LIB_PATH/array.bash"
}

find_this_script_path()
{
    local source=${BASH_SOURCE[0]}
    while [ -L "$source" ]; do # resolve $source until the file is no longer a symlink
        this_script_path=$( cd -P "$( dirname "$source" )" >/dev/null 2>&1 && pwd )
        source=$(readlink "$source")
        [[ $source != /* ]] && source=$this_script_path/$source # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    this_script_path=$( cd -P "$( dirname "$source" )" >/dev/null 2>&1 && pwd )
}

library_sourcing

############
### MAIN ###
############
main()
{
    handle_args "$@"

    init

    #
    ### Check if files already exist
    #
    local bashrc_source_file="$REPO_FILES_SOURCE_REL_PATH/$REPO_BASHRC_FILE_NAME"
    local bashrc_destination_file="$tmp_workspace_dir/$BASHRC_FILE_NAME"
    local file id to_source reference_file destination_file

    prepare_files_tmp_dir

    if files_equal_multiple "${#array_equal_files_tmp_source_path[@]}" \
                              "${array_equal_files_tmp_source_path[@]}" \
                              "${#array_export_destination_files_name[@]}" \
                              "${array_export_destination_files_name[@]}" \
                              "${#array_export_destination_files_path[@]}" \
                              "${array_export_destination_files_path[@]}" \
                              "${#array_export_destination_files_name[@]}" \
                              "${array_export_destination_files_name[@]}"
    then
        _exit 0 'already done'
    fi

    files_to_replace_source_name=("${files_differing_first_arr[@]}")
    files_to_replace_destination_name=("${files_differing_second_arr[@]}")

    get_indices_by_array_values "${#files_to_replace_destination_name[@]}" \
                                "${files_to_replace_destination_name[@]}" \
                                "${#array_export_destination_files_name[@]}" \
                                "${array_export_destination_files_name[@]}"
    # CREATES: indices_found

    get_values_by_array_indices "${#indices_found[@]}" \
                                "${indices_found[@]}" \
                                "${#array_export_destination_files_path[@]}" \
                                "${array_export_destination_files_path[@]}"
    # CREATES: values_found
    files_to_replace_destination_path=("${values_found[@]}")

    backup_multiple "$backup_destination_path" \
                    "${#files_to_replace_destination_path[@]}" \
                    "${files_to_replace_destination_path[@]}" \
                    "${#files_to_replace_destination_name[@]}" \
                    "${files_to_replace_destination_name[@]}"
    
    export_files_new "${#array_equal_files_tmp_source_path[@]}" \
                        "${array_equal_files_tmp_source_path[@]}" \
                        "${#array_export_destination_files_name[@]}" \
                        "${array_export_destination_files_name[@]}" \
                        "${#array_export_destination_files_path[@]}" \
                        "${array_export_destination_files_path[@]}" \
                        "${#array_export_destination_files_name[@]}" \
                        "${array_export_destination_files_name[@]}"
    _exit $? 'success'
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

    readonly FILES_DEST_PATH="$LOCAL_BIN_PATH/bash_prompt"

    readonly REPO_FILES_SOURCE_REL_PATH="$SETUP_SCRIPTS_PATH/setup_bash_prompt"
    readonly REPO_GIT_PROMPT_NAME="git-prompt.sh"
    readonly REPO_GIT_COMPLETION_NAME="git-completion.bash"
    readonly REPO_BASH_PROMPT_NAME="bash-prompt.sh"
    readonly REPO_BASHRC_FILE_NAME="bashrc.bash"

    backup_destination_path="$HOME/.backup/setup_bash_prompt"
    
    array_export_source_files=()
    array_export_destination_files=()

    array_export_source_files+=("${REPO_FILES_SOURCE_REL_PATH}/${REPO_GIT_PROMPT_NAME}")
    array_export_destination_files+=("${FILES_DEST_PATH}/${REPO_GIT_PROMPT_NAME}")

    array_export_source_files+=("${REPO_FILES_SOURCE_REL_PATH}/${REPO_GIT_COMPLETION_NAME}")
    array_export_destination_files+=("${FILES_DEST_PATH}/${REPO_GIT_COMPLETION_NAME}")

    array_export_source_files+=("${REPO_FILES_SOURCE_REL_PATH}/${REPO_BASH_PROMPT_NAME}")
    array_export_destination_files+=("${FILES_DEST_PATH}/${REPO_BASH_PROMPT_NAME}")

    array_export_source_files+=("${REPO_FILES_SOURCE_REL_PATH}/${REPO_BASHRC_FILE_NAME}")
    array_export_destination_files+=("${HOME}/${BASHRC_FILE_NAME}")

    
    array_export_source_files_path=()
    array_export_source_files_name=()
    array_export_destination_files_path=()
    array_export_destination_files_name=()
    
    for i in "${!array_export_source_files[@]}"
    do
        array_export_source_files_path+=("$(dirname ${array_export_source_files[i]})")
        array_export_source_files_name+=("$(basename ${array_export_source_files[i]})")
        array_export_destination_files_path+=("$(dirname ${array_export_destination_files[i]})")
        array_export_destination_files_name+=("$(basename ${array_export_destination_files[i]})")
    done
    

    tmp_workspace_dir="$(mktemp -d)"
    eval_cmd "Could not create directory:\n    $tmp_workspace_dir"

    echo -e "Temporary workspace directory: $tmp_workspace_dir\n"

    local len="${#array_export_source_files_name[@]}"

    create_initialized_array "$len" "$tmp_workspace_dir"
    array_equal_files_tmp_source_path=("${initialized_array[@]}")
    create_initialized_array "$len" "$backup_destination_path"
    array_backup_multiple_destination_path=("${initialized_array[@]}")

    mkdir -p "$FILES_DEST_PATH"
    eval_cmd "Could not create directory:\n    $FILES_DEST_PATH"
}
###################
### END OF INIT ###
###################


#############################
### PREPARE FILES TMP DIR ###
#############################
prepare_files_tmp_dir()
{
    prepend_stdout "TMP WORKDIR: "

    export_files_new "${#array_export_source_files_path[@]}" \
                     "${array_export_source_files_path[@]}" \
                     "${#array_export_source_files_name[@]}" \
                     "${array_export_source_files_name[@]}" \
                     "${#array_equal_files_tmp_source_path[@]}" \
                     "${array_equal_files_tmp_source_path[@]}" \
                     "${#array_export_destination_files_name[@]}" \
                     "${array_export_destination_files_name[@]}"

    echo ""
    file="$tmp_workspace_dir/$REPO_BASH_PROMPT_NAME"
    id="git-prompt"
    to_source="$FILES_DEST_PATH/$REPO_GIT_PROMPT_NAME"
    replace_sourcing_path "$file" "$id" "$to_source"

    file="$tmp_workspace_dir/$BASHRC_FILE_NAME"
    id="git-completion"
    to_source="$FILES_DEST_PATH/$REPO_GIT_COMPLETION_NAME"
    replace_sourcing_path "$file" "$id" "$to_source"

    file="$tmp_workspace_dir/$BASHRC_FILE_NAME"
    id="bash-prompt"
    to_source="$FILES_DEST_PATH/$REPO_BASH_PROMPT_NAME"
    replace_sourcing_path "$file" "$id" "$to_source"

 
    reset_prepended_stdout
}
#################################
### END PREPARE FILES TMP DIR ###
#################################


###############################
### REPLACE DIFFERING FILES ###
###############################
replace_differing_files()
{
    mkdir -p "$backup_destination_path"

    local file_source_name file_destination_name
    local file_source file_destination
    echo -e "\nStart backup and replacement of differing files..."
    # Backup and replace files differing from expected
    for i in "${!files_to_replace_destination_name[@]}"
    do
        get_index_array_value "${files_to_replace_destination_name[i]}" \
                              "${array_export_destination_files_name[@]}"
        file_source_name="${array_export_destination_files_name[i]}"
        file_destination_name="${array_export_destination_files_name[i]}"

        file_source="${array_equal_files_tmp_source_path[index_found]}/$file_source_name"
        file_destination="${array_export_destination_files_path[index_found]}/$file_destination_name"
        backup "$file_destination" "$backup_destination_path"

        cp "$file_source" "$file_destination"

        echo -e "\nCopied:"
        echo "    $file_source"
        echo "to"
        echo "    $file_destination"
    done
    echo "Backups and replacements done. See files above."
}
######################################
### END OF REPLACE DIFFERING FILES ###
######################################

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

replace_sourcing_path()
{
    local file id to_source

    file="$1"
    id="$2"
    to_source="$3"

    local general_source_line="source .*# ID $id"
    local specific_source_line="source \"$to_source\" # ID $id"

    if grep -qE "$general_source_line" "$file"
    then
        if grep -qE "$specific_source_line" "$file"
        then
            local result_value_replace_sourcing_path='already done'
        else
            echo "Replacing sourcing path in:"
            echo "    $file"

            sed -i "s|\
$general_source_line|\
$specific_source_line|g" "$file"
        fi
    fi
}

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