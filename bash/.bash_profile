# Honor per-interactive-shell startup file

export GUIX_EXTRA_PROFILES=$HOME/.guix-extra-profiles

for i in $GUIX_EXTRA_PROFILES/*; do
  profile=$i/$(basename "$i")
  if [ -f "$profile"/etc/profile ]; then
    GUIX_PROFILE="$profile"
    . "$GUIX_PROFILE"/etc/profile
  fi
  unset profile
done

[ -d $HOME/bin ] && PATH=$HOME/bin:$PATH

export PATH=`printf %s "$PATH" \
            | awk -v RS=: '{ if (!arr[$0]++) {printf("%s%s",!ln++?"":":",$0)}}'`

if [ -f ~/.bashrc ]; then . ~/.bashrc; fi
