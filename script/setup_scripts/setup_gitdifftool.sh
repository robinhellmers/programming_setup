
############################
### GIT DIFFTOOL VIMDIFF ###
############################
main()
{

    init

    cd $PATH_GITCONFIG
    RESULTS=$(git config --global --get diff.tool)
    if [[ "$RESULTS" != "vimdiff" ]]
    then # Not set to wished setting. Set it.
        git config --global diff.tool vimdiff

        RESULTS=$(git config --global --get diff.tool)
        if [[ "$RESULTS" != "vimdiff" ]]
        then # Could not set the setting
            return_value='could not set the git setting'
            echo "$return_value"
            exit 255
        fi

        return_value='success'
        echo "$return_value"
        exit 0
    else # Already set to the wished setting
        return_value='already done'
        echo "$return_value"
        exit 0
    fi

    RESULTS=$(git config --global --get difftool.prompt)
    if [[ "$RESULTS" != "vimdiff" ]]
    then # Not set to wished setting. Set it.
        git config --global diff.tool vimdiff

        RESULTS=$(git config --global difftool.prompt false)
        if [[ "$RESULTS" != "vimdiff" ]]
        then # Could no set the setting
            return_value='could not set the git setting'
            echo "$return_value"
            exit 255
        fi

        return_value='success'
        echo "$return_value"
        exit 0
    else # Already set to the wished setting
        return_value='already done'
        echo "$return_value"
        exit 0
    fi
    
    cd $SCRIPT_PATH
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

#
### Call main
#
main "$@"
#
###
#