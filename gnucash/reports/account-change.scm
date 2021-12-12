;; -*-scheme-*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of
;; the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, contact:
;;
;; Free Software Foundation           Voice:  +1-617-542-5942
;; 51 Franklin Street, Fifth Floor    Fax:    +1-617-542-2652
;; Boston, MA  02110-1301,  USA       gnu@gnu.org
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(define-module (gnucash report account-change))


(use-modules (gnucash engine)
	     (gnucash utilities)
	     (gnucash core-utils)
	     (gnucash app-utils)
	     (gnucash report)
	     (gnucash html)
	     (gnucash gnc-module)
	     (gnucash gettext)
	     (wgc report-utils))

(debug-enable 'backtrace)

(gnc:module-load "gnucash/report/report-system" 0)
(gnc:module-load "gnucash/html" 0) ;for gnc-build-url

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
      (lambda () (list (find-account (gnc:account-get-type-string-plural ACCT-TYPE-EXPENSE))))
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

(define get-account caar)
(define account-value cdar)
(define account-children cdr)
(define account-name xaccAccountGetName)

(define (account-has-value? node)
  (not (zero? (account-value node))))

(define (filter-accounts nodes show-zero-value-accounts)
  (if show-zero-value-accounts
      nodes
      (filter account-has-value? nodes)))

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

(define (account-change-renderer report-obj)
  (define (get-op section name)
    (gnc:lookup-option (gnc:report-options report-obj) section name))
  
  (define (op-value section name)
    (gnc:option-value (get-op section name)))

  (let ((start-date-val
	 (gnc:date-option-absolute-time
	  (op-value gnc:pagename-display optname-start-date)))
	(end-date-val
	 (gnc:time64-end-day-time
	  (gnc:date-option-absolute-time
	   (op-value gnc:pagename-display optname-end-date))))
	(root-account (car (op-value gnc:pagename-display optname-account)))
	(show-zero-value-accounts
	 (op-value gnc:pagename-display optname-show-zero-values))
	(max-depth (op-value gnc:pagename-display optname-max-depth))
	(show-child-indicator
	 (op-value gnc:pagename-display optname-show-ellipsis))
        (document (gnc:make-html-document)))

    (gnc:html-document-set-style!
     document "body" 
     'attribute (list "style" "padding: 5px 40px"))

    (let* ((check-date-val
	    (gnc:time64-end-day-time
	     (gnc:time64-previous-day start-date-val)))
	   (report-time-string (strftime "%X" (gnc-localtime (current-time))))
	   (report-date-string (strftime "%x" (gnc-localtime (current-time))))
           (start-date-string (strftime "%x" (gnc-localtime start-date-val)))
	   (end-date-string (strftime "%x" (gnc-localtime end-date-val)))
	   (check-date-val-prev (decdate check-date-val YearDelta))
	   (end-date-val-prev (decdate end-date-val YearDelta)))

      (define account-change-ul
	(lambda (check-date end-date)
	  (let account-ul ([nodes (list (account-change root-account
							check-date
							end-date))]
			   [depth 0])
	    (if (or (= max-depth 0)
		    (< depth max-depth))
		(gnc:html-markup-ul
		 (map
		  (lambda (node)
		    (let ([value (account-value node)]
			  [children (filter-accounts
				     (account-children node)
				     show-zero-value-accounts)])
		      (if (null? children)
			  (gnc:html-markup/format
			   (G_ "~a : ~a")
			   (account-name (get-account node))
			   (gnc:html-markup-b value))
			  (gnc:html-markup/format
			   (G_ "~a : ~a ~a")
			   (account-name (get-account node))
			   (gnc:html-markup-b value)
			   (account-ul children (+ depth 1))))))
		  nodes))
		(if show-child-indicator "..." "")))))

      (gnc:html-document-set-title! document (G_ "Account Change"))
      
      (gnc:html-document-add-object!
       document
       (gnc:make-html-text         

	(gnc:html-markup-p
	 (wgc-test))
	
	(gnc:html-markup-p
         (gnc:html-markup/format
          (G_ "Account: ~a") 
          (gnc:html-markup-b (account-name root-account))))

        (gnc:html-markup-p
         (gnc:html-markup/format
          (G_ "Report Time: ~a") 
          (gnc:html-markup-b
	   (string-append report-date-string " " report-time-string))))

        (gnc:html-markup-p
         (gnc:html-markup/format
          (G_ "Start Date: ~a") 
          (gnc:html-markup-b start-date-string)))

	(gnc:html-markup-p
         (gnc:html-markup/format
          (G_ "End Date: ~a") 
          (gnc:html-markup-b end-date-string)))))


      (let ((table (gnc:make-html-table)))
	(gnc:html-table-append-row! table (list
					   (gnc:make-html-table-header-cell (gnc:make-html-text (gnc:html-markup-b "Current")))
					   (gnc:make-html-table-header-cell (gnc:make-html-text (gnc:html-markup-b "Previous")))))
	(gnc:html-table-append-row! table
				    (list
				     (gnc:make-html-text
				      (account-change-ul check-date-val end-date-val))
				     (gnc:make-html-text
				      (account-change-ul check-date-val-prev end-date-val-prev))))

	(gnc:html-table-set-style! table "th"
				   'attribute (list "style" "border-right: 1px solid black;text-align:center; padding: 5px 20px"))
	(gnc:html-table-set-style! table "td"
				   'attribute (list "style" "border-right: 1px solid black;padding: 5px 20px"))
	(gnc:html-table-set-style! table "table"
				   'attribute (list "style" "border-top: 1px solid black; border-bottom: 1px solid black; border-left: 1px solid black"))
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
