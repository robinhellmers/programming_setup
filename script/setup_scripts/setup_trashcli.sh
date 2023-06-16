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

    # See if package isn't installed
    if ! (dpkg -l | grep -q trash-cli)
    then
        sudo apt install trash-cli
        
        if [[ $? != 0 ]]
            then
                debug_echo 100 -e "Failed installing 'trash-cli' package.\n"
                return_value='failed installing trash-cli package'
                exit 255
            fi
    fi

    TRASHCLI_CONTENT="alias rm=trash"

    add_content_to_file "$PATH_BASHRC" "$NAME_BASHRC" "$TRASHCLI_CONTENT"; return_code=$?
    echo "$return_value"
    exit $return_code
}
########################
### END OF TRASH-CLI ###
########################

#
### Call Main
#
main "$@"
#
###
#
