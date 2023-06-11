#!/bin/bash

# Error handling to get line number of error
# https://unix.stackexchange.com/questions/462156/how-do-i-find-the-line-number-in-bash-when-an-error-occured
# set -eE -o functrace
# failure() {
#   local lineno=$2
#   local fn=$3
#   local exitstatus=$4
#   local msg=$5
#   local lineno_fns=${1% 0}
#   if [[ "$lineno_fns" != "0" ]] ; then
#     lineno="${lineno} ${lineno_fns}"
#   fi
#   echo "${BASH_SOURCE[1]}:${fn}[${lineno}] Failed with status ${exitstatus}: $msg"
# }
# trap 'failure "${BASH_LINENO[*]}" "$LINENO" "${FUNCNAME[*]:-script}" "$?" "$BASH_COMMAND"' ERR

PATH_SCRIPT="$(dirname "$(readlink -f "$0")")"
LIB_PATH="$PATH_SCRIPT/lib"
################
### SETTINGS ###
################

# 2 entries per function
# 1st entry - Suffix of function. Function name should then follow the
#             naming "setup_<suffix>"
# 2nd entry - Description of function.
declare -a arr_setups=(vimdiff "vimdiff"
                       gitdifftool "vimdiff as git difftool"
                       trashcli "trash-cli and alias rm"
                       gitcompletionbash "git completion bash"
                       )

PATH_VIMCOLORSCHEME=~/.vim/colors
NAME_VIMCOLORSCHEME=mycolorscheme.vim

PATH_VIMRC=~
PATH_GITCONFIG=~
PATH_BASHRC=~
NAME_BASHRC=.bashrc

URL_GITCOMPLETIONBASH="https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash"
PATH_GITCOMPLETIONBASH=~
NAME_GITCOMPLETIONBASH=.git-completion.bash

DEBUG_LEVEL=1
#######################
### END OF SETTINGS ###
#######################

main()
{
    debug_echo 0 -e "\nLocation of script:"
    debug_echo 0 -e "$PATH_SCRIPT\n"

    initial_questions

    # Go through every setup, calling their corresponding function if to be done
    TOTAL_RESULTS=true
    for ind_arr_setups in "${!arr_setups[@]}"
    do 
        if [[ $(( ind_arr_setups % 2 )) == 0 ]]
        then
            # SETUP_INDIVIDUAL is used to call the magic variable through double
            # evaluation with ${!SETUP_INDIVIDUAL}
            SETUP_INDIVIDUAL=SETUP_${arr_setups[$ind_arr_setups]^^}
            if $SETUP_EVERYTHING || ${!SETUP_INDIVIDUAL}
            then

                debug_echo 1 -e "\n\n\n\n"
                debug_echo 1 -e "${ORANGE_COLOR}\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\${END_COLOR}"
                debug_echo 1 -e "${ORANGE_COLOR}\\\\\\ Start setup of \"${arr_setups[(($ind_arr_setups + 1))]}\"${END_COLOR}"
                debug_echo 1 -e "${ORANGE_COLOR}\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\${END_COLOR}"
                # Function call
                setup_${arr_setups[$ind_arr_setups]}

                case $return_value in 
                    'success')   # Success
                        END_RESULTS+="[✔️] ";;
                    'already done') # Already done
                        END_RESULTS+="[🔷] ";;
                    *)   # Failure
                        END_RESULTS+="[❌] ";
                        TOTAL_RESULTS=false;;
                esac
                debug_echo 1 -e "${ORANGE_COLOR}//////////////////////////////////////////////////////////////////////////////////////////////////${END_COLOR}"
                debug_echo 1 -e "${ORANGE_COLOR}/// End setup of \"${arr_setups[(($ind_arr_setups + 1))]}\"${END_COLOR}"
                debug_echo 1 -e "${ORANGE_COLOR}//////////////////////////////////////////////////////////////////////////////////////////////////${END_COLOR}"
            else
                # Setup not to be done
                END_RESULTS+="[🟠] "
            fi

            END_RESULTS+="${arr_setups[(($ind_arr_setups + 1))]}\n"
        fi
    done

    # Print end results
    echo -e "\n\n${DEFAULT_UNDERLINE_COLOR}Results:${END_COLOR}"
    echo -e " 🟠 = Not to be done"
    echo -e " ✔️ = Success"
    echo -e " ❌ = Failure"
    echo -e " 🔷 = Already setup\n"
    echo -e "$END_RESULTS\n"
    echo -e "****************************************"
    TOTAL_RESULTS_PRINT="Total results: "
    if $TOTAL_RESULTS
    then
        TOTAL_RESULTS_PRINT+="✔️ - SUCCESS"
    else
        TOTAL_RESULTS_PRINT+="❌ - FAILURE"
    fi
    echo -e "$TOTAL_RESULTS_PRINT"
    echo -e "****************************************\n"

}

