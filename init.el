;;; init.el --- Clean Emacs config with straight.el, SLY, Org‑babel -*- lexical-binding: t; -*-

;;; Commentary:
;; • Package management via straight.el
;; • Org‑babel for Python + Common Lisp (through SLY)
;; • Modern completion stack (Vertico, Orderless, Consult, Embark)
;; • Modus themes (use built‑in to avoid version clash)

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 0. Personal helpers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(add-to-list 'load-path (expand-file-name "lisp/" user-emacs-directory))
(require 'functions nil t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 1. straight.el bootstrap (replaces package.el)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar bootstrap-version)
(let ((bootstrap-file (expand-file-name "straight/repos/straight.el/bootstrap.el"
                                        user-emacs-directory))
      (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(setq straight-use-package-by-default t)
(straight-use-package 'use-package)
(require 'use-package)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 2. UI & Theme
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq inhibit-startup-message t  visible-bell nil)
(tool-bar-mode -1) (scroll-bar-mode -1) (menu-bar-mode -1)
(global-display-line-numbers-mode 1) (global-visual-line-mode 1)

(use-package modus-themes          ; use the version shipped with Emacs
  :straight nil
  :init (setq modus-themes-disable-other-themes t)
  :config (load-theme 'modus-vivendi :no-confirm))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 3. macOS tweaks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(when (eq system-type 'darwin)
  (setq mac-option-modifier 'meta)
  (add-to-list 'exec-path "/usr/local/texlive/2022basic/bin/universal-darwin")
  (setenv "PATH" (concat (getenv "PATH") ":/Library/TeX/texbin/pdflatex")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 4. Core editing behaviour
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(electric-pair-mode 1)
(setq abbrev-file-name (expand-file-name "abbrev_defs" user-emacs-directory)
      save-abbrevs 'silently)
(setq-default abbrev-mode t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 5. Evil + helpers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package evil :init (setq evil-want-C-i-jump nil) :config (evil-mode 1))
(use-package key-chord
  :after evil
  :config (key-chord-mode 1)
  (key-chord-define evil-insert-state-map "jk" 'evil-normal-state))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6. Markdown
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package markdown-mode :mode "\\.md\\'")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7. SLY (Common Lisp IDE)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package sly :defer t :init (setq inferior-lisp-program "sbcl"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 8. Company completion
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package company
  :hook (after-init . global-company-mode)
  :custom (company-idle-delay 0 company-minimum-prefix-length 1 company-selection-wrap-around t)
  :config (company-tng-configure-default))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 9. Magit & dependencies
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package magit)
(use-package transient)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 10. GPTel (OpenRouter)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package gptel
  :config
  (setq gptel-default-mode 'org-mode)
  (gptel-make-openai "OpenRouter"
    :host "openrouter.ai" :endpoint "/api/v1/chat/completions" :stream t
    :key (auth-source-pick-first-password :host "openrouter.ai")
    :models '(openai/o3-mini-high openai/gpt-4o-2024-11-20 deepseek/deepseek-r1-distill-qwen-7b deepseek/deepseek-chat-v3-0324 moonshotai/kimi-k2)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 11. Org‑mode & Org‑babel
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package org
  :straight (:type built-in)
  :bind (("\C-cl" . org-store-link) ("\C-ca" . org-agenda))
  :hook ((org-mode . visual-line-mode)
         (org-babel-after-execute . org-redisplay-inline-images))
  :config
  (org-babel-do-load-languages 'org-babel-load-languages
                               '((emacs-lisp . t) (python . t) (lisp . t) (ruby . t)))
  (setq org-babel-lisp-eval-fn #'sly-eval
        org-confirm-babel-evaluate nil
        org-src-fontify-natively t
        org-src-tab-acts-natively t
        python-shell-interpreter "/usr/bin/python3"
	org-indent-indentation-per-level 2
	org-hide-leading-stars t
	org-startup-indented t)
  ;; Agenda & capture
  (setq org-agenda-files '("~/Library/CloudStorage/Dropbox/Agenda/inbox.org"
                           "~/Library/CloudStorage/Dropbox/Agenda/todos-work.org")
        org-todo-keywords '((sequence "TODO(t)" "NEXT(n)" "PROJECT(p)" "DELEGATED (l)" "WAITING(w)" "|" "DONE(d)"))
        org-archive-location "~/Library/CloudStorage/Dropbox/Agenda/Archive/%s_archive::")
  (setq org-capture-templates '(("t" "Todo" entry (file "~/Library/CloudStorage/Dropbox/Agenda/inbox.org")
                                 "* TODO %?\n  %i\n  %a")))
  (defun my/org-set-delegated-meta ()
    (when (equal (org-get-todo-state) "DELEGATED")
      (end-of-line) (newline) (insert ":PERSON:\n:DUE:")))
  (add-hook 'org-after-todo-state-change-hook #'my/org-set-delegated-meta))

(global-set-key (kbd "C-c c") #'org-capture)
(use-package wc-goal-mode :hook (org-mode . wc-goal-mode))

;; ── Agenda basics ────────────────────────────────────────────────────────────
(setq org-agenda-span         'week          ; how many days to show
      org-agenda-start-on-weekday 0          ; Monday = 1, Sunday = 0
      org-agenda-compact-blocks t            ; tighter vertical spacing
      org-agenda-block-separator ?─          ; nice heavy dash under each block
      org-agenda-use-time-grid t
      org-agenda-time-grid
      '((today require-timed)                ; show grid only where it matters
        (800 1000 1200 1400 1600 1800)
        " ┄┄┄" "┈┈┈┈┈┈┈┈┈┈")             ; make the grid subtle
      org-agenda-prefix-format
      '((agenda . " %i %-12:c%?-12t% s")     ; icon, category, time, extra
        (todo    . " %i %-12:c")             ; same for TODO list
        (tags    . " %i %-12:c")
        (search  . " %i %-12:c")))

(use-package org-super-agenda
  :after org-agenda
  :config
  (setq org-super-agenda-groups
        '((:name "‼  Overdue"    :deadline past)
          (:name "★  Today"      :time-grid t :scheduled today :deadline today)
          (:name "⧖  Next"       :todo "NEXT")
          (:name "⌛  Waiting"    :todo "WAIT")
          (:name "⤵  Someday"    :todo "SOMEDAY" :scheduled future)))
  (org-super-agenda-mode))

(with-eval-after-load 'ox-latex
  (add-to-list 'org-latex-classes
               '("scrartcl"                                    ; name you’ll use in #+LATEX_CLASS
                 "\\documentclass[fontsize=16pt]{scrartcl}"    ; first line of the .tex file
                 ("\\section{%s}"       . "\\section*{%s}")
                 ("\\subsection{%s}"    . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}"     . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}"  . "\\subparagraph*{%s}"))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 12. Spelling
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq ispell-program-name "aspell" ispell-list-command "list" flyspell-issue-message-flag nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 13. PDF‑Tools
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package pdf-tools :config (pdf-tools-install) :hook (pdf-view-mode . (lambda () (display-line-numbers-mode -1))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 14. Encryption default key
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq epa-file-encrypt-to '("micahacobb@gmail.com"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 15. Completion stack (Vertico, Orderless, Consult, Embark, Avy)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package vertico :init (vertico-mode 1) :custom (vertico-cycle t))
(use-package orderless :custom (completion-styles '(orderless))
                         (completion-category-overrides '((file (styles partial-completion)))))
(use-package marginalia :after vertico :init (marginalia-mode))
(use-package consult :bind (("C-s" . consult-line) ("C-x b" . consult-buffer)))
(use-package embark :bind (("C-." . embark-act) ("C-;" . embark-dwim))
  :init (setq prefix-help-command #'embark-prefix-help-command))
(use-package embark-consult :after (embark consult))
(use-package avy :bind (("C-:" . avy-goto-char-timer)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 16. AUCTeX (LaTeX)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package tex
  :straight auctex
  :defer t
  :hook ((LaTeX-mode . visual-line-mode) (LaTeX-mode . flyspell-mode))
  :custom (TeX-engine 'xetex) (TeX-PDF-mode t) (TeX-auto-save t) (TeX-parse-self t)
  :config
  (setq reftex-plug-into-AUCTeX t)
  (add-hook 'LaTeX-mode-hook 'TeX-source-correlate-mode)
  (setq TeX-view-program-selection '((output-pdf "PDF Tools"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 17. vterm + appearance
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package vterm)
(set-face-attribute 'default nil :family "Menlo" :height 160)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 18. Open agenda file at startup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(add-hook 'emacs-startup-hook (lambda () (find-file "~/Library/CloudStorage/Dropbox/Agenda/2025.org")))

(provide 'init)
;;; init.el ends here
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(highlight ((t (:background "dark red" :foreground "#ffffff")))))
