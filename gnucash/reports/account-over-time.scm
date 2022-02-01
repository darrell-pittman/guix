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
(define (options-generator)
  (let ([options (gnc:new-options)])
    options))

(define (account-over-time-renderer report-obj)
  (let ([document (gnc:make-html-document)]
        [chart (gnc:make-html-chart)])

    (gnc:html-document-add-object!
     document
     (gnc:make-html-text

      (gnc:html-markup-p
       (gnc:html-markup/format
        (G_ "Extents: ~a")
        (map (lambda (val)
           (format #f "Ext: ~a, Val: ~1,2f"
                   (wgc:format-extent (car val))
                   (cdr val)))
         (wgc:account-change-over-time
          (wgc:find-account "Expenses:Groceries")
          (wgc:prev-year-extents 'MonthDelta)))))

      (gnc:html-markup-p
       (gnc:html-markup/format
        (G_ "Change: ~a")
        (let* ([end (gnc:get-start-next-month)]
               [start (decdate end YearDelta)]
               [extent (wgc:make-extent start end)]
               [acct (wgc:find-account "Expenses")])
          (wgc:account-change acct extent))))))

    (gnc:html-chart-set-title! chart "Accounts Over Time")
    (gnc:html-chart-set-type! chart 'line)
    (gnc:html-chart-set-width! chart '(pixels . 800))
    (gnc:html-chart-set-height! chart '(pixels . 600))
    (gnc:html-chart-set-y-axis-label! chart "Dollars")
    
    (gnc:html-chart-set-data-labels!
     chart
     '("Jan" "Feb" "Mar" "Apr" "May" "Jun"
       "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"))
    (gnc:html-chart-add-data-series!
     chart
     "Acct 1"
     '(100 82 105 74 28 123 67 44 71 120 54 89)
     (gnc:assign-colors 3)
     'border-width 1
     'fill #f)

    (gnc:html-chart-add-data-series!
     chart
     "Acct 2"
     '(22 35 78 44 99 110 23 30 89 90 77 25)
     (gnc:assign-colors 1)
     'border-width 1
     'fill #f)
    
    (gnc:html-document-add-object! document chart)
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
