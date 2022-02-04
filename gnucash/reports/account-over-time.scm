(define-module (wgc report account-over-time)
  #:use-module (gnucash engine)
  #:use-module (gnucash utilities) 
  #:use-module (gnucash core-utils)
  #:use-module (gnucash app-utils) 
  #:use-module (gnucash report)    
  #:use-module (gnucash html)      
  #:use-module (gnucash gnc-module)
  #:use-module (gnucash gettext)
  #:use-module ((wgc report utils)
                #:prefix wgc:))


(debug-enable 'backtrace)

(define report-id "6bcfb789835440d58a2dff2c5493c1d9")

;; Options
(define optname-account (N_ "Account"))
(define optname-num-years (N_ "Num Years"))
(define optname-delta (N_ "Sample Delta"))
(define optname-show-table (N_ "Show Table"))

(define (options-generator)
  (let* ([options (gnc:new-options)]
         [add-option 
          (lambda (new-option)
            (gnc:register-option options new-option))])

    (add-option
     (gnc:make-account-list-limited-option
      gnc:pagename-display optname-account
      "g"
      (N_ "Report Account")
      (lambda ()
	(list
	 (wgc:find-account
	  (gnc:account-get-type-string-plural ACCT-TYPE-EXPENSE))))
      #f
      #t
      (list ACCT-TYPE-EXPENSE)))

    (add-option
     (gnc:make-number-range-option
      gnc:pagename-display optname-num-years
      "ee" (N_ "Number of years to report.")
      1     ;; default
      1     ;; lower bound
      3    ;; upper bound
      0     ;; number of decimals
      1     ;; step size
      ))

    (add-option
     (gnc:make-multichoice-option
      gnc:pagename-display optname-delta
      "b"
      (N_ "Time gap between data samples")
      'MonthDelta
      (list (vector 'MonthDelta (N_ "Month"))
            (vector 'WeekDelta (N_ "Week")))))

    (add-option
     (gnc:make-simple-boolean-option
      gnc:pagename-display optname-show-table
      "a" (N_ "Show values in table.") #t))
    
    (gnc:options-set-default-section options gnc:pagename-display)
    options))

(define (make-value-cell val)
  (let ([cell (gnc:make-html-table-cell
               (gnc:make-html-text
                (format #f "~1,2f" val)))])
    (gnc:html-table-cell-set-style!
     cell
     "td"
     'attribute
     '("style" "text-align:right"))
    cell))

(define (account-over-time-renderer report-obj)
  (define (get-op section name)
    (gnc:lookup-option (gnc:report-options report-obj) section name))
  
  (define (op-value section name)
    (gnc:option-value (get-op section name)))

  (let* ([document (gnc:make-html-document)]
         [chart (gnc:make-html-chart)]
         [table (gnc:make-html-table)]
         [accounts (op-value gnc:pagename-display optname-account)]
         [num-years (op-value gnc:pagename-display optname-num-years)]
         [show-table (op-value gnc:pagename-display optname-show-table)]
         [delta (op-value gnc:pagename-display optname-delta)]
         [extents (wgc:prev-year-extents delta num-years)]
         [colours (wgc:random-colours (length accounts))])
    
    (gnc:html-chart-set-title! chart "Accounts Over Time")
    (gnc:html-chart-set-type! chart 'line)
    (gnc:html-chart-set! chart '(options ticks min) 0)
    ;;(gnc:html-chart-set-width! chart '(pixels . 800))
    ;;(gnc:html-chart-set-height! chart '(pixels . 600))

    (gnc:html-chart-set-y-axis-label! chart "Amount")

    (gnc:html-table-set-style!
     table "table"
     'attribute (list "border" 1)
     'attribute (list "width" "") 
     'attribute (list "align" "center")
     'attribute (list "valign" "top")
     'attribute (list "cellspacing" 0)
     'attribute (list "cellpadding" 5))
    
    (let loop ([accounts accounts]
               [iter 0]
               [colours colours])
      (unless (null? accounts)
        (let* ([acct (car accounts)]
               [trend (wgc:account-trend acct extents)])
          (when (zero? iter)
            (let ([curr (xaccAccountGetCommodity acct)])
              (gnc:html-chart-set-currency-iso!
               chart
               (gnc-commodity-get-mnemonic curr))

              (gnc:html-chart-set-currency-symbol!
               chart
               (gnc-commodity-get-nice-symbol curr))

              (let ([labels (wgc:account-trend-get-data-labels trend)])
                (gnc:html-chart-set-data-labels!
                 chart
                 labels)


                (gnc:html-table-append-row!
                 table
                 (map (lambda (lbl)
                        (gnc:make-html-table-header-cell
                         (gnc:make-html-text
                          (gnc:html-markup-b lbl))))
                      (append (cons "Account" labels) '("Total")))))))

          (let* ([vals (wgc:account-trend-get-values trend)]
                 [total (apply + vals)])
            
            (gnc:html-chart-add-data-series!
             chart
             (wgc:account-name acct)
             (wgc:account-trend-get-values trend)
             (car colours)
             'border-width 1
             'fill #f)

            (gnc:html-table-append-row!
             table
             (cons (gnc:make-html-table-cell
                    (gnc:make-html-text
                     (gnc:html-markup-b (wgc:account-name acct))))
                   (map make-value-cell
                        (append vals (list total))))))

          (loop (cdr accounts)
                (1+ iter)
                (cdr colours)))))
    
    (gnc:html-document-add-object! document chart)
    
    (when show-table
      (gnc:html-document-add-object! document table))
    
    document))

(gnc:define-report
 
 'version 1
 
 'name (N_ "Accounts Over Time")

 'report-guid report-id

 'menu-name (N_ "Accounts Over Time")

 'menu-tip (N_ "Accounts Over Time Report")

 'menu-path (list gnc:menuname-income-expense)

 'options-generator options-generator
 
 'renderer account-over-time-renderer)
