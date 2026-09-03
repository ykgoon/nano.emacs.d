;;; init.el --- nano-emacs via straight.el -*- lexical-binding: t -*-
;;; Commentary:
;; Single-file config for rougier/nano-emacs, managed by straight.el.
;; Launch with: emacs --init-directory ~/nano.emacs.d
;; Restart required after edits (no live reloader).
;; See AGENTS.md for layout/gotchas.

;;; Code:

;; =====================================================================
;; Table of Contents  (search "§N" to jump)
;;   §0  Bootstrap straight.el
;;   §1  Startup silencing & warnings  (before nano loads)
;;   §2  Appearance  (font, nano theme, visual-line, GUI chrome)
;;   §3  Vim emulation  (evil + which-key)
;;   §4  SPC leader definition  (native, no general.el)
;;   §5  Leader keybindings  (file / buffer / window / quit / search)
;;   §6  Window management  (winum, header-line number, double/triple columns)
;;   §7  Theme toggle + persistence  (SPC T n)
;;   §8  Completion  (built-in icomplete-vertical, helm-like list)
;;   §9  Workspace  (built-in tab-bar, SPC l, name in modeline)
;;   §10 Git  (magit + delta, SPC g)
;;   §11 Project  (built-in project.el, SPC p)
;;   §12 Search  (ripgrep via built-in project+xref, SPC s)
;;   §13 File sync  (built-in auto-revert, SPC b R fallback)
;;   §14 Zoom  (buffer text-scale, SPC z x, repeat transient)
;;   §15 Text  (SPC x, built-in + link-hint lazy)
;; =====================================================================


;; ---------------------------------------------------------------------
;; §0  Bootstrap straight.el
;; ---------------------------------------------------------------------
;; Provides `straight-use-package'.  On first run, fetches
;; radian-software/straight.el:develop/install.el via url-retrieve.
;; `user-emacs-directory' == launch dir (~/nano.emacs.d) thanks to
;; --init-directory.  All clones live in straight/repos/.
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


;; ---------------------------------------------------------------------
;; §1  Startup silencing & warnings  (must be BEFORE nano loads)
;; ---------------------------------------------------------------------
;; Goal: keep startup quiet while still logging.  nano + straight build
;; trigger native-comp and vendored lexical warnings that would otherwise
;; pop a read-only "*Warnings* (Special)" pane on every launch.
;;
;; What each does:
;; - native-comp-async-report-warnings-errors = silent   → no *Warnings* popup from async compile
;; - native-comp-warning-on-missing-source = nil         → ignore eln missing-source noise
;; - warning-minimum-level :error / log-level :warning   → only :error shown, rest logged
;; - warning-suppress-types (comp, native-compiler, lexical, undo discard-info) → filter known noisy categories
;; - python-indent-guess-indent-offset-verbose = nil     → silence python indent guess
(setq native-comp-async-report-warnings-errors 'silent
      native-comp-warning-on-missing-source nil
      warning-minimum-level :error
      warning-minimum-log-level :warning
      warning-suppress-types '((comp) (native-compiler) (lexical) (undo discard-info))
      python-indent-guess-indent-offset-verbose nil)

