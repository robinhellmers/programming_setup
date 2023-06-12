
source "<Will be replaced automatically>" # ID git-prompt

__git_ps1_custom()
{
    # preserve exit status
    local exit=$?
    local pcmode=no
    local detached=no
    local ps1pc_start='\u@\h:\w '
    local ps1pc_end='\$ '
    local printf_format=' (%s)'

    case "$#" in
        2|3)	pcmode=yes
            ps1pc_start="$1"
            ps1pc_end="$2"
            printf_format="${3:-$printf_format}"
            # set PS1 to a plain prompt so that we can
            # simply return early if the prompt should not
            # be decorated
            if [[ -z ${CUSTOM_BASH_PROMPT_INDICATION+x} ]]
            then
				PS1="$ps1pc_start$ps1pc_end"
			else
                PS1="$ps1pc_start$ps1_custom_bash_prompt_indication$ps1pc_end"
            fi
        ;;
        0|1)	printf_format="${1:-$printf_format}"
        ;;
        *)	return $exit
        ;;
    esac

    # ps1_expanded:  This variable is set to 'yes' if the shell
    # subjects the value of PS1 to parameter expansion:
    #
    #   * bash does unless the promptvars option is disabled
    #   * zsh does not unless the PROMPT_SUBST option is set
    #   * POSIX shells always do
    #
    # If the shell would expand the contents of PS1 when drawing
    # the prompt, a raw ref name must not be included in PS1.
    # This protects the user from arbitrary code execution via
    # specially crafted ref names.  For example, a ref named
    # 'refs/heads/$(IFS=_;cmd=sudo_rm_-rf_/;$cmd)' might cause the
    # shell to execute 'sudo rm -rf /' when the prompt is drawn.
    #
    # Instead, the ref name should be placed in a separate global
    # variable (in the __git_ps1_* namespace to avoid colliding
    # with the user's environment) and that variable should be
    # referenced from PS1.  For example:
    #
    #     __git_ps1_foo=$(do_something_to_get_ref_name)
    #     PS1="...stuff...\${__git_ps1_foo}...stuff..."
    #
    # If the shell does not expand the contents of PS1, the raw
    # ref name must be included in PS1.
    #
    # The value of this variable is only relevant when in pcmode.
    #
    # Assume that the shell follows the POSIX specification and
    # expands PS1 unless determined otherwise.  (This is more
    # likely to be correct if the user has a non-bash, non-zsh
    # shell and safer than the alternative if the assumption is
    # incorrect.)
    #
    local ps1_expanded=yes
    [ -z "${ZSH_VERSION-}" ] || [[ -o PROMPT_SUBST ]] || ps1_expanded=no
    [ -z "${BASH_VERSION-}" ] || shopt -q promptvars || ps1_expanded=no

    local repo_info rev_parse_exit_code
    repo_info="$(git rev-parse --git-dir --is-inside-git-dir \
        --is-bare-repository --is-inside-work-tree \
        --short HEAD 2>/dev/null)"
    rev_parse_exit_code="$?"

    if [ -z "$repo_info" ]; then
        return $exit
    fi

    local short_sha=""
    if [ "$rev_parse_exit_code" = "0" ]; then
        short_sha="${repo_info##*$'\n'}"
        repo_info="${repo_info%$'\n'*}"
    fi
    local inside_worktree="${repo_info##*$'\n'}"
    repo_info="${repo_info%$'\n'*}"
    local bare_repo="${repo_info##*$'\n'}"
    repo_info="${repo_info%$'\n'*}"
    local inside_gitdir="${repo_info##*$'\n'}"
    local g="${repo_info%$'\n'*}"

    if [ "true" = "$inside_worktree" ] &&
       [ -n "${GIT_PS1_HIDE_IF_PWD_IGNORED-}" ] &&
       [ "$(git config --bool bash.hideIfPwdIgnored)" != "false" ] &&
       git check-ignore -q .
    then
        return $exit
    fi

    local sparse=""
    if [ -z "${GIT_PS1_COMPRESSSPARSESTATE-}" ] &&
       [ -z "${GIT_PS1_OMITSPARSESTATE-}" ] &&
       [ "$(git config --bool core.sparseCheckout)" = "true" ]; then
        sparse="|SPARSE"
    fi

    local r=""
    local b=""
    local step=""
    local total=""
    if [ -d "$g/rebase-merge" ]; then
        __git_eread "$g/rebase-merge/head-name" b
        __git_eread "$g/rebase-merge/msgnum" step
        __git_eread "$g/rebase-merge/end" total
        r="|REBASE"
    else
        if [ -d "$g/rebase-apply" ]; then
            __git_eread "$g/rebase-apply/next" step
            __git_eread "$g/rebase-apply/last" total
            if [ -f "$g/rebase-apply/rebasing" ]; then
                __git_eread "$g/rebase-apply/head-name" b
                r="|REBASE"
            elif [ -f "$g/rebase-apply/applying" ]; then
                r="|AM"
            else
                r="|AM/REBASE"
            fi
        elif [ -f "$g/MERGE_HEAD" ]; then
            r="|MERGING"
        elif __git_sequencer_status; then
            :
        elif [ -f "$g/BISECT_LOG" ]; then
            r="|BISECTING"
        fi

        if [ -n "$b" ]; then
            :
        elif [ -h "$g/HEAD" ]; then
            # symlink symbolic ref
            b="$(git symbolic-ref HEAD 2>/dev/null)"
        else
            local head=""
            if ! __git_eread "$g/HEAD" head; then
                return $exit
            fi
            # is it a symbolic ref?
            b="${head#ref: }"
            if [ "$head" = "$b" ]; then
                detached=yes
                b="$(
                case "${GIT_PS1_DESCRIBE_STYLE-}" in
                (contains)
                    git describe --contains HEAD ;;
                (branch)
                    git describe --contains --all HEAD ;;
                (tag)
                    git describe --tags HEAD ;;
                (describe)
                    git describe HEAD ;;
                (* | default)
                    git describe --tags --exact-match HEAD ;;
                esac 2>/dev/null)" ||

                b="$short_sha..."
                b="($b)"
            fi
        fi
    fi

    if [ -n "$step" ] && [ -n "$total" ]; then
        r="$r $step/$total"
    fi

    local conflict="" # state indicator for unresolved conflicts
    if [[ "${GIT_PS1_SHOWCONFLICTSTATE}" == "yes" ]] &&
       [[ $(git ls-files --unmerged 2>/dev/null) ]]; then
        conflict="|CONFLICT"
    fi

    local w=""
    local i=""
    local s=""
    local u=""
    local h=""
    local c=""
    local p="" # short version of upstream state indicator
    local upstream="" # verbose version of upstream state indicator

    if [ "true" = "$inside_gitdir" ]; then
        if [ "true" = "$bare_repo" ]; then
            c="BARE:"
        else
            b="GIT_DIR!"
        fi
    elif [ "true" = "$inside_worktree" ]; then
        if [ -n "${GIT_PS1_SHOWDIRTYSTATE-}" ] &&
           [ "$(git config --bool bash.showDirtyState)" != "false" ]
        then
            git diff --no-ext-diff --quiet || w="*"
            git diff --no-ext-diff --cached --quiet || i="+"
            if [ -z "$short_sha" ] && [ -z "$i" ]; then
                i="#"
            fi
        fi
        if [ -n "${GIT_PS1_SHOWSTASHSTATE-}" ] &&
           git rev-parse --verify --quiet refs/stash >/dev/null
        then
            s="$"
        fi

        if [ -n "${GIT_PS1_SHOWUNTRACKEDFILES-}" ] &&
           [ "$(git config --bool bash.showUntrackedFiles)" != "false" ] &&
           git ls-files --others --exclude-standard --directory --no-empty-directory --error-unmatch -- ':/*' >/dev/null 2>/dev/null
        then
            u="%${ZSH_VERSION+%}"
        fi

        if [ -n "${GIT_PS1_COMPRESSSPARSESTATE-}" ] &&
           [ "$(git config --bool core.sparseCheckout)" = "true" ]; then
            h="?"
        fi

        if [ -n "${GIT_PS1_SHOWUPSTREAM-}" ]; then
            __git_ps1_show_upstream
        fi
    fi

    local z="${GIT_PS1_STATESEPARATOR-" "}"

    b=${b##refs/heads/}
    if [ $pcmode = yes ] && [ $ps1_expanded = yes ]; then
        __git_ps1_branch_name=$b
        b="\${__git_ps1_branch_name}"
    fi

    if [ -n "${GIT_PS1_SHOWCOLORHINTS-}" ]; then
        __git_ps1_colorize_gitstring
    fi

    local f="$h$w$i$s$u$p"
    local gitstring="$c$b${f:+$z$f}${sparse}$r${upstream}${conflict}"

    if [ $pcmode = yes ]; then
        if [ "${__git_printf_supports_v-}" != yes ]; then
            gitstring=$(printf -- "$printf_format" "$gitstring")
        else
            printf -v gitstring -- "$printf_format" "$gitstring"
        fi

        if [[ -z ${CUSTOM_BASH_PROMPT_INDICATION+x} ]]
        then
            PS1="$ps1pc_start$gitstring$ps1pc_end"
        else
            PS1="$ps1pc_start$gitstring$ps1_custom_bash_prompt_indication$ps1pc_end"
        fi
    else
        printf -- "$printf_format" "$gitstring"
    fi

    return $exit
}
