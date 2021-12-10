(define pulseaudio
  (make <service>
    #:provides '(pulseaudio)
    #:docstring "Pulseaudio service"
    #:start (make-forkexec-constructor
	     '("pulseaudio"
	       "--exit-idle-time=-1"))
    #:stop (make-kill-destructor)
    #:respawn? #t))

(register-services pulseaudio)

(start pulseaudio)
