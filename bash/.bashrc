# Bash initialization for interactive non-login shells and
# for remote shells (info "(bash) Bash Startup Files").

GPG_TTY=$(tty)
export GPG_TTY

# Export 'SHELL' to child processes.  Programs such as 'screen'
# honor it and otherwise use /bin/sh.
export SHELL

if [[ $- != *i* ]]
then
    # We are being invoked from a non-interactive shell.  If this
    # is an SSH session (as in "ssh host command"), source
    # /etc/profile so we get PATH and other essential variables.
    [[ -n "$SSH_CLIENT" ]] && source /etc/profile

    # Don't do anything else.
    return
fi

# Source the system-wide file.
source /etc/bashrc

# Adjust the prompt depending on whether we're in 'guix environment'.
if [ -n "$GUIX_ENVIRONMENT" ]
then
    PS1='\u@\h \w [env]\$ '
else
    PS1='\u@\h \w\$ '
fi


test_unicode() {
  echo -ne "\xe2\x88\xb4\033[6n\033[1K\r"
  read -d R foo
  echo -ne "\033[1K\r"
  echo -e "${foo}" | cut -d \[ -f 2 | cut -d";" -f 2 | (
    read UNICODE
    [ $UNICODE -eq 2 ] && return 0
    [ $UNICODE -ne 2 ] && return 1
  )
}

test_unicode
RC=$?
UNICODE_SUPPORT=`[ $RC -eq 0 ] && echo "Y" || echo "N"`
unset test_unicode

parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

display_user() {
    if [ "$USER" = "darrell" ]; then
        echo -e "\e[91;1m\u0394\u03c0\e[0m"
    else
        echo "$USER@$HOSTNAME"
    fi
}

if [ "$UNICODE_SUPPORT" = Y ]; then
    PS1=$'\u256d\u2500 $(display_user) '"\[\033[93m\]\w\[\033[92m\]\$(parse_git_branch)\[\033[00m\]\n"$'\u2570\u2500 $ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi


#GUIX_PROFILE="/home/darrell/.guix-profile"
#. "$GUIX_PROFILE/etc/profile"


[ -f $HOME/.bash_aliases ] && . $HOME/.bash_aliases


if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
  export XDG_SESSION_TYPE=wayland
  export XDG_SESSION_DESKTOP=sway
  export XDG_CURRENT_DESKTOP=sway
  export LIBSEAT_BACKEND=logind
  dbus-run-session sway
fi

