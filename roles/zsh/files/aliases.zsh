alias g='lazygit'
alias ls='eza --icons --group-directories-first --git'
alias ll='ls -lah'
alias lt='ls --tree --level=2 --icons'
alias lh='ls -d .* --icons'
alias ping='prettyping --nolegend'
alias cat='bat'
alias preview="fzf --preview 'bat --color \"always\" {}'"
alias top='htop'
alias man='tldr'
alias t='tmuxinator'
alias y='yazi'

# utility
alias ip="ifconfig -u | grep 'inet ' | grep -v 127.0.0.1 | cut -d\  -f2 | head -1"

# neovim
alias vim='nvim'
alias v='nvim'
alias vi='nvim'

# ruby
alias rubocop='bundle exec rubocop'
alias be='bundle exec'
