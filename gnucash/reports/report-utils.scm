(define-module (wgc report-utils)
  #:use-module (gnucash engine)
  #:export (test-function
	    account-change
	    account-value))

(define account-value cdar)

(define (test-function)
  "This is a test")

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
