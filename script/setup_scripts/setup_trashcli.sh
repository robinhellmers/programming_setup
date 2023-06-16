#!/usr/bin/env bash

SETUP_SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")" # This script's path
LIB_PATH="$SETUP_SCRIPTS_PATH/lib"

source "$LIB_PATH/config.bash"
source "$LIB_PATH/base.bash"
source "$LIB_PATH/file.bash"

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
