# ASDF
# . $HOME/.asdf/asdf.sh
# . $HOME/.asdf/completions/asdf.bash

# java
# . ~/.asdf/plugins/java/set-java-home.zsh
#
if command -v devbox &>/dev/null; then
  eval "$(devbox global shellenv --init-hook)"
fi

if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi
