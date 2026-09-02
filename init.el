;;; nano.emacs.d init.el --- nano-emacs via straight.el

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el"
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

;; early warning / native-comp silencing before nano loads (prevents RO | *Warnings* during straight build)
(setq native-comp-async-report-warnings-errors 'silent
      native-comp-warning-on-missing-source nil
      warning-minimum-level :error
      warning-minimum-log-level :warning
      warning-suppress-types '((comp) (native-compiler) (lexical) (undo discard-info))
      python-indent-guess-indent-offset-verbose nil)

(setq nano-font-family-monospaced "Noto Sans Mono")

(straight-use-package
 '(nano :type git :host github :repo "rougier/nano-emacs"))

(require 'nano)

;; --- fix vendored nano warnings / RO | *Warnings* (Special) bottom pane ---
;; warnings still logged to *Warnings* but not auto-displayed as bottom window
;; (RO | *Warnings* (Special) header). User can still view via C-h e
(add-to-list 'display-buffer-alist
             '("\\*Warnings\\*" (display-buffer-no-window) (allow-no-window . t)))

;; --- hard-disable GUI chrome (override nano-defaults.el:92) ---
(when (fboundp 'menu-bar-mode) (menu-bar-mode -1))
(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(setq default-frame-alist
      (cons '(menu-bar-lines . 0)
            (cons '(tool-bar-lines . 0)
                  (assq-delete-all 'tool-bar-lines
                    (assq-delete-all 'menu-bar-lines default-frame-alist)))))
(add-hook 'after-make-frame-functions
          (lambda (_f) (when (fboundp 'menu-bar-mode) (menu-bar-mode -1))
            (when (fboundp 'tool-bar-mode) (tool-bar-mode -1))))

;; --- evil (vars must be BEFORE load) ---
(setq evil-want-integration t
      evil-want-keybinding nil
      evil-want-C-u-scroll t
      evil-want-C-i-jump nil
      evil-undo-system 'undo-redo)

(straight-use-package 'evil)
(straight-use-package 'which-key)

(require 'evil)
(evil-mode 1)
(require 'which-key)
(which-key-mode 1)
(setq which-key-idle-delay 0.4
      which-key-idle-secondary-delay 0.1)

;; --- SPC leader native, no general (lightest) ---
(define-prefix-command 'spacemacs-leader-map)
(define-key evil-normal-state-map (kbd "SPC") spacemacs-leader-map)
(define-key evil-visual-state-map (kbd "SPC") spacemacs-leader-map)
(define-key evil-motion-state-map (kbd "SPC") spacemacs-leader-map)
(global-set-key (kbd "C-SPC") spacemacs-leader-map)

(which-key-add-key-based-replacements
  "SPC f" "file"
  "SPC b" "buffer"
  "SPC w" "window"
  "SPC q" "quit"
  "SPC s" "search"
  "SPC h" "help")

;; file
(define-key spacemacs-leader-map (kbd "SPC") 'execute-extended-command)
(define-key spacemacs-leader-map (kbd ":") 'execute-extended-command)
(define-key spacemacs-leader-map (kbd "f f") 'find-file)
(define-key spacemacs-leader-map (kbd "f s") 'save-buffer)
(define-key spacemacs-leader-map (kbd "f S") 'save-some-buffers)
(define-key spacemacs-leader-map (kbd "f r") 'recentf-open-files)
;; buffer
(define-key spacemacs-leader-map (kbd "b b") 'switch-to-buffer)
(define-key spacemacs-leader-map (kbd "b d") 'kill-current-buffer)
(define-key spacemacs-leader-map (kbd "b n") 'next-buffer)
(define-key spacemacs-leader-map (kbd "b p") 'previous-buffer)
;; window
(define-key spacemacs-leader-map (kbd "w /") 'split-window-right)
(define-key spacemacs-leader-map (kbd "w -") 'split-window-below)
(define-key spacemacs-leader-map (kbd "w d") 'delete-window)
(define-key spacemacs-leader-map (kbd "w m") 'delete-other-windows)
(define-key spacemacs-leader-map (kbd "w h") 'evil-window-left)
(define-key spacemacs-leader-map (kbd "w j") 'evil-window-down)
(define-key spacemacs-leader-map (kbd "w k") 'evil-window-up)
(define-key spacemacs-leader-map (kbd "w l") 'evil-window-right)
;; quit
(define-key spacemacs-leader-map (kbd "q q") 'save-buffers-kill-terminal)
(define-key spacemacs-leader-map (kbd "q Q") 'kill-emacs)
;; search/help
(define-key spacemacs-leader-map (kbd "s s") 'isearch-forward)