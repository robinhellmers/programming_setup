
rmws()
{
    sed -i 's/[[:space:]]\+$//' $1
}

rmwsdir()
{
    local thedepth=0

    local re='^[0-9]+$'

    if [[ -n "$1" ]]
    then
        if ! [[ "$1" =~ $re ]]
        then
            echo "Error: Input not a number" >&2
            return 1
        else
            thedepth="$1"
        fi
    fi

    echo "Removing trailing whitespace recursively $thedepth directories down."
    # The following part excludes hidden directories
    # -not -path '*/.*'
    # The following part excludes .md (markdown) files
    # -not -path '*.md'
    # The following part excludes binaries
    # -exec grep -Il '.' {} \;
    # The following part removes trailing whitespace
    # -exec sed -i 's/[[:space:]]\+$//' {} \+
    find . -maxdepth "$((thedepth + 1))" -type f -not -path '*/.*' -not -path '*.md' -exec grep -qIl '.' {} \; -exec sed -i 's/[[:space:]]\+$//' {} \+
}

# Highlighted 'cat'
alias ccat='highlight -O ansi --force'
# Highlighted 'less'
lless()
{
    ccat "$1" | less -R
}

alias rm=trash

git-commit-date-now()
{
    if [[ -z $1 ]]
    then
        mydate=$(date)
    else
        local mydate="$1"
        date -d "$mydate" &>/dev/null
        if (( $? != 0 ))
        then
            mydate=$(date)
        fi
    fi
    LC_ALL=C GIT_COMMITTER_DATE="$mydate" git commit --amend --no-edit --date "$mydate"
}

# After each command, set $BRANCH to currect branch
PROMPT_COMMAND="${PROMPT_COMMAND:+"$PROMPT_COMMAND; "}"'BRANCH=$(git symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3-)'


source "<Will be replaced automatically>" # ID git-completion
source "<Will be replaced automatically>" # ID bash-prompt

# Number of directories to show in bash prompt
export PROMPT_DIRTRIM=3

# Git information
export GIT_PS1_SHOWCOLORHINTS=true
export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export GIT_PS1_SHOWUPSTREAM='auto'

ps1_base_start='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u\[\033[00m\]'
ps1_base_end=':\[\033[01;34m\]\w\[\033[00m\]\$'
ps1_custom_bash_prompt_indication=' \[\033[1;38;5;214m\][CUSTOM]\[\033[00m\]'

# PS1 controls what is shown in the bash prompt
PS1="$ps1_base_start$ps1_base_end"

PROMPT_COMMAND="${PROMPT_COMMAND:+"$PROMPT_COMMAND; "}$(sed -r 's|^(.+)(\\\$\s*)$|__git_ps1_custom "\1" "\2 "|' <<< $PS1)"