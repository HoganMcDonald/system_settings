# ASDF
# . $HOME/.asdf/asdf.sh
# . $HOME/.asdf/completions/asdf.bash

# java
# . ~/.asdf/plugins/java/set-java-home.zsh
#
if command -v devbox &>/dev/null; then
  eval "$(devbox global shellenv)"
fi

if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi

if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
  alias cd='z'
  alias cdi='zi'
fi

if command -v atuin &>/dev/null; then
  eval "$(atuin init zsh)"
fi
