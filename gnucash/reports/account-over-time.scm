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
  (let* ([document (gnc:make-html-document)]
         [chart (gnc:make-html-chart)]
         [acct-name "Expenses:Auto:Gas"]
         [acct (wgc:find-account acct-name)]
         [acct-2-name "Expenses:Groceries"]
         [acct-2 (wgc:find-account acct-2-name)]
         [curr (xaccAccountGetCommodity acct)]
         [num-years 2])

    (gnc:html-chart-set-title! chart "Accounts Over Time")
    (gnc:html-chart-set-type! chart 'line)
    (gnc:html-chart-set-width! chart '(pixels . 800))
    (gnc:html-chart-set-height! chart '(pixels . 600))

    (gnc:html-chart-set-currency-iso!
     chart
     (gnc-commodity-get-mnemonic curr))

    (gnc:html-chart-set-currency-symbol!
     chart
     (gnc-commodity-get-nice-symbol curr))

    (gnc:html-chart-set-y-axis-label! chart "Amount")

    (let* ([trend (wgc:account-trend
                   acct
                   (wgc:prev-year-extents 'MonthDelta num-years))]
           [trend-2 (wgc:account-trend
                     acct-2
                     (wgc:prev-year-extents 'MonthDelta num-years))])
      
      (gnc:html-chart-set-data-labels!
       chart
       (wgc:account-trend-get-data-labels trend))
      
      (gnc:html-chart-add-data-series!
       chart
       (wgc:account-name acct)
       (wgc:account-trend-get-values trend)
       (gnc:assign-colors 3)
       'border-width 1
       'fill #f)


      (gnc:html-chart-add-data-series!
       chart
       (wgc:account-name acct-2)
       (wgc:account-trend-get-values trend-2)
       (gnc:assign-colors 1)
       'border-width 1
       'fill #f))
    
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
