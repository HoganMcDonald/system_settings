export PATH=${PATH}:$ZSH/bin
export PATH=$PATH:/$HOME/.dotfiles/bin

function print_path() {
    echo $PATH | sed $'s/:/\\\n/g'
}
