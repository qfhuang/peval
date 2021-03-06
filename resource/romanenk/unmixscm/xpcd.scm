(define (upcd:prevent-call-duplication! prog)
  (define (pcd-loop! prog)
    (display "Abstract Call Interpretation... Iterations: ")
    (let ((descr (abstract-call-interpretation prog)))
      (newline)
      (let ((program-modified? (make-rcall-prog! prog descr)))
        (if program-modified?
          (begin
            (display "Some \"call(s)\" has (have) been replaced with \"rcall(s)\"")
            (newline)
            (pcd-loop! prog))
          (begin
            (display "There is no call duplication risk")
            (newline)
            prog)))))
  (define (abstract-call-interpretation prog)
    (define descr #f)
    (define descr-modified? #f)
    (define (collect-c-args-prog!)
      (for-each
        (lambda (fundef)
          (let ((body (car (cddddr fundef)))
                (dvn (caddr fundef))
                (svn (cadr fundef))
                (fname (car fundef)))
            (let ((%%100 (assq fname descr)))
              (let ((dvv (cadr %%100))) (collect-c-args! body dvn dvv)))))
        prog))
    (define (collect-c-args! exp vn vv)
      (cond ((symbol? exp) #f)
            ((equal? (car exp) 'static) #f)
            ((equal? (car exp) 'ifs)
             (let ((exp* (cddr exp))) (collect-c-args*! exp* vn vv)))
            ((equal? (car exp) 'ifd)
             (let ((exp* (cdr exp))) (collect-c-args*! exp* vn vv)))
            ((equal? (car exp) 'call)
             (let ((d-exp* (cadddr exp))
                   (s-exp* (caddr exp))
                   (fname (cadr exp)))
               (let ((descr (collect-c-args*! d-exp* vn vv))
                     (arg* (c-eval* d-exp* vn vv descr)))
                 (update-c-args! fname arg*))))
            ((equal? (car exp) 'rcall)
             (let ((d-exp* (cadddr exp))
                   (s-exp* (caddr exp))
                   (fname (cadr exp)))
               (collect-c-args*! d-exp* vn vv)))
            ((equal? (car exp) 'xcall)
             (let ((exp* (cddr exp)) (fname (cadr exp)))
               (collect-c-args*! exp* vn vv)))
            (else
             (let ((exp* (cdr exp)) (op (car exp)))
               (collect-c-args*! exp* vn vv)))))
    (define (collect-c-args*! exp* vn vv)
      (for-each (lambda (exp) (collect-c-args! exp vn vv)) exp*))
    (define (collect-c-results-prog!)
      (map (lambda (fundef)
             (let ((body (car (cddddr fundef)))
                   (dvn (caddr fundef))
                   (svn (cadr fundef))
                   (fname (car fundef)))
               (let ((%%101 (assq fname descr)))
                 (let ((dvv (cadr %%101)))
                   (let ((%%102 (c-eval body dvn dvv descr)))
                     (let ((res %%102)) (update-c-result! fname res)))))))
           prog))
    (define (initial-c-descr)
      (map (lambda (fundef)
             (let ((dvn (caddr fundef))
                   (svn (cadr fundef))
                   (fname (car fundef)))
               `(,fname ,(map (lambda (par) 'e) dvn) . e)))
           prog))
    (define (update-c-args! fname args)
      (let ((%%103 (assq fname descr)))
        (let ((fdescr (cdr %%103)))
          (let ((res1 (cdr fdescr)) (args1 (car fdescr)))
            (let ((%%104 (lub* args args1)))
              (let ((lub-args %%104))
                (if (not (equal? lub-args args1))
                  (begin
                    (set-car! fdescr lub-args)
                    (set! descr-modified? #t)))))))))
    (define (update-c-result! fname res)
      (let ((%%105 (assq fname descr)))
        (let ((fdescr (cdr %%105)))
          (let ((res1 (cdr fdescr)) (args1 (car fdescr)))
            (let ((%%106 (lub res res1)))
              (let ((lub-res %%106))
                (if (not (equal? lub-res res1))
                  (begin
                    (set-cdr! fdescr lub-res)
                    (set! descr-modified? #t)))))))))
    (set! descr (initial-c-descr))
    (let recalc-c-descr ()
      (display "*")
      (set! descr-modified? #f)
      (collect-c-args-prog!)
      (collect-c-results-prog!)
      (if descr-modified? (recalc-c-descr) descr)))
  (define (c-eval exp vn vv descr)
    (cond ((symbol? exp) (lookup-variable exp vn vv))
          ((equal? (car exp) 'static) 'e)
          ((equal? (car exp) 'ifs)
           (let ((exp* (cddr exp))) (lub-list (c-eval* exp* vn vv descr))))
          ((equal? (car exp) 'ifd)
           (let ((exp* (cdr exp))) (lub-list (c-eval* exp* vn vv descr))))
          ((equal? (car exp) 'call)
           (let ((d-exp* (cadddr exp)) (s-exp* (caddr exp)) (fname (cadr exp)))
             (let ((%%107 (assq fname descr)))
               (let ((res (cddr %%107)))
                 (lub res (lub-list (c-eval* d-exp* vn vv descr)))))))
          ((equal? (car exp) 'rcall)
           (let ((d-exp* (cadddr exp)) (s-exp* (caddr exp)) (fname (cadr exp)))
             'c))
          ((equal? (car exp) 'xcall)
           (let ((exp* (cddr exp)) (fname (cadr exp)))
             (lub-list (c-eval* exp* vn vv descr))))
          (else
           (let ((exp* (cdr exp)) (op (car exp)))
             (lub-list (c-eval* exp* vn vv descr))))))
  (define (c-eval* exp* vn vv descr)
    (map (lambda (exp) (c-eval exp vn vv descr)) exp*))
  (define (lookup-variable vname vn vv)
    (if (and (null? vn) (null? vv))
      (error "Undefined variable: " vname)
      (let ((vrest (cdr vv)) (vv (car vv)) (nrest (cdr vn)) (vn (car vn)))
        (if (eq? vname vn) vv (lookup-variable vname nrest vrest)))))
  (define (lub ind1 ind2) (if (eq? ind1 'c) 'c ind2))
  (define (lub* ind1* ind2*) (map lub ind1* ind2*))
  (define (lub-list ind*) (if (memq 'c ind*) 'c 'e))
  (define (make-rcall-prog! prog descr)
    (define dupl #f)
    (define program-modified? #f)
    (define (make-rcall-func*!)
      (for-each (lambda (fundef) (make-rcall-func! fundef)) prog))
    (define (make-rcall-func! fundef)
      (let ((body (car (cddddr fundef)))
            (dvn (caddr fundef))
            (svn (cadr fundef))
            (fname (car fundef)))
        (let ((%%108 (assq fname descr)))
          (let ((dvv (cadr %%108))) (make-rcall! body dvn dvv)))))
    (define (make-rcall! exp vn vv)
      (cond ((symbol? exp) '())
            ((equal? (car exp) 'static) '())
            ((equal? (car exp) 'ifs)
             (let ((exp* (cddr exp))) (make-rcall*! exp* vn vv)))
            ((equal? (car exp) 'ifd)
             (let ((exp* (cdr exp))) (make-rcall*! exp* vn vv)))
            ((equal? (car exp) 'call)
             (let ((d-exp* (cadddr exp))
                   (s-exp* (caddr exp))
                   (fname (cadr exp)))
               (make-rcall*! d-exp* vn vv)
               (let ((d-arg* (c-eval* d-exp* vn vv descr)))
                 (if (dangerous-parameter? fname d-arg*)
                   (begin
                     (set-car! exp 'rcall)
                     (set! program-modified? #t))))))
            ((equal? (car exp) 'rcall)
             (let ((d-exp* (cadddr exp))
                   (s-exp* (caddr exp))
                   (fname (cadr exp)))
               (make-rcall*! d-exp* vn vv)))
            ((equal? (car exp) 'xcall)
             (let ((exp* (cddr exp)) (fname (cadr exp)))
               (make-rcall*! exp* vn vv)))
            (else
             (let ((exp* (cdr exp)) (op (car exp)))
               (make-rcall*! exp* vn vv)))))
    (define (make-rcall*! exp* vn vv)
      (for-each (lambda (exp) (make-rcall! exp vn vv)) exp*))
    (define (dangerous-parameter? fname arg*)
      (and (memq 'c arg*)
           (let ((%%109 (assq fname dupl)))
             (let ((dupl* (cdr %%109))) (dangerous-par? arg* dupl*)))))
    (define (dangerous-par? arg* dupl*)
      (if (and (null? arg*) (null? dupl*))
        #f
        (let ((dupl*-rest (cdr dupl*))
              (dupl (car dupl*))
              (arg*-rest (cdr arg*))
              (arg (car arg*)))
          (or (and (eq? arg 'c) dupl) (dangerous-par? arg*-rest dupl*-rest)))))
    (set! dupl (make-dupl-descr-prog prog))
    (set! program-modified? #f)
    (make-rcall-func*!)
    program-modified?)
  (define (make-dupl-descr-prog prog)
    (map (lambda (fundef)
           (let ((body (car (cddddr fundef)))
                 (dvn (caddr fundef))
                 (svn (cadr fundef))
                 (fname (car fundef)))
             `(,fname
               unquote
               (map (lambda (vname) (> (max-occurrences vname body) 1)) dvn))))
         prog))
  (define (max-occurrences vname exp)
    (cond ((symbol? exp) (if (eq? vname exp) 1 0))
          ((equal? (car exp) 'static) 0)
          ((equal? (car exp) 'ifs)
           (let ((exp3 (cadddr exp)) (exp2 (caddr exp)) (exp1 (cadr exp)))
             (max (max-occurrences vname exp2) (max-occurrences vname exp3))))
          ((equal? (car exp) 'ifd)
           (let ((exp3 (cadddr exp)) (exp2 (caddr exp)) (exp1 (cadr exp)))
             (let ((n1 (max-occurrences vname exp1))
                   (n2 (max-occurrences vname exp2))
                   (n3 (max-occurrences vname exp3)))
               (max (+ n1 n2) (+ n1 n3)))))
          ((equal? (car exp) 'call)
           (let ((d-exp* (cadddr exp))) (max-occurrences* vname d-exp*)))
          ((equal? (car exp) 'rcall)
           (let ((d-exp* (cadddr exp))) (max-occurrences* vname d-exp*)))
          ((equal? (car exp) 'xcall)
           (let ((exp* (cddr exp))) (max-occurrences* vname exp*)))
          (else (let ((exp* (cdr exp))) (max-occurrences* vname exp*)))))
  (define (max-occurrences* vname exp*)
    (foldl-map + 0 (lambda (exp) (max-occurrences vname exp)) exp*))
  (display "Preventing Call Duplication")
  (newline)
  (let ((s-fundef* (caddr prog)) (d-fundef* (cadr prog)) (rf (car prog)))
    (pcd-loop! d-fundef*)
    (let ((rf (uresfn:collect-residual-functions d-fundef*)))
      (display "-- Done --")
      (newline)
      `(,rf ,d-fundef* ,s-fundef*))))

