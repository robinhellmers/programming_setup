
SETUP_SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")" # This script's path
LIB_PATH="$SETUP_SCRIPTS_PATH/lib"

source "$LIB_PATH/config.bash"
source "$LIB_PATH/base.bash"

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