#!/usr/bin/env bash

SETUP_SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")" # This script's path
LIB_PATH="$SETUP_SCRIPTS_PATH/lib"

source "$LIB_PATH/config.bash"
source "$LIB_PATH/base.bash"
source "$LIB_PATH/file.bash"

####################
### VIM COLORING ###
####################
main() {

    init

    create_colorscheme
    local return_value_create_colorscheme="$return_value"

    create_vimrc
    local return_value_create_vim_rc="$return_value"

    if [[ "$return_value_create_colorscheme" == 'already done' ]] && \
       [[ "$return_value_create_vim_rc" == 'already done' ]]
    then
        return_value='already done'
        echo "$return_value"
        exit 0
    fi

    return_value='success'
    echo "$return_value"
    exit 0
}
###########################
### ENF OF VIM COLORING ###
###########################

############
### INIT ###
############
init()
{
    PATH_VIMCOLORSCHEME=~/.vim/colors
    NAME_VIMCOLORSCHEME=mycolorscheme.vim
    PATH_VIMRC=~
}
###################
### END OF INIT ###
###################

############################
### CREATING COLORSCHEME ###
############################
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

#
### Call Main
#
main "$@"
#
###
#
