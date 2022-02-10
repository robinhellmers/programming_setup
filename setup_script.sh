#!/bin/bash

PATH_SCRIPT="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
echo -e "\nLocation of script:"
echo -e "$PATH_SCRIPT\n"


PATH_VIMCOLORSCHEME=~/.vim/colors
NAME_VIMCOLORSCHEME=mycolorscheme.vim

PATH_VIMRC=~
PATH_GITCONFIG=~
PATH_BASHRC=~
NAME_BASHRC=.bashrc

URL_GITCOMPLETIONBASH="https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash"
PATH_GITCOMPLETIONBASH=~
NAME_GITCOMPLETIONBASH=.git-completion.bash


#############################
### YESNO QUESTION HELPER ###
#############################
yesno_question()
{

    read -p "Setup $2? [y/*]: " -n 1 -r
    echo

    case ${REPLY,,} in
        y)
            declare SETUP_${1^^}=true
            INIT_RESULTS+="✅ ";;
        *)
            declare SETUP_${1^^}=false
            INIT_RESULTS+="❌ ";;
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
    echo "Choose what to setup in the following prompts:"
    read -p "Setup everything? [y/*]: " -n 1 -r 
    echo -e "\n"
    case ${REPLY,,} in
        y|yes)
            SETUP_EVERYTHING=true;;
        *)
            SETUP_EVERYTHING=false;;
    esac

    if ! [[ $SETUP_EVERYTHING ]] ; then return ; fi

    yesno_question vimdiff "vimdiff"
    yesno_question gitdifftool "git difftool as vimdiff"
    yesno_question trashcli "trash-cli and alias rm"
    yesno_question gitcompletionbash "git completion bash"
    
    echo -e "\n$INIT_RESULTS"
}
################################
### END OF INITIAL QUESTIONS ###
################################

####################
### VIM COLORING ###
####################
setup_vimdiff () {
    echo -e "Start of \"Vimdiff setup\"\n"

    ##########################
    ### CREATE COLORSCHEME ###
    ##########################
    if [[ -f $PATH_VIMCOLORSCHEME/$NAME_VIMCOLORSCHEME ]]
    then
        echo -e "$NAME_VIMCOLORSCHEME exists.\n"
    else
        echo -e "Create directory: $PATH_VIMCOLORSCHEME/\n"
        mkdir -p $PATH_VIMCOLORSCHEME
        cd $PATH_VIMCOLORSCHEME

        echo -e "Create file $PATH_VIMCOLORSCHEME/$NAME_VIMCOLORSCHEME"
        cat <<EOF > $NAME_VIMCOLORSCHEME
highlight DiffAdd    cterm=bold ctermfg=15 ctermbg=22 gui=none guifg=bg guibg=Red
highlight DiffDelete cterm=bold ctermfg=15 ctermbg=88 gui=none guifg=bg guibg=Red
highlight DiffChange cterm=bold ctermfg=15 ctermbg=17 gui=none guifg=bg guibg=Red
highlight DiffText   cterm=bold ctermfg=15 ctermbg=130 gui=none guifg=bg guibg=Red
EOF
    fi
    cd $PATH_SCRIPT

    ####################
    ### CREATE VIMRC ###
    ####################
    if [[ -f $PATH_VIMRC/.vimrc ]]
    then
        echo -e "$PATH_VIMRC/.vimrc already exists."
        echo -e "Append to .vimrc.\n"
        cat <<EOF >> .vimrc
set number
if &diff
        colorscheme mycolorscheme
        au VimEnter * | execute 'windo set wrap' |
endif
EOF
        # ************************************************************************************** APPEND
    else

        echo -e "Create $PATH_VIMRC/.vimrc\n"
        # Create vimrc with colorscheme, word wrapping and line numbering
        cat <<EOF > .vimrc
set number
if &diff
        colorscheme mycolorscheme
        au VimEnter * | execute 'windo set wrap' |
endif
EOF
    fi

cd $PATH_SCRIPT
echo "End of \"Vimdiff setup\""
echo -e "****************************************\n"
}
###########################
### END OF VIM COLORING ###
###########################

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
            else
                URL_CONTENT=$(wget $URL_GITCOMPLETIONBASH -q -O -)
                echo URL_CONTENT > $PATH_GITCOMPLETIONBASH/$NAME_GITCOMPLETIONBASH
            fi
        else
            URL_CONTENT=$(curl -L $URL_GITCOMPLETIONBASH)
            echo URL_CONTENT > $PATH_GITCOMPLETIONBASH/$NAME_GITCOMPLETIONBASH
        fi
    else
        echo "The $PATH_GITCOMPLETIONBASH/$NAME_GITCOMPLETIONBASH file already exists."
        echo -e "Doesn't continue with setup_gitcompletionbash()\n"
    fi
}
###################################
### END OF GIT COMPLETION SETUP ###
###################################

initial_questions
# if [[ SETUP_VIMDIFF ]] || [[ SETUP_EVERYTHING ]]
# then
#     setup_vimdiff
# fi

# if [[ SETUP_GITDIFFTOOL ]] || [[ SETUP_EVERYTHING ]]
# then
#     setup_gitdifftool
# fi

# if [[ SETUP_TRASHCLI ]] || [[ SETUP_EVERYTHING ]]
# then
#     setup_trashcli
# fi

# if [[ SETUP_GITCOMPLETIONBASH ]] || [[ SETUP_EVERYTHING ]]
# then
#     setup_gitcompletionbash
# fi