;; Suppress auto-display of *Warnings* buffer as a bottom window (the
;; "RO | *Warnings* (Special)" header).  Warnings still accumulate in
;; *Warnings* and are viewable via `C-h e' (view-echo-area-messages)
;; or `M-x view-warning'.  Uses display-buffer-no-window so no window
;; is created, but buffer remains alive.
(add-to-list 'display-buffer-alist
             '("\\*Warnings\\*" (display-buffer-no-window) (allow-no-window . t)))


;; ---------------------------------------------------------------------
;; §2  Appearance
;; ---------------------------------------------------------------------
;; Order matters: font/theme vars MUST be set BEFORE (require 'nano),
;; else nano defaults override them (see AGENTS.md Gotchas).
;; GUI chrome hard-disable MUST be AFTER (require 'nano) to override
;; nano-defaults.el:92.

;; 2a. Font — Noto Sans Mono required system-wide (AGENTS.md).
;;     Family + size tweak here; must stay before nano load.
(setq nano-font-family-monospaced "Noto Sans Mono"
      nano-font-size 12)

;; 2b. Theme — rougier/nano-emacs via straight.  Vendored clone at
;;     straight/repos/nano-emacs/.  Edit vendored code → M-x straight-rebuild-package.
(straight-use-package
 '(nano :type git :host github :repo "rougier/nano-emacs"))

(require 'nano)

;; 2c. Line wrapping — visual-line wraps long lines without hard newline.
(global-visual-line-mode 1)

;; 2d. GUI chrome — hard-disable menu/tool/scroll bars even in GUI frames.
;;     nano-defaults enables them; this overrides unconditionally and also
;;     on new frames via after-make-frame-functions.
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

;; Maximized desktop startup — re-assert after nano-layout.el:22 overwrote alists.
;; early-init.el sets same before first frame (no flicker); this ensures persistence.
(add-to-list 'initial-frame-alist '(fullscreen . maximized))
(add-to-list 'default-frame-alist '(fullscreen . maximized))
;; Fallback: init.el runs after initial frame creation, so explicitly maximize
;; the live frame (tty/batch ignored, graphic only).
(add-hook 'window-setup-hook (lambda () (when (display-graphic-p)
                                     (set-frame-parameter nil 'fullscreen 'maximized))))


;; ---------------------------------------------------------------------
;; §3  Vim emulation  (evil + which-key)
;; ---------------------------------------------------------------------
;; Keep lightweight: evil + which-key only, no general.el or hydra.
;; Evil vars MUST be set BEFORE (require 'evil) / load.

;; 3a. Evil pre-load vars
;;     evil-want-integration t + evil-want-keybinding nil → use evil-collection style later if added
;;     evil-want-C-u-scroll t → C-u scrolls like vim
;;     evil-want-C-i-jump nil → keep C-i distinct from TAB in terminal
;;     evil-undo-system undo-redo → use Emacs 28+ undo-redo instead of undo-tree
(setq evil-want-integration t
      evil-want-keybinding nil
      evil-want-C-u-scroll t
      evil-want-C-i-jump nil
      evil-undo-system 'undo-redo)

;; 3b. Packages
(straight-use-package 'evil)
(straight-use-package 'which-key)

;; 3c. Enable
(require 'evil)
(evil-mode 1)
(require 'which-key)
(which-key-mode 1)
(setq which-key-idle-delay 0.4            ; pop after 400ms
      which-key-idle-secondary-delay 0.1)  ; second popup faster


;; ---------------------------------------------------------------------
;; §4  SPC leader definition  (native prefix map, no general.el)
;; ---------------------------------------------------------------------
;; Spacemacs-style mnemonic SPC leader using a single prefix map.
;; Bound in evil normal/visual/motion + global C-SPC for insert/emacs state.
;; which-key labels give discoverable "file / buffer / window ..." hints.
(define-prefix-command 'spacemacs-leader-map)
(define-key evil-normal-state-map (kbd "SPC") spacemacs-leader-map)
(define-key evil-visual-state-map (kbd "SPC") spacemacs-leader-map)
(define-key evil-motion-state-map (kbd "SPC") spacemacs-leader-map)
(global-set-key (kbd "C-SPC") spacemacs-leader-map)

;; Top-level which-key group labels (shown when pressing SPC)
(which-key-add-key-based-replacements
  "SPC f" "file"
  "SPC b" "buffer"
  "SPC w" "window"
  "SPC l" "workspace"
  "SPC q" "quit"
  "SPC s" "search"
  "SPC h" "help"
  "SPC t" "toggle"
  "SPC z" "zoom"
  "SPC z x" "text")


;; ---------------------------------------------------------------------
;; §5  Leader keybindings
;; ---------------------------------------------------------------------
;; Mnemonic groups: file, buffer, window, quit, search.
;; Edit here to add new SPC bindings.  Keep sorted by group for scanability.
;; Note: SPC w 2 / SPC w 3 live in §6 (window mgmt).

;; 5a. File  (SPC f)
(define-key spacemacs-leader-map (kbd "SPC") 'execute-extended-command) ; SPC SPC → M-x
(define-key spacemacs-leader-map (kbd ":") 'execute-extended-command)   ; SPC :   → M-x (Spacemacs compat)
(define-key spacemacs-leader-map (kbd "f f") 'find-file)
(define-key spacemacs-leader-map (kbd "f s") 'save-buffer)
(define-key spacemacs-leader-map (kbd "f S") 'save-some-buffers)
(define-key spacemacs-leader-map (kbd "f r") 'recentf-open-files)

;; 5b. Buffer  (SPC b)
(define-key spacemacs-leader-map (kbd "TAB") 'mode-line-other-buffer)
(define-key spacemacs-leader-map (kbd "b b") 'switch-to-buffer)
(define-key spacemacs-leader-map (kbd "b d") 'kill-current-buffer)
(define-key spacemacs-leader-map (kbd "b n") 'next-buffer)
(define-key spacemacs-leader-map (kbd "b p") 'previous-buffer)
(define-key spacemacs-leader-map (kbd "b R") 'revert-buffer)
(which-key-add-key-based-replacements
  "SPC TAB" "last buffer"
  "SPC b R" "revert buffer")

;; 5c. Window  (SPC w)  — basic splits & navigation
(define-key spacemacs-leader-map (kbd "w /") 'split-window-right)   ; vsplit
(define-key spacemacs-leader-map (kbd "w s") 'split-window-below)   ; hsplit
(define-key spacemacs-leader-map (kbd "w d") 'delete-window)
(define-key spacemacs-leader-map (kbd "w m") 'delete-other-windows) ; maximize
(define-key spacemacs-leader-map (kbd "w h") 'evil-window-left)
(define-key spacemacs-leader-map (kbd "w j") 'evil-window-down)
(define-key spacemacs-leader-map (kbd "w k") 'evil-window-up)
(define-key spacemacs-leader-map (kbd "w l") 'evil-window-right)
(define-key spacemacs-leader-map (kbd "w r") 'nano/window-rotate-forward)  ; rotate right
(define-key spacemacs-leader-map (kbd "w R") 'nano/window-rotate-backward) ; rotate left
;; SPC w 2 / SPC w 3 (double/triple columns) defined in §6c — kept with its implementation.

;; 5d. Quit / session  (SPC q)
(define-key spacemacs-leader-map (kbd "q q") 'save-buffers-kill-terminal)
(define-key spacemacs-leader-map (kbd "q Q") 'kill-emacs)
(define-key spacemacs-leader-map (kbd "q r") 'restart-emacs)

;; 5e. Search & help  (SPC s / SPC h)
(define-key spacemacs-leader-map (kbd "s s") 'isearch-forward)
;; SPC h group label declared in §4; add help bindings here as needed.


;; ---------------------------------------------------------------------
;; §6  Window management  (winum, header-line, double/triple columns)
;; ---------------------------------------------------------------------

;; 6a. Window numbers — winum (deb0ch/emacs-winum)
;;     Lightest numbered-window picker.  M-0..M-9 jump.
;;     M-0 = 0-or-10 (last window).
(straight-use-package '(winum :type git :host github :repo "deb0ch/emacs-winum"))
(require 'winum)
(setq winum-auto-assign-0-to-minibuffer nil
      winum-auto-setup-mode-line nil            ; we inject manually into nano header
      winum-ignored-buffers '(" *LV*" " *which-key*"))
(winum-mode 1)

;; M-0..M-9 global jumps (work in any evil state)
(define-key winum-keymap (kbd "M-0") 'winum-select-window-0-or-10)
(define-key winum-keymap (kbd "M-1") 'winum-select-window-1)
(define-key winum-keymap (kbd "M-2") 'winum-select-window-2)
(define-key winum-keymap (kbd "M-3") 'winum-select-window-3)
(define-key winum-keymap (kbd "M-4") 'winum-select-window-4)
(define-key winum-keymap (kbd "M-5") 'winum-select-window-5)
(define-key winum-keymap (kbd "M-6") 'winum-select-window-6)
(define-key winum-keymap (kbd "M-7") 'winum-select-window-7)
(define-key winum-keymap (kbd "M-8") 'winum-select-window-8)
(define-key winum-keymap (kbd "M-9") 'winum-select-window-9)

;; 6b. Modeline sections — Spacemacs blocks, bottom bar only
;;     Layout: [N] [RO/RW/**] filename (detail) ... position <workspace>
;;     Redefines `nano-modeline-compose' (same signature, so every mode
;;     benefits) instead of patching nano source.  Single auto-named tab
;;     tracks the buffer name, which used to render `<init.el> ... init.el'
;;     (workspace + file duplicated); workspace now lives far-right and the
;;     initial tab is named "main" in §9, so no adjacency dup.
(defun nano/winum-number-string ()
  "Return propertized window number block for current window, or nil."
  (when (and (bound-and-true-p winum-mode)
             (fboundp 'winum-get-number))
    (let ((n (ignore-errors (winum-get-number (selected-window)))))
      (when n
        (propertize (format " %d " n) 'face 'nano-face-header-strong)))))

(defun nano/workspace-name-string ()
  "Return propertized current tab-bar workspace block, or nil.
Reads the tab's explicit name (`SPC l r'); unnamed tabs fall back to
their index.  NOTE: `tab-bar-tab-name-current' is unusable here — in
Emacs 30 it is a C subr that always derives the name from the buffer,
which duplicated the filename in the modeline."
  (when (and (bound-and-true-p tab-bar-mode)
             (fboundp 'tab-bar--current-tab))
    (let* ((tab (ignore-errors (tab-bar--current-tab)))
           ;; NOTE: auto tabs carry (explicit-name) with nil VALUE — test
           ;; the value, not key presence.
           (name (or (and (alist-get 'explicit-name tab)
                          (alist-get 'name tab))
                     (and (fboundp 'tab-bar--current-tab-index)
                          (ignore-errors
                            (number-to-string
                             (1+ (tab-bar--current-tab-index))))))))
      (when (and name (not (string-empty-p name)))
        (propertize (format " <%s> " name) 'face 'nano-face-header-salient)))))

;; Drop the old status-prefix advice on reload; the redefinition below
;; renders winum + workspace as their own blocks instead.
(advice-remove 'nano-modeline-compose 'nano-winum-prefix)

(with-eval-after-load 'nano-modeline
  (defun nano-modeline-compose (status name primary secondary)
    "Spacemacs-block modeline: winum, RO/RW/**, filename, far-right workspace."
    (let* ((char-width    (window-font-width nil 'mode-line))
           (space-up       +0.15)
           (space-down     -0.20)
           (winum (nano/winum-number-string))
           (ws    (nano/workspace-name-string))
           ;; Status block — same RO/**/RW face mapping as upstream.
           (prefix (let* ((code (cond ((string-suffix-p "RO" status) "RO")
                                      ((string-suffix-p "**" status) "**")
                                      ((string-suffix-p "RW" status) "RW")
                                      (t nil)))
                          (face (if (window-dedicated-p)
                                    'nano-face-header-popout
                                  (cond ((string= code "RO") 'nano-face-header-popout)
                                        ((string= code "**") 'nano-face-header-critical)
                                        ((string= code "RW") 'nano-face-header-faded)
                                        (t 'nano-face-header-popout))))
                          (text (if code
                                    (let ((base (substring status 0 (- (length status) (length code)))))
                                      (concat (if (string= base "") " " base)
                                              (if (window-dedicated-p) "--" code) " "))
                                  status)))
                     (propertize text 'face face)))
           (sep (propertize " " 'face 'nano-face-header-default
                            'display `(raise ,space-down)))
           (head (concat
                  (or winum "")
                  sep
                  prefix
                  (propertize (concat " " name " ") 'face 'nano-face-header-strong)
                  (propertize primary 'face 'nano-face-header-default
                              'display `(raise ,space-up))))
           (right (concat secondary
                          (propertize " " 'face 'nano-face-header-default
                                      'display `(raise ,space-down))
                          (or ws "")))
           (available-width (- (window-total-width)
                               (length head) (length right)
                               (/ (window-right-divider-width) char-width)))
           (available-width (max 1 available-width)))
      (concat head
              (propertize (make-string available-width ?\ )
                          'face 'nano-face-header-default)
              (propertize right 'face `(:inherit nano-face-header-default
                                         :foreground ,nano-color-faded))))))

;; 6c. Double / triple vertical split — SPC w 2 / SPC w 3
;;     Creates two / three balanced vertical columns in current frame.
;;     Populates w2/w3 from eligible buffers (skips ephemeral " *..." buffers).
;;     C-u SPC w 2 / C-u SPC w 3 (purge) forces delete-other-windows ignoring window-parameters
;;     (e.g. pinned side windows that normally resist deletion).
(defun nano/window-split-eligible-buffers ()
  "Buffers to populate after split, excluding ephemeral * spaced names."
  (seq-remove (lambda (b)
                (and (string= (substring (buffer-name b) 0 1) " ")
                     (not (buffer-file-name b))))
              (buffer-list)))

(defun nano/window-split-double-columns (&optional purge)
  "Two vertical columns, balanced.  With PURGE (C-u), use `delete-other-windows' ignoring window params."
  (interactive "P")
  (if purge
      (let ((ignore-window-parameters t)) (delete-other-windows))
    (delete-other-windows))
  (let* ((bufs (nano/window-split-eligible-buffers))
         (w2 (ignore-errors (split-window-right))))
    (if w2
        (progn
          (set-window-buffer w2 (or (nth 1 bufs) "*scratch*"))
          (balance-windows))
      (message "SPC w 2: frame too narrow to split"))))

(defun nano/window-split-triple-columns (&optional purge)
  "Three vertical columns, balanced.  With PURGE (C-u), use `delete-other-windows' ignoring window params."
  (interactive "P")
  (if purge
      (let ((ignore-window-parameters t)) (delete-other-windows))
    (delete-other-windows))
  (let* ((bufs (nano/window-split-eligible-buffers))
         (w2 (ignore-errors (split-window-right)))
         (w3 (when w2 (ignore-errors (split-window w2 nil 'right)))))
    (if (and w2 w3)
        (progn
          (set-window-buffer w2 (or (nth 1 bufs) "*scratch*"))
          (set-window-buffer w3 (or (nth 2 bufs) "*scratch*"))
          (balance-windows))
      (message "SPC w 3: frame too narrow to split"))))

(define-key spacemacs-leader-map (kbd "w 2") 'nano/window-split-double-columns)
(define-key spacemacs-leader-map (kbd "w 3") 'nano/window-split-triple-columns)
(which-key-add-key-based-replacements "SPC w 2" "double columns"
                                      "SPC w 3" "triple columns")

;; 6d. Window rotation — SPC w r / SPC w R (Spacemacs parity, rotate all)
;;     SPC w r → forward (right), SPC w R → backward (left).
;;     Rotates buffers (and window states) across all windows in cyclic order.
;;     Supports prefix COUNT (C-u 2 SPC w r = two steps).  Plain = one step.
;;     No filtering — rotates all windows per user spec.
(defun nano/window-rotate-forward (count)
  "Rotate windows forward (right).  With COUNT rotate that many steps."
  (interactive "p")
  (let* ((wins (window-list))
         (num (length wins))
         (states (mapcar #'window-state-get wins))
         (step (+ num (or count 1))))
    (if (< num 2)
        (user-error "You can't rotate a single window!")
      (dotimes (i num)
        (window-state-put (elt states i)
                          (elt wins (% (+ step i) num)))))))

(defun nano/window-rotate-backward (count)
  "Rotate windows backward (left).  With COUNT rotate that many steps."
  (interactive "p")
  (nano/window-rotate-forward (* -1 (or count 1))))

(which-key-add-key-based-replacements "SPC w r" "rotate forward"
                                      "SPC w R" "rotate backward")


;; ---------------------------------------------------------------------
;; §7  Toggles  (SPC t n theme, SPC t w whitespace)
;; ---------------------------------------------------------------------
;; 7a. Theme — uses vendored nano-theme.el:802 `nano-toggle-theme' which checks
;; `nano-theme-var' ("light"/"dark") and calls `nano-theme-set-*' +
;; `nano-refresh-theme'.  Wrapper handles nil (e.g. -default start)
;; and adds echo feedback.  Lightweight, no extra package.
;; Choice persists in plain-text `nano/theme-state-file', restored on
;; next launch (skipped when explicit -dark/-light/-default CLI flag).
(require 'subr-x) ; string-trim for state file read (built-in)

(defvar nano/theme-state-file
  (locate-user-emacs-file "var/nano-theme")
  "Plain-text file holding last nano theme choice (\"light\"/\"dark\").")

(defun nano/theme-save ()
  "Persist current `nano-theme-var' to `nano/theme-state-file'."
  (when (member nano-theme-var '("light" "dark"))
    (make-directory (file-name-directory nano/theme-state-file) t)
    (with-temp-file nano/theme-state-file
      (insert nano-theme-var))))

(defun nano/theme-restore ()
  "Restore saved theme, unless explicit CLI theme flag given."
  (unless (or (member "-dark" command-line-args)
              (member "-light" command-line-args)
              (member "-default" command-line-args))
    (when (file-exists-p nano/theme-state-file)
      (let ((saved (with-temp-buffer
                     (insert-file-contents nano/theme-state-file)
                     (string-trim (buffer-string)))))
        (when (member saved '("light" "dark"))
          (cond ((string= saved "light") (nano-theme-set-light))
                ((string= saved "dark") (nano-theme-set-dark)))
          (nano-refresh-theme))))))

(defun nano/toggle-theme ()
  "Toggle nano light/dark theme.  Bound to SPC t n."
  (interactive)
  (cond ((string= nano-theme-var "light") (nano-theme-set-dark))
        ((string= nano-theme-var "dark")  (nano-theme-set-light))
        (t (nano-theme-set-dark))) ; nil/unknown -> dark as sensible default
  (nano-refresh-theme)
  (nano/theme-save)
  (message "nano theme: %s" nano-theme-var))

(nano/theme-restore)

;; 7b. Trailing whitespace — true red in ALL buffers, Spacemacs red parity.
;;     Mechanism is NOT theme-only: `show-trailing-whitespace' enables the
;;     highlight, `trailing-whitespace' face colors it.  Nano maps that face
;;     to `nano-face-subtle' (nano-theme.el:124), so override to true red here.
;;     `nano-refresh-theme' re-applies nano faces, so re-assert via advice.
(setq-default show-trailing-whitespace t)

(defun nano/apply-trailing-whitespace-face ()
  "Paint `trailing-whitespace' true red.  Re-applied after theme refresh."
  (set-face-attribute 'trailing-whitespace nil
                      :foreground 'unspecified :background "red"))

(nano/apply-trailing-whitespace-face)
(when (fboundp 'nano-refresh-theme)
  (advice-add 'nano-refresh-theme :after #'nano/apply-trailing-whitespace-face))

(defun nano/toggle-trailing-whitespace ()
  "Toggle trailing-whitespace highlight in all buffers.  Bound to SPC t w."
  (interactive)
  (let ((v (not (default-value 'show-trailing-whitespace))))
    (setq-default show-trailing-whitespace v)
    (dolist (b (buffer-list))
      (with-current-buffer b (setq show-trailing-whitespace v)))
    (message "trailing whitespace: %s" (if v "on" "off"))))

(define-key spacemacs-leader-map (kbd "t n") 'nano/toggle-theme)
(define-key spacemacs-leader-map (kbd "t w") 'nano/toggle-trailing-whitespace)
(which-key-add-key-based-replacements "SPC t n" "toggle theme"
                                      "SPC t w" "trailing whitespace")


;; ---------------------------------------------------------------------
;; §8  Completion  (built-in icomplete-vertical, helm-like list)
;; ---------------------------------------------------------------------
;; Zero-dep helm replacement: vertical candidate list for find-file,
;; switch-to-buffer, M-x, recentf, and any completing-read.
;; `fido-vertical-mode' = icomplete + vertical display + ido-like keys.
;; `flex' style gives fuzzy matching without orderless/vertico.
(require 'icomplete)
(fido-vertical-mode 1)
(setq icomplete-delay-completions 0
      icomplete-compute-delay 0
      icomplete-show-matches-on-no-input t
      icomplete-hide-common-prefix nil)
(setq completion-styles '(basic substring partial-completion flex)
      completion-category-overrides '((file (styles partial-completion))))
(setq enable-recursive-minibuffers t
      completion-cycle-threshold 3)
;; History: recentf backs SPC f r (bound in §5, mode was off);
;; savehist persists M-x / file / buffer histories across restarts.
(recentf-mode 1)
(savehist-mode 1)
;; C-n/C-p + arrows come free with icomplete-vertical-mode; add C-j/C-k
;; for evil-friendly navigation.  Displaced defaults preserved on C-M-:
;; C-j was `icomplete-force-complete-and-exit', C-k was `icomplete-fido-kill'.
(define-key icomplete-minibuffer-map (kbd "C-j") 'icomplete-forward-completions)
(define-key icomplete-minibuffer-map (kbd "C-k") 'icomplete-backward-completions)
(define-key icomplete-minibuffer-map (kbd "C-M-j") 'icomplete-force-complete-and-exit)
(define-key icomplete-minibuffer-map (kbd "C-M-k") 'icomplete-fido-kill)


;; ---------------------------------------------------------------------
;; §9  Workspace  (built-in tab-bar, SPC l, name in modeline)
;; ---------------------------------------------------------------------
;; Single-level Spacemacs `SPC l' equivalent: each tab = named workspace
;; with own window config.  Zero-dep (Emacs 30 built-in), no persp-mode /
;; eyebrowse.  Top tab bar stays hidden (`tab-bar-show' nil reclaims the
;; row); the name shows far-right in the bottom modeline (§6b), Spacemacs-style.
(require 'tab-bar)
(tab-bar-mode 1)
;; NOTE: plain setq on `tab-bar-show' does NOT take effect — it has a
;; custom :set that refreshes `tab-bar-lines' on all frames.  Must use
;; `customize-set-variable' or the top bar stays visible.
(customize-set-variable 'tab-bar-show nil)
(setq tab-bar-close-button-show nil
      tab-bar-new-button-show nil
      tab-bar-tab-hints t
      tab-bar-new-tab-choice "*scratch*"
      tab-bar-format '(tab-bar-format-tabs tab-bar-separator))

;; Single auto-named tab tracks the buffer name — name it "main" so the
;; modeline shows a workspace, not a second copy of the filename.
;; Deferred to window-setup: the first tab only settles once the initial
;; frame exists (at init-load time the tab list may still be empty).
;; Fresh launch always starts with one tab; no tab persistence configured.
(add-hook 'window-setup-hook
          (lambda ()
            (when (and (bound-and-true-p tab-bar-mode)
                       (= (length (tab-bar-tabs)) 1))
              (ignore-errors (tab-bar-rename-tab "main")))))

(defun nano/workspace-new-tab (arg)
  "New workspace tab, then prompt for its name (`SPC l n').
With prefix ARG, pass through to `tab-bar-new-tab'."
  (interactive "P")
  (tab-bar-new-tab arg)
  (call-interactively #'tab-bar-rename-tab))

;; 9a. Core ops  (SPC l ...)
(define-key spacemacs-leader-map (kbd "l l") 'tab-bar-switch-to-tab)
(define-key spacemacs-leader-map (kbd "l n") 'nano/workspace-new-tab)
(define-key spacemacs-leader-map (kbd "l d") 'tab-bar-close-tab)
(define-key spacemacs-leader-map (kbd "l r") 'tab-bar-rename-tab)
(define-key spacemacs-leader-map (kbd "l ]") 'tab-bar-switch-to-next-tab)
(define-key spacemacs-leader-map (kbd "l [") 'tab-bar-switch-to-prev-tab)
(define-key spacemacs-leader-map (kbd "l TAB") 'tab-bar-switch-to-last-tab)
(define-key spacemacs-leader-map (kbd "l b") 'switch-to-buffer)
(dotimes (i 9)
  (let ((n (1+ i)))
    (define-key spacemacs-leader-map
                (kbd (format "l %d" n))
                `(lambda () (interactive) (tab-bar-select-tab ,n)))))
(which-key-add-key-based-replacements
  "SPC l l" "switch workspace"
  "SPC l n" "new workspace"
  "SPC l d" "close workspace"
  "SPC l r" "rename workspace"
  "SPC l ]" "next workspace"
  "SPC l [" "prev workspace"
  "SPC l TAB" "last workspace"
  "SPC l b" "buffer in workspace")

;; 9b. Vim-style cycle (Spacemacs eyebrowse `gt/gT' parity)
(define-key evil-motion-state-map (kbd "gt") 'tab-bar-switch-to-next-tab)
(define-key evil-motion-state-map (kbd "gT") 'tab-bar-switch-to-prev-tab)


;; ---------------------------------------------------------------------
;; §10  Git  (magit + delta, SPC g)
;; ---------------------------------------------------------------------
;; Spacemacs `SPC g' parity, minimal subset.  magit lazy via autoloads
;; (no `require') so startup unaffected; first `SPC g s' builds
;; transient + with-editor + magit-section via straight.
(straight-use-package 'magit)

;; magit-delta: syntax-highlighted diffs.  Gated on `delta' binary —
;; skipped silently when absent (no error on machines without git-delta).
(straight-use-package 'magit-delta)
(with-eval-after-load 'magit
  (when (executable-find "delta")
    (require 'magit-delta)
    (magit-delta-mode +1)))

;; Evil keys in magit buffers (Spacemacs default = evil-collection
;; scoped to magit only, not full collection).  §3 evil-want-* vars
;; already satisfy evil-collection requirements.
(straight-use-package 'evil-collection)
(with-eval-after-load 'evil
  (with-eval-after-load 'magit
    (when (require 'evil-collection nil t)
      (evil-collection-init '(magit)))))

;; 10a. Bindings
(define-key spacemacs-leader-map (kbd "g s") 'magit-status)
(define-key spacemacs-leader-map (kbd "g m") 'magit-dispatch)
(define-key spacemacs-leader-map (kbd "g c") 'magit-clone)
(define-key spacemacs-leader-map (kbd "g i") 'magit-init)
(define-key spacemacs-leader-map (kbd "g L") 'magit-list-repositories)
(define-key spacemacs-leader-map (kbd "g S") 'magit-stage-files)
(define-key spacemacs-leader-map (kbd "g U") 'magit-unstage-files)
(define-key spacemacs-leader-map (kbd "g f F") 'magit-find-file)
(define-key spacemacs-leader-map (kbd "g f l") 'magit-log-buffer-file)
(define-key spacemacs-leader-map (kbd "g f d") 'magit-diff)
(define-key spacemacs-leader-map (kbd "g f m") 'magit-file-dispatch)
(which-key-add-key-based-replacements
  "SPC g" "git"
  "SPC g s" "status"
  "SPC g m" "dispatch"
  "SPC g c" "clone"
  "SPC g i" "init"
  "SPC g L" "list repositories"
  "SPC g S" "stage files"
  "SPC g U" "unstage files"
  "SPC g f" "file"
  "SPC g f F" "find file"
  "SPC g f l" "log file"
  "SPC g f d" "diff"
  "SPC g f m" "file dispatch")


;; ---------------------------------------------------------------------
;; §11  Project  (built-in project.el, SPC p)
;; ---------------------------------------------------------------------
;; Zero-dep: Emacs 30 built-in, detects .git roots, works with
;; fido-vertical from §8.  No projectile (heavier, caching daemon).
(require 'project)

(define-key spacemacs-leader-map (kbd "p f") 'project-find-file)
(define-key spacemacs-leader-map (kbd "p b") 'project-switch-to-buffer)
(define-key spacemacs-leader-map (kbd "p p") 'project-switch-project)
(define-key spacemacs-leader-map (kbd "p d") 'project-find-dir)
(define-key spacemacs-leader-map (kbd "p g") 'project-find-regexp)
(define-key spacemacs-leader-map (kbd "p k") 'project-kill-buffers)
(which-key-add-key-based-replacements
  "SPC p" "project"
  "SPC p f" "find file"
  "SPC p b" "switch buffer"
  "SPC p p" "switch project"
  "SPC p d" "find dir"
  "SPC p g" "search (regexp)"
  "SPC p k" "kill buffers")


;; ---------------------------------------------------------------------
;; §12  Search  (ripgrep via built-in project+xref, SPC s)
;; ---------------------------------------------------------------------
;; Minimal set, no Spacemacs sprawl (no helm-swoop/ag/pt/ack,
;; no consult/vertico/ivy/helm/deadgrep/rg.el/fzf.el).
;; External tool: `rg' (ripgrep 15.2.0 at /usr/bin/rg) — fastest
;; and lightest on this machine: single static binary, respects
;; .gitignore, skips hidden/binary, parallel.  `fd'/`ag' absent,
;; `grep'/`find' slower, `fzf' needs a source list anyway.
;; Zero-dep: built-in project.el + xref + fido-vertical (§8) only.
;; SPC s s (isearch) stays in §5e; this section adds s f / s g.
(require 'xref)

;; Use rg as xref backend when present; else stay on grep.
(when (executable-find "rg")
  (setq xref-search-program 'ripgrep))

(defvar nano/search-rg-warned nil
  "Non-nil once missing-rg fallback warning was shown.")

(defun nano/search-ensure-rg ()
  "Return t if `rg' exists, else warn once and return nil.
Fallback path uses built-in grep / project-find-file."
  (if (executable-find "rg")
      t
    (unless nano/search-rg-warned
      (setq nano/search-rg-warned t)
      (message "rg not found, using grep fallback — install ripgrep for speed"))
    nil))

(defun nano/search-root ()
  "Project root if inside one, else `default-directory'."
  (if-let ((proj (project-current)))
      (project-root proj)
    default-directory))

(defun nano/rg-find-file ()
  "Find file by name with `rg --files'.  Bound to SPC s f.
Completing-read feeds fido-vertical (§8).  Falls back to
`project-find-file' when rg is missing or root is remote."
  (interactive)
  (let ((root (nano/search-root)))
    (if (and (nano/search-ensure-rg)
             (not (file-remote-p root)))
        (let* ((default-directory (file-name-as-directory root))
               (files (ignore-errors
                        (process-lines "rg" "--files" "--hidden"
                                       "--glob" "!.git/*"))))
          (if (not files)
              (user-error "SPC s f: no files found in %s" root)
            (find-file
             (expand-file-name
              (completing-read "Find file (rg): " files nil t)
              root))))
      (call-interactively #'project-find-file))))

(defun nano/search-grep ()
  "Live-grep project with rg via `project-find-regexp'.  SPC s g.
Uses `xref-search-program' (ripgrep when §12 set it).
Falls back to grep backend + one-time install hint when rg missing."
  (interactive)
  (nano/search-ensure-rg)
  (call-interactively #'project-find-regexp))

(define-key spacemacs-leader-map (kbd "s f") 'nano/rg-find-file)
(define-key spacemacs-leader-map (kbd "s g") 'nano/search-grep)
(which-key-add-key-based-replacements
  "SPC s f" "find file (rg)"
  "SPC s g" "grep project (rg)")


;; ---------------------------------------------------------------------
;; §13  File sync  (built-in auto-revert, SPC b R fallback)
;; ---------------------------------------------------------------------
;; External edits (git pull, rg replace, other editor) auto-reflect.
;; Zero-dep: built-in autorevert.el only.  Unsaved buffers never
;; clobbered — auto-revert skips modified buffers.  SPC b R stays
;; as manual `revert-buffer' fallback (§5b).
(require 'autorevert)
(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t ; dired too
      auto-revert-verbose nil               ; quiet
      auto-revert-remote-files nil          ; skip TRAMP, perf
      auto-revert-use-notify t              ; inotify, no poll
      auto-revert-check-vc-info nil)        ; perf, magit handles vc
(add-to-list 'global-auto-revert-ignore-modes 'Buffer-menu-mode)


;; ---------------------------------------------------------------------
;; §14  Zoom  (buffer text-scale, SPC z x, repeat transient)
;; ---------------------------------------------------------------------
;; Buffer-only, Spacemacs `SPC z x' parity.  Zero-dep: built-in
;; text-scale.el only.  Frame zoom skipped (needs zoom-frm).
;; Step 0.5 matches Spacemacs `spacemacs/scale-up-or-down-font-size'.
;; Each entry re-arms `set-transient-map' so + - 0 repeat without
;; re-pressing SPC; q or any other key exits.
(defvar nano/zoom-step 0.5
  "Font scale step for `nano/zoom-in' / `nano/zoom-out'.")

(defvar nano/zoom-repeat-map
  (let ((m (make-sparse-keymap)))
    (define-key m (kbd "+") 'nano/zoom-in)
    (define-key m (kbd "=") 'nano/zoom-in)
    (define-key m (kbd "k") 'nano/zoom-in)
    (define-key m (kbd "-") 'nano/zoom-out)
    (define-key m (kbd "_") 'nano/zoom-out)
    (define-key m (kbd "j") 'nano/zoom-out)
    (define-key m (kbd "0") 'nano/zoom-reset)
    (define-key m (kbd "q") 'nano/zoom-quit)
    m)
  "Repeat keys active after one `SPC z x' zoom.")

(defun nano/zoom-transient-activate ()
  "Re-arm zoom repeat map with hint in echo area."
  (set-transient-map nano/zoom-repeat-map t)
  (message "zoom [+/=/k] in [-/_/j] out [0] reset [q] quit (%+d)"
           (or (and (boundp 'text-scale-mode-amount)
                    text-scale-mode-amount)
               0)))

(defun nano/zoom-in ()
  "Scale buffer font up by `nano/zoom-step', then repeat."
  (interactive)
  (text-scale-increase nano/zoom-step)
  (nano/zoom-transient-activate))

(defun nano/zoom-out ()
  "Scale buffer font down by `nano/zoom-step', then repeat."
  (interactive)
  (text-scale-decrease nano/zoom-step)
  (nano/zoom-transient-activate))

(defun nano/zoom-reset ()
  "Reset buffer font size, then repeat."
  (interactive)
  (text-scale-set 0)
  (nano/zoom-transient-activate))

(defun nano/zoom-quit ()
  "Quit zoom repeat transient."
  (interactive)
  (message "zoom quit"))

(define-key spacemacs-leader-map (kbd "z x +") 'nano/zoom-in)
(define-key spacemacs-leader-map (kbd "z x =") 'nano/zoom-in)
(define-key spacemacs-leader-map (kbd "z x k") 'nano/zoom-in)
(define-key spacemacs-leader-map (kbd "z x -") 'nano/zoom-out)
(define-key spacemacs-leader-map (kbd "z x _") 'nano/zoom-out)
(define-key spacemacs-leader-map (kbd "z x j") 'nano/zoom-out)
(define-key spacemacs-leader-map (kbd "z x 0") 'nano/zoom-reset)
(which-key-add-key-based-replacements
  "SPC z x +" "zoom in"
  "SPC z x =" "zoom in"
  "SPC z x k" "zoom in"
  "SPC z x -" "zoom out"
  "SPC z x _" "zoom out"
  "SPC z x j" "zoom out"
  "SPC z x 0" "reset zoom")


;; ---------------------------------------------------------------------
;; §15  Text  (SPC x, built-in + link-hint lazy)
;; ---------------------------------------------------------------------
;; Minimal Spacemacs `SPC x' parity.  Built-ins only except link-hint
;; (lazy, first `SPC x Y' builds avy + link-hint via straight).
;; Skipped: xa* align, xt* transpose, xj* justification, xw* word
;; analysis, xlr randomize, xlc column sort — niche/heavy, add on demand.
;; Stub for future align: built-in `align-regexp' (e.g. SPC x a = aligns
;; `=' across lines) — uncomment §15e when needed.

;; 15a. Line ops — ported from Spacemacs funcs.el, evil-checks guarded.
(defun nano/duplicate-line-or-region (&optional n)
  "Duplicate current line, or region if active.
With argument N, make N copies.
With negative N, comment out original line and use the absolute value."
  (interactive "*p")
  (let ((use-region (use-region-p)))
    (save-excursion
      (let ((text (if use-region
                      (buffer-substring (region-beginning) (region-end))
                    (prog1 (thing-at-point 'line)
                      (end-of-line)
                      (if (< 0 (forward-line 1))
                          (newline))))))
        (dotimes (_i (abs (or n 1)))
          (insert text))))
    (if use-region nil
      (let ((pos (- (point) (line-beginning-position))))
        (if (> 0 n)
            (comment-region (line-beginning-position) (line-end-position)))
        (forward-line 1)
        (forward-char pos)))))

(defun nano/region-or-buffer ()
  "Return (BEG . END) of region if active, else whole buffer."
  (if (or (region-active-p)
          (and (fboundp 'evil-visual-state-p)
               (ignore-errors (evil-visual-state-p))))
      (cons (region-beginning) (region-end))
    (cons (point-min) (point-max))))

(defun nano/sort-lines (&optional reverse)
  "Sort lines in region or buffer.  Prefix REVERSE sorts in reverse."
  (interactive "P")
  (let ((r (nano/region-or-buffer)))
    (sort-lines reverse (car r) (cdr r))))

(defun nano/sort-lines-reverse ()
  "Sort lines in reverse, in region or buffer."
  (interactive)
  (nano/sort-lines -1))

(defun nano/uniquify-lines ()
  "Remove duplicate adjacent lines in region or buffer."
  (interactive)
  (save-excursion
    (save-restriction
      (let ((r (nano/region-or-buffer)))
        (goto-char (car r))
        (while (re-search-forward "^\\(.*\n\\)\\1+" (cdr r) t)
          (replace-match "\\1"))))))

;; 15b. Built-in URL fallback — no dep.  `SPC x y' copies URL at point.
(defun nano/copy-url-at-point ()
  "Copy URL at point to kill-ring + clipboard.  Fallback when link-hint absent."
  (interactive)
  (let ((url (thing-at-point 'url t)))
    (unless url (user-error "No URL at point"))
    (kill-new url)
    (when (fboundp 'gui-set-selection)
      (ignore-errors (gui-set-selection 'CLIPBOARD url)))
    (message "Copied: %s" url)))

;; 15c. Link-hint — lazy via autoloads (no `require', zero startup cost).
(straight-use-package 'link-hint)

;; 15d. Bindings
(define-key spacemacs-leader-map (kbd "x d SPC") 'cycle-spacing)
(define-key spacemacs-leader-map (kbd "x d l") 'delete-blank-lines)
(define-key spacemacs-leader-map (kbd "x d w") 'delete-trailing-whitespace)
(define-key spacemacs-leader-map (kbd "x l d") 'nano/duplicate-line-or-region)
(define-key spacemacs-leader-map (kbd "x l s") 'nano/sort-lines)
(define-key spacemacs-leader-map (kbd "x l S") 'nano/sort-lines-reverse)
(define-key spacemacs-leader-map (kbd "x l u") 'nano/uniquify-lines)
(define-key spacemacs-leader-map (kbd "x U") 'upcase-region)
(define-key spacemacs-leader-map (kbd "x u") 'downcase-region)
(define-key spacemacs-leader-map (kbd "x C") 'capitalize-region)
(define-key spacemacs-leader-map (kbd "x c") 'count-words-region)
(define-key spacemacs-leader-map (kbd "x f") 'fill-paragraph)
(define-key spacemacs-leader-map (kbd "x TAB") 'indent-rigidly)
(define-key spacemacs-leader-map (kbd "x y") 'nano/copy-url-at-point)
(define-key spacemacs-leader-map (kbd "x Y") 'link-hint-copy-link)
(which-key-add-key-based-replacements
  "SPC x" "text"
  "SPC x d" "delete"
  "SPC x d SPC" "cycle spacing"
  "SPC x d l" "delete blank lines"
  "SPC x d w" "delete trailing whitespace"
  "SPC x l" "lines"
  "SPC x l d" "duplicate line/region"
  "SPC x l s" "sort lines"
  "SPC x l S" "sort lines reverse"
  "SPC x l u" "uniquify lines"
  "SPC x U" "upcase region"
  "SPC x u" "downcase region"
  "SPC x C" "capitalize region"
  "SPC x c" "count words"
  "SPC x f" "fill paragraph"
  "SPC x TAB" "indent rigidly"
  "SPC x y" "copy URL at point"
  "SPC x Y" "copy link (hint)")

;; Vim-style indent-rigidly motion (Spacemacs parity)
(with-eval-after-load 'indent
  (define-key indent-rigidly-map "h" 'indent-rigidly-left)
  (define-key indent-rigidly-map "l" 'indent-rigidly-right)
  (define-key indent-rigidly-map "H" 'indent-rigidly-left-to-tab-stop)
  (define-key indent-rigidly-map "L" 'indent-rigidly-right-to-tab-stop))

;; 15e. Future align stub (built-in align-regexp, zero dep).  Uncomment to enable:
;; (defun nano/align-repeat (start end regexp)
;;   "Align region lines on REGEXP, auto-expanding to matching neighbors."
;;   (interactive "r\nsAlign regexp: ")
;;   (require 'align)
;;   (unless (use-region-p)
;;     (save-excursion
;;       (while (and (string-match-p (concat "\\(\\s-*\\)" regexp) (thing-at-point 'line))
;;                   (= 0 (forward-line -1)))
;;         (setq start (point-at-bol))))
;;     (save-excursion
;;       (while (and (string-match-p (concat "\\(\\s-*\\)" regexp) (thing-at-point 'line))
;;                   (= 0 (forward-line 1)))
;;         (setq end (point-at-eol)))))
;;   (align-regexp start end (concat "\\(\\s-*\\)" regexp) 1 1 t))
;; (define-key spacemacs-leader-map (kbd "x a =") (lambda (s e) (interactive "r") (nano/align-repeat s e "=")))
;; (define-key spacemacs-leader-map (kbd "x a |") (lambda (s e) (interactive "r") (nano/align-repeat s e "|")))
