(use-modules (shepherd service)
	     (ice-9 ftw))

;; Load all .scm files in init.d directory

(for-each
 (lambda (file)
   (load (string-append "init.d/" file)))
 (scandir (string-append (dirname (current-filename)) "/init.d")
	  (lambda (file)
	    (string-suffix? ".scm" file))))

(action 'shepherd 'daemonize)
