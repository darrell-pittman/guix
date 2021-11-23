#!/bin/sh

if [ ! $(pgrep redshift) ]
then
  LOCATION=$(wget -qO- "https://location.services.mozilla.com/v1/geolocate?key=geoclue" \
         | awk 'OFS=":" {print $3,$5}' \
         | tr -d ',}')

  nohup redshift -m wayland -l $LOCATION &>/dev/null &
fi

