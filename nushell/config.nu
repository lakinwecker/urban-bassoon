# Direnv integration
$env.config = ($env.config | upsert hooks.pre_prompt (
    ($env.config.hooks.pre_prompt? | default []) | append {||
        if (which direnv | is-empty) { return }
        direnv export json | from json | default {} | load-env
    }
))

# Aliases
alias ls = eza
alias vim = nvim
alias lg = lazygit
alias cat = bat
alias gd = git diff
alias gs = git status
