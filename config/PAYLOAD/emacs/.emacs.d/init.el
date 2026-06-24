(add-to-list 'custom-theme-load-path
             (expand-file-name "themes" user-emacs-directory))
(load-theme 'jeju-one-dark t)      ; ‘t’ = load w/o query

(require 'cl-lib)

(defgroup mv-statusline nil
  "Neovim-like statusline segment for Emacs."
  :group 'mode-line)

(defcustom mv-statusline-bg "#14191f"
  "Fallback background color for the statusline."


  :type 'string
  :group 'mv-statusline)

(defcustom mv-statusline-fg "#ffffff"
  "Fallback foreground color for the statusline."
  :type 'string
  :group 'mv-statusline)

(defcustom mv-statusline-mode-colors
  ["#A04C62" "#467159" "#C45A26" "#285A6B"]
  "Mode base colors in the same order as the Neovim statusline."
  :type '(vector string string string string)
  :group 'mv-statusline)

(defcustom mv-statusline-gradient-steps 12
  "Number of fade steps between mode color and background."
  :type 'integer
  :group 'mv-statusline)

(defvar mv-statusline--icon-backend nil)
(defvar mv-statusline--startup-random-color nil)
(defconst mv-function-lavender "#cabbed"
  "Shared lavender tone used for function symbols.")
(defvar mv-icon-packages '(nerd-icons nerd-icons-dired treemacs treemacs-nerd-icons)
  "UI packages used by statusline icons and the file tree.")
(defconst mv-function-call-fallback-blocklist
  '("if" "for" "while" "switch" "catch" "return" "throw" "new"
    "sizeof" "typeof" "class" "struct" "enum" "fn" "def" "function")
  "Keywords that should not be highlighted as function calls.")

(defun mv-statusline--random-mode-color ()
  (aref mv-statusline-mode-colors
        (random (length mv-statusline-mode-colors))))

(unless mv-statusline--startup-random-color
  (setq mv-statusline--startup-random-color
        (mv-statusline--random-mode-color)))

(defun mv-apply-function-highlight-faces ()
  (when (facep 'font-lock-function-name-face)
    (set-face-attribute 'font-lock-function-name-face nil
                        :foreground mv-function-lavender))
  (when (facep 'font-lock-function-call-face)
    (set-face-attribute 'font-lock-function-call-face nil
                        :foreground mv-function-lavender
                        :weight 'normal)))

(defun mv-reapply-highlights-after-theme (&rest _)
  (mv-apply-function-highlight-faces))

(mv-apply-function-highlight-faces)
(unless (advice-member-p #'mv-reapply-highlights-after-theme 'load-theme)
  (advice-add 'load-theme :after #'mv-reapply-highlights-after-theme))

(with-eval-after-load 'treesit
  (setq-default treesit-font-lock-level 4))

(defun mv-boost-treesit-font-lock ()
  (when (boundp 'treesit-font-lock-level)
    (setq-local treesit-font-lock-level 4)))

(add-hook 'after-change-major-mode-hook #'mv-boost-treesit-font-lock)

(defvar mv-treesit-remap-targets
  '((bash-mode bash-ts-mode bash)
    (c-mode c-ts-mode c)
    (c++-mode c++-ts-mode cpp)
    (css-mode css-ts-mode css)
    (js-mode js-ts-mode javascript)
    (json-mode json-ts-mode json)
    (python-mode python-ts-mode python)
    (rust-mode rust-ts-mode rust)
    (typescript-mode typescript-ts-mode typescript))
  "Legacy major modes remapped to tree-sitter modes when grammars exist.")

(defun mv-setup-treesit-remaps ()
  (when (fboundp 'treesit-language-available-p)
    (dolist (entry mv-treesit-remap-targets)
      (pcase-let ((`(,classic-mode ,ts-mode ,language) entry))
        (when (and (fboundp ts-mode)
                   (treesit-language-available-p language))
          (add-to-list 'major-mode-remap-alist
                       (cons classic-mode ts-mode)))))))

(mv-setup-treesit-remaps)

(defun mv-function-call-fallback-matcher (limit)
  (catch 'match
    (while (re-search-forward "\\_<\\([[:alpha:]_][[:alnum:]_]*\\)\\s-*(" limit t)
      (let ((symbol (match-string-no-properties 1)))
        (unless (member symbol mv-function-call-fallback-blocklist)
          (throw 'match t))))
    nil))

(defun mv-enable-function-call-fallback-highlighting ()
  ;; Fallback for non-tree-sitter modes or missing grammars.
  (font-lock-add-keywords
   nil
   '((mv-function-call-fallback-matcher
      (1 'font-lock-function-call-face keep)))
   'append))

(add-hook 'prog-mode-hook #'mv-enable-function-call-fallback-highlighting)

(defun mv-statusline--hex-to-rgb (hex)
  (unless (and (stringp hex)
               (string-match-p "^#[[:xdigit:]]\\{6\\}$" hex))
    (setq hex "#000000"))
  (list (string-to-number (substring hex 1 3) 16)
        (string-to-number (substring hex 3 5) 16)
        (string-to-number (substring hex 5 7) 16)))

(defun mv-statusline--blend (a b tval)
  (pcase-let ((`(,r1 ,g1 ,b1) (mv-statusline--hex-to-rgb a))
              (`(,r2 ,g2 ,b2) (mv-statusline--hex-to-rgb b)))
    (cl-labels ((lerp (x y) (+ x (* (- y x) tval))))
      (format "#%02x%02x%02x"
              (round (lerp r1 r2))
              (round (lerp g1 g2))
              (round (lerp b1 b2))))))

(defun mv-statusline--theme-bg ()
  (let ((bg (face-background 'default nil t)))
    (if (and (stringp bg) (string-prefix-p "#" bg))
        bg
      mv-statusline-bg)))

(defun mv-statusline--theme-fg ()
  (let ((fg (face-foreground 'default nil t)))
    (if (and (stringp fg) (string-prefix-p "#" fg))
        fg
      mv-statusline-fg)))

(defun mv-statusline--mode-state ()
  (cond
   ((and (bound-and-true-p evil-local-mode) (boundp 'evil-state))
    (pcase evil-state
      ('normal '("NORMAL" . 1))
      ('motion '("NORMAL" . 1))
      ('insert '("INSERT" . 2))
      ('replace '("REPLACE" . 3))
      ('emacs '("NORMAL" . 3))
      ('operator '("SELECT" . 4))
      ('visual
       (cond
        ((and (boundp 'evil-visual-selection)
              (eq evil-visual-selection 'line))
         '("V-LINE" . 4))
        ((and (boundp 'evil-visual-selection)
              (eq evil-visual-selection 'block))
         '("V-BLOCK" . 4))
        (t '("VISUAL" . 4))))
      (_ '("NORMAL" . 1))))
   ((minibufferp (current-buffer)) '("NORMAL" . 3))
   ((and (boundp 'overwrite-mode) overwrite-mode) '("REPLACE" . 3))
   ((use-region-p) '("SELECT" . 4))
   (t '("GNU Emacs" . 2))))

(defun mv-statusline--buffer-label ()
  (let ((name (and (buffer-file-name)
                   (file-name-nondirectory (buffer-file-name)))))
    (if (and name (not (equal name "")))
        name
      "[No Name]")))

(defun mv-statusline--icon-source ()
  (or (buffer-file-name)
      (when (derived-mode-p 'dired-mode)
        (directory-file-name default-directory))
      (buffer-name)))

(defun mv-statusline--detect-icon-backend ()
  (or mv-statusline--icon-backend
      (setq mv-statusline--icon-backend
            (cond
             ((and (require 'nerd-icons nil t)
                   (fboundp 'nerd-icons-icon-for-file))
              'nerd-icons)
             ((and (require 'all-the-icons nil t)
                   (fboundp 'all-the-icons-icon-for-file))
              'all-the-icons)
             (t 'fallback)))))

(defun mv-statusline--file-icon (file bg)
  (let ((icon
         (pcase (mv-statusline--detect-icon-backend)
           ('nerd-icons (nerd-icons-icon-for-file file))
           ('all-the-icons (all-the-icons-icon-for-file file))
           (_ ""))))
    (unless (and (stringp icon) (> (length icon) 0))
      (setq icon ""))
    (add-face-text-property 0 (length icon) `(:background ,bg) t icon)
    icon))

(defun mv-statusline-render ()
  (let* ((steps (max 1 mv-statusline-gradient-steps))
         (bg (mv-statusline--theme-bg))
         (fg (mv-statusline--theme-fg))
         (state (mv-statusline--mode-state))
         (label (car state))
         (base mv-statusline--startup-random-color)
         (gradient (cl-loop for i from 0 to steps
                            collect (mv-statusline--blend
                                     base bg (/ (float i) steps))))
         (mode-block (propertize (format " %s " label)
                                 'face `(:foreground ,fg :background ,base)))
         (fade (mapconcat
                (lambda (i)
                  (propertize ""
                              'face `(:foreground ,(nth (1- i) gradient)
                                     :background ,(nth i gradient))))
                (number-sequence 1 steps)
                ""))
	         (file (mv-statusline--buffer-label))
	         (icon (mv-statusline--file-icon
	                (mv-statusline--icon-source) bg))
	         (file-part (concat "  "
	                            icon
	                            " "
	                            (propertize file 'face `(:foreground ,fg :background ,bg))
	                            " ")))
    (concat mode-block fade file-part)))

(setq-default mode-line-format '("%e" (:eval (mv-statusline-render))))
(setq backup-directory-alist `(("." . "~/.emacs.d/.saves")))
(add-hook 'prog-mode-hook
          (lambda ()
            (font-lock-add-keywords
             nil
             '(("\\_<[0-9]+\\(?:\\.[0-9]+\\)?\\_>" 
                0 'font-lock-number-face keep)))))

(add-to-list 'custom-theme-load-path
             (expand-file-name "themes" user-emacs-directory))
(load-theme 'jeju-one-dark t)
(xterm-mouse-mode 1)

(mouse-wheel-mode 1)

(setq mouse-wheel-scroll-amount '(1 ((shift) . 5) ((control) . nil))
	        mouse-wheel-progressive-speed nil
			      mouse-wheel-follow-mouse t)
(setq scroll-step 1
	        scroll-conservatively 10000
			      scroll-preserve-screen-position t) 

(setq scroll-margin 4)

(setq next-screen-context-lines 1)

(require 'package)

(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))


(let ((missing (cl-remove-if #'package-installed-p mv-icon-packages)))
  (when missing
    (condition-case err
        (package-refresh-contents)
      (error
       (message "Could not refresh package archives: %s"
                (error-message-string err))))
    (dolist (pkg missing)
      (condition-case err
          (package-install pkg)
        (error
         (message "Could not install %s: %s"
                  pkg (error-message-string err)))))))

(with-eval-after-load 'dired
  (when (require 'nerd-icons-dired nil t)
    (add-hook 'dired-mode-hook #'nerd-icons-dired-mode)))

(when (require 'treemacs nil t)
  (setq treemacs-width 34
        treemacs-follow-after-init t
        treemacs-is-never-other-window t)
  (global-set-key (kbd "C-c t") #'treemacs)
  (global-set-key (kbd "C-c T") #'treemacs-select-window)
  (when (require 'treemacs-nerd-icons nil t)
    (treemacs-load-theme "nerd-icons")))

(menu-bar-mode -1)
(set-face-attribute 'mode-line nil
                    :background "#14191f"
                    :foreground "#ffffff"
		    :box nil)
(set-face-attribute 'mode-line-inactive nil
                    :background "#14191f"
                    :foreground "#ffffff"
		    :box nil)

;; Auto-insert matching (), {}, and [] while typing.
(electric-pair-mode 1)
(show-paren-mode 1)

(global-hl-line-mode 1)
(set-face-attribute 'hl-line nil :background "#1c2228" :extend t)

(setq-default display-line-numbers-type 'relative)
(setq display-line-numbers-current-absolute t)
(global-display-line-numbers-mode 1)

(dolist (hook '(term-mode-hook
                shell-mode-hook
                eshell-mode-hook
                treemacs-mode-hook
                vterm-mode-hook))
  (add-hook hook (lambda () (display-line-numbers-mode 0))))

(setq-default left-margin-width 2)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(require 'package)

(setq package-archives
      '(("gnu"   . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa" . "https://melpa.org/packages/")))

(unless package-archive-contents
  (package-refresh-contents))

(dolist (pkg '(use-package magit vterm))
  (unless (package-installed-p pkg)
    (package-install pkg)))

(require 'use-package)

(use-package magit
  :ensure t
  :commands (magit-status magit-dispatch))

(use-package vterm
  :ensure t
  :commands vterm)
