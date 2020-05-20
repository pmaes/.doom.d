;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "John Doe"
      user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
(setq doom-font (font-spec :family "monospace" :size 14))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-gruvbox)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)


;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c g k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c g d') to jump to their definition and see how
;; they are implemented.

(setq mac-option-modifier nil
      mac-command-modifier 'meta)

(use-package! rx)
(use-package! s)
(use-package! org-datetree)

(defvar pm/porg-directory)

(setq pm/porg-directory "~/org/projects/")

(setq pm/porg--file-regexp
      (rx
       (eval (expand-file-name pm/porg-directory))
       (zero-or-one (and (group-n 2 (one-or-more (not (any "#.")))) "_"))
       (group-n 1 (one-or-more (not (any "#.")))) ".org" eol))

(defun pm/porg-meta-for-path (path)
  (-zip-pair '(path project client)
             (s-match pm/porg--file-regexp path)))

(defun pm/porg-key-for-path (path key)
  (->> path
       pm/porg-meta-for-path
       (alist-get key)))

(defun pm/porg-project-metas ()
  (->> (directory-files-recursively pm/porg-directory "")
       (-map 'pm/porg-meta-for-path)
       -non-nil))

(defun pm/porg-project->metas ()
  (let ((metas (pm/porg-project-metas)))
    (-zip-pair (-map (-partial 'alist-get 'project) metas)
               metas)))

(defun pm/porg-meta-for-name (name)
  (alist-get name (pm/porg-project->metas) nil nil 'equal))

(defun pm/porg-current-name ()
  (let ((current-project (->> (pm/porg-meta-for-path (buffer-file-name))
                              (alist-get 'project))))
    (cond
     (current-project current-project)
     ((projectile-project-p) (projectile-project-name))
     (t nil))))

(defun pm/porg-current-file ()
  (->> (pm/porg-meta-for-name (pm/porg-current-name))
       (alist-get 'path)))

(defun pm/porg-open-file ()
  (interactive)
  (when-let ((file (pm/porg-current-file)))
    (find-file-other-window file)))

(defun pm/porg--capture-templates-for (name)
	(let ((file (alist-get 'path (pm/porg-meta-for-name name))))
	  `(("j" "Log" entry (file+olp+datetree ,file "Log")
	    "*** %<%H:%M> %?\n")
	   ("k" "Logged task" entry (file+olp+datetree ,file "Log")
	    "*** TODO %<%H:%M> %?\n" :clock-in t)
	   ("l" "Task" entry (file+olp,file "Tasks")
	    "*** TODO %t %?\n")
	   ("m" "Note" entry (file+olp ,file "Notes")
	    "** %t %?\n"))))

(defun pm/porg-capture ()
	(interactive)
	(when-let (file (pm/porg-current-file))
	  (let ((org-capture-templates (pm/porg--capture-templates-for (pm/porg-current-name))))
	    (org-capture))))

(use-package! pasp-mode
  :mode "\\.lp$"
  :defer t
  :config
  (map! :map pasp-mode-map
        :localleader
        "e" #'pasp-run-buffer))

(+global-word-wrap-mode +1)

(map! :leader
      "n p" #'pm/porg-capture
      "n P" #'pm/porg-open-file)

(setq avy-all-windows t)
