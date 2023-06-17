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

# 'export' to pass variables to script shell executed from this script
export MAIN_SCRIPT_PATH="$(dirname "$(readlink -f "$0")")"
SETUP_SCRIPTS_PATH="$MAIN_SCRIPT_PATH/setup_scripts"
LIB_PATH="$SETUP_SCRIPTS_PATH/lib"

source "$LIB_PATH/base.bash"

NL='
'
DEFAULT_BOLD_COLOR='\033[1;39m'
DEFAULT_UNDERLINE_COLOR='\033[4;39m'
RED_COLOR='\033[0;31m'
GREEN_COLOR='\033[0;32m'
ORANGE_COLOR='\033[0;33m'
MAGENTA_COLOR='\033[0;35m'
END_COLOR='\033[0m'

################
### SETTINGS ###
################

# 2 entries per function
# 1st entry - Suffix of function. Function name should then follow the
#             naming "setup_<suffix>"
# 2nd entry - Description of function.
declare -a arr_setups=(setup_vimdiff "vimdiff"
                       setup_gitdifftool "vimdiff as git difftool"
                       setup_trashcli "trash-cli and alias rm"
                    #    bash_prompt "Bash prompt PS1 including git indication"
                       )



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
    debug_echo 0 -e "$MAIN_SCRIPT_PATH\n"

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
                debug_echo 1 -e "${ORANGE_COLOR}$(for i in {1..100}; do printf '\\'; done; printf '\n';)${END_COLOR}"
                debug_echo 1 -e "${ORANGE_COLOR}\\\\\\ Start setup of \"${arr_setups[(($ind_arr_setups + 1))]}\"${END_COLOR}"
                debug_echo 1 -e "${ORANGE_COLOR}$(for i in {1..100}; do printf '\\'; done; printf '\n';)${END_COLOR}"
                # Script call
                script_output_file="$(mktemp)"
                "$SETUP_SCRIPTS_PATH/${arr_setups[$ind_arr_setups]}.sh" -o "$script_output_file"
                unset return_value
                source "$script_output_file"

                debug_echo 0 "Sourced script output file:"
                debug_echo 0 "----------------------------"
                debug_echo 0 "$(cat $script_output_file)"
                debug_echo 0 "----------------------------"

                rm "$script_output_file"

                case $return_value in 
                    'success')   # Success
                        END_RESULTS+="[✔️] ";;
                    'already done') # Already done
                        END_RESULTS+="[🔷] ";;
                    *)   # Failure
                        END_RESULTS+="[❌] ";
                        TOTAL_RESULTS=false;;
                esac
                debug_echo 1 -e "${ORANGE_COLOR}$(for i in {1..100}; do printf '\\'; done; printf '\n';)${END_COLOR}"
                debug_echo 1 -e "${ORANGE_COLOR}/// End setup of \"${arr_setups[(($ind_arr_setups + 1))]}\"${END_COLOR}"
                debug_echo 1 -e "${ORANGE_COLOR}$(for i in {1..100}; do printf '\\'; done; printf '\n';)${END_COLOR}"
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

#################
### CALL MAIN ###
#################
main
#################
#################