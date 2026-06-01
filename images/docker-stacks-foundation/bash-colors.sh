#!/bin/bash
# Enable terminal colors system-wide so they survive when an external
# home directory is mounted (e.g. by JupyterHub) and overwrites ~/.bashrc.
# Sourced from /etc/bash.bashrc (interactive non-login shells).
# See https://github.com/jupyter/docker-stacks/issues/815

force_color_prompt=yes

if [ "$force_color_prompt" = yes ]; then
    # shellcheck disable=SC2154 # debian_chroot is set elsewhere if applicable
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi

if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi
