#!/usr/bin/env bash

# Add $1 to path if it is not there already
function pathmunge {
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

    if ! [ -f "$_DIR/bin/activate" ]; then
        echo "Error: venv dir not found: $_DIR"
        return 1
    fi

    source "$_DIR/bin/activate"
    echo "$(readlink -f $_DIR) activated"
}

# pretty csv adapted from: https://www.stefaanlippens.net/pretty-csv.html
function pretty_csv {
    # cat "$@" | sed 's/,/ ,/g' | column -t -s, | less -S
    s="$IFS"
    if [ "$s" = "" ]; then
        s=","
    fi
    perl -pe "s/((?<=$s)|(?<=^))$s/ $s/g;" "$@" \
        | awk -F\" "{for (i=1; i<=NF; i+=2) gsub(/$s/,\"^\",\$i)} 1" OFS='"' \
	| column -t -s'^' \
        | less  -F -S -X -K
}


# https://stackoverflow.com/a/2709514/11579038
function remove_filename_spaces_recursively {
    if [ -z "$1" ]; then
        echo "Usage remove_filename_spaces_recursively DIR"
        return
    fi
    find "$1" -depth -name '* *' \
	    | while IFS= read -r f ; do {
        mv -i "$f" "$(dirname "$f")/$(basename "$f"|tr ' ' _)" </dev/tty ; 
    } done
}

function remove_filename_space_num_recursively {
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
function winpath_to_wsl {
    s="$1"
    echo "$s" | sed 's@\\@/@g' \
                    | (head -c 1 | tr A-Z a-z; sed 1q) \
                    | sed -E 's@^([a-z]):@/mnt/\1@'
}


# deprecated in favor of factor gnu util
function factorize {
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
