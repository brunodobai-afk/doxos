# ~/.bashrc: DOXos interactive terminal configuration

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History settings
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=5000
HISTFILESIZE=10000
shopt -s checkwinsize

# Clean, monochrome prompt (Black & White aesthetic)
PS1='\[\033[01;37m\][DOXos]\[\033[00m\] \[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Aliases
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'

# Launch Fastfetch with DOXos branding on terminal start
if command -v fastfetch >/dev/null 2>&1; then
    fastfetch --config /etc/doxos/fastfetch.jsonc 2>/dev/null || fastfetch
fi
