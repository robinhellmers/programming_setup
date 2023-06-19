[[ -n $GUARD_CONFIG ]] && return || readonly GUARD_CONFIG=1
# Variables etc.

# Default value assumes main script is 1 dir level down relative the called
# script which source this lib
MAIN_SCRIPT_PATH="${MAIN_SCRIPT_PATH:-"$( readlink -f "$(dirname "$(readlink -f "$0")")/.." )"}"

PATH_BASHRC=~
NAME_BASHRC=.bashrc

LOCAL_BIN_PATH="$HOME/.local/bin"