NL='
'
DEFAULT_BOLD_COLOR='\033[1;39m'
DEFAULT_UNDERLINE_COLOR='\033[4;39m'
RED_COLOR='\033[0;31m'
GREEN_COLOR='\033[0;32m'
ORANGE_COLOR='\033[0;33m'
MAGENTA_COLOR='\033[0;35m'
END_COLOR='\033[0m'

source "$LIB_PATH/base.bash"
source "$LIB_PATH/array.bash"
source "$LIB_PATH/file.bash"
source "$LIB_PATH/if_statement.bash"
source "$LIB_PATH/insert.bash"


#############################
### YESNO QUESTION HELPER ###
#############################
# Input: 2 arguments
# 1 - Variable name
# 2 - Description for question and results
# 
yesno_question()
{

    read -p "Setup $2? [y/n]: " -n 1 -r

    case ${REPLY,,} in
        y|yes)
            declare -g SETUP_${1^^}=true
            INIT_RESULTS+="[  ] ";;
        *)
            declare -g SETUP_${1^^}=false
            INIT_RESULTS+="[🟠] ";;
    esac
    INIT_RESULTS+="$2\n"
}
####################################
### END OF YESNO QUESTION HELPER ###
####################################

#########################
### INITIAL QUESTIONS ###
#########################
initial_questions()
{
    # List what this script will setup
    echo "This script have the options to setup:"
    for i in "${!arr_setups[@]}"
    do 
        if [[ $(( i % 2 )) != 0 ]]
        then
            echo "[  ] ${arr_setups[$i]}"
        fi
    done
    echo ""

    # Ask about setting up everything
    read -p "Setup everything given above? [y/n]: " -n 1 -r 
    echo -e "\n"
    case ${REPLY,,} in
        y|yes)
            SETUP_EVERYTHING=true;;
        *)
            SETUP_EVERYTHING=false;;
    esac

    if $SETUP_EVERYTHING; then return 0; fi


    # Ask about individual setups
    ASK_INDIVIDUAL_SETUPS=true
    while $ASK_INDIVIDUAL_SETUPS
    do
        echo -e "Choose which individual setups to do:"
        for i in "${!arr_setups[@]}"
        do 
            if [[ $(( i % 2 )) == 0 ]]
            then
                yesno_question "${arr_setups[$i]}" "${arr_setups[(($i + 1))]}"
                echo ""
            fi
        done

        # Ask if happy with choices and to continue
        echo -e "\nSetups to be done:"
        echo -e " 🟠 = Not to be done"
        echo -e "$INIT_RESULTS"
        read -p "Start the setup with the choices above? [y/n/q]: " -n 1 -r
        echo -e "\n"
        case ${REPLY,,} in
            y|yes)
                ASK_INDIVIDUAL_SETUPS=false;;
            q|quit|exit)
                echo "Exiting script."; exit;;
            *)
                echo -e "Doesn't seem like you were happy with your choices.\n";
                INIT_RESULTS="";;
        esac
    done
}
################################
### END OF INITIAL QUESTIONS ###
################################

####################
### VIM COLORING ###
####################
setup_vimdiff() {
    
    create_colorscheme
    local return_value_create_colorscheme="$return_value"

    create_vimrc
    local return_value_create_vim_rc="$return_value"

    if [[ "$return_value_create_colorscheme" == 'already done' ]] && \
       [[ "$return_value_create_vim_rc" == 'already done' ]]
    then
        return_value='already done'
        return 0
    else
        return_value='success'
        return 0
    fi
    
}
###########################
### END OF VIM COLORING ###
###########################

