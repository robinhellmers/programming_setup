[[ -n $GUARD_BASE ]] && return || readonly GUARD_BASE=1

##############################
### Library initialization ###
##############################
init_lib()
{
    # Unset as only called once and most likely overwritten when sourcing libs
    unset -f init_lib

    local -r THIS_SCRIPT_PATH="$(find_script_path)"

    # Store $THIS_SCRIPT_PATH as unique or local variables
    local -r LIB_PATH="$THIS_SCRIPT_PATH"

    ### Source libraries ###

}

# Only store output in multi-file unique readonly global variables or
# local variables to avoid variable values being overwritten in e.g.
# sourced library files.
# Recommended to always call the function when to use it
find_script_path()
{
    local this_script_path
    local bash_source="${BASH_SOURCE[0]}"

    while [ -L "$bash_source" ]; do # resolve $bash_source until the file is no longer a symlink
        this_script_path=$( cd -P "$( dirname "$bash_source" )" >/dev/null 2>&1 && pwd )
        bash_source=$(readlink "$bash_source")
        # If $bash_source was a relative symlink, we need to resolve it relative
        # to the path where the symlink file was located
        [[ $bash_source != /* ]] && bash_source=$this_script_path/$bash_source 
    done
    this_script_path=$( cd -P "$( dirname "$source" )" >/dev/null 2>&1 && pwd )

    echo "$this_script_path"
}

init_lib

#####################
### Library start ###
#####################
