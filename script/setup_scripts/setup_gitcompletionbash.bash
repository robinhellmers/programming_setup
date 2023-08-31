

########################
### Library sourcing ###
########################

library_sourcing()
{
    find_this_script_path

    local -r LIB_PATH="$this_script_path/lib"
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
### GIT COMPLETION SETUP ###
############################
setup_gitcompletionbash()
{
    # get_internet_file "$PATH_GITCOMPLETIONBASH" "$NAME_GITCOMPLETIONBASH" "$URL_GITCOMPLETIONBASH"
    # RETURN_GET_INTERNET_FILE=$?
    
    # case $RETURN_GET_INTERNET_FILE in 
    #     0)   # Success
    #         return_value='success'
    #         ;;
    #     255) # Already done
    #         return_value='already done'
    #         ;;
    #     *)   # Failure
    #         return_value='Could not get internet file git completion bash.'
    #         return -1;;
    # esac

    # # Make it executable
    # sudo chmod +x $PATH_GITCOMPLETIONBASH/$NAME_GITCOMPLETIONBASH
    # RETURN_CHMOD=$?

    # if [[ $RETURN_CHMOD != 0 ]]
    # then
    #     return_value='Chmod of git completion bash failure.'
    #     return -1
    # fi



    # Find if statement to know where to place content (above,in-between,below)
    debug_echo 100 "*****************************************************************************"
    debug_echo 100 "***** Time for finding if statement *****************************************"
    debug_echo 100 "*****************************************************************************"
    IF_STATEMENT='if [ "$color_prompt" = yes ]; then'
    exists_in_file "$PATH_BASHRC/$NAME_BASHRC" "$IF_STATEMENT" IF_STATEMENT
    debug_echo 100 "IF_STATEMENT_exists: $IF_STATEMENT_exists"
    debug_echo 100 "IF_STATEMENT_START: $IF_STATEMENT_START IF_STATEMENT_END: $IF_STATEMENT_END"
    if $IF_STATEMENT_exists
    then
        find_else_elif_fi_statement "$PATH_BASHRC/$NAME_BASHRC" "$IF_STATEMENT_START" if_statement 1
        if [[ "$?" != 0 ]]
        then
            debug_echo 100 "Problem in finding else/elif/fi statement."
            return_value='problem finding else/elif/fi statement'
            return -1
        fi

        debug_echo 100 -e "\nFound if statement at..."
        debug_echo 100 "if_statement_LNs: ${if_statement_LNs[*]}"
        debug_echo 100 -e "if_statement_type: ${if_statement_type[*]}\n"

        everything_already_done=true
        anything_success=false
        anything_failure=false
        #################################################################
        ############################ INPUT 1 ############################
        #################################################################

        # Variable expansion line
        BASHRC_INPUT1_1="source $PATH_GITCOMPLETIONBASH/$NAME_GITCOMPLETIONBASH"
        # Doesn't include any variable expansion
        define BASHRC_INPUT1_2 <<'EOF'
export PROMPT_DIRTRIM=3
export GIT_PS1_SHOWCOLORHINTS=true
export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export GIT_PS1_SHOWUPSTREAM="auto"
EOF
        # Concat the two above. OBS don't use \n for newline, seems good when doing diff
        # but doesn't work the same when doing the check in 'exists_in_file'
        BASHRC_INPUT1="${BASHRC_INPUT1_1}
${BASHRC_INPUT1_2}"

        IF_STATEMENT='if [ "$color_prompt" = yes ]; then'
        declare -a intervals=("${if_statement_LNs[@]}")
        declare -a allowed_intervals=('true' 'true' 'false' 'true')
        declare -a preferred_interval=('false' 'true' 'false' 'false')

        add_single_line_content "$PATH_BASHRC" "$NAME_BASHRC" BASHRC_INPUT1 "INBETWEEN" "END" \
                                "${#allowed_intervals[@]}" "${allowed_intervals[@]}" \
                                "${#preferred_interval[@]}" "${preferred_interval[@]}" \
                                "${#intervals[@]}" "${intervals[@]}"

        case "$return_value" in
            'already done')
                ;;
            'success')
                everything_already_done=false
                anything_success=true
                ;;
            *)
                everything_already_done=false
                anything_failure=true
                ;;
        esac

        #################################################################
        ############################ INPUT 2 ############################
        #################################################################

        # Multi-line needs to be handled as multi-line. Not go through iteration while loop
        define BASHRC_INPUT2 <<'EOF'
