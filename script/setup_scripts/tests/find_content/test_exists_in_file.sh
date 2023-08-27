#!/usr/bin/env bash

source "../lib/base.bash"
source "../lib/if_statement.bash"
source "../lib/insert.bash"
source "../lib/file.bash"

main()
{
    DEBUG_LEVEL=100
    DEBUG=true

    define IF_STATEMENT <<'EOF'
if [[ "$mystr" == 'abc' ]]
EOF

    exists_in_file "./testfile" "$IF_STATEMENT" IF_STATEMENT

    define MULTILINE_CONTENT <<'EOF'
        echo "myvar: $myvar"
        echo "mystr: $mystr"
EOF
    exists_in_file "./testfile" "$MULTILINE_CONTENT" MULTILINE
    exit 1
    find_else_elif_fi_statement "./testfile" 6 if_statement 2

    echo -e "\nif_statement_line_nums:\n${if_statement_LNs[@]}\n"
    echo -e "if_statement_type:\n${if_statement_type[@]}\n"
    echo -e "if_statement_level:\n${if_statement_level[@]}\n"

    declare -a intervals=("${if_statement_LNs[@]}")
    declare -a allowed_intervals=('true' 'true' 'false' 'true')
    declare -a preferred_interval=('false' 'true' 'false' 'false')

    exit 1

    define BASHRC_INPUT1 <<'EOF'
export PROMPT_DIRTRIM=3
export GIT_PS1_SHOWCOLORHINTS=true
export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export GIT_PS1_SHOWUPSTREAM="auto"
EOF

    add_single_line_content "." "testfile" BASHRC_INPUT1 "INBETWEEN" "END" \
                            "${#allowed_intervals[@]}" "${allowed_intervals[@]}" \
                            "${#preferred_interval[@]}" "${preferred_interval[@]}" \
                            "${#intervals[@]}" "${intervals[@]}"
    
}

main "$@"
