# START ZPLUG -- ZSH Package manager

source /usr/share/zsh/scripts/zplug/init.zsh

# Make sure to use double quotes
zplug "zsh-users/zsh-history-substring-search"

# Pure theme
#zplug mafredri/zsh-async, from:github
#zplug sindresorhus/pure, use:pure.zsh, from:github, as:theme
# END Pure theme

# powerlevel9k
#POWERLEVEL9K_MODE='awesome-patched'
zplug "bhilburn/powerlevel9k", use:powerlevel9k.zsh-theme, as:theme

POWERLEVEL9K_CUSTOM_PROMPT="echo λ"

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(vcs dir rbenv newline custom_prompt)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(root_indicator command_execution_time background_jobs time)

# /powerlevel9k

# Set the priority when loading
# e.g., zsh-syntax-highlighting must be loaded
# after executing compinit command and sourcing other plugins
# (If the defer tag is given 2 or above, run after compinit command)
zplug "zsh-users/zsh-syntax-highlighting", defer:2

# Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

# Then, source plugins and add commands to $PATH
zplug load

# END ZPLUG

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e
# End of lines configured by zsh-newuser-install

# alias micro so it can start with correct terminal mode
alias micro="TERM=xterm-256color micro"

# dotfile management alias
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME'

# psc
source /psc/scripts/.zsh

# masquerade exa as ll
alias ls="exa"
alias ll="exa -la"
