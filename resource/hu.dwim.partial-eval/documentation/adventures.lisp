;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.partial-eval.documentation)

;;;;;;
;;; Adventures

(def book adventures (:title "Adventures in the Land of Partial Evaluation" :authors '("Levente Mészáros"))
  (chapter (:title "Introduction")
    (paragraph ()
      "The idea of partial evaluation is a well known optimization technique in computer science, unfortunately it is less often used in practice. This document describes my personal experience with partial evaluation in Common Lisp. The provided code is tested under Steel Banks Common Lisp (SBCL) x86-64 running on Ubuntu Linux."))
  (chapter (:title "Motivation")
    (paragraph ()
      "In the recent months I was working on a heavily metadata driven web user interface. Due to some Common Lisp Object System (CLOS) Meta Object Protocol (MOP) customizations and the way how the component factory uses MAKE-INSTANCE to create the user interface objects, I faced serious performance issues. Most Common Lisp implementations, like SBCL, do a fairly good job when they are optimizing instance construction through MAKE-INSTANCE calls. That is calling MAKE-INSTANCE with compile time known class name and keyword arguments results in a very efficient instance allocation. Unfortunately in this particular case the optimization was defeated by generic methods defined on (SETF SLOT-VALUE-USING-CLASS) and by dynamic class name and variable initialization arguments passed to MAKE-INSTANCE.")
    (paragraph ()
      "I looked at the code that is making the hand made optimization inside SBCL. I could change it in a way that makes the instance allocation somewhat more efficient than going through all the generic machinery in this case. Obviously the result is non-portable Common Lisp code that heavily depends on the compiler's internals. Unfortunately it also means that this solution might break any time when the internals are changed. Actually it already happened since then, even though it wasn't hard to follow the changes."))
  (chapter (:title "Idea")
    (paragraph ()
      "I already knew the idea of partial evaluation and I became curios about whether applying this technique to Common Lisp could help solving these kind of issues. I searched the internet for an existing partial evaluator that could be applied to generic methods, more specifically to MAKE-INSTANCE and its friends, but I could not find anything usable. Then I thought, after all Common Lisp is known to be good at transforming source code, and we already had a good code walker, so I decided to give it a try.")
    (paragraph ()
      "My idea was the following: in Common Lisp a partial evaluator is simply a function that takes as input an expression, possibly with free variables and free function calls in it, and a couple of assumptions about the expression's environment. Then it produces a specialized version of the input expression that is optimized with respect to the given assumptions. The output expression is expected to behave exactly the same way for all possible environments as the input expression would do, as long as the assumptions are kept.")
    (paragraph ()
      "In Common Lisp this means the resulting expression must have the same side effects, in the same order, with the same return value(s), and the same non local transfer of controls (both in and out). Moreover, objects that are freshly allocated in the input expression should also be freshly allocated in the ouput expression when they may be visible outside. Unfortunately these requirements, and the fact that Common Lisp is not a purely functional language and that it supports side effects, make partial evaluation pretty difficult in general.")
    (paragraph ()
      "Once I realised that general partial evaluation in Common Lisp is so difficult, instead of trying to solve the unsolvable I decided to make the public interface very flexible. This allows specializing the partial evaluator for a particular problem by the programmer using specific assumptions that would otherwise pretty hard to be proved by a generic algorithm."))
  (chapter (:title "Assumptions")
    (paragraph ()
      "The simplest class of assumptions speak about one of the input expression's free variables. The variable's value can be a constant number, a constant string, a particular object, etc. Other assumptions speak about the type of one such free variable. For example, the value can be an arbitrary integer, a string, or an instance of a particular class. Some more complicated examples may use arbitrary predicates such as the value is a negative odd integer, a prime number, a fixed length string of alphanumeric characters, a subclass of a particular class, an open character file with utf-8 encoding, etc. There may be even more complex assumptions that specify constraints on two or more free variables at once.")
    (paragraph ()
      "Another class of assumptions speak about the expected behavior of one or more of the function calls that is used during the evaluation of the input expression. The function may be specified to have no side effects, not to return freshly allocated objects, be inlined, be evaluated for constant arguments at partial evaluation time, etc. This applies to functions called anywhere down the call tree.")
    (paragraph ()
      "Another class of assumptions speak about particular expressions such as if expressions, loops that is tagbodies, or recursive function calls. For example, one of an if expression's branch may be cut off, a loop may be forced to be unrolled, or kept intact, a finite recursion may be inlined, etc.")
    (paragraph ()
      "The list of different assumptions are endless. The point is that being able to customize the partial evaluator might drammatically simplify it while still allowing to get good results."))
  (chapter (:title "Implementation")
    (paragraph ()
      "This partial evaluator is basically a special Common Lisp interpreter. The main difference to a standard interpreter is that the values of variables, function arguments, and return values can not only be constants, but arbitrary expressions. The partial evaluator function takes a lisp form as cons cells and builds up an internal abstract syntax tree (AST) representation using a Common Lisp code walker. The actual partial evaluation is done on the AST recursively using a layered functions. The result is another AST that is potentially the same as the input. At the end the tree is unwalked to produce the output expression in the usual lisp representation. The output can simply be put in place of the input expression and expected to work correctly as long as the assumptions are kept. This makes the partial evaluator a really good tool to write Common Lisp compiler macros.")
    (paragraph ()
      "The implementation uses a couple of layered functions. A layered function is like a generic function with an extra implicit argument carried by a special variable. This allows easy customization at various points in the partial evaluation algorithm while keeping other parts intact.")
    (paragraph ()
      "The partial evaluation algorithm leaves constant expressions unchanged. Other individual Common Lisp special forms are partially evaluated according to the language rules.")
    (paragraph ()
      "IF expressions are interpreted on both branches unless it can be proved that one of the branches will be always taken. To avoid exponential boom IF expressions can be cut off, and left untouched by customizing the partial evaluator, or by the default guard. The environment is automatically extended with the assumption that the condition evaluates to NIL or non NIL depending on which branch is followed.")
    (paragraph ()
      "In Common Lisp loops are implemented using the special forms TAGBODY and GO. Loop unrolling is done by following GO expressions and continuing partial evaluation at the referred label. To avoid infinite looping the default guard stops partial evaluation above a certain threshold and leaves the loop in the output expression. This does not mean that the forms within the TAGBODY can not be partially evaluated.")
    (paragraph ()
      "When partially evaluating the input expression there might be a call to another function. It is possible to partially evaluate the body of the called function as long as the source can be retrieved. Fortunately SBCL provides source locations that can be used to lazily read the source for a given function. When the partial evaluator finds a function call it can do one of three things, either leave the call intact, or call the function immediately at partial evaluation time if all arguments are constants and other necessary conditions hold, or inline the function body and continue partial evaluation within.")
    (paragraph ()
      "Recursive function calls are also guarded to avoid infinite recursion. TODO.")
    (paragraph ()
      "For each generic function the partial evaluator builds a lambda form that implements the discrimination function and calls the generic method bodies according to the CLOS standard generic function rules. This is obviously already present in the Common Lisp implementation in some form, but unfortunately it turns out to be not so trivial to get what we want. There would be no problem with calling other functions, even generic functions from the generated lambda form as long as it does not refer to the original generic function. Once the partial evaluator has the lambda form, the original generic function call becomes a simple function call that it can already partially evaluate as specifed above."))
  (chapter (:title "Goal")
    (paragraph ()
      "The Common Lisp Object System (CLOS) has a quite flexible, but also quite complicated Meta Object Protocol (MOP). One of the most often used protocol is the instance construction called MAKE-INSTANCE. As mentioned earlier most Common lisp implementations do a fairly good job when optimizing instance construction. The goal is to partially evaluate a MAKE-INSTANCE call with a constant class name and initialization arguments. The expected result should have similar performance when comparing to the hand made optimizations provided by the SBCL compiler.")
    (paragraph ()
      "For reference, the instance construction protocol uses the following generic functions: MAKE-INSTANCE, ALLOCATE-INSTANCE, INITIALIZE-INSTANCE, SHARED-INITIALIZE, (SETF SLOT-VALUE-USING-CLASS) and some others. To achieve the performance goal we must be able to inline and partially evaluate all of these generic functions."))
  (chapter (:title "Example")
    (paragraph ()
      "TODO"))
  (chapter (:title "Performance")
    (paragraph ()
      "TODO"))
  (chapter (:title "Source")
    (paragraph ()
      "TODO"))
  (chapter (:title "Licence")
    (paragraph ()
      "TODO"))
  (chapter (:title "Test Suite")
    (paragraph ()
      "TODO"))
  (chapter (:title "Conclusion")
    (paragraph ()
      "TODO"))
  (chapter (:title "Limitations")
    (paragraph ()
      "TODO"))
  (chapter (:title "Special Thanks")
    (paragraph ()
      "Paul Khuong, Attila Lendvai, Tamás Borbély, ")))
