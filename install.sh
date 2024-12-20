#!/usr/bin/env bash

# If called with two positional arguments, installs a single dotfile:
# ./install.sh TARGET_PATH LINK_PATH
#
# If called without arguments, try to auto install/upgrade all dotfiles:
# ./install.sh


usage() {
    echo "usage: $0 [TARGET_PATH] [LINK_PATH]"
    echo ""
    echo "    When called without arguments, install all dotfiles."
    exit 0
}


prompt_yes_no() {
    while true; do
        read -p "$1 [y/n]: "
        case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
            y|yes) 
                echo "yes"
                return
                ;;
            n|no)  
                echo "no"
                return
                ;;
            *)
                ;;
        esac
    done
}

# Install a dotfile with prompt if the file exists already
install_dotfile() {
    local target_path=$1
    local link_path=$2

    if ! [ -a "$target_path" ]; then
        echo "Target path ($target_path) does not exist."
        return 1
    fi

    # Check if the link already exists and points to the same file
    if [ -L "$link_path" ] && [ "$(realpath -e "$link_path")" == "$(realpath -e "$target_path")" ]; then
        echo "Link ($link_path) already points to the correct target, skipping..."
        return 0
    fi

    
    if [ -a "$link_path" ]; then
        local existing_target="$(realpath -e "$link_path")"

        echo "The file ($link_path) already exists. Select an action:"
        select action in "overwrite" "view diff" "view content" "skip"; do
            case $action in
                overwrite)
                    rm "$link_path" && ln -s "$target_path" "$link_path";
                    return 0
                    ;;
                "view diff")
                    diff "$existing_target" "$target_path"
                    read -p "Press Enter to continue..." 
                    ;;
                "view content")
                    less "$existing_target"
                    ;;
                skip) 
                    echo "File skipped"
                    return 0
                    ;;
            esac
        done
    fi

    # link directory does not exist
    _parent_dir="$(dirname "$link_path")"
    if ! [ -d "$_parent_dir" ]; then
        REPLY=$(prompt_yes_no "Directory $_parent_dir does not exist. Do you want to create it?")
        if [ "$REPLY" == yes ]; then
            mkdir -p "$_parent_dir"
        else
            echo "Directory not created, aborting."
            return 0
        fi
    fi

    # Create the link if it doesn't exist or is broken
    rm "$link_path" 2>/dev/null
    ln -s "$target_path" "$link_path"
    echo "${link_path} -> ${target_path} installed."
}

for opt in "$@"; do
    case $opt in
        -h|--help|--usage)
            usage
            ;;
        *)
            ;;
    esac
done

case "$#" in
    0)
        INSTALL_ALL=0
        ;;
    2)
        INSTALL_ALL=1
        ;;
    *)
        usage
        ;;
esac


if [ $INSTALL_ALL -ne 0 ]; then
    install_dotfile "$1" "$2"
    exit $?
fi

DIR="$(dirname "$(realpath -e $0)")"

# Shell #######################################################################
# Install manually by sourcing shell/.bashrc in ~/.bashrc
install_dotfile "$DIR"/shell/.inputrc "$HOME"/.inputrc

# cli_util ####################################################################
install_dotfile "$DIR"/cli_util/htoprc "$HOME"/.config/htop/htoprc

# git #########################################################################
install_dotfile "$DIR"/git/gitconfig "$HOME"/.gitconfig 
install_dotfile "$DIR"/git/gitignore "$HOME"/.gitignore
install_dotfile "$DIR"/git/gitattributes "$HOME"/.gitattributes

# ssh #########################################################################
# Check if the dotfile is already included
grep -E "Include (\\w|/)+" ~/.ssh/config \
    | cut -d ' ' -f2 \
    | xargs -I % sh -c 'realpath -e %' \
    | grep -q "^$(realpath -e ./ssh_config)$"

if [ "$?" -ne 0 ]; then
    REPLY=$(prompt_yes_no "ssh not configured yet. Include this config in global file?")
    if [[ "$REPLY" == "yes" ]]; then
        echo -e "\nInclude $(realpath -e ./ssh_config)" >> ~/.ssh/config        
    else
        echo "Not including ssh config."
    fi
else
    echo "ssh config already installed."
fi

# python ######################################################################
install_dotfile "$DIR"/python/uv.toml "$HOME"/.config/uv/uv.toml

# Misc ########################################################################
install_dotfile "$DIR"/.Rprofile "$HOME"/.Rprofile

