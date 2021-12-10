(use-modules (web client)
	     (json)
	     (rnrs bytevectors)
	     (srfi srfi-1)
	     (srfi srfi-26))

(define geoclue-uri
  "https://location.services.mozilla.com/v1/geolocate?key=geoclue")

(define-json-type <coords>
  (lat)
  (lng))

(define-json-type <location>
  (accuracy)
  (location "location" <coords>))

(define (location)
  (let* ((req (lambda () (http-get geoclue-uri #:decode-body? #t)))
	 (resp (lambda (_ contents) (utf8->string contents)))
	 (json-string (call-with-values req resp)))
    (json->location json-string)))


(define (format-location location-rec)
  (let* ((loc (location-location location-rec))
	 (lat (coords-lat loc))
	 (lng (coords-lng loc)))
    (format #f "~a:~a" lat lng)))


(define redshift
  (make <service>
    #:provides '(redshift)
    #:docstring "Redshift service"
    #:start (make-forkexec-constructor
	     (list "redshift"
		   "-m"
		   "wayland"
		   "-l"
		   (format-location (location))))
    #:stop (make-kill-destructor)
    #:respawn? #t))

(register-services redshift)

(start redshift)