PS1_custom='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u\[\033[00m\]:\['\
'\033[01;34m\]\w\[\033[00m\]\$ '
EOF

        # Update if statement variables with new line numbers
        IF_STATEMENT='if [ "$color_prompt" = yes ]; then'
        exists_in_file "$PATH_BASHRC/$NAME_BASHRC" "$IF_STATEMENT" IF_STATEMENT
        find_else_elif_fi_statement "$PATH_BASHRC/$NAME_BASHRC" "$IF_STATEMENT_START" if_statement 1
        declare -a intervals=("${if_statement_LNs[@]}")
        declare -a allowed_intervals=(true false false false)
        declare -a preferred_interval=(true false false false)
        
        add_multiline_content "$PATH_BASHRC" "$NAME_BASHRC" BASHRC_INPUT2 "INBETWEEN" "END" "${#intervals[@]}" "${intervals[@]}" "${#allowed_intervals[@]}" "${allowed_intervals[@]}" "${#preferred_interval[@]}" "${preferred_interval[@]}"

        case "$return_value" in
            'already done')
                ;;
            'success')
                everything_already_done=false
                anything_success=true
                ;;
            *)
                everything_already_done=false
                anything_failure=true
                ;;
        esac
        #################################################################
        ############################ INPUT 3 ############################
        #################################################################

        define BASHRC_INPUT3 <<'EOF'
PS1_original='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m'\
'\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
EOF
        # Update if statement variables with new line numbers
        IF_STATEMENT='if [ "$color_prompt" = yes ]; then'
        exists_in_file "$PATH_BASHRC/$NAME_BASHRC" "$IF_STATEMENT" IF_STATEMENT
        find_else_elif_fi_statement "$PATH_BASHRC/$NAME_BASHRC" "$IF_STATEMENT_START" if_statement 1
        declare -a intervals=("${if_statement_LNs[@]}")
        declare -a allowed_intervals=(true false false false)
        declare -a preferred_interval=(true false false false)
        
        add_multiline_content "$PATH_BASHRC" "$NAME_BASHRC" BASHRC_INPUT3 "INBETWEEN" "END" "${#intervals[@]}" "${intervals[@]}" "${#allowed_intervals[@]}" "${allowed_intervals[@]}" "${#preferred_interval[@]}" "${preferred_interval[@]}"

        case "$return_value" in
            'already done')
                ;;
            'success')
                everything_already_done=false
                anything_success=true
                ;;
            *)
                everything_already_done=false
                anything_failure=true
                ;;
        esac

        #################################################################
        ############################ INPUT 4 ############################
        #################################################################

        # Update if statement variables with new line numbers
        IF_STATEMENT='if [ "$color_prompt" = yes ]; then'
        exists_in_file "$PATH_BASHRC/$NAME_BASHRC" "$IF_STATEMENT" IF_STATEMENT
        find_else_elif_fi_statement "$PATH_BASHRC/$NAME_BASHRC" "$IF_STATEMENT_START" if_statement 1
        declare -a intervals=("${if_statement_LNs[@]}")
        declare -a allowed_intervals=('false' 'true' 'false' 'false')
        declare -a preferred_interval=('false' 'true' 'false' 'false')
        
        BASHRC_INPUT4='PS1=$PS1_custom'
        add_single_line_content "$PATH_BASHRC" "$NAME_BASHRC" BASHRC_INPUT4 "INBETWEEN" "START" \
                                "${#allowed_intervals[@]}" "${allowed_intervals[@]}" \
                                "${#preferred_interval[@]}" "${preferred_interval[@]}" \
                                "${#intervals[@]}" "${intervals[@]}"

        case "$return_value" in
            'already done')
                ;;
            'success')
                everything_already_done=false
                anything_success=true
                ;;
            *)
                everything_already_done=false
                anything_failure=true
                ;;
        esac

        #################################################################
        ############################ INPUT 5 ############################
        #################################################################
        
        define BASHRC_INPUT5 <<'EOF'
PROMPT_COMMAND=$(sed -r 's|^(.+)(\\\$\s*)$|__git_ps1 "\1" "\2"|' <<< $PS1)
EOF
        if $anything_failure
        then
            return_value='failure'
            return 0
        elif $anything_success
        then
            return_value='success'
        elif $everything_already_done
        then
            return_value='already done'
        else
            return_value='unknown'


            return 0
        fi

        return 0
    fi
}
###################################
### END OF GIT COMPLETION SETUP ###
###################################
