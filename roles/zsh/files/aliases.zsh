alias g='lazygit'
alias ls='eza --icons'
alias ll='eza -lah --git --icons'
alias lt='eza --tree --level=2 --icons'
alias lh='eza -d .* --icons'
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
alias be='bundle exec'

# ruby
alias rubocop='bundle exec rubocop'
