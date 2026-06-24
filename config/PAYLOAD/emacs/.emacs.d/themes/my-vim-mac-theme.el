(deftheme my-vim-mac
  "Minimal theme that mimics the default macOS Vim palette.")

;; a helper so we don’t repeat the `t` spec
(defun mv/face (face &rest plist)
  (custom-theme-set-faces
   'my-vim-mac `(,face ((t ,plist)))))



(mv/face 'default                 :background "#000000" :foreground "#ffffff")
(mv/face 'font-lock-type-face     :foreground "#A8FDBA")
(mv/face 'font-lock-keyword-face  :foreground "#ECEC51")
(mv/face 'font-lock-constant-face :foreground "#EC4FF7") ; literals
(mv/face 'font-lock-string-face   :foreground "#EC4FF7")
(mv/face 'font-lock-variable-name-face   :foreground "#ffffff")
(mv/face 'font-lock-comment-face   :foreground "#8BDFFB")
(mv/face 'font-lock-preprocessor-face   :foreground "#88DFFB")
(mv/face 'font-lock-escape-face   :foreground "#f8dddd")
(mv/face 'font-lock-function-name-face   :foreground "#9ad5fb")
(mv/face 'font-lock-number-face   :foreground "#EC4FF7")
(mv/face 'font-lock-function-call-face   :foreground "#9ad5fb")

(provide-theme 'my-vim-mac)
;; vim-colors-theme.el ends here
