#!/usr/bin/env bash

########################
### Library sourcing ###
########################

library_sourcing()
{
    find_this_script_path

    local -r LIB_PATH="$this_script_path/lib"

    source "$LIB_PATH/config.bash"
    source "$LIB_PATH/base.bash"
    source "$LIB_PATH/file.bash"
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

#################
### TRASH-CLI ###
#################
main()
{
    handle_args "$@"

    # See if package isn't installed
    if ! (dpkg -l | grep -q trash-cli)
    then
        sudo apt install trash-cli
        
        if [[ $? != 0 ]]
            then
                debug_echo 100 -e "Failed installing 'trash-cli' package.\n"
                _exit 255 'failed installing trash-cli package'
            fi
    fi

    TRASHCLI_CONTENT="alias rm=trash"

    add_content_to_file "$PATH_BASHRC" "$NAME_BASHRC" "$TRASHCLI_CONTENT"
    _exit $? "$return_value"
}
########################
### END OF TRASH-CLI ###
########################

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

#
### Call Main
#
main "$@"
#
###
#
