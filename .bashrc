function meta() {

    if [ -z "$3" ]; then
        PY="python3"
    else
        PY="$3"
    fi

    cat "$2" | "$PY" "$1.py" > "$1_out.txt"
    # /usr/bin/time -f "%E"

    if [ "$?" -ne 0 ]; then
        echo "Error when running the program."
        return 1
    fi

    IN_LINES=$(wc -l "$2")
    OUT_LINES=$(wc -l "$1_out.txt")
    echo "Input lines: $IN_LINES"
    echo "Output lines: $OUT_LINES"
    echo "In sample:"
    echo "--------------------"
    head -n 10 "$2"

    printf "\n"
    echo "Out sample:"
    echo "--------------------"
    head -n 10 "$1_out.txt"
}
