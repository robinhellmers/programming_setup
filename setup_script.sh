#!/bin/bash

PATH_SCRIPT="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
echo -e "\nLocation of script:"
echo -e "$PATH_SCRIPT\n"

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

#######################
### END OF SETTINGS ###
#######################

# Reads multiline text and inputs to variable
#
# Example usage:
# define VAR <<'EOF'
# abc'asdf"
#     $(dont-execute-this)
# foo"bar"'''
# EOF
define(){ IFS=$'\n' read -r -d '' ${1} || true; }

# Checks if variable content exists in file
# Input: 2 arguments
# 1 - Filename
# 2 - Multiline variable. Must be quoted
exists_in_file()
{
    FILECONTENT=$(<$1)
    REPLACED_CONTENT=${FILECONTENT/$2/}

    if [[ "$FILECONTENT" != "$REPLACED_CONTENT" ]]
    then
        return 0
    fi

    return -1
}

# Makes sure file exists with the exact content given. If not, it creates or
# appends it
# 1 - Path to where file is
# 2 - File name
# 3 - Content to add to file
add_content_to_file()
{
    PATH_FILE=$1
    FILE_NAME=$2
    CONTENT_TO_ADD=$3

    if [[ -f $PATH_FILE/$FILE_NAME ]]
    then # File already exists
        echo -e "$FILE_NAME already exists."

        if exists_in_file "$PATH_FILE/$FILE_NAME" "$CONTENT_TO_ADD"
        then # Content is already in the file
            echo -e "$FILE_NAME already contains the relevant content.\n"
            return 255
        else # Append content to file
            echo -e "Append to $FILE_NAME\n"
            echo "$CONTENT_TO_ADD" >> "$PATH_FILE/$FILE_NAME"
            return 0;
        fi
    else # Create file with content
        echo -e "Create directory: $PATH_FILE/\n"
        mkdir -p $PATH_FILE
        echo -e "Create file $PATH_FILE/$FILE_NAME\n"
        echo "$CONTENT_TO_ADD" > $PATH_FILE/$FILE_NAME
        return 0
    fi
    
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
    echo

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
                echo "Doesn't seem like you were happy with your choices.";;
        esac
    done
}
################################
### END OF INITIAL QUESTIONS ###
################################

####################
### VIM COLORING ###
####################
setup_vimdiff () {
    
    create_colorscheme
    RETURN_COLORSCHEME=$?

    create_vimrc
    RETURN_VIMRC=$?

    if [[ $RETURN_COLORSCHEME == 255 && $RETURN_VIMRC == 255 ]]
    then
        return 255
    else
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
        then # Could no set the setting
            return -1
        fi

        return 0
    else # Already set to the wished setting
        return 255
    fi

    RESULTS=$(git config --global --get difftool.prompt)
    if [[ "$RESULTS" != "vimdiff" ]]
    then # Not set to wished setting. Set it.
        git config --global diff.tool vimdiff

        RESULTS=$(git config --global difftool.prompt false)
        if [[ "$RESULTS" != "vimdiff" ]]
        then # Could no set the setting
            return -1
        fi

        return 0
    else # Already set to the wished setting
        return 255
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
    sudo apt install trash-cli

    if [[ $? > 0 ]]
    then
        echo -e "Failed setup_trashcli()\n"
    else
        echo "alias rm=trash" >> $PATH_BASHRC/$NAME_BASHRC
    fi
}
########################
### END OF TRASH-CLI ###
########################

############################
### GIT COMPLETION SETUP ###
############################
setup_gitcompletionbash()
{
    if ! [[ -f $PATH_GITCOMPLETIONBASH/$NAME_GITCOMPLETIONBASH ]]
    then
        if ! [[ -x $(command -v curl) ]]
        then
            echo "Command \"curl\" not available"
            if ! [[ -x $(command -v wget) ]]
            then
                echo -e "Command \"wget\" not available\n"
                echo "Failed setup_gitcompletionbash()"
                return -1
            else
                URL_CONTENT=$(wget $URL_GITCOMPLETIONBASH -q -O -)
                echo URL_CONTENT > $PATH_GITCOMPLETIONBASH/$NAME_GITCOMPLETIONBASH
                return 0
            fi
        else
            URL_CONTENT=$(curl -L $URL_GITCOMPLETIONBASH)
            echo URL_CONTENT > $PATH_GITCOMPLETIONBASH/$NAME_GITCOMPLETIONBASH
            return 0
        fi
    else
        echo "The $PATH_GITCOMPLETIONBASH/$NAME_GITCOMPLETIONBASH file already exists."
        return 0
    fi
}
###################################
### END OF GIT COMPLETION SETUP ###
###################################



############
### MAIN ###
############

initial_questions

# Go through every setup, calling their corresponding function if to be done
TOTAL_RESULTS=true
for i in "${!arr_setups[@]}"
do 
    if [[ $(( i % 2 )) == 0 ]]
    then
        # SETUP_INDIVIDUAL is used to call the magic variable through double
        # evaluation with ${!SETUP_INDIVIDUAL}
        SETUP_INDIVIDUAL=SETUP_${arr_setups[$i]^^}
        if $SETUP_EVERYTHING || ${!SETUP_INDIVIDUAL}
        then
            echo -e "****************************************"
            echo -e "Start setup of \"${arr_setups[(($i + 1))]}\""
            echo -e "****************************************\n"
            # Function call
            setup_${arr_setups[$i]}
            case $? in 
                0)   # Success
                    END_RESULTS+="[✔️] ";;
                255) # Already done
                    END_RESULTS+="[🔷] ";;
                *)   # Failure
                    END_RESULTS+="[❌] ";
                    TOTAL_RESULTS=false;;
            esac
            echo -e "****************************************"
            echo "End setup of \"${arr_setups[(($i + 1))]}\""
            echo -e "****************************************\n"
        else
            # Setup not to be done
            END_RESULTS+="[🟠] "
        fi

        END_RESULTS+="${arr_setups[(($i + 1))]}\n"
    fi
done

# Print end results
echo -e "Results:\n"
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


