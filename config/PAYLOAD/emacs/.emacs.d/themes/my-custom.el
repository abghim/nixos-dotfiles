;;; my-custom-theme.el --- Custom theme skeleton  -*- lexical-binding: t; -*-
;;
;;  A minimal starter theme that lists all commonly used font‑lock faces.
;;  Edit the hex codes below to whatever palette you like.
;;
;;; Code:

(deftheme my-custom "Custom theme skeleton listing common syntax faces.")

(let ((class '((class color) (min-colors 89)))
      ;; --- Palette ----------------------------------------------------------
      (bg         "#1e1e1e")
      (fg         "#d4d4d4")
      (cursor     "#aeafad")
      (region     "#264f78")
      (keyword    "#569cd6")
      (type       "#4ec9b0")
      (builtin    "#c586c0")
      (constant   "#dcdcaa")
      (string     "#ce9178")
      (comment    "#6a9955")
      (preproc    "#9cdcfe")
      (variable   "#9cdcfe")
      (function   "#dcdcaa")
      (warning    "#f44747"))
  ;; --- Faces ---------------------------------------------------------------
  (custom-theme-set-faces
   'my-custom
   `(default                     ((,class (:background ,bg :foreground ,fg))))
   `(cursor                      ((,class (:background ,cursor))))
   `(region                      ((,class (:background ,region))))
   `(highlight                   ((,class (:background ,region))))

   ;; Syntax highlighting faces:
   `(font-lock-builtin-face      ((,class (:foreground ,builtin))))
   `(font-lock-keyword-face      ((,class (:foreground ,keyword :weight bold))))
   `(font-lock-type-face         ((,class (:foreground ,type))))
   `(font-lock-preprocessor-face ((,class (:foreground ,preproc))))
   `(font-lock-constant-face     ((,class (:foreground ,constant))))
   `(font-lock-variable-name-face((,class (:foreground ,variable))))
   `(font-lock-function-name-face((,class (:foreground ,function))))
   `(font-lock-string-face       ((,class (:foreground ,string))))
   `(font-lock-comment-face      ((,class (:foreground ,comment :slant italic))))
   `(font-lock-warning-face      ((,class (:foreground ,warning :weight bold))))

   ;; Misc UI helpers
   `(link                         ((,class (:underline t :foreground ,keyword))))
   ))

;;;###theme-autoload
(provide-theme 'my-custom)
;;; my-custom-theme.el ends here
