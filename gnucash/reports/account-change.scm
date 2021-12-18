(define-module (gnucash report account-change))

(use-modules (gnucash engine)
	     (gnucash utilities)
	     (gnucash core-utils)
	     (gnucash app-utils)
	     (gnucash report)
	     (gnucash html)
	     (gnucash gnc-module)
	     (gnucash gettext)
	     ((wgc report-utils)
	      #:prefix wgc:))

(debug-enable 'backtrace)

(define report-id "4b1586cb3f0b4f8b99dce3258dc23362")

;; Options

(define optname-start-date (N_ "Start Date"))
(define optname-end-date (N_ "End Date"))
(define optname-account (N_ "Account"))
(define optname-show-zero-values (N_ "Show Zero Value Accounts"))
(define optname-show-ellipsis (N_ "Show Children Ellipsis"))
(define optname-max-depth (N_ "Max Depth"))

(define (options-generator)    
  (let* ((options (gnc:new-options)) 
         (add-option 
          (lambda (new-option)
            (gnc:register-option options new-option))))
    
    (add-option
     (gnc:make-date-option
      gnc:pagename-display optname-start-date
      "d" (N_ "Start Date of report.")
      (lambda () (cons 'absolute (gnc:get-start-this-month)))
      #f 'absolute #f ))

    (add-option
     (gnc:make-date-option
      gnc:pagename-display optname-end-date
      "d" (N_ "End Date of report.")
      (lambda () (cons 'absolute (gnc:get-end-this-month)))
      #f 'absolute #f ))

    (add-option
     (gnc:make-account-list-option
      gnc:pagename-display optname-account
      "g" (N_ "Report Account")
      (lambda ()
	(list
	 (wgc:find-account
	  (gnc:account-get-type-string-plural ACCT-TYPE-EXPENSE))))
      #f #f))   

    (add-option
     (gnc:make-simple-boolean-option
      gnc:pagename-display optname-show-zero-values
      "a" (N_ "Enable to show accounts with zero value.") #f))

    (add-option
     (gnc:make-simple-boolean-option
      gnc:pagename-display optname-show-ellipsis
      "a" (N_ "Show visual indicator that account has children.") #t))

    (add-option
     (gnc:make-number-range-option
      gnc:pagename-display optname-max-depth
      "ee" (N_ "Maximum Depth of sub accounts.")
      2     ;; default
      0     ;; lower bound
      10    ;; upper bound
      0     ;; number of decimals
      1     ;; step size
      ))

    (gnc:options-set-default-section options gnc:pagename-display)      
    options))


(define (account-has-value? node)
  (not (zero? (wgc:account-value node))))

(define (filter-accounts nodes show-zero-value-accounts)
  (if show-zero-value-accounts
      nodes
      (filter account-has-value? nodes)))

(define (format-extent extent)
  (let ([begin
	  (strftime "%x" (gnc-localtime (wgc:extent-begin extent)))]
	[end
	 (strftime "%x" (gnc-localtime (wgc:extent-end extent)))])
    (format #f "~a -> ~a" begin end)))

(define (account-change-renderer report-obj)
  (define (get-op section name)
    (gnc:lookup-option (gnc:report-options report-obj) section name))
  
  (define (op-value section name)
    (gnc:option-value (get-op section name)))

  (let ((start-date-val
	 (gnc:date-option-absolute-time
	  (op-value gnc:pagename-display optname-start-date)))
	(end-date-val
	 (gnc:date-option-absolute-time
	  (op-value gnc:pagename-display optname-end-date)))
	(root-account
	 (car (op-value gnc:pagename-display optname-account)))
	(show-zero-value-accounts
	 (op-value gnc:pagename-display optname-show-zero-values))
	(max-depth (op-value gnc:pagename-display optname-max-depth))
	(show-child-indicator
	 (op-value gnc:pagename-display optname-show-ellipsis))
        (document (gnc:make-html-document)))

    (gnc:html-document-set-style!
     document "body" 
     'attribute (list "style" "padding: 5px 40px"))

    (let* ((report-date-string
	    (strftime "%x %X" (gnc-localtime (current-time))))
	   (current-extent
	    (wgc:make-extent start-date-val end-date-val))
	   (previous-extent
	    (wgc:slide-extent current-extent - YearDelta)))

      (define account-change-ul
	(lambda (extent)
	  (let account-ul ([nodes (list (wgc:account-change
					 root-account
					 extent))]
			   [depth 0])
	    (if (or (= max-depth 0)
		    (< depth max-depth))
		(gnc:html-markup-ul
		 (map
		  (lambda (node)
		    (let ([value (wgc:account-value node)]
			  [children (filter-accounts
				     (wgc:account-children node)
				     show-zero-value-accounts)])
		      (if (null? children)
			  (gnc:html-markup/format
			   (G_ "~a : ~a")
			   (wgc:account-name (wgc:get-account node))
			   (gnc:html-markup-b value))
			  (gnc:html-markup/format
			   (G_ "~a : ~a ~a")
			   (wgc:account-name (wgc:get-account node))
			   (gnc:html-markup-b value)
			   (account-ul children (+ depth 1))))))
		  nodes))
		(if show-child-indicator "..." "")))))

      (gnc:html-document-set-title! document (G_ "Account Change"))
      
      (gnc:html-document-add-object!
       document
       (gnc:make-html-text         

	(gnc:html-markup-p
         (gnc:html-markup/format
          (G_ "Account: ~a") 
          (gnc:html-markup-b (wgc:account-name root-account))))

        (gnc:html-markup-p
         (gnc:html-markup/format
          (G_ "Report Time: ~a") 
          (gnc:html-markup-b report-date-string)))))


      (let ((table (gnc:make-html-table)))
	(gnc:html-table-append-row!
	 table
	 (list
	  (gnc:make-html-table-header-cell
	   (gnc:make-html-text (gnc:html-markup-b "Current")))
	  (gnc:make-html-table-header-cell
	   (gnc:make-html-text (gnc:html-markup-b "Previous")))))

	(gnc:html-table-append-row!
	 table
	 (list
	  (gnc:make-html-table-header-cell
	   (format-extent current-extent))
	  (gnc:make-html-table-header-cell
	   (format-extent previous-extent))))
	
	(gnc:html-table-append-row!
	 table
	 (list
	  (gnc:make-html-text
	   (account-change-ul current-extent))
	  (gnc:make-html-text
	   (account-change-ul previous-extent))))
	
	(gnc:html-table-set-style!
	 table
	 "th"
	 'attribute
	 (list "style"
	       (string-append
		"border-right: 1px solid black;"
		"text-align:center;"
		"padding: 5px 20px")))
	(gnc:html-table-set-style!
	 table
	 "td"
	 'attribute
	 (list
	  "style"
	  (string-append
	   "border-right: 1px solid black;"
	   "padding: 5px 20px")))
	(gnc:html-table-set-style!
	 table
	 "table"
	 'attribute
	 (list
	  "style"
	  (string-append
	   "border-top: 1px solid black;"
	   "border-bottom: 1px solid black;"
	   "border-left: 1px solid black")))
        (gnc:html-document-add-object! document table))

      document)))

(gnc:define-report
 
 'version 1
 
 'name (N_ "Account Change")

 'report-guid report-id

 'menu-name (N_ "Account Change")

 'menu-tip (N_ "Account Change Report")

 'menu-path (list gnc:menuname-income-expense)

 'options-generator options-generator
 
 'renderer account-change-renderer)
