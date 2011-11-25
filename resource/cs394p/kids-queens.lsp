; kids-queens.lsp    ; From hewett Mon Apr  4 16:38:42 1994

;;; QUEENS functions
;;; Generated by replaying KIDS Queens derivation,    4 April 1994


#|
.> (re::kids-foci)
(constant QUEENS-GS-AUX
   : map(tuple
           (integer, seq(integer), set(integer), set(integer),
            set(integer), integer),
         set(seq(integer))) 
  constant QUEENS: map(integer, set(seq(integer))))

.>  ; Compile with Refine with "Print Compiled code to Emacs window" on.
|#

(DEFUN QUEENS (K)
  (QUEENS-GS-AUX K (LIST)
    (SEQ-TO-LIST-MAKE-INTEGER-SUBRANGE 1 K) 
    NIL NIL 0))

; changed (IF! p THEN q ELSE r) to (if p q r)
(DEFUN QUEENS-GS-AUX
  (K V UNOCCUPIED-ROWS OCCUPIED-UP-DIAGONALS 
    OCCUPIED-DOWN-DIAGONALS V-LENGTH)
  (IF (NULL UNOCCUPIED-ROWS) 
     (LIST V) 
    (LET ((THE-VALUE (QUOTE *UNDEFINED*)))
      (LET ((THE-SET-0
              (LET ((--SETVAR-0 NIL))
                (LET ((SF-0 NIL) 
                       APS-4 ADDENDS-0 SUBTRAHEND-0)
                  (LOOP FOR I IN 
                    UNOCCUPIED-ROWS DO
                    (IF (AND (NOT (LET ((X-2
                                           (+ (+ V-LENGTH 1) I)))
                                     (LOOP FOR 
                                       Y-3 IN 
                                       OCCUPIED-DOWN-DIAGONALS 
                                       THEREIS
                                       (EQL X-2 Y-3))))
                           (NOT (LET ((X-3
                                        (- I (+ V-LENGTH 1))))
                                  (LOOP FOR 
                                    Y-4 IN 
                                    OCCUPIED-UP-DIAGONALS THEREIS
                                    (EQL X-3 Y-4))))) 
                      (PROGN
                        (IF (NOT SF-0) 
                          (PROGN (SETQ SF-0 T)
                            (SETQ SUBTRAHEND-0 (+ 1 V-LENGTH))
                            (SETQ ADDENDS-0 (+ 1 V-LENGTH))
                            (SETQ APS-4 (+ 1 V-LENGTH))))
                        (SETQ --SETVAR-0
                          (LET ((S-0 --SETVAR-0)
                                 (X-1
                                   (QUEENS-GS-AUX K (APPEND V (LIST I))
                                     (SET-LESS I UNOCCUPIED-ROWS)
                                     (LISP:UNION
                                       (LIST (- I SUBTRAHEND-0)) 
                                       OCCUPIED-UP-DIAGONALS)
                                     (LISP:UNION
                                       (LIST (+ ADDENDS-0 I)) 
                                       OCCUPIED-DOWN-DIAGONALS) 
                                     APS-4)))
                            (IF (LOOP FOR 
                                   Y-0 IN S-0 
                                   THEREIS
                                   (LET ((--SET-1 Y-0)
                                          (--SET-0 X-1))
                                     (AND (EQL (LENGTH --SET-0)
                                            (LENGTH --SET-1))
                                       (LOOP FOR 
                                         Y-1 IN 
                                         --SET-0 ALWAYS
                                         (LOOP FOR 
                                           Y-2 IN 
                                           --SET-1 THEREIS
                                           (LET ((SEQ-1 Y-2)
                                                  (SEQ-0 Y-1))
                                             (OR (EQ SEQ-0 SEQ-1
                                                  )
                                               (AND (DEFINED? SEQ-0)
                                                 (DEFINED? SEQ-1)
                                                 (LET ((--SIZE-0
                                                         (LENGTH SEQ-0))
                                                       )
                                                   (AND (EQL --SIZE-0
                                                         (LENGTH SEQ-1))
                                                     (LOOP 
                                                      FOR 
                                                      I-0 
                                                      FROM 1 
                                                      TO 
                                                      --SIZE-0 
                                                      ALWAYS
                                                      (EQL (SEQ-TO-LIST-GET-NTH
                                                            SEQ-0 
                                                             I-0)
                                                         (SEQ-TO-LIST-GET-NTH 
                                                          SEQ-1 
                                                          I-0))))))))))
                                      ))) 
                               S-0 
                              (CONS X-1 S-0)))))))
                  (IF SF-0 (PROGN))) 
                --SETVAR-0)))
        (SETQ THE-VALUE
          (LET ((--RESULT-0 NIL))
            (LOOP FOR X-0 
              IN THE-SET-0 DO
              (SETQ --RESULT-0
                (REGROUP-UNION! --RESULT-0 X-0))) 
            --RESULT-0))) 
      THE-VALUE)))

; The following functions added by GSN:
(defun SEQ-TO-LIST-MAKE-INTEGER-SUBRANGE (start end) ; (1 K)
  (let (l)
    (dotimes (i (1+ (- end start))) (push (+ start i) l))
    (nreverse l) ))

(defun SEQ-TO-LIST-GET-NTH (l n) (nth (1+ n) l))

(defun set-less (i set) (set-difference set (list i)))

(defun REGROUP-UNION! (x y) (union x y))

(defun DEFINED? (x) (not (null x)))