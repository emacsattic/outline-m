;; Outline as minor mode.

;; You need the minor keymap handler to use this file.

;; To make outline-mode a minor mode, append the following to your
;; ".emacs" file, or in a local.el:

;; (make-variable-buffer-local 'outline-prefix-char)
;; (setq-default outline-prefix-char "\C-l")
;; (make-variable-buffer-local 'outline-regexp)
;; (setq-default outline-regexp "[*\^l]+")
;; (make-variable-buffer-local 'outline-level-function)
;; (setq-default outline-level-function 'outline-level-default)

;; COPYLEFT

;; Created 1987 by Per Abrahamsen at University of Aalborg, Denmark.
;; Please report improvents and bugs to abraham@iesd.auc.dk.

;; Might contain code from the original outline.el, so...

;; COPYRIGHT

;; Outline mode commands for Emacs
;; Copyright (C) 1986 Free Software Foundation, Inc.

;; This file is part of GNU Emacs.

;; License: GPL

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY.  No author or distributor
;; accepts responsibility to anyone for the consequences of using it
;; or for whether it serves any particular purpose or works at all,
;; unless he says so in writing.  Refer to the GNU Emacs General Public
;; License for full details.

;; Everyone is granted permission to copy, modify and redistribute
;; GNU Emacs, but only under the conditions described in the
;; GNU Emacs General Public License.   A copy of this license is
;; supposed to have been given to you along with GNU Emacs so you
;; can know your rights and responsibilities.  It should be in a
;; file named COPYING.  Among other things, the copyright notice
;; and this notice must be preserved on all copies.

;; Jan '86, Some new features added by Peter Desnoyers and rewritten by RMS.
  
(require 'minor-map)

(if (featurep 'outline)
    ()
  (load-library "outline")
  (provide 'outline))

(setq minor-mode-alist (cons '(selective-display " Outline")
			     minor-mode-alist))

; Changed to allow read-only buffers and to speed up nonmodified buffers

(defun outline-flag-region (from to flag)
  "Hides or shows lines from FROM to TO, according to FLAG.  If FLAG
is \\n (newline character) then text is hidden, while if FLAG is \\^M
\(control-M) the text is shown."
  (let ((modp (buffer-modified-p))
	(read-only buffer-read-only))
    (if read-only (toggle-read-only))
    (unwind-protect
        (subst-char-in-region from to
			      (if (= flag ?\n) ?\^M ?\n)
			      flag t)
      (progn
	(if read-only (toggle-read-only))
	(set-buffer-modified-p modp)))))

(defun hide-region-body (start end)
  "Hide all body lines in the region, but not headings."
  (save-excursion
    (save-restriction
      (narrow-to-region start end)
      (goto-char (point-min))
      (let ((modp (buffer-modified-p)))
	(set-buffer-modified-p t)
	(while (not (eobp))
	  (outline-flag-region (point) (progn (outline-next-preface) (point)) ?\^M)
	  (if (not (eobp))
	      (forward-char
	       (if (looking-at "[\n\^M][\n\^M]")
		   2 1))))
	(set-buffer-modified-p modp)))))

(defun outline-level-default ()
  "Return the depth to which a statement is nested in the outline.
Point must be at the beginning of a header line.
This is actually the length of whatever outline-regexp matches."
  (save-excursion
    (looking-at outline-regexp)
    (- (match-end 0) (match-beginning 0))))

(defun outline-level ()
  "Return the depth to which a this heading is nested in the outline.
This is done by a call to the value of outline-level-function, which
default to outline-level-default."
  (funcall outline-level-function))
  
(if (boundp 'outline-minor-keymap)
    ()
  (setq outline-minor-keymap (make-keymap))	; allocate outline keymap table
  (define-key outline-minor-keymap "\C-n" 'outline-next-visible-heading)
  (define-key outline-minor-keymap "\C-p" 'outline-previous-visible-heading)
  (define-key outline-minor-keymap "\C-f" 'outline-forward-same-level)
  (define-key outline-minor-keymap "\C-b" 'outline-backward-same-level)
  (define-key outline-minor-keymap "\C-u" 'outline-up-heading)
  (define-key outline-minor-keymap "\C-t" 'hide-body)
  (define-key outline-minor-keymap "\C-a" 'show-all)
  (define-key outline-minor-keymap "\C-o" 'outline-mode)
  (define-key outline-minor-keymap "\C-h" 'hide-subtree)
  (define-key outline-minor-keymap "\C-s" 'show-subtree)
  (define-key outline-minor-keymap "\C-i" 'show-children)
  (define-key outline-minor-keymap "\C-c" 'hide-entry)
  (define-key outline-minor-keymap "\C-e" 'show-entry)
  (define-key outline-minor-keymap "\C-l" 'hide-leaves)
  (define-key outline-minor-keymap "\C-x" 'show-branches))

(defun outline-minor-mode (&optional arg) "\
Toggle outline mode.
With arg, turn ouline mode on iff arg is positive.

Minor mode for editing outlines with selective display.
Headings are lines which start with asterisks: one for major headings,
two for subheadings, etc.  Lines not starting with asterisks are body lines. 

Body text or subheadings under a heading can be made temporarily
invisible, or visible again.  Invisible lines are attached to the end 
of the heading, so they move with it, if the line is killed and yanked
back.  A heading with text hidden under it is marked with an ellipsis (...).

Commands:
C-l C-n   outline-next-visible-heading      move by visible headings
C-l C-p   outline-previous-visible-heading
C-l C-f   outline-forward-same-level        similar but skip subheadings
C-l C-b   outline-backward-same-level
C-l C-u   outline-up-heading		    move from subheading to heading

C-l C-t   hide-body		make all text invisible (not headings).
C-l C-a   show-all		make everything in buffer visible.

C-l C-o    outline-minor-mode         leave outline mode.

The remaining commands are used when point is on a heading line.
They apply to some of the body or subheadings of that heading.

C-l C-h   hide-subtree	        make body and subheadings invisible.
C-l C-s   show-subtree	        make body and subheadings visible.
C-l C-i   show-children	        make direct subheadings visible.
		 No effect on body, or subheadings 2 or more levels down.
		 With arg N, affects subheadings N levels down.

C-l C-c    hide-entry	   make immediately following body invisible.
C-l C-e    show-entry	   make it visible.
C-l C-l    hide-leaves	   make body under heading and under its subheadings
			   invisible. The subheadings remain visible.

C-l C-x    show-branches   make all subheadings at all levels visible.

The prefix char (C-l) is determinated by the value of outline-prefix-char.
If outline-minor-keymap is set, it will be used instead of the default
keymap.

The variable outline-regexp can be changed to control what is a heading.
A line is a heading if outline-regexp matches something at the
beginning of the line.  The longer the match, the deeper the level."

  (interactive "P")
  (if (or (and (null arg) selective-display)
	  (<= (prefix-numeric-value arg) 0))
      (progn				;Turn it off
	(unbind-minor-mode 'outline-minor-mode)
	(if selective-display
	    (progn
	      (show-all)
	      (setq selective-display nil))))
    (setq selective-display t)		;Turn it on
    (minor-set-key outline-prefix-char
		   outline-minor-keymap
		   'outline-minor-mode))
  (set-buffer-modified-p (buffer-modified-p))) ;No-op, but updates mode line.
