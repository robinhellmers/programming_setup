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
# 3 - Variable name for setting true/false depending on the results
exists_in_file()
{
    DEBUG=false
    FILECONTENT=$(<$1)
    REPLACED_CONTENT=${FILECONTENT/"$2"/}
    declare -g $3=false

    if $DEBUG
    then
        echo -e "VARIABLE INPUT:\n$2\nEND OF VARIABLE INPUT"
        echo "$2" | grep -q "export PROMPT_DIRTRIM=3"
        if [[ "$?" == 0 ]]
        then
            vimdiff <(echo "$FILECONTENT") <(echo "$REPLACED_CONTENT")
            echo -e "\n\nSTART DIFF:"
            diff <(echo "$FILECONTENT") <(echo "$REPLACED_CONTENT")
            echo -e "END DIFF\n\n"
        fi
    fi
    
    if [[ "$FILECONTENT" != "$REPLACED_CONTENT" ]]
    then
        echo "YESYESYES"
        declare -g $3=true
        return 0
    fi
    echo "NONONO"

    return -1
}

# Makes sure file exists with the exact content given. If not, it creates or
# appends it
# 1 - Path to file
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

        if exists_in_file "$PATH_FILE/$FILE_NAME" "$CONTENT_TO_ADD" CONTENT_TO_ADD_EXISTS
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

# Fetches file from URL using either curl or wget. Saves into given file.
# 1 - Path to file
# 2 - File name
# 3 - URL with text content
get_internet_file()
{
    
    PATH_FILE=$1
    FILE_NAME=$2
    FILE_URL=$3

    IS_CURL_AVAILABLE="$(command -v curl)"
    IS_WGET_AVAILABLE="$(command -v wget)"

    # Use 'curl' if available
    if [[ -z $IS_CURL_AVAILABLE ]]
    then
        URL_CONTENT=$(curl -L $FILE_URL)

        if [[ $? != 0 ]]
        then
            echo "Failed. 'curl' command failed."
            return -1
        fi

        FILE_CONTENT=$(<$PATH_FILE/$FILE_NAME)
        add_content_to_file "$PATH_FILE" "$FILE_NAME" "$URL_CONTENT"
        return
    fi
    echo -e "Command \"curl\" not available\n"

    # Use 'wget' if available
    if [[ -n $IS_WGET_AVAILABLE ]]
    then
        URL_CONTENT=$(wget -O- $FILE_URL)

        if [[ $? != 0 ]]
        then
            echo "Failed. 'wget' command failed."
            return -1
        fi

        add_content_to_file "$PATH_FILE" "$FILE_NAME" "$URL_CONTENT"
        return
    fi

    echo -e "Command \"wget\" not available\n"
    echo "Failed. Neither 'curl' or 'wget' is availale. Can't fetch content."

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

    # See if package isn't installed
    if ! (dpkg -l | grep -q trash-cli)
    then
        sudo apt install trash-cli
        
        if [[ $? != 0 ]]
            then
                echo -e "Failed installing 'trash-cli' package.\n"
                return -1
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
    #         ;;
    #     255) # Already done
    #         ;;
    #     *)   # Failure
    #         return -1;;
    # esac

    # # Make it executable
    # sudo chmod +x $PATH_GITCOMPLETIONBASH/$NAME_GITCOMPLETIONBASH
    # RETURN_CHMOD=$?

    # if [[ $RETURN_CHMOD != 0 ]]; then return -1; fi

# Variable expansion line
    BASHRC_INPUT1_1="$PATH_GITCOMPLETIONBASH/$NAME_GITCOMPLETIONBASH"
# Doesn't include any variable expansion
    define BASHRC_INPUT1_2 <<'EOF'
export PROMPT_DIRTRIM=3
export GIT_PS1_SHOWCOLORHINTS=true
export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export GIT_PS1_SHOWUPSTREAM="auto"
PS1_custom='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u\[\033[00m\]:\['\
'\033[01;34m\]\w\[\033[00m\]\$ '
PS1_original='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m'\
'\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
EOF
# Concat the two above. OBS don't use \n for newline, seems good when doing diff
# but doesn't work the same when doing the check in 'exists_in_file'
    BASHRC_INPUT1="${BASHRC_INPUT1_1}
${BASHRC_INPUT1_2}"

    define BASHRC_INPUT2 <<'EOF'
if [ "$color_prompt" = yes ]; then
    PS1=$PS1_custom
EOF
    define BASHRC_INPUT3 <<'EOF'
PROMPT_COMMAND=$(sed -r 's|^(.+)(\\\$\s*)$|__git_ps1 "\1" "\2"|' <<< $PS1)
EOF

    # Check if changes are done since before
    exists_in_file "$PATH_BASHRC/$NAME_BASHRC" "$BASHRC_INPUT1" BASHRC_INPUT1_EXISTS
    exists_in_file "$PATH_BASHRC/$NAME_BASHRC" "$BASHRC_INPUT2" BASHRC_INPUT2_EXISTS
    exists_in_file "$PATH_BASHRC/$NAME_BASHRC" "$BASHRC_INPUT3" BASHRC_INPUT3_EXISTS

    echo "BASHRC_INPUT1_EXISTS: $BASHRC_INPUT1_EXISTS"
    echo "BASHRC_INPUT2_EXISTS: $BASHRC_INPUT2_EXISTS"
    echo -e "BASHRC_INPUT3_EXISTS: $BASHRC_INPUT3_EXISTS\n"

    if $BASHRC_INPUT1_EXISTS && $BASHRC_INPUT2_EXISTS && $BASHRC_INPUT3_EXISTS
    then
        echo "Changes done since before."
        exit
        return 255
    fi




    # Read file, line by line
    # Start line to search for:
    SEARCH_FOR_CONTENT="if [ \"\$color_prompt\" = yes ]; then"
    FOUND=false
    PREVIOUSLY_SET=false
    LINE_COUNTER=1
    arr_with_line_numbers=()
    while IFS= read -r line; do

        # Remove leading and trailing whitespace
        line="$(echo -e "${line}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

        # If found previous loop
        if $FOUND
        then
            if [[ "$line" == "PS1=\$PS1_custom" ]]
            then
                PREVIOUSLY_SET=true
            else
                PREVIOUSLY_SET=false
            fi

            # Find line interval to replace
            FOUND=false
            SEARCH_FOR_CONTENT="fi" # End of if statement
        fi

        if [[ "$line" == "$SEARCH_FOR_CONTENT" ]]
        then
            FOUND=true
            echo "Found at line: $LINE_COUNTER"
            arr_with_line_numbers+=("$LINE_COUNTER")

            if [[ ${#arr_with_line_numbers[@]} == 2 ]]
            then # Got start and ending line number
                break
            fi
        fi

        LINE_COUNTER=$((LINE_COUNTER + 1))
    done < $PATH_BASHRC/$NAME_BASHRC

    # Probably empty bashrc file
    if ! $FOUND
    then
        echo "haaa" # Append to file
    fi

    if $FOUND
    then
        echo "Between line ${arr_with_line_numbers[0]} and ${arr_with_line_numbers[1]}"

        sed -i "${arr_with_line_numbers[0]}i 
        " "$PATH_BASHRC/$NAME_BASHRC"
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


