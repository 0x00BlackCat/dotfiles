(setq custom-file "~/.emacs.custom.el")

(add-to-list 'load-path "~/.emacs.local/")

(setq backup-directory-alist '(("." . "~/.emacs.d/backup"))
  backup-by-copying t    ; Don't delink hardlinks
  version-control t      ; Use version numbers on backups
  delete-old-versions t  ; Automatically delete excess backups
  kept-new-versions 20   ; how many of the newest versions to keep
  kept-old-versions 5    ; and how many of the old
  )

(setq inhibit-startup-message t)
(tool-bar-mode 0)
(menu-bar-mode 0)
(scroll-bar-mode 0)
(column-number-mode 1)
(electric-pair-mode 1)
(show-paren-mode 1)
(delete-selection-mode 1)
(global-display-line-numbers-mode)
(setq ring-bell-function 'ignore)

;; Preferences
(global-set-key (kbd "C-,") 'duplicate-line)
(global-set-key (kbd "C-c C-q") 'kill-current-buffer)
(global-set-key (kbd "C-c C-p") 'previous-buffer)
(global-set-key (kbd "C-c C-n") 'next-buffer)
(global-set-key (kbd "C-c C-n") 'next-buffer)

(add-to-list 'default-frame-alist `(font . "Iosevka-20"))

;; Initialize package sources
(require 'package)

(setq package-archives '(("melpa" . "https://melpa.org/packages/")
			 ("gnu" . "https://elpa.gnu.org/packages/")
			 ("nongnu" . "https://elpa.nongnu.org/nongnu/")))

(package-initialize)
(unless package-archive-contents
 (package-refresh-contents))

;; Initialize use-package on non-Linux platforms
(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

;; theme

(use-package gruber-darker-theme
  :ensure t
  :config
  (load-theme 'gruber-darker t))

(use-package smex
  :ensure t
  :bind (("M-x" . smex)
	 ("C-c C-c M-x" . execute-extended-command)))

(use-package ido-completing-read+
  :ensure t
  :config
  (ido-mode 1)
  (ido-everywhere 1)
  (ido-ubiquitous-mode 1))

;;; c-mode
(setq-default c-basic-offset 4
	      c-default-style '((java-mode . "java")
				(awk-mode . "awk")
				(other . "bsd")))

(add-hook 'c-mode-hook (lambda ()
			 (interactive)
			 (c-toggle-comment-style -1)))

(defvar lisp-modes '(emacs-lisp-mode
		     clojure-mode
		     lisp-mode
		     common-lisp-mode
		     scheme-mode
		     racket-mode)
  "List of lisp modes to enable paredit and other specific tools.")

(use-package paredit
  :ensure t
  :hook (lisp-modes . paredit-mode))

(use-package magit
  :ensure t
  :config
  (setq magit-auto-revert-mode nil)
  :bind (("C-c m s" . magit-status)
	 ("C-c m l" . magit-log)))

;;; Whitespace mode
(use-package whitespace
  :ensure nil
  :preface
  (defun time/set-up-whitespace-handling ()
    (interactive)
    (whitespace-mode 1)
    (add-hook 'before-save-hook 'delete-trailing-whitespace nil t))
  :hook
  ((prog-mode     . time/set-up-whitespace-handling)
   (markdown-mode . time/set-up-whitespace-handling)
   (yaml-mode     . time/set-up-whitespace-handling)))

(require 'dired-x)
(setq dired-omit-files
      (concat dired-omit-files "\\|^\\..+$"))
(setq-default dired-dwim-target t)
(setq dired-listing-switches "-alh")
(setq dired-mouse-drag-files t)

;;; helm

(use-package helm
  :ensure t
  :init

  (setq helm-ff-transformer-show-only-basename nil)
  :bind

  (("C-c f f" . helm-find)
   ("C-c h a" . helm-org-agenda-files-headings)
   ("C-c h r" . helm-recentf)))

(use-package helm-ls-git
  :ensure t
  :bind
  (("C-c h g l" . helm-ls-git-ls)
   ("C-c h t" . helm-ls-git-ls)))

(use-package expand-region
  :ensure t
  :bind (("C-=" . er/expand-region)))

;;; word-wrap
(defun time/enable-word-wrap ()
  (interactive)
  (toggle-word-wrap 1))

(add-hook 'markdown-mode-hook 'time/enable-word-wrap)

;;; Move Text
(use-package move-text
  :ensure t
  :bind(("M-p" . move-text-up)
	("M-n" . move-text-down)))

(require 'compile)

compilation-error-regexp-alist-alist

(add-to-list 'compilation-error-regexp-alist
	     '("\\([a-zA-Z0-9\\.]+\\)(\\([0-9]+\\)\\(,\\([0-9]+\\)\\)?) \\(Warning:\\)?"
	       1 2 (4) (5)))

(use-package company)
(global-company-mode)

(use-package flycheck
  :ensure t
  :init (global-flycheck-mode))

(use-package lsp-mode
  :ensure t
  :init
  (setq lsp-headerline-breadcrumb-enable nil)
  (setq lsp-keymap-prefix "C-c l")
  :hook (
	 (go-mode . lsp-deferred)
	 (python-mode . lsp-deferred)
	 (typescript-mode . lsp-deferred)
	 (lsp-mode . lsp-enable-which-key-integration))
  :commands lsp)

(use-package lsp-ui
  :ensure t
  :commands lsp-ui-mode)

(use-package go-mode
  :ensure t
  :hook (before-save . gofmt-before-save)) ;; Auto-format on save

(use-package typescript-mode
  :ensure t
  :mode "\\.ts\\'")

(use-package no-littering
  :ensure t
  :config
  ;; Move auto-save files to a specific directory handled by no-littering
  (setq auto-save-file-name-transforms
	`((".*" ,(no-littering-expand-var-file-name "auto-save/") t))))

;; simpc

(require 'simpc-mode)
(add-to-list 'auto-mode-alist '("\\.[hc]\\(pp\\)?\\'" . simpc-mode))
(add-to-list 'auto-mode-alist '("\\.[b]\\'" . simpc-mode))
(defun astyle-buffer (&optional justify)
  (interactive)
  (let ((saved-line-number (line-number-at-pos)))
    (shell-command-on-region
     (point-min)
     (point-max)
     "astyle --style=kr"
     nil
     t)
    (goto-line saved-line-number)))

(add-hook 'simpc-mode-hook
	  (lambda ()
	    (interactive)
	    (setq-local fill-paragraph-function 'astyle-buffer)))

(use-package tree-sitter
  :ensure t
  :config (global-tree-sitter-mode))


(load-file custom-file)
