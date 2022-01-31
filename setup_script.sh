#!/bin/bash

PATH_SCRIPT="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
echo -e "\nLocation of script:"
echo -e "$PATH_SCRIPT\n"


PATH_VIMCOLORSCHEME=~/.vim/colors
NAME_VIMCOLORSCHEME=mycolorscheme.vim

PATH_VIMRC=~

####################
### VIM COLORING ###
####################
setup_vimdiff () {
    echo -e "Start of \"Vimdiff setup\"\n"

    ##########################
    ### CREATE COLORSCHEME ###
    ##########################
    if [[ -f $PATH_VIMCOLORSCHEME/mycolorscheme.vim ]]
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

echo "End of \"Vimdiff setup\""
echo -e "****************************************\n" 
}
###########################
### END OF VIM COLORING ###
###########################



setup_vimdiff


