#!/bin/bash

PATH_SCRIPT="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
echo -e "\nLocation of script:"
echo -e "$PATH_SCRIPT\n"

declare -a arr_setups=(vimdiff "vimdiff"
                           gitdifftool "git difftool as vimdiff"
                           trashcli "trash-cli and alias rm"
                           gitcompletionbash "git completion bash")


PATH_VIMCOLORSCHEME=~/.vim/colors
NAME_VIMCOLORSCHEME=mycolorscheme.vim

PATH_VIMRC=~
PATH_GITCONFIG=~
PATH_BASHRC=~
NAME_BASHRC=.bashrc

URL_GITCOMPLETIONBASH="https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash"
PATH_GITCOMPLETIONBASH=~
NAME_GITCOMPLETIONBASH=.git-completion.bash

# Reads multiline text and inputs to variable
define(){ IFS=$'\n' read -r -d '' ${1} || true; }
# Example usage:
# define VAR <<'EOF'
# abc'asdf"
#     $(dont-execute-this)
# foo"bar"'''
# EOF

# Checks if variable content exists in file
# Input: 2 arguments
# 1 - Filename
# 2 - Multiline variable. Must be quoted
existsInFile()
{
    FILECONTENT=$(<$1)
    REPLACED_CONTENT=${FILECONTENT/$2/}

    if [[ "$FILECONTENT" != "$REPLACED_CONTENT" ]]
    then
        return 0
    fi

    return -1
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
            INIT_RESULTS+="[❌] ";;
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
    echo "This script have to option to setup:"
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
        echo -e " ❌ = Not to be done"
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
    echo -e "Start of \"Vimdiff setup\"\n"
    
    create_colorscheme

    create_vimrc

    echo "End of \"Vimdiff setup\""
    echo -e "****************************************\n"
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

    if [[ -f $PATH_VIMCOLORSCHEME/$NAME_VIMCOLORSCHEME ]]
    then # File already exists
        echo -e "$NAME_VIMCOLORSCHEME exists."

        if existsInFile "$PATH_VIMCOLORSCHEME/$NAME_VIMCOLORSCHEME" "$VIMCOLORSCHEME"
        then # Content is already in the file
            echo -e "$NAME_VIMCOLORSCHEME already contains the relevant content.\n"
            return 0
        else # Append content to file
            echo -e "Append to $NAME_VIMCOLORSCHEME.\n"
            echo "$VIMCOLORSCHEME" >> $NAME_VIMCOLORSCHEME
            return 0
        fi
    else # Create file with content
        echo -e "Create directory: $PATH_VIMCOLORSCHEME/\n"
        mkdir -p $PATH_VIMCOLORSCHEME
        echo -e "Create file $PATH_VIMCOLORSCHEME/$NAME_VIMCOLORSCHEME"    
        echo "$VIMCOLORSCHEME" > $PATH_VIMCOLORSCHEME/$NAME_VIMCOLORSCHEME
        return 0
    fi

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
    
    if [[ -f $PATH_VIMRC/.vimrc ]]
    then # File already exists
        echo -e "$PATH_VIMRC/.vimrc exists."

        if existsInFile "$PATH_VIMRC/.vimrc" "$VIMRC_CONTENT"
        then # Content is already in the file
            echo -e ".vimrc already contains the relevant content.\n"
            return 0
            echo "nnn"
        else # Append content to file
            echo -e "Append to .vimrc.\n"
            echo "$VIMRC_CONTENT" >> "$PATH_VIMRC/.vimrc"
            return 0;
        fi
    else # Create file with content
        echo -e "Create directory: $PATH_VIMCOLORSCHEME/\n"
        mkdir -p $PATH_VIMCOLORSCHEME
        echo -e "Create file $PATH_VIMRC/.vimrc\n"
        echo "$VIMRC_CONTENT" > $PATH_VIMRC/.vimrc
        return 0
    fi
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
    git config --global diff.tool vimdiff
    git config --global difftool.prompt false
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

initial_questions

if $SETUP_VIMDIFF || $SETUP_EVERYTHING
then
    create_vimrc
    # setup_vimdiff
fi

if $SETUP_GITDIFFTOOL || $SETUP_EVERYTHING
then
    #setup_gitdifftool
fi

# if [[ SETUP_TRASHCLI ]] || [[ SETUP_EVERYTHING ]]
# then
#     setup_trashcli
# fi

# if [[ SETUP_GITCOMPLETIONBASH ]] || [[ SETUP_EVERYTHING ]]
# then
#     setup_gitcompletionbash
# fi




