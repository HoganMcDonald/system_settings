export PATH=${PATH}:$ZSH/bin
export PATH=$PATH:/$HOME/.dotfiles/bin
# export PATH="/Users/hogan.mcdonald/.local/bin"
export PATH="/Users/hogan.mcdonald/.local/bin:$PATH"

function print_path() {
    echo $PATH | sed $'s/:/\\\n/g'
}
