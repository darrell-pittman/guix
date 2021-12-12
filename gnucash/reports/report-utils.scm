(define-module (wgc report-utils)
  #:use-module (gnucash engine)
  #:use-module (gnucash utilities)
  #:use-module (gnucash gnc-module)
  #:export (account-change
	    account-value
	    get-account
	    account-name
	    account-children
	    visit-account
	    find-account))

(gnc:module-load "gnucash/report/report-system" 0)
(gnc:module-load "gnucash/html" 0) ;for gnc-build-url

(define account-value cdar)
(define get-account caar)
(define account-children cdr)
(define account-name xaccAccountGetName)

(define visit-account
  (lambda (root init visitor)
    (call/cc
     (lambda (k)
       (let $visit-account ([root root] [init init])
	 (let loop ([children (gnc-account-get-children root)]
		    [acc (visitor root init k)])
	   (if (null? children)
	       acc
	       (loop
		(cdr children)
		($visit-account (car children) acc)))))))))

(define find-account
  (case-lambda
    [(needle) (find-account needle (gnc-get-current-root-account))]
    [(needle root) (visit-account
		    root
		    #f
		    (lambda (acct val k)
		      (let ([name (gnc-account-get-full-name acct)])
			(if (string= name needle)
			    (k acct)
			    #f))))]))


(define account-change
  (lambda (root start-date end-date)

    (define change
      (lambda (acct)
	(- (xaccAccountGetBalanceAsOfDate acct end-date)
	   (xaccAccountGetBalanceAsOfDate acct start-date))))

    (define loop-children
      (lambda (parent children)
	(if (null? children)
	    '()
	    (let ([child (account-change (car children) start-date end-date)])
	      (set-cdr! parent (+ (cdr parent) (account-value child)))
	      (cons child (loop-children parent (cdr children)))))))

    (define make-node
      (lambda (acct)
	(let ([node (cons acct (change acct))])
	  (cons node (loop-children node (gnc-account-get-children-sorted acct))))))

    (make-node root)))
