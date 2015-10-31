;;; z3-mode.el -- A z3/SMTLIBv2 interactive development environment -*-lexical-binding: t-*-

;; Version: 0.0.1
;; Author: Zephyr Pellerin <zephyr.pellerin@gmail.com>
;; Homepage: https://github.com/zv/z3-mode
;; Keywords: z3 yices smt

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; An interactive development environment for SMT-LIB files and Z3. Z3 and
;; Contessa as well as various SMTLIB supporting theorem provers & solvers are
;; supported. Structured statements can be inserted and ran with C-c

;;; Code:
(require 'flycheck)

(defgroup z3 nil
  "Z3/SMT script Mode"
  :group 'languages
  :prefix "z3-")

(defcustom z3-mode-solver-cmd "/home/zv/Development/z3/build/z3"
  "The command used when you run the solver

The following solvers are currently supported
- Z3
"
  :type 'file
  :group 'z3)

(defcustom z3-mode-input-format "smt2"
  "The input format"
  :group 'z3
  :options '(("SMTLIBv1" "smt")
             ("SMTLIBv2" "smt2")
             ("Datalog" "dl")
             ("DIMACS" "dimacs")))

(defvar z3-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") 'run-solver) map)
  "Keymap for z3-mode")

;;;; Font-lock support.
;; Matches alternative base numeric primitives such as `#xF0FA' & `#b010'
(defconst z3-altbase-literal-regexp "\\(#x[0-9a-fA-F]+\\|#b[01]+\\)")

; Matches the simplest symbol regexp format
(defconst z3-symbol-regexp "[a-zA-Z~!@$%^&*_+=<>.?/-][0-9a-zA-Z~!@$%^&*_+=<>.?/-]*")

;; Matches an alternative quote symbol regexp format
(defconst z3-quoted-symbol-regexp "|[]!-[^-{}~ \t\r\n]*|")

;; Matches lisp-symbol style keywords, i.e `:keyword'
(defconst z3-keyword-symbol-regexp ":[0-9a-zA-Z~!@$%^&*_+=<>.?/-]+")

;; Z3 commands as keywords
(defvar z3-keywords '("apply" "assert" "assert-soft" "check-sat" "check-sat-using"
                      "compute-interpolant" "declare-const" "declare-datatypes" "declare-fun"
                      "declare-map" "declare-rel" "declare-sort" "declare-tactic"
                      "define-sort" "display" "echo" "eval" "exit" "fixedpoint-pop"
                      "fixedpoint-push" "get-assertions" "get-assignment" "get-info"
                      "get-interpolant" "get-model" "get-option" "get-proof" "get-unsat-core"
                      "get-user-tactics" "get-value" "help" "help-tactic" "labels" "maximize"
                      "minimize" "pop" "push" "query" "reset" "rule" "set-info" "set-logic"
                      "set-option" "simplify"))

;; Define our font-lock
(setq z3-keywords-regexp (regexp-opt z3-keywords 'words))

(setq z3-font-lock-defaults
      `((
         (,(regexp-opt z3-keywords 'words) . font-lock-keyword-face)
         (,z3-keyword-symbol-regexp . font-lock-builtin-face)
         (,z3-altbase-literal-regexp . font-lock-constant-face)
         ;; We *can* highlight symbols, but it compromises the clarity
         ;; (,z3-symbol-regexp . font-lock-function-name-face)
         )))

;; Define the mode
(define-derived-mode z3-mode lisp-mode "Z3/SMT2"
  "Major mode for editing Z3 files"

  (setq auto-mode-alist
        (append
         '(("\\.smt[2]?$" . z3-mode)) auto-mode-alist))

  ;; code for syntax highlighting
  (setq font-lock-defaults z3-font-lock-defaults))

;; Setup Syntax Checking

;; Setup the executable configuration group
;;; Setup the flycheck specific customize group
(defcustom flycheck-z3-smt2-lint-executable nil
  (format "The executable of the z3-smt2-lint syntax checker.

Either a string containing the name or the path of the
executable, or nil to use the default executable from the syntax
checker declaration.

The default executable is %S." z3-solver-cmd)
  :type '(choice (const :tag "Default executable" nil)
                 (string :tag "Name or path"))
  :group 'flycheck-executables
  :risky t)

;; Configure the command checker
(flycheck-define-command-checker 'z3-smt2-lint
  "A syntax and style checker for SMTLIBv2 with Z3"
  :command `(,z3-solver-cmd "-v:1" "-smt2" source)
  :error-patterns
  '((error "error \"line " line " column " column ": " (message) "\")"))
  :modes 'z3-mode)

;; Command to run SMT solver on the whole buffer
(defun run-solver ()
  "Run the SMT solver on the buffer "
  (interactive)
  (shell-command-on-region
   (if (region-active-p) (region-beginning) (point-min))
   (if (region-active-p) (region-end) (point-max))
   (read-shell-command "Run SMT solver: " (concat z3-solver-cmd " " (buffer-file-name)))
   "SMT Solver Output"))

(provide 'z3-mode)
