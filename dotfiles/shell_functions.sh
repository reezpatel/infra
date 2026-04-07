# Run command multiple times: x 3 echo hello
function x() {
    if [[ $# -lt 2 ]]; then
    echo "Usage: x <number_of_times> <command>"
    return 1
    fi
    local count=$1
    shift
    for ((i = 1; i <= count; i++)); do
    eval "$@"
    done
}

dirsize() {
    du -sh "$1"
}

extract() {
    if [ -f "$1" ]; then
    case "$1" in
        *.tar.bz2) tar xvjf "$1" ;;
        *.tar.gz)  tar xvzf "$1" ;;
        *.bz2)     bunzip2 "$1" ;;
        *.rar)     unrar x "$1" ;;
        *.gz)      gunzip "$1" ;;
        *.tar)     tar xvf "$1" ;;
        *.tbz2)    tar xvjf "$1" ;;
        *.tgz)     tar xvzf "$1" ;;
        *.zip)     unzip "$1" ;;
        *.Z)       uncompress "$1" ;;
        *.7z)      7z x "$1" ;;
        *)         echo "don't know how to extract '$1'" ;;
    esac
    else
    echo "'$1' is not a valid file"
    fi
}
