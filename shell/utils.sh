#!/usr/bin/env bash

# Add $1 to path if it is not there already
function -pathmunge {
    # remove slashes from the end
    EXTRA=$(echo "$1" | sed -E 's@/+$@@')
    case ":${PATH}:" in
        *"$EXTRA"*)
            ;;
        *)
            if [ "$2" = "after" ] ; then
                PATH="$PATH:$EXTRA"
            else
                PATH="$EXTRA:$PATH"
            fi
    esac
}

function swap
{
    local TMPFILE=tmp.$$
    mv "$1" $TMPFILE && mv "$2" "$1" && mv $TMPFILE "$2"
}

function venv
{
    if [ -n "$1" ]; then
        _DIR="$1"
    else
        _DIR="./.venv"
    fi
    _DIR=$(realpath "$_DIR")

    if ! [ -f "$_DIR/bin/activate" ]; then
        echo "Error: venv dir not found: $_DIR"
        return 1
    fi

    source "$_DIR/bin/activate"
    echo "$_DIR activated"

    _VENV_PATH=$(realpath "$VIRTUAL_ENV" 2>/dev/null)
    if [ "$_VENV_PATH" != "$_DIR" ]; then
        echo "Error: The venv is broken, please recreate it. VIRTUAL_ENV=${VIRTUAL_ENV}"
        if type deactivate >/dev/null 2>&1; then
            deactivate
        fi
        return 1
    fi
}

function _safe_rm_file {
    if [ -f "$1" ] || [ -L "$1" ] || [ -p "$1" ]; then
        file_type=$(stat -c "%F" "$1")
        echo -e "Delete $CYAN${file_type}$RESET $RED$1$RESET?"
        select action in yes no; do
            case $action in
                yes)
                    /bin/rm -f "$1"
                    break
                    ;;
                no)
                    break
                    ;;
            esac
        done

    elif [ -d "$1" ]; then
        n_files=$(ls -A "$1" | wc -l)
        echo -e "Delete directory $RED$1$RESET containing $CYAN${n_files}$RESET files?"
        select action in enter no recurse list; do
            case $action in
                no)
                    break
                    ;;
                recurse)
                    /bin/rm -rf "$1"
                    break
                    ;;
                enter)
                    while IFS= read -r -d '' file; do
                        </dev/tty _safe_rm_file "$file"
                    done < <(find "$1" -type l,f,p -print0)
                    
                    if [ -z "$(ls -A "$1")" ]; then
                        echo -e "Deleting empty directory $RED$1$RESET"
                    fi
                    break
                    ;;
                list)
                    ls -Al "$1"
                    ;;
            esac
        done
    else
        echo -e "Skipping unknown file type: $RED$1$RESET"
    fi
}

function -safe_rm {
    if [ -z "$1" ]; then
        echo "No argument provided."
        return 1
    fi

    args=($@)
    echo -e "Trying to delete $CYAN${#args[@]}$RESET files/directories ..."

    for fname in "${args[@]}"; do
        if [ -e  "$fname" ] || [ -L "$file" ]; then
            _safe_rm_file "$fname"
        else
            echo -e "$RED${fname}$RESET does not exist."
        fi
    done
}

# pretty csv adapted from: https://www.stefaanlippens.net/pretty-csv.html
function -pretty_csv {
    s="$IFS"
    if [ -z "$s" ]; then
        s=","
    fi
    perl -pe "s/((?<=$s)|(?<=^))$s/ $s/g;" "$@" \
        | awk -F\" "{for (i=1; i<=NF; i+=2) gsub(/$s/,\"^\",\$i)} 1" OFS='"' \
	    | column -t -s'^' \
        | less  -F -S -X -K
}


# https://stackoverflow.com/a/2709514/11579038
function -remove_filename_spaces_recursively {
    if [ -z "$1" ]; then
        echo "Usage -remove_filename_spaces_recursively DIR"
        return
    fi
    find "$1" -depth -name '* *' \
	    | while IFS= read -r f ; do {
        mv -i "$f" "$(dirname "$f")/$(basename "$f"|tr ' ' _)" </dev/tty ; 
    } done
}

function -remove_filename_space_num_recursively {
    if [ -z "$1" ]; then
        echo "Usage remove_filename_space_num_recursively DIR"
        return
    fi
    find "$1" -depth -regex '.* [0-9]+\..*' -type f \
        | while IFS= read -r f ; do {
        mv -i "$f" "$(dirname "$f")/$(basename "$f" | sed -E 's/ [0-9]+//')" </dev/tty
    } done
}

# transform a windows path (C:/...) to valid wsl path (/mnt/c...)
function -winpath_to_wsl {
    s="$1"
    echo "$s" | sed 's@\\@/@g' \
                    | (head -c 1 | tr A-Z a-z; sed 1q) \
                    | sed -E 's@^([a-z]):@/mnt/\1@'
}

# release cached memory in wsl
function -wsl_release_memory() {
    sudo bash -c "sync; echo 3 > /proc/sys/vm/drop_caches"
}



# deprecated in favor of factor gnu util
function -factorize {
    if [ -z "$1" ]; then
        echo "usage: factorize NUMBER"
        return
    fi

    factors=()
    _I=2
    _X="$1"
    while [ $(( _I * _I )) -le "$_X" ]; do
        if [ $(( _X % _I )) -eq 0 ]; then
            factors+=("$_I")
            _X=$(( _X / _I ))
        else
            _I=$(( _I + 1 ))
        fi
    done
    
    if [ $_X -gt 1 ]; then
        factors+=("$_X")
    fi

    echo "${factors[@]}"
}

# extraction of nested .tar.gz file
function -extract_nested_tarball() {
    if [ -z "$1" ]; then
        return 1
    fi
    
    echo "Extracting $(realpath "$1") ..."
    TOP_DIR=$(tar tf "$1" | cut -d '/' -f1 | sort -u)
    NUM_TOP_DIRS=$(echo "$TOP_DIR" | wc -l)
    if [ "$NUM_TOP_DIRS" -gt 1 ]; then
        echo "Multiple top directories in the tar archive"
        return 1
    fi

    if [ -z "$TOP_DIR" ]; then
        echo "No top level directories in the tar archive"
        return 1
    fi
    tar -xf "$1"

    # Find and extract nested archives
    pushd "$TOP_DIR" &>/dev/null

    find . -type f \( -name "*.tar" -o -name "*.tar.gz" -o -name "*.tgz" \) -print0 | while IFS= read -r -d '' archive; do 
        -extract_nested_tarball "$archive" "delete"
    done
    popd &>/dev/null

    if [ "$2" == "delete" ]; then
        rm "$1"
    fi
}
