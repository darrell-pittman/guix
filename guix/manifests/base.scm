;; This "manifest" file can be passed to 'guix package -m' to reproduce
;; the content of your profile.  This is "symbolic": it only specifies
;; package names.  To reproduce the exact same profile, you also need to
;; capture the channels being used, as returned by "guix describe".
;; See the "Replicating Guix" section in the manual.

(specifications->manifest
  (list "adwaita-icon-theme"
        "xdot"
        "graphviz"
        "gimp"
        "ripgrep"
        "font-awesome"
        "waybar"
        "pinentry"
        "weechat"
        "speedcrunch"
        "imagemagick"
        "xsane"
        "wev"
        "redshift-wayland"
        "swayidle"
        "git"
        "openssh"
        "alacritty"
        "ungoogled-chromium-wayland"
        "dmenu"
        "gnucash"
        "lynx"
        "gnupg"
        "pulseaudio"
        "bluez"
        "dbus"
        "fontconfig"
        "cups"
        "font-abattis-cantarell"
        "font-fira-code"
        "alsa-utils"
        "light"))