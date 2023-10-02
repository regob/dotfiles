# extended shell globbing
shopt -s extglob
shopt -s globstar

# history settings
export HISTSIZE=-1
export HISTFILESIZE=-1


# pretty csv from: https://www.stefaanlippens.net/pretty-csv.html
function pretty_csv {
    perl -pe 's/((?<=,)|(?<=^)),/ ,/g;' "$@" | column -t -s, | less  -F -S -X -K
}


