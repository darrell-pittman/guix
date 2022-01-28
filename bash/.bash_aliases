alias ls='ls -p --color=auto'
alias ll='ls -la'
alias grep='grep --color=auto'

alias ds=lynx-google
alias ec='emacsclient -c -a ""'
alias btc='bluetoothctl connect $(bluetoothctl devices|head -1|cut -d " " -f 2)'
alias btd='bluetoothctl disconnect'

