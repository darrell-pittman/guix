;; This is an operating system configuration template
;; for a "bare bones" setup, with no X11 display server.

(use-modules (gnu)
             (gnu system setuid)
             (gnu services desktop)
             (gnu services dbus)
             (gnu services avahi)
             (gnu services sound)
             (gnu services cups)
             (gnu packages cups)
             (nongnu packages linux)
             (nongnu system linux-initrd))

(use-service-modules networking ssh)
(use-package-modules screen ssh certs)

(define %mouse-name-rules
  (udev-rule
   "90-mouse-names.rules"
   (string-append "KERNEL==\"mouse[0-9]\""
                  ", SUBSYSTEMS==\"input\""
                  ", ATTRS{name}==\"Logitech Wireless Mouse\""
                  ", SYMLINK+=\"input/mouse-logitech\""
                  "\n"
                  "KERNEL==\"mouse[0-9]\""
                  ", SUBSYSTEMS==\"input\""
                  ", ATTRS{name}==\"AlpsPS/2 ALPS DualPoint Stick\""
                  ", SYMLINK+=\"input/mouse-stick\"")))

(define %backlight-rules
  (udev-rule
   "90-backlight.rules"
   (string-append "ACTION==\"add\""
                  ", SUBSYSTEM==\"backlight\""
                  ", RUN+=\"/bin/chgrp video /sys/class/backlight/%k/brightness\""
                  "\n"
                  "ACTION==\"add\""
                  ", SUBSYSTEM==\"backlight\""
                  ", RUN+=\"/bin/chmod g+w /sys/class/backlight/%k/brightness\"")))

(operating-system
 (kernel linux)
 (kernel-arguments (cons* "video=1280x720"
                          "radeon.si_support=1"
                          "radeon.cik_support=1"
                          "radeon.dpm=1"
                          "radeon.runpm=0"
                          %default-kernel-arguments))
 (initrd microcode-initrd)
 (firmware (cons* iwlwifi-firmware
                  radeon-firmware
                  ibt-hw-firmware
                  %base-firmware))
 (host-name "guix_laptop")
 (timezone "America/St_Johns")
 (locale "en_CA.utf8")
 (keyboard-layout (keyboard-layout "us" #:options '("ctrl:nocaps")))

 (bootloader
  (bootloader-configuration
   (bootloader grub-efi-bootloader)
   (targets (list "/boot/efi"))
   (menu-entries
    (list (menu-entry
           (label "Debian")
           (linux "(hd0,gpt5)/boot/vmlinuz")
           (linux-arguments '( "root=\"LABEL=root\""
                               "ro"
                               "quiet"
                               "splash"
                               "radeon.si_support=0"
                               "amdgpu.si_support=1"
                               "amdgpu.dc=1"))
           (initrd "(hd0,gpt5)/boot/initrd"))))
   (keyboard-layout keyboard-layout)))

 (file-systems
  (cons* (file-system
          (mount-point "/")
          (device (file-system-label "guix-root"))
          (type "ext4"))
         (file-system
          (mount-point "/boot/efi")
          (device (uuid "04BF-EFE8" 'fat32))
          (type "vfat"))
         %base-file-systems))

 (swap-devices
  (list
   (swap-space
    (target (uuid "e14bd434-3306-43ec-bfe9-368582fe9641")))))
 
 ;; This is where user accounts are specified.  The "root"
 ;; account is implicit, and is initially created with the
 ;; empty password.
 (users (cons* (user-account
                (name "darrell")
                (comment "Darrell")
                (group "users")
                (home-directory "/home/darrell")
                (supplementary-groups
                 '("wheel" "netdev" "audio" "video" "lp")))
               %base-user-accounts))
 

 ;; Globally-installed packages.
 (packages (append (map 
                    specification->package
                    '("screen" 
                      "nss-certs" 
                      "sway" 
                      "swaylock"
		      "at-spi2-core"))
                   %base-packages))

 ;; Add services to the baseline: a DHCP client
 (services (append (list
                    fontconfig-file-system-service
                    (service sane-service-type)
                    (service cups-service-type
                             (cups-configuration
                              (auto-purge-jobs? #t)
                              (web-interface? #t)
                              (extensions
                               (list cups-filters hplip-minimal))))
                    (service cups-pk-helper-service-type)
                    (service connman-service-type
                             (connman-configuration
                              (disable-vpn? #t)))
                    (accountsservice-service)
                    (service pulseaudio-service-type)
                    (service alsa-service-type)
                    polkit-wheel-service
                    (dbus-service 
                     #:services (map specification->package
                                     '("avahi"
				       "at-spi2-core")))
                    (service avahi-service-type)
                    (service polkit-service-type)
                    (bluetooth-service #:auto-enable? #t)
                    (extra-special-file 
                     "/bin/chmod" 
                     (file-append coreutils "/bin/chmod"))
                    (extra-special-file 
                     "/bin/chgrp" 
                     (file-append coreutils "/bin/chgrp"))
                    (extra-special-file 
                     "/bin/grep" 
                     (file-append grep "/bin/grep"))
                    (udev-rules-service 'mouse-names %mouse-name-rules)
                    (udev-rules-service 'backlight %backlight-rules)
                    (elogind-service #:config 
				     (elogind-configuration
				      (handle-lid-switch-external-power 'suspend)))
                    (service wpa-supplicant-service-type 
                             (wpa-supplicant-configuration
                              (config-file (local-file "./wpa-supplicant.conf"))
                              (interface "wlp1s0")))
                    )
                   (modify-services
                    %base-services
                    (guix-service-type
                     config => (guix-configuration
                                (inherit config)
                                (substitute-urls
                                 (append (list "https://substitutes.nonguix.org")
                                         %default-substitute-urls))
                                (authorized-keys
                                 (append (list (local-file "./signing-key.pub"))
                                         %default-authorized-guix-keys)))))))

 (setuid-programs
  (cons* 
   (setuid-program
    (program 
     (file-append 
      (specification->package "swaylock") 
      "/bin/swaylock")))
   %setuid-programs)))








