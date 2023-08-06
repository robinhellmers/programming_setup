[[ -n $GUARD_BASE ]] && return || readonly GUARD_BASE=1

##############################
### Library initialization ###
##############################

init_lib()
{
    find_this_script_path

    local -r LIB_PATH="$this_script_path"
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