##########################
### CREATING COLORSCHEME ###
##########################
create_colorscheme()
{
    define VIMCOLORSCHEME << 'EOF'
highlight DiffAdd    cterm=bold ctermfg=15 ctermbg=22 gui=none guifg=bg guibg=Red
highlight DiffDelete cterm=bold ctermfg=15 ctermbg=88 gui=none guifg=bg guibg=Red
highlight DiffChange cterm=bold ctermfg=15 ctermbg=17 gui=none guifg=bg guibg=Red
highlight DiffText   cterm=bold ctermfg=15 ctermbg=130 gui=none guifg=bg guibg=Red
EOF

    add_content_to_file "$PATH_VIMCOLORSCHEME" "$NAME_VIMCOLORSCHEME" "$VIMCOLORSCHEME"
    
}
###################################
### END OF CREATING COLORSCHEME ###
###################################

#####################
### CREATNG VIMRC ###
#####################
create_vimrc()
{
    # Create vimrc with colorscheme, word wrapping and line numbering
    define VIMRC_CONTENT << 'EOF'
set number
if &diff
        colorscheme mycolorscheme
        au VimEnter * | execute 'windo set wrap' |
endif
EOF

    add_content_to_file "$PATH_VIMRC" ".vimrc" "$VIMRC_CONTENT"
    
}
############################
### END OF CREATNG VIMRC ###
############################

############################
### GIT DIFFTOOL VIMDIFF ###
############################
setup_gitdifftool()
{
    cd $PATH_GITCONFIG
    RESULTS=$(git config --global --get diff.tool)
    if [[ "$RESULTS" != "vimdiff" ]]
    then # Not set to wished setting. Set it.
        git config --global diff.tool vimdiff

        RESULTS=$(git config --global --get diff.tool)
        if [[ "$RESULTS" != "vimdiff" ]]
        then # Could not set the setting
            return_value='could not set the git setting'
            return 255
        fi

        return_value='success'
        return 0
    else # Already set to the wished setting
        return_value='already done'
        return 0
    fi

    RESULTS=$(git config --global --get difftool.prompt)
    if [[ "$RESULTS" != "vimdiff" ]]
    then # Not set to wished setting. Set it.
        git config --global diff.tool vimdiff

        RESULTS=$(git config --global difftool.prompt false)
        if [[ "$RESULTS" != "vimdiff" ]]
        then # Could no set the setting
            return_value='could not set the git setting'
            return 255
        fi

        return_value='success'
        return 0
    else # Already set to the wished setting
        return_value='already done'
        return 0
    fi
    
    cd $PATH_SCRIPT
}
###############################
### END OF DIFFTOOL VIMDIFF ###
###############################

#################
### TRASH-CLI ###
#################
setup_trashcli()
{

    # See if package isn't installed
    if ! (dpkg -l | grep -q trash-cli)
    then
        sudo apt install trash-cli
        
        if [[ $? != 0 ]]
            then
                debug_echo 100 -e "Failed installing 'trash-cli' package.\n"
                return_value='failed installing trash-cli package'
                return 255
            fi
    fi

    TRASHCLI_CONTENT="alias rm=trash"

    add_content_to_file "$PATH_BASHRC" "$NAME_BASHRC" "$TRASHCLI_CONTENT" 
}
########################
### END OF TRASH-CLI ###
########################

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
    debug_echo 100 "IF_STATEMENT_EXISTS: $IF_STATEMENT_EXISTS"
    debug_echo 100 "IF_STATEMENT_START: $IF_STATEMENT_START IF_STATEMENT_END: $IF_STATEMENT_END"
    if $IF_STATEMENT_EXISTS
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
        declare -a allowed_intervals=(true true false true)
        declare -a preferred_interval=(false true false false)

        add_single_line_content "$PATH_BASHRC" "$NAME_BASHRC" BASHRC_INPUT1 "INBETWEEN" "END" "${#intervals[@]}" "${intervals[@]}" "${#allowed_intervals[@]}" "${allowed_intervals[@]}" "${#preferred_interval[@]}" "${preferred_interval[@]}"

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
        declare -a allowed_intervals=(false true false false)
        declare -a preferred_interval=(false true false false)
        
        BASHRC_INPUT4='PS1=$PS1_custom'
        add_single_line_content "$PATH_BASHRC" "$NAME_BASHRC" BASHRC_INPUT4 "INBETWEEN" "START" "${#intervals[@]}" "${intervals[@]}" "${#allowed_intervals[@]}" "${allowed_intervals[@]}" "${#preferred_interval[@]}" "${preferred_interval[@]}"

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



#################
### CALL MAIN ###
#################
main
#################
#################