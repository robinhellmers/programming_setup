[[ -n $GUARD_COMMON ]] && return || readonly GUARD_COMMON=1

##############################
### Library initialization ###
##############################

init_lib()
{
    find_this_script_path

    readonly LIB_PATH="$this_script_path"
}

find_this_script_path()
{
    local source=${BASH_SOURCE[0]}
    while [ -L "$source" ]; do # resolve $source until the file is no longer a symlink
        this_script_path=$( cd -P "$( dirname "$source" )" >/dev/null 2>&1 && pwd )
        source=$(readlink "$source")
        [[ $source != /* ]] && source=$this_script_path/$source # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    this_script_path=$( cd -P "$( dirname "$source" )" >/dev/null 2>&1 && pwd )
}

init_lib

#####################
### Library start ###
#####################

set_gitconfig_key_value()
{
    local key value current_value

    key="$1"
    value="$2"

    current_value="$(git config --global --get $key)"

    if [[ "$current_value" == "$value" ]]
    then
        return_value_set_gitconfig_key_value='already done'
        return 0
    fi

    # Set key value pair
    git config --global "$key" "$value"

    current_value="$(git config --global --get $key)"

    if [[ "$current_value" != "$value" ]]
    then # Could not set the setting
        _exit 255 'could not set the git setting'
    fi

    _exit 0 'success'
}

