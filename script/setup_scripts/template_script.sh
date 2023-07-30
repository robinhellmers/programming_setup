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

    # Source files here using $LIB_PATH
    source "$LIB_PATH/base.bash"
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
    :
}
###################
### END OF INIT ###
###################


#################
### Call main ###
#################
main "$@"
#################
