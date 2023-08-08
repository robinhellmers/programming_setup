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
    readonly MAIN_SCRIPT_PATH="$this_script_path"
    export MAIN_SCRIPT_PATH

    readonly SETUP_SCRIPTS_PATH="$this_script_path/setup_scripts"
    local -r LIB_PATH="$SETUP_SCRIPTS_PATH/lib"

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
                       setup_gitconfig "git configuration"
                       setup_bash_prompt "Bash prompt PS1 including git indication"
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
    total_results_success='true'
    total_results_already_done='true'
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
                debug_echo 1 -e "${ORANGE_COLOR}$(for i in {1..100}; do printf '\\\'; done; printf '\n';)${END_COLOR}"
                debug_echo 1 -e "${ORANGE_COLOR}\\\\\\\\\ Start setup of \"${arr_setups[(($ind_arr_setups + 1))]}\"${END_COLOR}"
                debug_echo 1 -e "${ORANGE_COLOR}$(for i in {1..100}; do printf '\\\'; done; printf '\n';)${END_COLOR}"
                # Script call
                script_output_file="$(mktemp)"
                "$SETUP_SCRIPTS_PATH/${arr_setups[$ind_arr_setups]}.sh" -o "$script_output_file"
                unset return_value
                source "$script_output_file"

                script_output_file_content="$(cat $script_output_file)"
                debug_echo 0 -e "\nSourced script output file:"
                debug_echo 0 "----------------------------"
                [[ -n "$script_output_file_content" ]] && debug_echo 0 "$script_output_file_content"
                debug_echo 0 "----------------------------"

                rm "$script_output_file"
                unset script_output_file_content

                case $return_value in 
                    'success')   # Success
                        end_results+="[✔️] "
                        total_results_already_done='false'
                        ;;
                    'already done') # Already done
                        end_results+="[🔷] "
                        ;;
                    *)   # Failure
                        end_results+="[❌] ";
                        total_results_success='false'
                        total_results_already_done='false'
                        ;;
                esac
                debug_echo 1 -e "${ORANGE_COLOR}$(for i in {1..100}; do printf '/'; done; printf '\n';)${END_COLOR}"
                debug_echo 1 -e "${ORANGE_COLOR}/// End setup of \"${arr_setups[(($ind_arr_setups + 1))]}\"${END_COLOR}"
                debug_echo 1 -e "${ORANGE_COLOR}$(for i in {1..100}; do printf '/'; done; printf '\n';)${END_COLOR}"
            else
                # Setup not to be done
                end_results+="[🟠] "
            fi

            end_results+="${arr_setups[(($ind_arr_setups + 1))]}\n"
        fi
    done

    # Print end results
    echo -e "\n\n${DEFAULT_UNDERLINE_COLOR}Results:${END_COLOR}"
    echo -e " 🟠 = Not to be done"
    echo -e " ✔️ = Success"
    echo -e " ❌ = Failure"
    echo -e " 🔷 = Already setup\n"
    echo -e "$end_results\n"
    echo -e "****************************************"

    total_results_print="Total results: "
    if [[ "$total_results_already_done" = 'true' ]]
    then
        total_results_print+="🔷 - ALREADY SETUP"
    elif [[ "$total_results_success" == 'true' ]]
    then
        total_results_print+="✔️ - SUCCESS"
    else
        total_results_print+="❌ - FAILURE"
    fi

    echo -e "$total_results_print"
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