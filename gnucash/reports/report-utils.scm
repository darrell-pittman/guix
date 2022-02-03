(define-module (wgc report utils)
  #:use-module (gnucash engine)
  #:use-module (gnucash utilities)
  #:use-module (gnucash app-utils)
  #:use-module (gnucash gnc-module)
  #:use-module (srfi srfi-9)
  #:use-module (srfi srfi-1)
  #:export (account-change
            account-change-rec-extent
            account-change-rec-node
            account-node-acct
            account-node-change
            account-node-children
	    account-name
	    visit-account
	    find-account
	    make-extent
	    slide-extent
	    extent-begin
	    extent-end
            prev-year-extents
            format-extent
            account-trend
            extent-collection-delta
            extent-collection-extents
            extent-change-extent
            extent-change-change
            account-trend-get-data-labels
            account-trend-get-values))

(gnc:module-load "gnucash/report/report-system" 0)
(gnc:module-load "gnucash/html" 0) ;for gnc-build-url

(define account-name xaccAccountGetName)

(define-record-type <extent>
  (make-extent begin end)
  extent?
  (begin extent-begin)
  (end extent-end))

(define-record-type <extent-collection>
  (make-extent-collection delta extents)
  extent-collection?
  (delta extent-collection-delta)
  (extents extent-collection-extents))

(define-record-type <extent-change>
  (make-extent-change extent change)
  extent-change?
  (extent extent-change-extent)
  (change extent-change-change))

(define-record-type <account-trend>
  (make-account-trend acct delta vals)
  account-trend?
  (acct account-trend-acct)
  (delta account-trend-delta)
  (vals account-trend-vals))

(define-record-type <account-node>
  (make-account-node acct change children)
  account-node?
  (acct account-node-acct)
  (change account-node-change)
  (children account-node-children))

(define-record-type <account-change-rec>
  (make-account-change-rec extent node)
  account-change-node?
  (extent account-change-rec-extent)
  (node account-change-rec-node))

(define (date-mode-method op)
  (cond
   [(eq? op -) decdate]
   [(eq? op +) incdate]))

(define (slide-extent extent op delta)
  (let ([moddate (date-mode-method op)])
    (make-extent
     (moddate (extent-begin extent) delta)
     (moddate (extent-end extent) delta))))

(define (adjust-account-change-extent extent)
  (let ([begin (gnc:time64-end-day-time
		(gnc:time64-previous-day (extent-begin extent)))]
	[end (gnc:time64-end-day-time (extent-end extent))])
    (make-extent begin end)))

(define (visit-account root init visitor)
  (call/cc
   (lambda (k)
     (let $visit-account ([root root] [init init])
       (let loop ([children (gnc-account-get-children root)]
		  [acc (visitor root init k)])
	 (if (null? children)
	     acc
	     (loop
	      (cdr children)
	      ($visit-account (car children) acc))))))))

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

(define (account-change root extent)
  (let* ([adjusted (adjust-account-change-extent extent)]
	 [start-date (extent-begin adjusted)]
	 [end-date (extent-end adjusted)])

    (define (change acct)
      (- (xaccAccountGetBalanceAsOfDate acct end-date)
	 (xaccAccountGetBalanceAsOfDate acct start-date)))

    (define (loop-children children)
      (if (null? children)
	  '()
	  (let ([child (make-node (car children))])
	    (cons child (loop-children (cdr children))))))

    (define (make-node acct)
      (let ([children (loop-children
                       (gnc-account-get-children-sorted acct))])
        (make-account-node
         acct
         (+ (change acct)
            (fold (lambda (child amt)
                    (+ amt (account-node-change child)))
                  0
                  children))
         children)))

    (make-account-change-rec adjusted (make-node root))))

(define (make-extents start-date number delta)
  (if (zero? number)
      '()
      (let ([next-start-date (incdate start-date delta)])
        (cons (make-extent start-date
                           (decdate next-start-date DayDelta))
              (make-extents next-start-date
                            (1- number)
                            delta)))))

(define (extent->account-value acct)
  (lambda (extent)
    (account-node-change
     (account-change-rec-node
      (account-change acct extent)))))

(define (extent-value acct)
  (let ([value-fn (extent->account-value acct)])
    (lambda (extent)
      (make-extent-change
       extent
       (value-fn extent)))))

(define (account-trend acct extent-coll)
  (make-account-trend
   acct
   (extent-collection-delta extent-coll)
   (map (extent-value acct)
        (extent-collection-extents extent-coll))))

(define* (prev-year-start-date #:optional (num-years 1))
  (let loop ([num-years num-years]
             [dt (decdate (gnc:get-start-next-month) YearDelta)])
    (if (<= num-years 1)
        dt
        (loop (1- num-years)
              (decdate dt YearDelta)))))

(define (delta->num-extents delta)
  (case delta
    ((MonthDelta) 12)
    ((WeekDelta) 52)
    (else (raise-exception 'invalid-delta))))

(define* (prev-year-extents delta #:optional (num-years 1))
  (make-extent-collection
   delta
   (make-extents
    (prev-year-start-date num-years)
    (* (delta->num-extents delta) num-years)
    (eval delta (interaction-environment)))))

(define (format-extent extent)
  (let ([begin
	  (strftime "%x" (gnc-localtime (extent-begin extent)))]
	[end
	 (strftime "%x" (gnc-localtime (extent-end extent)))])
    (format #f "~a -> ~a" begin end)))

(define (month->string month)
  (case month
    [(1) "Jan"]
    [(2) "Feb"]
    [(3) "Mar"]
    [(4) "Apr"]
    [(5) "May"]
    [(6) "Jun"]
    [(7) "Jul"]
    [(8) "Aug"]
    [(9) "Sep"]
    [(10) "Oct"]
    [(11) "Nov"]
    [(12) "Dec"]
    [else (raise-exception 'invalid-month)]))

(define (account-trend-get-data-labels acct-trend)
  (let ([converter
         (case (account-trend-delta acct-trend)
           [(MonthDelta) (lambda (start)
                           (month->string
                            (gnc:time64-get-month start)))]
           [(WeekDelta) (lambda (start)
                          (number->string
                           (1+ (modulo
                                (- (gnc:time64-get-week start) 9)
                                52))))]
           [else (raise-exception 'invalid-delta)])])
    (map (lambda (extent-change)
           (let ([start (extent-begin
                         (extent-change-extent extent-change))])
             (converter start)))
         (account-trend-vals acct-trend))))

(define (account-trend-get-values acct-trend)
  (map (lambda (extent-change)
         (extent-change-change extent-change))
       (account-trend-vals acct-trend)))
