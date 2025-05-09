alias ls='ls -G'
alias lt='tree'
alias ll='ls -lFha'
alias lh='ls -a | egrep "^\."'
alias ping='prettyping --nolegend'
alias cat='bat'
alias preview="fzf --preview 'bat --color \"always\" {}'"
alias top='htop'
alias man='tldr'
alias t='tmuxinator'

# utility
alias ip="ifconfig -u | grep 'inet ' | grep -v 127.0.0.1 | cut -d\  -f2 | head -1"

# neovim
alias vim='nvim'
alias v='nvim'
alias vi='nvim'
alias be='bundle exec'

# ruby
alias rubocop='bundle exec rubocop'