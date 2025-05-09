export PATH=${PATH}:$ZSH/bin
export PATH=$PATH:/$HOME/.dotfiles/bin
# export PATH="/Users/hogan.mcdonald/.local/bin"
export PATH="/Users/hogan.mcdonald/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

function print_path() {
    echo $PATH | sed $'s/:/\\\n/g'
}

# pnpm
export PNPM_HOME="/Users/hoganmcdonald/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end