(define (uarps:optimize prog types)
  (define (opt-fundef fundef)
    (let ((body (cadddr fundef)) (parlist (cadr fundef)) (fname (car fundef)))
      (let ((%%76 (assq fname types)))
        (let ((partypes (cdr %%76)))
          (let ((%%77 (split-par* parlist partypes)))
            (let ((exp* (cdr %%77)) (new-parlist (car %%77)))
              (let ((%%78 (opt-exp body parlist exp*)))
                (let ((new-body %%78))
                  `(,fname ,new-parlist = ,new-body)))))))))
  (define (opt-exp exp vn vv)
    (cond ((symbol? exp) (lookup-variable exp vn vv))
          ((equal? (car exp) 'quote) exp)
          ((equal? (car exp) 'car)
           (let ((exp1 (cadr exp))) (opt-car (opt-exp exp1 vn vv))))
          ((equal? (car exp) 'cdr)
           (let ((exp1 (cadr exp))) (opt-cdr (opt-exp exp1 vn vv))))
          ((equal? (car exp) 'pair?)
           (let ((exp1 (cadr exp))) (opt-pair? (opt-exp exp1 vn vv))))
          ((equal? (car exp) 'cons)
           (let ((exp2 (caddr exp)) (exp1 (cadr exp)))
             (opt-cons (opt-exp exp1 vn vv) (opt-exp exp2 vn vv))))
          ((equal? (car exp) 'equal?)
           (let ((exp2 (caddr exp)) (exp1 (cadr exp)))
             (opt-equal? (opt-exp exp1 vn vv) (opt-exp exp2 vn vv))))
          ((equal? (car exp) 'if)
           (let ((exp3 (cadddr exp)) (exp2 (caddr exp)) (exp1 (cadr exp)))
             (opt-if (opt-exp exp1 vn vv) exp2 exp3 vn vv)))
          ((equal? (car exp) 'call)
           (let ((exp* (cddr exp)) (fname (cadr exp)))
             (let ((%%79 (assq fname types)))
               (let ((arg-types (cdr %%79)))
                 (let ((%%80 (opt-exp* exp* vn vv)))
                   (let ((exp* %%80))
                     `(call ,fname unquote (split-arg* exp* arg-types))))))))
          ((equal? (car exp) 'xcall)
           (let ((exp* (cddr exp)) (fname (cadr exp)))
             `(xcall ,fname unquote (opt-exp* exp* vn vv))))
          (else
           (let ((exp* (cdr exp)) (fname (car exp)))
             `(,fname unquote (opt-exp* exp* vn vv))))))
  (define (opt-exp* exp* vn vv) (map (lambda (exp) (opt-exp exp vn vv)) exp*))
  (define (opt-car exp)
    (cond ((and (pair? exp)
                (equal? (car exp) 'quote)
                (pair? (cdr exp))
                (pair? (cadr exp))
                (null? (cddr exp)))
           (let ((c2 (cdadr exp)) (c1 (caadr exp))) `',c1))
          ((and (pair? exp)
                (equal? (car exp) 'cons)
                (pair? (cdr exp))
                (pair? (cddr exp))
                (null? (cdddr exp)))
           (let ((e2 (caddr exp)) (e1 (cadr exp))) e1))
          (else `(car ,exp))))
  (define (opt-cdr exp)
    (cond ((and (pair? exp)
                (equal? (car exp) 'quote)
                (pair? (cdr exp))
                (pair? (cadr exp))
                (null? (cddr exp)))
           (let ((c2 (cdadr exp)) (c1 (caadr exp))) `',c2))
          ((and (pair? exp)
                (equal? (car exp) 'cons)
                (pair? (cdr exp))
                (pair? (cddr exp))
                (null? (cdddr exp)))
           (let ((e2 (caddr exp)) (e1 (cadr exp))) e2))
          (else `(cdr ,exp))))
  (define (opt-pair? exp)
    (cond ((and (pair? exp)
                (equal? (car exp) 'quote)
                (pair? (cdr exp))
                (null? (cddr exp)))
           (let ((c (cadr exp))) `',(pair? c)))
          ((and (pair? exp)
                (equal? (car exp) 'cons)
                (pair? (cdr exp))
                (pair? (cddr exp))
                (null? (cdddr exp)))
           (let ((e2 (caddr exp)) (e1 (cadr exp))) ''#t))
          (else `(pair? ,exp))))
  (define (opt-cons exp1 exp2)
    (if (and (pair? exp1)
             (equal? (car exp1) 'quote)
             (pair? (cdr exp1))
             (null? (cddr exp1))
             (pair? exp2)
             (equal? (car exp2) 'quote)
             (pair? (cdr exp2))
             (null? (cddr exp2)))
      (let ((c2 (cadr exp2)) (c1 (cadr exp1))) `'(,c1 unquote c2))
      `(cons ,exp1 ,exp2)))
  (define (opt-equal? exp1 exp2)
    (if (and (pair? exp1)
             (equal? (car exp1) 'quote)
             (pair? (cdr exp1))
             (null? (cddr exp1))
             (pair? exp2)
             (equal? (car exp2) 'quote)
             (pair? (cdr exp2))
             (null? (cddr exp2)))
      (let ((c2 (cadr exp2)) (c1 (cadr exp1))) `',(equal? c1 c2))
      `(equal? ,exp1 ,exp2)))
  (define (opt-if cnd exp1 exp2 vn vv)
    (if (and (pair? cnd)
             (equal? (car cnd) 'quote)
             (pair? (cdr cnd))
             (null? (cddr cnd)))
      (let ((c (cadr cnd))) (if c (opt-exp exp1 vn vv) (opt-exp exp2 vn vv)))
      `(if ,cnd ,(opt-exp exp1 vn vv) ,(opt-exp exp2 vn vv))))
  (define (split-par* par* type*)
    (if (and (null? par*) (null? type*))
      '(())
      (let ((r-type* (cdr type*))
            (type (car type*))
            (r-par* (cdr par*))
            (par (car par*)))
        (let ((%%81 (split-par* r-par* r-type*)))
          (let ((exp* (cdr %%81)) (names (car %%81)))
            (let ((%%82 (split-par par type names)))
              (let ((exp (cdr %%82)) (names (car %%82)))
                `(,names ,exp unquote exp*))))))))
  (define (split-par par type names)
    (if (or (eq? type 'absent) (eq? type 'any))
      `((,par unquote names) unquote par)
      (let ((%%83 (count-gaps type)))
        (let ((maxnum %%83))
          (let ((%%84 (gen-new-names par 1 maxnum names)))
            (let ((names %%84))
              (let ((%%85 (type-to-exp names type)))
                (let ((exp (car %%85))) `(,names unquote exp)))))))))
  (define (count-gaps type)
    (cond ((equal? type 'absent) 1)
          ((equal? type 'any) 1)
          ((equal? (car type) 'atom) 0)
          ((equal? (car type) 'cons)
           (let ((t2 (caddr type)) (t1 (cadr type)))
             (+ (count-gaps t1) (count-gaps t2))))
          (else (error "SELECT: no match for" type))))
  (define (gen-new-names var num maxnum names)
    (if (> num maxnum)
      names
      `(,(string->symbol
           (string-append (symbol->string var) "-$" (number->string num)))
        unquote
        (gen-new-names var (+ 1 num) maxnum names))))
  (define (type-to-exp names type)
    (cond ((equal? type 'absent) names)
          ((equal? type 'any) names)
          ((equal? (car type) 'atom)
           (let ((a (cadr type))) `(',a unquote names)))
          ((equal? (car type) 'cons)
           (let ((t2 (caddr type)) (t1 (cadr type)))
             (let ((%%86 (type-to-exp names t1)))
               (let ((names (cdr %%86)) (e1 (car %%86)))
                 (let ((%%87 (type-to-exp names t2)))
                   (let ((names (cdr %%87)) (e2 (car %%87)))
                     `(,(opt-cons e1 e2) unquote names)))))))
          (else (error "SELECT: no match for" type))))
  (define (split-arg* arg* type*)
    (if (and (null? arg*) (null? type*))
      '()
      (let ((r-type* (cdr type*))
            (type (car type*))
            (r-arg* (cdr arg*))
            (arg (car arg*)))
        (let ((exp* (split-arg* r-arg* r-type*))) (split-arg arg type exp*)))))
  (define (split-arg arg type exp*)
    (cond ((equal? type 'absent) `(,arg unquote exp*))
          ((equal? type 'any) `(,arg unquote exp*))
          ((equal? (car type) 'atom) exp*)
          ((equal? (car type) 'cons)
           (let ((t2 (caddr type)) (t1 (cadr type)))
             (let ((exp* (split-arg (opt-cdr arg) t2 exp*)))
               (split-arg (opt-car arg) t1 exp*))))
          (else (error "SELECT: no match for" type))))
  (define (lookup-variable vname vn vv)
    (if (and (null? vn) (null? vv))
      (error "Undefined variable" vname)
      (let ((vrest (cdr vv)) (vv (car vv)) (nrest (cdr vn)) (vn (car vn)))
        (if (eq? vname vn) vv (lookup-variable vname nrest vrest)))))
  (map opt-fundef prog))

