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
    find_this_script_path

    local -r LIB_PATH="$this_script_path/lib"

    source "$LIB_PATH/config.bash"
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

############################
### GIT DIFFTOOL VIMDIFF ###
############################
main()
{
    handle_args "$@"

    init

    cd $PATH_GITCONFIG
    RESULTS=$(git config --global --get diff.tool)
    if [[ "$RESULTS" != "vimdiff" ]]
    then # Not set to wished setting. Set it.
        git config --global diff.tool vimdiff

        RESULTS=$(git config --global --get diff.tool)
        if [[ "$RESULTS" != "vimdiff" ]]
        then # Could not set the setting
            _exit 255 'could not set the git setting'
        fi

        _exit 0 'success'
    else # Already set to the wished setting
        _exit 0 'already done'
    fi

    RESULTS=$(git config --global --get difftool.prompt)
    if [[ "$RESULTS" != "vimdiff" ]]
    then # Not set to wished setting. Set it.
        git config --global diff.tool vimdiff

        RESULTS=$(git config --global difftool.prompt false)
        if [[ "$RESULTS" != "vimdiff" ]]
        then # Could no set the setting
            _exit 255 'could not set the git setting'
        fi

        _exit 0 'success'
    else # Already set to the wished setting
        _exit 0 'already done'
    fi
    
    cd $MAIN_SCRIPT_PATH
}
###############################
### END OF DIFFTOOL VIMDIFF ###
###############################

############
### INIT ###
############
init()
{
    PATH_GITCONFIG=~
}
###################
### END OF INIT ###
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

#
### Call main
#
main "$@"
#
###
#