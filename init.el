;;; init.el --- nano-emacs via straight.el -*- lexical-binding: t -*-
;;; Commentary:
;; Single-file config for rougier/nano-emacs, managed by straight.el.
;; Launch with: emacs --init-directory ~/nano.emacs.d
;; Edits: SPC f e r reloads in-place; font/boot changes need SPC q r.
;; See AGENTS.md for layout/gotchas.

;;; Code:

;; =====================================================================
;; Table of Contents  (search "§N" to jump)
;;   §0  Bootstrap straight.el (+ built-in org pin)
;;   §1  Startup silencing & warnings  (before nano loads)
;;   §2  Appearance  (font, nano theme, visual-line, GUI chrome)
;;   §3  Vim emulation  (evil + which-key)
;;   §4  SPC leader definition  (native, no general.el)
;;   §5  Leader keybindings  (file / buffer / window / quit / search)
;;   §6  Window management  (winum, header-line, double/triple/quad columns, uniform widths)
;;   §7  Theme toggle + persistence + spacemacs-light/nord-dark faces  (SPC t n)
;;   §8  Completion  (built-in icomplete-vertical, helm-like list)
;;   §9  Workspace  (built-in tab-bar, SPC l, name in modeline; §9c quad)
;;   §10 Git  (magit + delta + blame transient, SPC g; §10c magit in desktop)
;;   §11 Project  (built-in project.el, SPC p)
;;   §12 Search  (ripgrep via built-in project+xref, SPC s)
;;   §13 File sync  (built-in auto-revert, SPC b R fallback)
;;   §14 Zoom  (buffer text-scale, SPC z x, repeat transient)
;;   §15 Text  (SPC x, built-in + link-hint lazy)
;;   §16 Major-mode leader  (, + SPC m, V0 fallback + V1 org curated)
;;   §17  Jump  (avy, SPC j, lazy)
;;   §18  Org  (autolist, links, tags, todo flow, babel, agenda, notify, random, bullets, present)
;;   §19  Insert  (SPC i, zero-dep lorem / password / uuid v4)
;;   §20  Markdown  (markdown-mode + gfm, SPC m / ,, lazy)
;;   §21  Roam  (org-roam + sqlite-builtin, , r / SPC o, lazy)
;;   §22  Update  (float latest, SPC f e U pull+rebuild; SPC f e r reload init)
;;   §23  Web  (built-in eww + elfeed/ttrss, SPC a w, lazy)
;;   §24  Select  (expand-region, SPC v, lazy)
;;   §25  Keepass  (keepass-mode, .kdbx open, evilified parity)
;;   §26  Animal Spirit  (local autoload, SPC a a, lazy)
;;   §27  OpenCode v2  (jdormit/emacs-opencode, SPC a c, lazy;
;;                        default model = nano/opencode-default-model, 27d;
;;                        session minimap on SPC a c l, 27i)
;;   §28  Indentation  (global 2 spaces, Python 4)
;;   §29  Shell  (builtins, SPC ' + SPC a t, lazy)
;;   §30  Ghostel  (libghostty terminal, SPC a t g, lazy)
;;   §31  Matrix chat  (alphapapa/ement.el, SPC a m, lazy; no E2EE)
;; =====================================================================


;; ---------------------------------------------------------------------
;; §0  Bootstrap straight.el
;; ---------------------------------------------------------------------
;; Provides `straight-use-package'.  On first run, fetches
;; radian-software/straight.el:develop/install.el via url-retrieve.
;; `user-emacs-directory' == launch dir (~/nano.emacs.d) thanks to
;; --init-directory.  All clones live in straight/repos/.
;; Pin `org' as built-in BEFORE any org-dependent package (§18a,
;; §18d, §21) so straight never clones its 112M repo on fresh
;; bootstrap to satisfy a Package-Requires header — built-in 9.7 used.
;; NOTE: pin MUST stay AFTER bootstrap load below — `straight-use-package'
;; is undefined until bootstrap.el loads, else boot dies with void-function.
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
(straight-use-package '(org :type built-in))


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
;;     straight/repos/nano-emacs/.  Do NOT edit vendored code (lost on
;;     `straight-pull-all'); override in init.el (§2b2, §6b, §7b2) instead.
(straight-use-package
 '(nano :type git :host github :repo "rougier/nano-emacs"))

(require 'nano)

;; 2b2. Upstream modernization — replaces vendored nano-defaults.el edits.
;;      `default-major-mode' obsolete since 23, `defadvice' since 30.1,
;;      bare `(temp-buffer-resize-mode)' toggles instead of enabling.
;;      `nano-command.el' point-at-bol/eol aliases still functional and
;;      warnings suppressed in §1 — no override needed, dropped.
(with-eval-after-load 'nano-defaults
  (setq-default major-mode 'text-mode)
  ;; Scratch defaults to org-mode (autoloaded, no eager require).
  (setq initial-major-mode 'org-mode)
  (when (fboundp 'temp-buffer-resize-mode)
    (temp-buffer-resize-mode 1))
  ;; Replace legacy defadvice with modern advice-add.
  (when (fboundp 'ad-remove-advice)
    (ignore-errors
      (ad-remove-advice 'term-sentinel 'around 'my-advice-term-sentinel)
      (ad-activate 'term-sentinel)))
  (defun nano--term-sentinel-around (orig proc msg)
    (funcall orig proc msg)
    (when (memq (process-status proc) '(signal exit))
      (let ((buffer (process-buffer proc)))
        (when (buffer-live-p buffer)
          (kill-buffer buffer)))))
  (advice-add 'term-sentinel :around #'nano--term-sentinel-around))

;; 2c. Line wrapping — visual-line wraps long lines without hard newline.
(global-visual-line-mode 1)

;; 2c2. Line numbers — absolute gutter in code buffers only.
;;      Built-in display-line-numbers (native C, faster than linum/nlinum).
;;      prog-mode-hook covers .el/.py + all derived code modes;
;;      text/org/md stay clean.
(setq display-line-numbers-type 'absolute
      display-line-numbers-width-start t)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)

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
  "SPC j" "jump"
  "SPC w" "window"
  "SPC l" "workspace"
  "SPC q" "quit"
  "SPC s" "search"
  "SPC h" "help"
  "SPC t" "toggle"
  "SPC i" "insert"
  "SPC a" "apps"
  "SPC v" "expand region"
  "SPC o" "org-mode"
  "SPC a w" "web"
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
(define-key spacemacs-leader-map (kbd "f S") 'evil-write-all) ; Spacemacs parity (:wa, silent, no prompt)
(define-key spacemacs-leader-map (kbd "f r") 'nano/find-recent-file)
(define-key spacemacs-leader-map (kbd "f D") 'nano/delete-current-buffer-file)
(define-key spacemacs-leader-map (kbd "f R") 'nano/rename-current-buffer-file)
(define-key spacemacs-leader-map (kbd "f c") 'nano/copy-current-buffer-file)
(which-key-add-key-based-replacements
  "SPC f f" "find file"
  "SPC f r" "recent files"
  "SPC f s" "save file"
  "SPC f S" "save all"
  "SPC f c" "copy file"
  "SPC f D" "delete file"
  "SPC f R" "rename file")

(defun nano/find-recent-file (&optional arg)
  "Open recent file via minibuffer completion, like SPC f f.  Bound to SPC f r.
Type to filter; empty input lists all (fido-vertical, §8).
With prefix ARG, open old widget dialog (`recentf-open-files')."
  (interactive "P")
  (unless recentf-mode (recentf-mode 1))
  (if arg
      (call-interactively #'recentf-open-files)
    (if (null recentf-list)
        (user-error "No recent files")
      (funcall recentf-menu-action
               (completing-read "Open recent file: " recentf-list nil t)))))

(defun nano/delete-current-buffer-file (&optional arg)
  "Delete file visited by current buffer, then kill buffer.  Bound to SPC f D.
Confirms unless prefix ARG.  Errors when buffer visits no file."
  (interactive "P")
  (let ((filename (buffer-file-name))
        (buffer (current-buffer))
        (name (buffer-name)))
    (unless (and filename (file-exists-p filename))
      (user-error "Buffer %s visits no file" name))
    (if (or arg (yes-or-no-p (format "Delete file '%s'? " name)))
        (progn
          (delete-file filename t)
          (kill-buffer buffer)
          (when (fboundp 'recentf-remove-if-non-kept)
            (recentf-remove-if-non-kept filename))
          (message "File deleted: '%s'" filename))
      (message "Canceled: file deletion"))))

(defun nano/rename-current-buffer-file (&optional arg)
  "Rename file visited by current buffer.  Bound to SPC f R.
No prefix: edit file name in place (e.g. `exocortex1.org' ->
`exocortex.org'); RET takes input literally.
With prefix ARG, pick full new path with file completion.
Creates parent dirs after confirm.  Errors when buffer visits no file."
  (interactive "P")
  (let ((old (buffer-file-name)))
    (unless (and old (file-exists-p old))
      (user-error "Buffer %s visits no file" (buffer-name)))
    (let* ((old-dir (file-name-directory old))
           (old-short (file-name-nondirectory old))
           ;; `read-string', not `read-file-name': fido RET
           ;; force-completes to the first partial match, so typing
           ;; `exocortex.org' next to `exocortex1.org' would snap back
           ;; to the old file.  No completion here; literal input wins.
           ;; Relative input (sub/dir, ../x) expands under old-dir.
           (new (if arg
                    (let ((path (read-file-name "Move to: " old-dir)))
                      (if (string= (file-name-nondirectory path) "")
                          (concat path old-short)
                        path))
                  (let ((input (read-string (format "Rename %s to: " old-short)
                                            old-short)))
                    (when (string-empty-p input)
                      (user-error "Canceled: rename"))
                    (expand-file-name input old-dir)))))
      (when (get-buffer new)
        (user-error "A buffer named '%s' already exists" new))
      (when (string-equal new old)
        (user-error "Same new and old name"))
      (let ((new-dir (file-name-directory new)))
        (when (and new-dir (not (file-exists-p new-dir)))
          (unless (yes-or-no-p (format "Create directory '%s'? " new-dir))
            (user-error "Canceled: rename"))
          (make-directory new-dir t)))
      (rename-file old new 1)
      (set-visited-file-name new t)
      (set-buffer-modified-p nil)
      (when (fboundp 'recentf-add-file)
        (recentf-add-file new)
        (when (fboundp 'recentf-remove-if-non-kept)
          (recentf-remove-if-non-kept old)))
      (message "Renamed '%s' to '%s'" old-short (file-name-nondirectory new)))))

(defun nano/copy-current-buffer-file (&optional arg)
  "Copy file visited by current buffer to new path.  Bound to SPC f c.
No prefix: edit copy name in place (e.g. `exocortex1.org' ->
`exocortex-backup.org'); RET takes input literally.
With prefix ARG, pick full destination with file completion.
Creates parent dirs after confirm.  Buffer keeps visiting old file.
Overwrites after confirm.  Errors when buffer visits no file."
  (interactive "P")
  (let ((old (buffer-file-name)))
    (unless (and old (file-exists-p old))
      (user-error "Buffer %s visits no file" (buffer-name)))
    (let* ((old-dir (file-name-directory old))
           (old-short (file-name-nondirectory old))
           ;; Same fido dodge as rename above: `read-string' keeps
           ;; RET literal; `read-file-name' would force-complete to a
           ;; partial-matching sibling.
           (new (expand-file-name
                 (if arg
                     (let ((path (read-file-name "Move copy to: " old-dir)))
                       (if (string= (file-name-nondirectory path) "")
                           (concat path old-short)
                         path))
                   (let ((input (read-string (format "Copy %s to: " old-short)
                                             old-short)))
                     (when (string-empty-p input)
                       (user-error "Canceled: copy"))
                     input)))))
      (when (string-equal new (expand-file-name old))
        (user-error "Same new and old name"))
      (let ((new-dir (file-name-directory new)))
        (when (and new-dir (not (file-exists-p new-dir)))
          (unless (yes-or-no-p (format "Create directory '%s'? " new-dir))
            (user-error "Canceled: copy"))
          (make-directory new-dir t)))
      (copy-file old new 1)
      (when (fboundp 'recentf-add-file)
        (recentf-add-file new))
      (message "Copied '%s' to '%s'" old-short (file-name-nondirectory new)))))

;; 5a2. Yank/copy  (SPC f y) — Spacemacs parity, zero-dep.
;;      7 leaves: path, dir, name, base, buffer, path+line, path+line+col.
;;      `kill-new' + CLIPBOARD + echo, same pattern as §15b/§19.
;;      Paths expanded via `file-truename'.  `y y' falls back to dired
;;      filename under cursor, else listed dir path.
(defun nano/yank--file-path ()
  "Expanded file path of current buffer, or nil when no file."
  (when-let ((f (buffer-file-name)))
    (file-truename f)))

(defun nano/yank--file-path-with-line ()
  "Expanded file path plus `:LINE', or nil when no file."
  (when-let ((f (nano/yank--file-path)))
    (concat f ":" (number-to-string (line-number-at-pos)))))

(defun nano/yank--copy (s)
  "Push S to kill-ring + clipboard, echo it."
  (kill-new s)
  (when (fboundp 'gui-set-selection)
    (ignore-errors (gui-set-selection 'CLIPBOARD s)))
  (message "%s" s))

(defun nano/copy-file-path ()
  "Copy + show file path.  In dired, file under cursor else listed dir.  SPC f y y."
  (interactive)
  (if-let ((p (or (nano/yank--file-path)
                  (and (derived-mode-p 'dired-mode)
                       (dired-get-filename nil t)))))
      (nano/yank--copy p)
    (user-error "Current buffer is not visiting a file")))

(defun nano/copy-directory-path ()
  "Copy + show `default-directory' truename.  SPC f y d."
  (interactive)
  (nano/yank--copy (file-truename default-directory)))

(defun nano/copy-file-name ()
  "Copy + show file nondirectory.  SPC f y n."
  (interactive)
  (if-let ((p (nano/yank--file-path)))
      (nano/yank--copy (file-name-nondirectory p))
    (user-error "Current buffer is not visiting a file")))

(defun nano/copy-file-name-base ()
  "Copy + show file name sans extension.  SPC f y N."
  (interactive)
  (if-let ((p (nano/yank--file-path)))
      (nano/yank--copy (file-name-base p))
    (user-error "Current buffer is not visiting a file")))

(defun nano/copy-buffer-name ()
  "Copy + show buffer name, even non-file.  SPC f y b."
  (interactive)
  (nano/yank--copy (buffer-name)))

(defun nano/copy-file-path-with-line ()
  "Copy + show path `:LINE'.  SPC f y l."
  (interactive)
  (if-let ((p (nano/yank--file-path-with-line)))
      (nano/yank--copy p)
    (user-error "Current buffer is not visiting a file")))

(defun nano/copy-file-path-with-line-column ()
  "Copy + show path `:LINE:COL'.  SPC f y c.  Respects zero-based flag."
  (interactive)
  (if-let ((p (nano/yank--file-path-with-line)))
      (nano/yank--copy
       (format "%s:%s" p (+ (current-column)
                            (if (bound-and-true-p column-number-indicator-zero-based) 0 1))))
    (user-error "Current buffer is not visiting a file")))

(define-key spacemacs-leader-map (kbd "f y y") 'nano/copy-file-path)
(define-key spacemacs-leader-map (kbd "f y d") 'nano/copy-directory-path)
(define-key spacemacs-leader-map (kbd "f y n") 'nano/copy-file-name)
(define-key spacemacs-leader-map (kbd "f y N") 'nano/copy-file-name-base)
(define-key spacemacs-leader-map (kbd "f y b") 'nano/copy-buffer-name)
(define-key spacemacs-leader-map (kbd "f y l") 'nano/copy-file-path-with-line)
(define-key spacemacs-leader-map (kbd "f y c") 'nano/copy-file-path-with-line-column)
(which-key-add-key-based-replacements
  "SPC f y" "yank/copy"
  "SPC f y y" "file path"
  "SPC f y d" "directory path"
  "SPC f y n" "file name"
  "SPC f y N" "file name base"
  "SPC f y b" "buffer name"
  "SPC f y l" "path with line"
  "SPC f y c" "path with line+col")

;; 5b. Buffer  (SPC b)
(define-key spacemacs-leader-map (kbd "TAB") 'mode-line-other-buffer)
(define-key spacemacs-leader-map (kbd "b b") 'switch-to-buffer)
(define-key spacemacs-leader-map (kbd "b d") 'kill-current-buffer)
(define-key spacemacs-leader-map (kbd "b D") 'kill-matching-buffers)
(define-key spacemacs-leader-map (kbd "b e") 'erase-buffer)
(define-key spacemacs-leader-map (kbd "b n") 'next-buffer)
(define-key spacemacs-leader-map (kbd "b p") 'previous-buffer)
(define-key spacemacs-leader-map (kbd "b R") 'revert-buffer)
(define-key spacemacs-leader-map (kbd "b s") 'nano/switch-to-scratch-buffer)
(define-key spacemacs-leader-map (kbd "b w") 'read-only-mode)
(define-key spacemacs-leader-map (kbd "b Y") 'nano/copy-whole-buffer-to-clipboard)
(which-key-add-key-based-replacements
  "SPC TAB" "last buffer"
  "SPC b D" "kill buffers by pattern"
  "SPC b R" "revert buffer"
  "SPC b e" "erase buffer"
  "SPC b s" "scratch buffer"
  "SPC b w" "toggle read-only"
  "SPC b Y" "copy buffer")

(defun nano/switch-to-scratch-buffer (&optional arg)
  "Switch to `*scratch*', creating it first if needed.
With prefix ARG, open in another window.
Fresh buffer defaults to `org-mode'."
  (interactive "P")
  (let ((scratch (get-buffer-create "*scratch*")))
    (with-current-buffer scratch
      (when (= (buffer-size) 0)
        (unless (eq major-mode 'org-mode)
          (org-mode))))
    (if arg
        (switch-to-buffer-other-window scratch)
      (switch-to-buffer scratch))))

(defun nano/copy-whole-buffer-to-clipboard ()
  "Copy entire buffer to kill-ring + clipboard.  Bound to SPC b Y."
  (interactive)
  (clipboard-kill-ring-save (point-min) (point-max))
  (message "Copied: %d chars" (- (point-max) (point-min))))

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
;; SPC w 2 / SPC w 3 / SPC w 4 (double/triple/quad columns) defined in §6c — kept with its implementation.

;; 5d. Quit / session  (SPC q)
;; SPC q q / SPC q r save + restore file buffers, window splits (§6),
;; tab-bar workspaces (§9), and all frames via built-in desktop-save-mode
;; frameset (var/desktop/).  Quit-only save (`desktop-auto-save-timeout'
;; nil); kill-hook re-save also silent.  Restart keeps --init-directory
;; since builtin `restart-emacs' re-execs same argv.
;; Tab-bar MUST be on BEFORE `desktop-save-mode' reads, else frameset
;; restores without tabs (workspaces lost).  Both autoload; no `require'.
(tab-bar-mode 1)
;; NOTE: plain setq on `tab-bar-show' does NOT take effect — custom :set
;; refreshes `tab-bar-lines'.  Full tab-bar config lives in §9; this
;; early hide keeps first frame clean before §9 re-asserts.
(customize-set-variable 'tab-bar-show nil)
;; No `require' desktop: `desktop-save-mode' autoloads; vars set first
;; (defcustom keeps pre-set values on load).
(setq desktop-dirname (locate-user-emacs-file "var/desktop")
      desktop-path (list desktop-dirname)
      desktop-save t
      ;; nil = refuse to load whenever a lock file exists, so a crash or a
      ;; `kill' leaves the next start with an empty session ("Desktop file
      ;; in use; not loaded", nothing restored).  check-pid loads unless the
      ;; recorded PID is still a live Emacs — stale locks self-heal.
      desktop-load-locked-desktop 'check-pid
      desktop-restore-eager 10
      desktop-restore-frames t
      desktop-restore-reuses-frames t
      desktop-restore-in-current-display t
      desktop-auto-save-timeout nil)
(make-directory desktop-dirname t)
(desktop-save-mode 1)

;; `desktop-kill' (kill-emacs-query-functions) re-saves at kill; on desktop
;; conflict it errors ("Desktop file conflict") and aborts the quit.  Advice:
;; never abort — skip save on conflict / any error, still release the lock.
(defun nano/desktop-kill-tolerant (orig)
  "Like `desktop-kill' but never blocks quitting.
Skipped too when quit-time save already failed (same failure twice)."
  (if nano/desktop-save-failed
      (desktop--on-kill)
    (condition-case err
        (funcall orig)
      (error (message "Desktop save skipped (%s)" (cadr err)))))
  t)

(advice-add 'desktop-kill :around #'nano/desktop-kill-tolerant)

(defun nano/desktop-ensure-dir ()
  "Return desktop dir, creating it.  Never nil — avoids `Directory:' prompt.
`desktop-save-in-desktop-dir' falls back to interactive `desktop-save'
when `desktop-dirname' is nil; explicit dir here keeps quit silent."
  (let ((dir (or desktop-dirname (locate-user-emacs-file "var/desktop"))))
    (make-directory dir t)
    (setq desktop-dirname dir)
    dir))

(defvar nano/desktop-save-failed nil
  "Non-nil when desktop save failed at quit; kill-hook re-save then skipped.")

(defun nano/desktop-save-silently ()
  "Non-interactive desktop save.  Never prompts for directory.
On desktop conflict (file changed since load / other instance) skip
instead of overwriting; quit still proceeds."
  (setq nano/desktop-save-failed nil)
  (let ((desktop-save t))
    (condition-case err
        (desktop-save (nano/desktop-ensure-dir))
      (error
       (setq nano/desktop-save-failed t)
       (message "Desktop save skipped (%s)" (cadr err))))))

(defun nano/restart-emacs-restore ()
  "Save desktop session, then restart.  Bound to SPC q r."
  (interactive)
  (nano/desktop-save-silently)
  (let ((desktop-save t)) ; kill-hook re-save also silent, no second prompt
    (restart-emacs)))

(defun nano/quit-save-silently ()
  "Save desktop silently, then quit (still prompts for unsaved files).
Desktop conflict skips save, quit proceeds.  Bound to SPC q q."
  (interactive)
  (nano/desktop-save-silently)
  (let ((desktop-save t)) ; kill-hook re-save also silent
    (save-buffers-kill-terminal)))

(define-key spacemacs-leader-map (kbd "q q") 'nano/quit-save-silently)
(define-key spacemacs-leader-map (kbd "q Q") 'kill-emacs)
(define-key spacemacs-leader-map (kbd "q r") 'nano/restart-emacs-restore)
(which-key-add-key-based-replacements "SPC q q" "quit"
  "SPC q r" "restart")

;; 5d2. Special-buffer window restore — org-agenda.
;; Desktop writes `desktop-create-buffer' entries for file buffers only,
;; unless buffer-local `desktop-save-buffer' is non-nil; org-agenda never
;; sets it, so a saved frameset leaf points at a buffer that is never
;; recreated — frameset then drops the whole split (single window after
;; restart; reproduced: file + *Org Agenda* side-by-side → wins=1).
;; Fix: mark agenda buffers saveable + rebuild on read via mode handler
;; (args FILENAME BUFNAME MISC, returns live buffer).  Nothing is
;; required at startup: the handler autoloads org-agenda itself.
;;
;; The VIEW KIND is saved with the buffer, not assumed.  The handler used
;; to call `org-agenda-list' unconditionally, so every restored agenda
;; came back as the weekly view even when it had been the TODO list —
;; the `*Org Agenda*' buffer is shared by all org agenda views, so the
;; buffer name alone says nothing about which one was on screen.
;; `desktop-save-buffer' may be a function, and its return value is
;; handed back as MISC on read, so it now records `org-agenda-type'.
;; Restore then replays the matching command:
;;   todo -> `org-todo-list'   (what `SPC o a' then `t' gives)
;;   agenda -> `org-agenda-list' (weekly view)
;;   anything else (tags/search) and unknown/old desktops -> weekly view,
;; the previous behaviour, so a desktop written by an older init.el still
;; restores.
(defvar-local nano/org-agenda-last-type nil
  "Last non-nil `org-agenda-type' seen in this buffer.
A fallback for `nano/org-agenda--current-type' when neither the variable
nor the buffer text carries the kind.  Buffer-local because several
agenda buffers can coexist (`org-agenda-sticky').")

(defun nano/org-agenda--current-type ()
  "Return the view kind of the current agenda buffer.
`org-agenda-type' is authoritative once a view is generated, but
`org-agenda-mode-hook' runs from `org-agenda-mode' BEFORE the view is
inserted, so at hook time it is still nil.  Every agenda line carries
the kind as an `org-agenda-type' text property, which is what this
falls back to, and finally to `nano/org-agenda-last-type'."
  (or (bound-and-true-p org-agenda-type)
      (get-text-property (point-min) 'org-agenda-type)
      nano/org-agenda-last-type))

(defun nano/org-agenda-mode--remember-type ()
  "Record the current view kind in `nano/org-agenda-last-type'.
Runs from `org-agenda-mode-hook'.  The first run of a fresh buffer sees
no view yet (nil); later runs, after a rebuild, pick the kind up.  The
save side therefore re-reads the buffer instead of trusting this alone."
  (when-let* ((kind (get-text-property (point-min) 'org-agenda-type)))
    (setq-local nano/org-agenda-last-type kind)))

(defun nano/org-agenda--desktop-save (_dirname)
  "Return the auxiliary desktop data for this agenda buffer.
Records the view kind so `nano/desktop-restore-org-agenda' can rebuild
the same view instead of always the weekly agenda.  Read at save time,
when the view is definitely on screen."
  (list (nano/org-agenda--current-type)))

(defun nano/desktop-restore-org-agenda (_file _name misc)
  "Rebuild the agenda buffer for desktop restore.  Returns live buffer.
MISC carries the saved view kind (see
`nano/org-agenda--desktop-save'); `todo' replays `org-todo-list', the
weekly `agenda' view and anything unknown replay `org-agenda-list'."
  (unless (fboundp 'org-todo-list)
    (require 'org-agenda))
  (when (fboundp 'nano/org-agenda-refresh-files)
    (nano/org-agenda-refresh-files))
  (let ((kind (car-safe misc)))
    (if (eq kind 'todo)
        (org-todo-list)
      (org-agenda-list)))
  (get-buffer org-agenda-buffer-name))
(with-eval-after-load 'desktop
  (add-to-list 'desktop-buffer-mode-handlers
               '(org-agenda-mode . nano/desktop-restore-org-agenda)))
(with-eval-after-load 'desktop
  (add-hook 'org-agenda-mode-hook
            (lambda ()
              (setq-local desktop-save-buffer #'nano/org-agenda--desktop-save))))

;; 5e. Help  (SPC h)
;; SPC s search bindings live in §12; isearch still on C-s / C-r natively.
;; SPC h group label declared in §4; add help bindings here as needed.

;; 5f. Comment  (SPC c l)
;; Built-in newcomment.el autoload, zero startup cost.  `comment-line'
;; DWIM: active region (incl. evil visual) toggles each line, else
;; current line.  Works in any prog/text mode via `comment-start'.
(define-key spacemacs-leader-map (kbd "c l") 'comment-line)
(which-key-add-key-based-replacements
  "SPC c" "comment"
  "SPC c l" "comment lines")


;; ---------------------------------------------------------------------
;; §6  Window management  (winum, header-line, double/triple/quad columns, uniform widths, scratch routing)
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
;;     Layout: [N] [E] [RO/RW/**/>< /@host] filename (detail) ... [proc|sel|position] <workspace> %p
;;     `proc' = buffer-local `mode-line-process' (a (:eval ...) status
;;     template set by packages), rendered far right only in buffers
;;     that set it (nano/compose drops that standard slot).
;;     Redefines `nano-modeline-compose' (same signature, so every mode
;;     benefits) instead of patching nano source.  Single auto-named tab
;;     tracks the buffer name, which used to render `<init.el> ... init.el'
;;     (workspace + file duplicated); workspace now lives far-right and the
;;     initial tab is named "main" in §9, so no adjacency dup.
(defface nano-face-header-active nil
  "Selected-window highlight for modeline blocks."
  :group 'nano)

(defface nano-face-header-evil-insert nil
  "Evil insert-state tag (` I ').  Spacemacs chartreuse3 green."
  :group 'nano)

(defface nano-face-header-evil-replace nil
  "Evil replace-state tag (` R ').  Spacemacs chocolate orange."
  :group 'nano)

(defun nano/apply-modeline-faces ()
  "Paint custom modeline block faces per theme.  Re-applied after refresh.
Covers `nano-face-header-active', `nano-face-header-critical' (modified
` ** ' only) plus Spacemacs-state `nano-face-header-evil-insert' (` I ')
and `nano-face-header-evil-replace' (` R '): stock critical is solid neon
red under the §7c remap (light: Spacemacs `err' #e0211d) — alarms, not state
tags.  Spacemacs designs state tags as medium-chroma solid blocks
(chartreuse3 insert, chocolate replace); follow that: light insert
Spacemacs green #67b11d (§7c head3), replace Spacemacs war #dc752f (§7c);
dark insert same #67b11d (distinct from normal sage #A3BE8C), replace Nord
doc #D08770 (§7c2 chocolate analog).
All bar faces get `:box nil': powerline XPM arrows read only the
background, so the vendored 1px `:box' (`nano-faces.el', re-applied on
every `nano-refresh-theme') draws a visible outline that breaks arrow
fusion.  Flat faces fuse; e.g. ` N ' green melts into ` init.el ' violet.
Flushes memoized powerline arrow XPMs so separators pick up new colors."
  (when (fboundp 'powerline-reset)
    (ignore-errors (powerline-reset)))
  (let ((light (and (boundp 'nano-theme-var) (string= nano-theme-var "light"))))
    (set-face-attribute 'nano-face-header-active nil
                        :foreground (if light "#655370" "#2E3440")
                        :background (if light "#d3d3e7" "#A3BE8C")
                        :box nil)
    (let ((fg (if light "#fbf8ef" "#2E3440")))
      (dolist (spec `(("nano-face-header-critical" ,(if light "#B22222" "#BF616A"))
                      ("nano-face-header-evil-insert" "#67b11d")
                      ("nano-face-header-evil-replace" ,(if light "#dc752f" "#D08770"))))
        (set-face-attribute (intern (car spec)) nil
                            :foreground fg :background (cadr spec)
                            :box nil))))
  ;; Strip the vendored 1px box from every other face used in the bar.
  ;; Keeps theme fg/bg, kills only the outline so arrows fuse.
  (dolist (f '(nano-face-header-default nano-face-header-strong
               nano-face-header-salient nano-face-header-popout
               nano-face-header-faded))
    (ignore-errors (set-face-attribute f nil :box nil))))

(nano/apply-modeline-faces)
(when (fboundp 'nano-refresh-theme)
  (advice-add 'nano-refresh-theme :after #'nano/apply-modeline-faces))

(defun nano/modeline-selected-p ()
  "Non-nil when rendered modeline belongs to selected window."
  (if (fboundp 'mode-line-window-selected-p)
      (mode-line-window-selected-p)
    t))

(defun nano/winum-number-string ()
  "Return propertized window number block for current window, or nil."
  (when (and (bound-and-true-p winum-mode)
             (fboundp 'winum-get-number))
    (let ((n (ignore-errors (winum-get-number (selected-window)))))
      (when n
        (propertize (format " %d " n)
                    'face (if (nano/modeline-selected-p)
                              'nano-face-header-active
                            'nano-face-header-strong))))))

;; Evil-state tag. Single letter, state-colored when selected. nil when evil off.
(defun nano/evil-state-string ()
  "Return propertized evil-state block, or nil."
  (when (and (bound-and-true-p evil-mode)
             (boundp 'evil-state) evil-state)
    (let* ((active (nano/modeline-selected-p))
           (pair (cond ((eq evil-state 'normal)   '(" N " . nano-face-header-active))
                       ((eq evil-state 'insert)   '(" I " . nano-face-header-evil-insert))
                       ((eq evil-state 'visual)   '(" V " . nano-face-header-salient))
                       ((eq evil-state 'emacs)    '(" E " . nano-face-header-popout))
                       ((eq evil-state 'motion)   '(" M " . nano-face-header-strong))
                       ((eq evil-state 'replace)  '(" R " . nano-face-header-evil-replace))
                       ((eq evil-state 'operator) '(" O " . nano-face-header-popout))
                       (t nil))))
      (when pair
        (propertize (car pair)
                    'face (if active (cdr pair) 'nano-face-header-strong))))))

;; Narrow (><) + TRAMP (@host) flags, one faced string per flag.
;; List form so the composer can arrow-fuse each flag with its own
;; neighbors; e.g. `(" >< " popout) (" @host " faded)'.
(defun nano/modeline-extra-flags ()
  "Return list of propertized narrow/remote flag strings, or nil.
Buffer-local checks only."
  (let ((narrow (and (fboundp 'buffer-narrowed-p) (ignore-errors (buffer-narrowed-p))))
        (host (ignore-errors (file-remote-p default-directory 'host)))
        (out nil))
    (when narrow
      (push (propertize " >< " 'face 'nano-face-header-popout) out))
    (when (and host (not (string-empty-p host)))
      (push (propertize (format " @%s " host) 'face 'nano-face-header-faded) out))
    (nreverse out)))

;; Selection info. Replaces position with L:C while region is active.
(defun nano/modeline-selection-string ()
  "Return propertized ` L:C ' block when region active, else nil.
Skips `count-lines' on huge regions (>50k chars); chars still show."
  (when (use-region-p)
    (ignore-errors
      (let* ((rb (region-beginning))
             (re (region-end))
             (chars (- re rb))
             (lines (if (> chars 50000)
                        -1
                      (count-lines rb re))))
        (propertize (if (< lines 0)
                        (format " %dC " chars)
                      (format " %dL:%dC " lines chars))
                    'face 'nano-face-header-default)))))

;; Responsive truncation. Narrow columns drop ws, primary, static position first.
(defvar nano/modeline-truncate-ws-width 90
  "Below this column width, drop the workspace block.")
(defvar nano/modeline-truncate-primary-width 70
  "Below this column width, drop the primary (mode/branch) block.")
(defvar nano/modeline-truncate-secondary-width 50
  "Below this column width, drop static position; selection still shows.")

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

;; Scroll percent — built-in %p scrollbar analog (Top / NN% / Bot / All).
;; Same pattern as upstream secondary ("%l:%c"): evaluated per redisplay
;; inside :eval, in window buffer context.
(defun nano/modeline-scroll-percent ()
  "Return scroll percent string for current buffer/window."
  (format-mode-line "%p"))

;; Render `mode-line-process' (a (:eval ...) status template set by
;; packages) to a string.  Hand-evaluated:
;; `format-mode-line' silently DROPS :eval constructs, so standard
;; packages using `mode-line-process' would vanish from the nano
;; modeline.  Mirrors redisplay semantics: dynamic eval, errors → nil.
(defun nano/modeline--render-process ()
  "Return string for buffer-local `mode-line-process', or nil."
  (when-let ((mlp mode-line-process))
    (cond ((stringp mlp) mlp)
          ((and (eq (car-safe mlp) :eval) (= (length mlp) 2))
           (ignore-errors (eval (cadr mlp) nil)))
          (t (ignore-errors (format-mode-line mlp))))))

;; Arrow separators — same powerline XPM method as the (now removed)
;; elfeed header (`elfeed-goodies/powerline-default-separator', default
;; `arrow-fade').  No new install: powerline ships as a goodies dep and
;; is already in `straight/repos/'.  Per-separator XPMs memoize per
;; (face1,face2,height) in a frame-local cache, so steady-state cost is
;; a hash lookup per redisplay; flush via `powerline-reset' on theme
;; change (see `nano/apply-modeline-faces').  TTY/batch returns nil and
;; collapses to the flat look — same as the old header did.
(defun nano/modeline--separator-fn (dir)
  "Powerline separator fn for DIR (`left'/`right'), tracking elfeed style."
  (let* ((sep (if (and (boundp 'elfeed-goodies/powerline-default-separator)
                       elfeed-goodies/powerline-default-separator)
                  elfeed-goodies/powerline-default-separator
                'arrow-fade))
         (pdir (if (boundp 'powerline-default-separator-dir)
                   (if (eq dir 'left)
                       (car powerline-default-separator-dir)
                     (cdr powerline-default-separator-dir))
                 dir)))
    (intern (format "powerline-%s-%s" sep pdir))))

(defun nano/modeline--sep-img (dir face1 face2 &optional sep-fn gui-p)
  "Raw powerline arrow image for FACE1 -> FACE2, or nil when unavailable.
Returns the image spec itself (NOT a rendered string) so callers can
push it into a `powerline-render' list exactly like elfeed-goodies
does (`search-header/draw-wide').  `powerline-render' handles the
image->space conversion (`pl/render'); pre-rendering then concat'ing
breaks width math.  Same face twice, TTY/batch, or missing powerline
returns nil (flat look).
Optional SEP-FN avoids per-separator `format'/`intern'; GUI-P avoids
re-testing `window-system' per gap — callers hoist both once per
compose."
  (when (and (if (null gui-p) window-system gui-p) (not (eq face1 face2)))
    (when (or (fboundp 'powerline-arrow-fade-left)
              (ignore-errors (require 'powerline nil t)))
      (let ((fn (or sep-fn (nano/modeline--separator-fn dir))))
        (when (fboundp fn)
          (ignore-errors (funcall fn face1 face2)))))))

;; Stale single-arrow renderer from the first arrows pass; the composer
;; below now threads raw images through `powerline-render' instead.
;; Drop it so reloads (`SPC f e r') don't leave two separator paths.
(when (fboundp 'nano/modeline--separator)
  (fmakunbound 'nano/modeline--separator))

(defun nano/modeline--pair (s &optional default-face)
  "Split faced string S into a (TEXT . FACE) block pair, or nil when empty.
FACE is the face at position 0; falls back to DEFAULT-FACE (bar
default) for unpropertized upstream strings like `primary'."
  (when (and s (not (string-empty-p s)))
    (cons (substring-no-properties s)
          (or (get-text-property 0 'face s)
              default-face
              'nano-face-header-default))))

(defun nano/modeline--render-side (dir pairs &optional sep-fn gui-p)
  "Build a `powerline-render' list for one side, arrow at every bg change.
DIR is `left' (LHS) or `right' (RHS); PAIRS are (TEXT . FACE) blocks
in display order.  Empty texts skipped; equal adjacent faces joined
without an arrow (a same-face arrow renders as an invisible gap).
Optional SEP-FN / GUI-P are hoisted per compose (see `nano/modeline--sep-img').
Requires `powerline-raw'; callers fall back to flat concat without it."
  (let (out prev-face)
    (dolist (p pairs)
      (when (and (car-safe p) (not (string-empty-p (car p))))
        (let ((face (or (cdr p) 'nano-face-header-default)))
          (when (and prev-face (not (eq prev-face face)))
            (let ((img (nano/modeline--sep-img dir prev-face face sep-fn gui-p)))
              (when img (push img out))))
          (push (powerline-raw (car p) face) out)
          (setq prev-face face))))
    (list (nreverse out) prev-face)))

;; Drop the old status-prefix advice on reload; the redefinition below
;; renders winum + workspace as their own blocks instead.
(advice-remove 'nano-modeline-compose 'nano-winum-prefix)

(with-eval-after-load 'nano-modeline
  (defun nano-modeline-compose (status name primary secondary)
    "Spacemacs-fused modeline: arrow at every block background change.
LHS blocks: winum, evil-state, RO/RW/**/narrow/remote, filename,
primary (mode/branch).  RHS blocks: proc/session, secondary/position,
workspace, scroll percent.  E.g.
` 1  N  RW  init.el (emacs-lisp) … <main>  Bot '
with `>' arrows melting each block into the next, like the removed
elfeed header and Spacemacs spaceline.
Drops low-priority blocks on narrow columns; selection replaces
position.  Flat concat when powerline is missing (fresh boot before
goodies installs); TTY keeps alignment via `powerline-fill' with nil
arrows (separator XPMs are GUI-only)."
    (let* ((ww (window-total-width))
           ;; Width-gated blocks.
           (ws-full (nano/workspace-name-string))
           (ws (if (< ww nano/modeline-truncate-ws-width) nil ws-full))
           (primary-eff (if (< ww nano/modeline-truncate-primary-width) "" primary))
           (sel (nano/modeline-selection-string))
           (secondary-base (or sel secondary))
           (secondary-eff (if (or sel (>= ww nano/modeline-truncate-secondary-width))
                              secondary-base ""))
           ;; Package-set `mode-line-process' block (a (:eval ...)
           ;; status template).  Nil in most buffers, so a no-op there.
           ;; Hand-rendered value may be any type; only strings display.
           ;; Literal % doubled: :eval output is %-expanded once, so a
           ;; single trailing % in "NN%" gets eaten.
           (proc-raw (when mode-line-process
                       (nano/modeline--render-process)))
           (proc (when (stringp proc-raw) (string-replace "%" "%%" proc-raw)))
           (active (nano/modeline-selected-p))
           ;; RO/RW both faded grey, ** critical.
           (prefix (let* ((code (cond ((string-suffix-p "RO" status) "RO")
                                      ((string-suffix-p "**" status) "**")
                                      ((string-suffix-p "RW" status) "RW")
                                      (t nil)))
                          (face (if (string= code "RO")
                                    'nano-face-header-faded
                                  (if (window-dedicated-p)
                                      'nano-face-header-popout
                                    (cond ((string= code "**") 'nano-face-header-critical)
                                          ((string= code "RW") 'nano-face-header-faded)
                                          (t 'nano-face-header-popout)))))
                          (text (if code
                                    (let ((base (substring status 0 (- (length status) (length code)))))
                                      (concat (if (string= base "") " " base)
                                              (if (window-dedicated-p) "--" code) " "))
                                  status)))
                     (propertize text 'face face)))
           (name-face (if active
                           'nano-face-header-active
                         'nano-face-header-strong))
           (B #'nano/modeline--pair)
           (lhs-pairs (delq nil
                            (append (list (funcall B (nano/winum-number-string))
                                          (funcall B (nano/evil-state-string))
                                          (funcall B prefix))
                                    (mapcar B (nano/modeline-extra-flags))
                                    (list (funcall B (propertize (concat " " name " ")
                                                                 'face name-face))
                                          (funcall B primary-eff)))))
           (pct (string-replace "%" "%%"
                                (concat " " (nano/modeline-scroll-percent) " ")))
           (rhs-pairs (delq nil (list (funcall B proc)
                                      (funcall B secondary-eff)
                                      (funcall B ws)
                                      (funcall B pct)))))
      (unless (fboundp 'powerline-raw)
        (ignore-errors (require 'powerline nil t)))
      (if (not (and (fboundp 'powerline-raw) (fboundp 'powerline-render)
                    (fboundp 'powerline-fill) (fboundp 'powerline-width)))
          ;; Flat fallback (fresh boot, powerline missing): same blocks,
          ;; filler keeps RHS right-aligned like the old concat path.
          (let* ((lhs (mapconcat (lambda (p) (propertize (car p) 'face (cdr p)))
                                 lhs-pairs ""))
                 (rhs (mapconcat (lambda (p) (propertize (car p) 'face (cdr p)))
                                 rhs-pairs ""))
                 (fill (max 1 (- ww (string-width lhs) (string-width rhs)))))
            (concat lhs
                    (propertize (make-string fill ?\ ) 'face 'nano-face-header-default)
                    rhs))
        ;; Powerline pipeline, same shape as the removed elfeed header:
        ;; render LHS, stretch-fill, render RHS.  Arrows fuse because
        ;; every bg change carries a separator and all faces are flat
        ;; (`:box nil' in `nano/apply-modeline-faces').
        ;; Hoist per-compose invariants: GUI flag + separator fns, so
        ;; per-gap cost is hash lookup + funcall, no format/intern.
        (let* ((gui window-system)
               (fn-l (nano/modeline--separator-fn 'left))
               (fn-r (nano/modeline--separator-fn 'right))
               (lhs-res (nano/modeline--render-side 'left lhs-pairs fn-l gui))
               (lhs (car lhs-res))
               (lhs-last (cadr lhs-res))
               ;; Cap a colored trailing block with an arrow into the
               ;; filler: when `primary' truncates away, the bar ends on
               ;; the filename block and would otherwise hard-edge.
               (lhs (if (and lhs-last (not (eq lhs-last 'nano-face-header-default)))
                        (let ((img (nano/modeline--sep-img
                                    'left lhs-last 'nano-face-header-default fn-l gui)))
                          (if img (append lhs (list img)) lhs))
                      lhs))
               (rhs (car (nano/modeline--render-side 'right rhs-pairs fn-r gui)))
               (reserve (powerline-width rhs)))
          (concat (powerline-render lhs)
                  (powerline-fill 'nano-face-header-default reserve)
                  (powerline-render rhs))))))
  ;; Bottom bar — replaces vendored nano-modeline.el installer edit.
  ;; Upstream `nano-modeline' installs on header-line (top) and
  ;; `nano-modeline-update-windows' hides mode-line per window.
  ;; Copy-over (not frozen list) so upstream cond additions survive.
  ;; Idempotent: skips when header default already moved (reload safe).
  (remove-hook 'window-configuration-change-hook #'nano-modeline-update-windows)
  (dolist (w (window-list nil t))
    (set-window-parameter w 'mode-line-format nil))
  (let ((hdr (default-value 'header-line-format)))
    (when hdr
      (setq-default mode-line-format hdr)
      (setq-default header-line-format nil)))
  (force-mode-line-update t))

;; 6c. Double / triple / quad vertical split — SPC w 2 / SPC w 3 / SPC w 4
;;     (basic SPC w splits live in §5c — this extends that group).
;;     Creates two / three / four balanced vertical columns in current frame.
;;     Every pane — including the current one — lands on `*scratch*': a
;;     clean layout, not a buffer shuffle.  Existing buffers stay open
;;     elsewhere (return via M-1..M-4).  The single `*scratch*' is
;;     shared, so panes stay in sync; point is left untouched.
;;     C-u SPC w 2 / C-u SPC w 3 / C-u SPC w 4 (purge) forces delete-other-windows ignoring window-parameters
;;     (e.g. pinned side windows that normally resist deletion).
(defun nano/window-set-scratch-columns (wins)
  "Point every window in WINS at `*scratch*'; balance widths.
Return t on success, nil when no `*scratch*' buffer exists."
  (let ((scratch (get-buffer "*scratch*")))
    (when scratch
      (dolist (w wins)
        (set-window-buffer w scratch))
      (nano/balance-window-widths)
      t)))

(defun nano/window-split-double-columns (&optional purge)
  "Two vertical columns, balanced, every pane on `*scratch*'.
With PURGE (C-u), use `delete-other-windows' ignoring window params."
  (interactive "P")
  (if purge
      (let ((ignore-window-parameters t)) (delete-other-windows))
    (delete-other-windows))
  (let ((w2 (ignore-errors (split-window-right))))
    (if w2
        (or (nano/window-set-scratch-columns (list (selected-window) w2))
            (message "SPC w 2: no *scratch* buffer"))
      (message "SPC w 2: frame too narrow to split"))))

(defun nano/window-split-triple-columns (&optional purge)
  "Three vertical columns, balanced, every pane on `*scratch*'.
With PURGE (C-u), use `delete-other-windows' ignoring window params."
  (interactive "P")
  (if purge
      (let ((ignore-window-parameters t)) (delete-other-windows))
    (delete-other-windows))
  (let* ((w2 (ignore-errors (split-window-right)))
         (w3 (when w2 (ignore-errors (split-window w2 nil 'right)))))
    (if (and w2 w3)
        (or (nano/window-set-scratch-columns (list (selected-window) w2 w3))
            (message "SPC w 3: no *scratch* buffer"))
      (message "SPC w 3: frame too narrow to split"))))

(defun nano/window-split-quad-columns (&optional purge)
  "Four vertical columns, balanced, every pane on `*scratch*'.
With PURGE (C-u), use `delete-other-windows' ignoring window params."
  (interactive "P")
  (if purge
      (let ((ignore-window-parameters t)) (delete-other-windows))
    (delete-other-windows))
  (let* ((w2 (ignore-errors (split-window-right)))
         (w3 (when w2 (ignore-errors (split-window w2 nil 'right))))
         (w4 (when w3 (ignore-errors (split-window w3 nil 'right)))))
    (if (and w2 w3 w4)
        (or (nano/window-set-scratch-columns (list (selected-window) w2 w3 w4))
            (message "SPC w 4: no *scratch* buffer"))
      (message "SPC w 4: frame too narrow to split"))))

(define-key spacemacs-leader-map (kbd "w 2") 'nano/window-split-double-columns)
(define-key spacemacs-leader-map (kbd "w 3") 'nano/window-split-triple-columns)
(define-key spacemacs-leader-map (kbd "w 4") 'nano/window-split-quad-columns)
(which-key-add-key-based-replacements "SPC w 2" "double columns"
  "SPC w 3" "triple columns"
  "SPC w 4" "quad columns")

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

;; 6e. Uniform column widths — SPC w =
;;     `window-combination-resize t' makes splits/deletes take space
;;     proportionally from all siblings (default nil steals from one
;;     neighbor only, skewing columns). Exact equalization after each
;;     split/delete via `nano/balance-window-widths' — widths only,
;;     since `balance-windows' would also reset intentional height tweaks.
;;     Geometry check (equal tops = side-by-side) skips stacked splits
;;     and full-width bottom popups (which-key/LV). Advice covers ALL
;;     split paths (SPC w / s, evil, mouse). Manual drag survives until
;;     next split — no config-change hook snap.
(setq window-combination-resize t)

(defun nano/window-siblings (first)
  "List FIRST window plus following siblings via `window-next-sibling'."
  (let ((wins (list first)) (w (window-next-sibling first)))
    (while w (push w wins) (setq w (window-next-sibling w)))
    (nreverse wins)))

(defun nano/equalize-widths (windows)
  "Resize side-by-side WINDOWS to equal widths, left to right.
Total preserved; +1 remainder goes leftmost. Heights untouched.
`adjust-window-trailing-edge' moves one edge only (unlike
`window-resize' proportional). Min-width/fixed errors ignored."
  (let* ((n (length windows))
         (total (apply #'+ (mapcar #'window-total-width windows)))
         (base (/ total n))
         (rem (% total n))
         (i 0))
    (dolist (w (butlast windows))
      (let* ((target (+ base (if (< i rem) 1 0)))
             (delta (- target (window-total-width w))))
        (unless (zerop delta)
          (ignore-errors (adjust-window-trailing-edge w delta t))))
      (setq i (1+ i)))))

(defun nano/balance-window-widths-1 (win)
  "Recursive worker: equalize every side-by-side level under WIN."
  (when (window-child win)
    (let* ((siblings (nano/window-siblings (window-child win)))
           (tops (mapcar (lambda (w) (nth 1 (window-edges w))) siblings))
           (side-by-side-p (and (> (length siblings) 1)
                                (apply #'= tops))))
      (when side-by-side-p
        (nano/equalize-widths siblings))
      (dolist (w siblings)
        (nano/balance-window-widths-1 w)))))

(defun nano/balance-window-widths (&optional frame)
  "Equalize widths of all side-by-side columns on FRAME. Heights untouched.
Bound to SPC w =. Runs automatically after splits/deletes."
  (interactive)
  (let ((root (frame-root-window (or frame (selected-frame)))))
    (ignore-errors (nano/balance-window-widths-1 root))))

(defun nano/balance-widths-after-split (&rest _)
  "Advice target: rebalance widths after split/delete.
Skips minibuffer and single-window frames (nothing to equalize)."
  (unless (or (window-minibuffer-p (selected-window))
              (<= (length (window-list nil nil)) 1))
    (nano/balance-window-widths)))

(advice-add 'split-window-right :after #'nano/balance-widths-after-split)
(advice-add 'split-window-below :after #'nano/balance-widths-after-split)
(advice-add 'delete-window :after #'nano/balance-widths-after-split)
(advice-add 'delete-other-windows :after #'nano/balance-widths-after-split)

(define-key spacemacs-leader-map (kbd "w =") 'nano/balance-window-widths)
(which-key-add-key-based-replacements "SPC w =" "balance widths")

;; 6f. Scratch-window routing — new buffers display where *scratch* is.
;;     Extends §18b1 org-link rule to everything: first display of any
;;     not-yet-visible buffer lands in `*scratch*' window, origin keeps
;;     its buffer, focus follows.  E.g. `SPC w 2' (scratch left, org
;;     right) then `SPC f f notes.org' opens notes in scratch pane.
;;     Two paths (Emacs splits display): `display-buffer' consults
;;     `display-buffer-alist' (help/magit/agenda), `switch-to-buffer'
;;     (find-file/SPC b b/org-open) bypasses it — hence alist catch-all
;;     PLUS `:around' on `switch-to-buffer' sharing one predicate.
;;     Explicit stays explicit: `switch-to-buffer-other-window',
;;     `display-buffer-in-direction' (elfeed §23a2),
;;     dedicated/side windows bypass.  Single window or scratch hidden
;;     → open in place.  Elfeed search/show untouched both as origin
;;     and as target buffer.
(defvar nano/scratch-redirect-in-progress nil
  "Non-nil while scratch-window routing runs its own display.
Guards `switch-to-buffer' advice vs `display-buffer' action reentry.")

(defun nano/scratch-target-window ()
  "Window showing `*scratch*', or selected window as fallback.
Single window or scratch invisible → current window.  Scoped to
selected frame; never touches elfeed splits (`elfeed-search/show')."
  (let ((wins (window-list nil nil)))
    (cond ((null (cdr wins)) (selected-window))
          ((get-buffer-window "*scratch*" nil))
          (t (selected-window)))))

(defun nano/scratch-target-usable-p (target origin)
  "Non-nil when TARGET can receive an opened buffer.
Requires live, distinct from ORIGIN, not dedicated/minibuffer."
  (and target (window-live-p target)
       (not (eq target origin))
       (not (window-dedicated-p target))
       (not (window-minibuffer-p target))))

(defun nano/scratch-buffer-skip-p (buf-or-name)
  "Non-nil when BUF-OR-NAME must keep default placement.
Skips ephemeral ` *' UI (which-key/LV/transient/minibuffer),
` *Completions*', `*Warnings*', `*scratch*' itself.  Accepts live
buffer or name string (new buffers not yet created)."
  (let ((name (if (bufferp buf-or-name) (buffer-name buf-or-name)
                (if (stringp buf-or-name) buf-or-name
                  (format "%s" buf-or-name)))))
    (or (null name) (string-empty-p name)
        (string-prefix-p " " name)
        (string-prefix-p "*Warnings*" name)
        (member name '("*Completions*" "*Completion*" "*scratch*")))))

(defun nano/elfeed-buffer-p (buf)
  "Non-nil when BUF is a live elfeed buffer.
Checks `elfeed-search/show-mode' or `*elfeed' name prefix."
  (and (buffer-live-p buf)
       (with-current-buffer buf
         (or (derived-mode-p 'elfeed-search-mode 'elfeed-show-mode)
             (let ((n (buffer-name buf)))
               (and (stringp n) (string-prefix-p "*elfeed" n)))))))

(defun nano/scratch-elfeed-context-p (buf origin)
  "Non-nil when scratch routing must stand down for elfeed.
True when ORIGIN shows an elfeed buffer or BUF is one.  BUF may be
a live buffer or name; unknown names → nil."
  (or (and (window-live-p origin)
           (nano/elfeed-buffer-p (window-buffer origin)))
      (nano/elfeed-buffer-p
       (if (bufferp buf) buf (and (stringp buf) (get-buffer buf))))))

(defun nano/move-opened-buffer-to-target (origin target origin-buf shown-before)
  "Move buffer just opened from ORIGIN into TARGET, then select TARGET.
ORIGIN-BUF is the buffer before open; SHOWN-BEFORE is an alist
of (window . buffer) captured pre-open.  Open must run in ORIGIN
first (keeps context); this only relocates the result.
Returns t when a new buffer moved, nil when open stayed in place
\(same-file jump, browser link, error path)."
  (when (nano/scratch-target-usable-p target origin)
    (let* ((cur-win (selected-window))
           (result-win (if (eq cur-win origin) origin cur-win))
           (result-buf (window-buffer result-win))
           (result-pt (window-point result-win)))
      (unless (or (null result-buf) (eq result-buf origin-buf))
        (when (eq result-win origin)
          (set-window-buffer origin origin-buf))
        (when (and (not (eq result-win origin))
                   (not (eq result-win target)))
          (let ((prev (cdr (assq result-win shown-before))))
            (cond ((and prev (buffer-live-p prev))
                   (set-window-buffer result-win prev))
                  ((and (not (assq result-win shown-before))
                        (window-live-p result-win))
                   (delete-window result-win)))))
        (set-window-buffer target result-buf)
        (set-window-point target result-pt)
        (select-window target)
        t))))

(defun nano/display-buffer-in-scratch-window (buffer alist)
  "Display BUFFER in `*scratch*' window for `display-buffer-alist'.
Catch-all (appended last); returns target window or nil to fall
through.  Never selects (caller `pop-to-buffer' does); never splits.
Skips visible buffers, skipped names, elfeed, unusable targets."
  (ignore alist)
  (when (and (not nano/scratch-redirect-in-progress)
             (buffer-live-p buffer)
             (not (nano/scratch-buffer-skip-p buffer)))
    (let ((origin (selected-window))
          (target (nano/scratch-target-window)))
      (when (and (not (nano/scratch-elfeed-context-p buffer origin))
                 (nano/scratch-target-usable-p target origin)
                 (not (get-buffer-window buffer nil)))
        (let ((nano/scratch-redirect-in-progress t))
          (set-window-buffer target buffer)
          target)))))

(defun nano/switch-to-buffer-in-scratch-window (orig buffer-or-name &optional norecord force-same-window)
  "Route first display of not-yet-visible buffers to scratch window.
Around `switch-to-buffer' (covers `find-file', `SPC b b', org-open).
Restores origin buffer, moves point, selects target.  Passthrough
when redirect in progress, FORCE-SAME-WINDOW, minibuffer, same
buffer, already visible, skipped name, elfeed, or unusable target."
  (if (or nano/scratch-redirect-in-progress
          force-same-window
          (window-minibuffer-p (selected-window)))
      (funcall orig buffer-or-name norecord force-same-window)
    (let* ((buf (if (bufferp buffer-or-name) buffer-or-name
                  (get-buffer buffer-or-name)))
           (origin (selected-window))
           (origin-buf (window-buffer origin)))
      (cond ((and (buffer-live-p buf) (eq buf origin-buf))
             (funcall orig buffer-or-name norecord force-same-window))
            ((and (buffer-live-p buf) (get-buffer-window buf nil))
             (funcall orig buffer-or-name norecord force-same-window))
            ((nano/scratch-buffer-skip-p (or buf buffer-or-name))
             (funcall orig buffer-or-name norecord force-same-window))
            ((nano/scratch-elfeed-context-p (or buf buffer-or-name) origin)
             (funcall orig buffer-or-name norecord force-same-window))
            (t
             (let ((target (nano/scratch-target-window)))
               (if (not (nano/scratch-target-usable-p target origin))
                   (funcall orig buffer-or-name norecord force-same-window)
                 (let ((shown-before (mapcar (lambda (w) (cons w (window-buffer w)))
                                             (window-list nil nil)))
                       result)
                   (let ((nano/scratch-redirect-in-progress t))
                     (setq result (funcall orig buffer-or-name norecord force-same-window)))
                   (nano/move-opened-buffer-to-target origin target origin-buf shown-before)
                   result))))))))

(advice-add 'switch-to-buffer :around #'nano/switch-to-buffer-in-scratch-window)
(add-to-list 'display-buffer-alist '("." (nano/display-buffer-in-scratch-window)) t)


;; ---------------------------------------------------------------------
;; §7  Toggles  (SPC t n theme, SPC t w whitespace, §7c spacemacs-light)
;; ---------------------------------------------------------------------
;; 7a. Theme — uses vendored nano-theme.el:802 `nano-toggle-theme' which checks
;; `nano-theme-var' ("light"/"dark") and calls `nano-theme-set-*' +
;; `nano-refresh-theme'.  Wrapper handles nil (e.g. -default start)
;; and adds echo feedback.  Lightweight, no extra package.
;; Choice persists in plain-text `nano/theme-state-file', restored on
;; next launch (skipped when explicit -dark/-light/-default CLI flag).
;; No `require' subr-x: `string-trim' autoloads, zero startup cost.

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

;; 7b. Trailing whitespace — true red in code/text buffers, Spacemacs parity.
;;     Mechanism is NOT theme-only: `show-trailing-whitespace' enables the
;;     highlight, `trailing-whitespace' face colors it.  Nano maps that face
;;     to `nano-face-subtle' (nano-theme.el:124), so override to true red here.
;;     `nano-refresh-theme' re-applies nano faces, so re-assert via advice.
;;     Spacemacs opt-in model (spacemacs-defaults/packages.el:494-495,
;;     funcs.el:178): global default stays nil, highlight enabled ONLY via
;;     `prog-mode-hook' + `text-mode-hook' (covers org/markdown derivatives).
;;     fundamental/dired/special/help/magit/minibuffer never highlight.
;;     Exempt within scope: read-only + special-mode buffers (eww derives from
;;     special-mode, plus help/magit/...) — mode hooks run before
;;     `after-change-major-mode-hook', so the inhibit below still wins there.
(setq-default show-trailing-whitespace nil)

(defvar nano/trailing-whitespace-enabled t
  "Non-nil enables trailing-whitespace highlight in prog/text buffers.
Mirrors `dotspacemacs-show-trailing-whitespace'.  Flipped by
`nano/toggle-trailing-whitespace' (SPC t w); the global default of
`show-trailing-whitespace' stays nil so other modes never inherit it.")

(defun nano/enable-trailing-whitespace ()
  "Enable trailing-whitespace highlight in prog/text buffers (Spacemacs parity)."
  (when nano/trailing-whitespace-enabled
    (setq show-trailing-whitespace t)))

(add-hook 'prog-mode-hook #'nano/enable-trailing-whitespace)
(add-hook 'text-mode-hook #'nano/enable-trailing-whitespace)

(defun nano/apply-trailing-whitespace-face ()
  "Paint `trailing-whitespace' true red.  Re-applied after theme refresh."
  (set-face-attribute 'trailing-whitespace nil
                      :foreground 'unspecified :background "red"))

(nano/apply-trailing-whitespace-face)
(when (fboundp 'nano-refresh-theme)
  (advice-add 'nano-refresh-theme :after #'nano/apply-trailing-whitespace-face))

;; 7b2. Mode-line box — replaces vendored nano-theme.el edit.
;;      Upstream sets mode-line :height 0.1 + :box nil (hairline hidden).
;;      Restore readable 1px box in default bg. Re-applied after refresh.
(defun nano/apply-mode-line-box ()
  "Restore visible 1px mode-line box.  Re-applied after theme refresh."
  (let ((bg (face-background 'nano-face-default)))
    (set-face-attribute 'mode-line nil :height 1.0
                        :box `(:line-width 1 :color ,bg :style nil))
    (set-face-attribute 'mode-line-inactive nil :height 1.0
                        :box `(:line-width 1 :color ,bg :style nil))))

(nano/apply-mode-line-box)
(when (fboundp 'nano-refresh-theme)
  (advice-add 'nano-refresh-theme :after #'nano/apply-mode-line-box))

;; 7c. Spacemacs-light emulation — light only; dark analog in 7c2.
;;     Palette = spacemacs-theme.el GUI light column
;;     (~/.emacs.d/core/libs/spacemacs-theme/spacemacs-theme.el:111-169).
;;     Two hooks on vendored `nano-refresh-theme' (nano-theme.el:790):
;;     :before remaps the 9 nano colors so `nano-faces'/`nano-theme'
;;     derive from Spacemacs values; :after breaks out the flat
;;     font-lock/org faces nano collapses (all-salient keywords,
;;     all-strong org levels).  Never edit straight/repos/ (lost on
;;     `straight-pull-all'); all overrides live here.
(defconst nano/spacemacs-light-palette
  '((bg1 . "#fbf8ef") (bg2 . "#efeae9") (base . "#50425c")
    (base-dim . "#7e7482") (keyword . "#3a81c3") (func . "#6c3163")
    (str . "#2d9574") (type . "#ba2f59") (var . "#715ab1")
    (const . "#4e3163") (comment . "#2aa1ae") (comment-bg . "#ecf3ec")
    (meta . "#da8b55") (war . "#dc752f") (suc . "#42ae2c")
    (err . "#e0211d") (highlight . "#d3d3e7") (strong . "#100a14")
    (head2 . "#2d9574") (head3 . "#67b11d") (head4 . "#b1951d")
    (yellow-bg . "#f6f1e1") (green-bg . "#edf2e9")
    (cblk . "#50425c") (cblk-bg . "#e8e3f0")
    (cblk-ln . "#9380b2") (cblk-ln-bg . "#ddd8eb"))
  "Spacemacs-light GUI hexes used by the §7c overrides.
`base'/`base-dim'/`cblk' deliberately darkened one step vs stock
Spacemacs (#655370/#a094a2) for starker body + faded text.")

;; 7c2. Nord-dark font-lock/org breakout — dark only.
;;      Dark keeps stock nano-dark base (nano-theme-dark.el) untouched:
;;      no color remap, modeline/nano-faces unchanged.  Only font-lock +
;;      org faces are broken out of the flat 4-role aliasing
;;      (nano-theme.el:130-141) into distinct Nord hues, mirroring the
;;      information density of 7c.  `keyword' = nord9 = nano salient, so
;;      the theme identity carries over.
(defconst nano/nord-dark-palette
  '((keyword . "#81A1C1") (func . "#88C0D0") (type . "#8FBCBB")
    (var . "#D8DEE9") (const . "#B48EAD") (str . "#A3BE8C")
    (comment . "#616E88") (comment-bg . "#3B4252") (doc . "#D08770")
    (war . "#EBCB8B") (prep . "#5E81AC") (subtle . "#434C5E"))
  "Nord hexes used by the §7c2 dark breakout.")

(defun nano/remap-spacemacs-light-colors (&rest _)
  "Remap the 9 nano colors to Spacemacs-light when light.
Installed :before `nano-refresh-theme' so `nano-faces' derives
from remapped values.  No-op when dark."
  (when (and (boundp 'nano-theme-var) (string= nano-theme-var "light"))
    (let ((g (lambda (k) (cdr (assq k nano/spacemacs-light-palette)))))
      (setq nano-color-background (funcall g 'bg1)
            nano-color-foreground (funcall g 'base)
            nano-color-highlight (funcall g 'bg2)
            nano-color-subtle (funcall g 'bg2)
            nano-color-faded (funcall g 'base-dim)
            nano-color-salient (funcall g 'keyword)
            nano-color-strong (funcall g 'strong)
            nano-color-popout (funcall g 'type)
            nano-color-critical (funcall g 'err)))))

(defun nano/set-face-maybe (face &rest args)
  "Apply `set-face-attribute' ARGS to FACE when it exists.
Guards org/outline faces before their libraries load."
  (when (facep face)
    (apply #'set-face-attribute face nil args)))

(defun nano/apply-spacemacs-light-org-faces ()
  "Apply Spacemacs-light org/outline faces.  Safe before org loads."
  (when (and (boundp 'nano-theme-var) (string= nano-theme-var "light"))
    (let ((g (lambda (k) (cdr (assq k nano/spacemacs-light-palette)))))
      (nano/set-face-maybe 'org-level-1 :foreground (funcall g 'keyword) :weight 'bold :height 1.3)
      (nano/set-face-maybe 'org-level-2 :foreground (funcall g 'head2) :weight 'bold :height 1.2)
      (nano/set-face-maybe 'org-level-3 :foreground (funcall g 'head3) :weight 'normal :height 1.1)
      (nano/set-face-maybe 'org-level-4 :foreground (funcall g 'head4) :weight 'normal)
      (nano/set-face-maybe 'org-level-5 :foreground (funcall g 'keyword) :weight 'normal)
      (nano/set-face-maybe 'org-level-6 :foreground (funcall g 'head2) :weight 'normal)
      (nano/set-face-maybe 'org-level-7 :foreground (funcall g 'head3) :weight 'normal)
      (nano/set-face-maybe 'org-level-8 :foreground (funcall g 'head4) :weight 'normal)
      (nano/set-face-maybe 'outline-1 :foreground (funcall g 'keyword))
      (nano/set-face-maybe 'outline-2 :foreground (funcall g 'head2))
      (nano/set-face-maybe 'outline-3 :foreground (funcall g 'head3))
      (nano/set-face-maybe 'outline-4 :foreground (funcall g 'head4))
      (nano/set-face-maybe 'org-link :foreground (funcall g 'keyword) :underline t :weight 'normal)
      (nano/set-face-maybe 'org-date :foreground (funcall g 'var) :underline t)
      (nano/set-face-maybe 'org-todo :foreground (funcall g 'war) :background (funcall g 'yellow-bg) :weight 'bold)
      (nano/set-face-maybe 'org-done :foreground (funcall g 'suc) :background (funcall g 'green-bg) :weight 'bold)
      (nano/set-face-maybe 'org-block :foreground (funcall g 'cblk) :background (funcall g 'cblk-bg) :extend t)
      (nano/set-face-maybe 'org-block-begin-line :foreground (funcall g 'cblk-ln) :background (funcall g 'cblk-ln-bg) :extend t)
      (nano/set-face-maybe 'org-block-end-line :foreground (funcall g 'cblk-ln) :background (funcall g 'cblk-ln-bg) :extend t)
      (nano/set-face-maybe 'org-tag :foreground (funcall g 'meta))
      (nano/set-face-maybe 'org-special-keyword :foreground (funcall g 'func))
      (nano/set-face-maybe 'org-meta-line :foreground (funcall g 'meta))
      (nano/set-face-maybe 'org-document-title :foreground (funcall g 'func) :weight 'bold :height 1.4 :underline t))))

(defun nano/apply-spacemacs-light-faces (&rest _)
  "Break out font-lock/org faces to Spacemacs-light when light.
Installed :after `nano-refresh-theme'.  No-op when dark."
  (when (and (boundp 'nano-theme-var) (string= nano-theme-var "light"))
    (let ((g (lambda (k) (cdr (assq k nano/spacemacs-light-palette)))))
      (nano/set-face-maybe 'font-lock-comment-face :foreground (funcall g 'comment) :background (funcall g 'comment-bg) :slant 'normal :weight 'regular)
      (nano/set-face-maybe 'font-lock-doc-face :foreground (funcall g 'meta) :weight 'regular)
      (nano/set-face-maybe 'font-lock-string-face :foreground (funcall g 'str))
      (nano/set-face-maybe 'font-lock-keyword-face :foreground (funcall g 'keyword) :weight 'bold)
      (nano/set-face-maybe 'font-lock-builtin-face :foreground (funcall g 'keyword) :weight 'bold)
      (nano/set-face-maybe 'font-lock-preprocessor-face :foreground (funcall g 'func))
      (nano/set-face-maybe 'font-lock-type-face :foreground (funcall g 'type) :weight 'bold)
      (nano/set-face-maybe 'font-lock-constant-face :foreground (funcall g 'const))
      (nano/set-face-maybe 'font-lock-variable-name-face :foreground (funcall g 'var))
      (nano/set-face-maybe 'font-lock-function-name-face :foreground (funcall g 'func) :weight 'bold)
      (nano/set-face-maybe 'font-lock-warning-face :foreground (funcall g 'war))
      (nano/set-face-maybe 'link :foreground (funcall g 'keyword) :underline t)
      (nano/apply-spacemacs-light-org-faces))))

;; 7c3. Light text starkness — body + faded/comments slightly starker.
;;      Vendored `nano-theme--basics' pins `default :weight light' and
;;      `nano-faces' pins salient/faded `:weight light'; thin with Noto
;;      Sans Mono.  Bump to `regular' light-only so body + secondary read
;;      thicker without changing hues.  Dark untouched.
(defun nano/apply-light-text-starkness (&rest _)
  "Thicken light-mode body + faded faces.  No-op when dark.
Installed :after `nano-refresh-theme' (after §7c breakout so vendored
`light' weights stay overridden).  Safe before org loads."
  (when (and (boundp 'nano-theme-var) (string= nano-theme-var "light"))
    (nano/set-face-maybe 'default :weight 'regular)
    (nano/set-face-maybe 'nano-face-default :weight 'regular)
    (nano/set-face-maybe 'nano-face-salient :weight 'regular)
    (nano/set-face-maybe 'nano-face-faded :weight 'regular)
    (nano/set-face-maybe 'font-lock-doc-face :weight 'regular)
    (nano/set-face-maybe 'org-meta-line :weight 'regular)
    (nano/set-face-maybe 'org-special-keyword :weight 'regular)
    (nano/set-face-maybe 'org-drawer :weight 'regular)
    (nano/set-face-maybe 'org-table :weight 'regular)
    (nano/set-face-maybe 'org-tag :weight 'regular)))

(defun nano/apply-nord-dark-org-faces ()
  "Apply Nord-dark org/outline faces.  Safe before org loads."
  (when (and (boundp 'nano-theme-var) (string= nano-theme-var "dark"))
    (let ((g (lambda (k) (cdr (assq k nano/nord-dark-palette)))))
      (nano/set-face-maybe 'org-level-1 :foreground (funcall g 'func) :weight 'bold :height 1.3)
      (nano/set-face-maybe 'org-level-2 :foreground (funcall g 'str) :weight 'bold :height 1.2)
      (nano/set-face-maybe 'org-level-3 :foreground (funcall g 'war) :weight 'normal :height 1.1)
      (nano/set-face-maybe 'org-level-4 :foreground (funcall g 'doc) :weight 'normal)
      (nano/set-face-maybe 'org-level-5 :foreground (funcall g 'keyword) :weight 'normal)
      (nano/set-face-maybe 'org-level-6 :foreground (funcall g 'str) :weight 'normal)
      (nano/set-face-maybe 'org-level-7 :foreground (funcall g 'war) :weight 'normal)
      (nano/set-face-maybe 'org-level-8 :foreground (funcall g 'doc) :weight 'normal)
      (nano/set-face-maybe 'outline-1 :foreground (funcall g 'func))
      (nano/set-face-maybe 'outline-2 :foreground (funcall g 'str))
      (nano/set-face-maybe 'outline-3 :foreground (funcall g 'war))
      (nano/set-face-maybe 'outline-4 :foreground (funcall g 'doc))
      (nano/set-face-maybe 'org-link :foreground (funcall g 'keyword) :underline t :weight 'normal)
      (nano/set-face-maybe 'org-date :foreground (funcall g 'var) :underline t)
      (nano/set-face-maybe 'org-todo :foreground (funcall g 'war) :background (funcall g 'subtle) :weight 'bold)
      (nano/set-face-maybe 'org-done :foreground (funcall g 'str) :background (funcall g 'comment-bg) :weight 'bold)
      (nano/set-face-maybe 'org-block :foreground (funcall g 'keyword) :background (funcall g 'comment-bg) :extend t)
      (nano/set-face-maybe 'org-block-begin-line :foreground (funcall g 'type) :background (funcall g 'subtle) :extend t)
      (nano/set-face-maybe 'org-block-end-line :foreground (funcall g 'type) :background (funcall g 'subtle) :extend t)
      (nano/set-face-maybe 'org-tag :foreground (funcall g 'doc))
      (nano/set-face-maybe 'org-special-keyword :foreground (funcall g 'type))
      (nano/set-face-maybe 'org-meta-line :foreground (funcall g 'doc))
      (nano/set-face-maybe 'org-document-title :foreground (funcall g 'func) :weight 'bold :height 1.4 :underline t))))

(defun nano/apply-nord-dark-faces (&rest _)
  "Break out font-lock/org faces to Nord-dark when dark.
Installed :after `nano-refresh-theme'.  No-op when light."
  (when (and (boundp 'nano-theme-var) (string= nano-theme-var "dark"))
    (let ((g (lambda (k) (cdr (assq k nano/nord-dark-palette)))))
      (nano/set-face-maybe 'font-lock-comment-face :foreground (funcall g 'comment) :background (funcall g 'comment-bg) :slant 'normal :weight 'light)
      (nano/set-face-maybe 'font-lock-doc-face :foreground (funcall g 'doc))
      (nano/set-face-maybe 'font-lock-string-face :foreground (funcall g 'str))
      (nano/set-face-maybe 'font-lock-keyword-face :foreground (funcall g 'keyword) :weight 'bold)
      (nano/set-face-maybe 'font-lock-builtin-face :foreground (funcall g 'keyword) :weight 'bold)
      (nano/set-face-maybe 'font-lock-preprocessor-face :foreground (funcall g 'prep))
      (nano/set-face-maybe 'font-lock-type-face :foreground (funcall g 'type) :weight 'bold)
      (nano/set-face-maybe 'font-lock-constant-face :foreground (funcall g 'const))
      (nano/set-face-maybe 'font-lock-variable-name-face :foreground (funcall g 'var))
      (nano/set-face-maybe 'font-lock-function-name-face :foreground (funcall g 'func) :weight 'bold)
      (nano/set-face-maybe 'font-lock-warning-face :foreground (funcall g 'war))
      (nano/set-face-maybe 'link :foreground (funcall g 'keyword) :underline t)
      (nano/apply-nord-dark-org-faces))))

(defun nano/apply-theme-org-faces ()
  "Re-apply org faces for the active theme (dispatch by `nano-theme-var')."
  (if (and (boundp 'nano-theme-var) (string= nano-theme-var "dark"))
      (nano/apply-nord-dark-org-faces)
    (nano/apply-spacemacs-light-org-faces)))

;; Re-apply org faces when org loads later (toggle state read live).
(with-eval-after-load 'org
  (nano/apply-theme-org-faces)
  (nano/apply-light-text-starkness))

(when (fboundp 'nano-refresh-theme)
  (advice-add 'nano-refresh-theme :before #'nano/remap-spacemacs-light-colors)
  (advice-add 'nano-refresh-theme :after #'nano/apply-spacemacs-light-faces)
  (advice-add 'nano-refresh-theme :after #'nano/apply-light-text-starkness)
  (advice-add 'nano-refresh-theme :after #'nano/apply-nord-dark-faces))

;; `nano/theme-restore' above already refreshed with stock colors;
;; light: re-refresh once so faces derive from the remapped palette.
;; dark: stock faces already derived, just apply the 7c2 breakout.
(cond ((and (boundp 'nano-theme-var) (string= nano-theme-var "light")
            (fboundp 'nano-refresh-theme))
       (nano-refresh-theme))
      ((and (boundp 'nano-theme-var) (string= nano-theme-var "dark"))
       (nano/apply-nord-dark-faces)))

(defun nano/trailing-whitespace-inhibit-p ()
  "Non-nil when current buffer should skip trailing-whitespace highlight."
  (or buffer-read-only
      (derived-mode-p 'special-mode)))

(defun nano/disable-trailing-whitespace-maybe ()
  "Set `show-trailing-whitespace' nil in read-only / special buffers."
  (when (nano/trailing-whitespace-inhibit-p)
    (setq show-trailing-whitespace nil)))

(add-hook 'after-change-major-mode-hook #'nano/disable-trailing-whitespace-maybe)
(add-hook 'read-only-mode-hook #'nano/disable-trailing-whitespace-maybe)
;; No boot-time buffer loop: hooks cover new buffers; saves O(buffers) startup.

(defun nano/toggle-trailing-whitespace ()
  "Toggle trailing-whitespace highlight in prog/text buffers.  Bound to SPC t w.
Flips `nano/trailing-whitespace-enabled'; other modes stay off when enabling.
Exempt buffers (read-only / special-mode) stay off when enabling.
The global default of `show-trailing-whitespace' stays nil so modes
outside prog/text never inherit the highlight."
  (interactive)
  (setq nano/trailing-whitespace-enabled (not nano/trailing-whitespace-enabled))
  (let ((v nano/trailing-whitespace-enabled))
    (dolist (b (buffer-list))
      (with-current-buffer b
        (setq show-trailing-whitespace
              (and v
                   (derived-mode-p 'prog-mode 'text-mode)
                   (not (nano/trailing-whitespace-inhibit-p))))))
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
(setq completion-styles '(space-wildcard basic substring partial-completion flex)
      completion-category-overrides '((file (styles space-wildcard partial-completion))))
;; §8b  SPACE-wildcard completion style (custom, zero-dep)
;; Whitespace in the query splits it into tokens; every token must match,
;; in order, with arbitrary characters (space, hyphen, underscore, dot...)
;; allowed between tokens.  Built on the same PCM engine as partial-
;; completion, so file-name handling is inherited (`completion-boundaries'
;; keeps the directory part literal; the file try-filter applies).
;; Example: "lorem dolor" matches both "lorem ipsum dolor" and
;; "lorem-ipsum-dolor.txt"; "ut dolor" matches neither.  Single-token
;; input behaves exactly like plain prefix completion.
(defun nano/space-wildcard--tokens-pattern (s)
  "Turn whitespace-separated S into a PCM pattern with `star' joins."
  (let ((tokens (split-string s "[ \t\n]+" t)))
    (if (<= (length tokens) 1)
        (append tokens (list 'point))
      (let ((pat (list (car tokens))))
        (dolist (tok (cdr tokens))
          (setq pat (append pat (list 'star tok))))
        (append pat (list 'point))))))

(defun nano/space-wildcard--all (string table pred point)
  "Compute (ALL PATTERN PREFIX SUFFIX CARBOUNDS) for SPACE-wildcard."
  (let* ((beforepoint (substring string 0 point))
         (afterpoint (substring string point))
         (bounds (completion-boundaries beforepoint table pred afterpoint))
         (suffix (substring afterpoint (cdr bounds)))
         (prefix (substring beforepoint 0 (car bounds)))
         (pattern (append '(prefix)
                          (nano/space-wildcard--tokens-pattern
                           (substring beforepoint (car bounds)))))
         (all (completion-pcm--all-completions prefix pattern table pred)))
    (list all pattern prefix suffix (car bounds))))

(defun nano/space-wildcard-try-completion (string table pred point)
  (pcase-let ((`(,all ,pattern ,prefix ,suffix ,_cb)
               (nano/space-wildcard--all string table pred point)))
    (when minibuffer-completing-file-name
      (setq all (completion-pcm--filename-try-filter all)))
    (completion-pcm--merge-try pattern all prefix suffix)))

(defun nano/space-wildcard-all-completions (string table pred point)
  (pcase-let ((`(,all ,pattern ,prefix ,_suffix ,_cb)
               (nano/space-wildcard--all string table pred point)))
    (when all
      (nconc (completion-pcm--hilit-commonality pattern all)
             (length prefix)))))

(add-to-list 'completion-styles-alist
             '(space-wildcard
               nano/space-wildcard-try-completion
               nano/space-wildcard-all-completions
               "SPACE-wildcard completion.
Whitespace in the input splits it into tokens; all tokens must match,
in order, separated by arbitrary characters (\"lorem dolor\" matches
\"lorem ipsum dolor\" and \"lorem-ipsum-dolor.txt\")."))
(setq enable-recursive-minibuffers t
      completion-cycle-threshold 3)
;; History: recentf backs SPC f r (bound in §5, mode was off);
;; savehist persists M-x / file / buffer histories across restarts.
;; Caps keep memory + disk small: 50 recent files, no histories pileup.
(setq recentf-max-saved-items 50
      recentf-exclude '("/tmp/" "/ssh:" "/sudo:")
      savehist-additional-variables nil
      history-length 100)
(recentf-mode 1)
(savehist-mode 1)
;; C-n/C-p + arrows come free with icomplete-vertical-mode; add C-j/C-k
;; for evil-friendly navigation.  Displaced defaults preserved on C-M-:
;; C-j was `icomplete-force-complete-and-exit', C-k was `icomplete-fido-kill'.
;; SPC must type a literal space in completion minibuffers: default binding
;; is `minibuffer-complete-word', which hijacks multi-token queries like
;; "lorem dolor" (SPACE becomes word-completion instead of an input char).
;; With a literal space, `partial-completion' (§8 styles above) already
;; treats it as an in-order wildcard: "lorem dolor" -> "lorem ipsum dolor".
(define-key minibuffer-local-completion-map (kbd "SPC") 'self-insert-command)
(define-key minibuffer-local-filename-completion-map (kbd "SPC") 'self-insert-command)
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
;; No `require': `tab-bar-mode' autoloaded (§5d already enabled it).
(tab-bar-mode 1) ; already on via §5d (before desktop read); idempotent here.
;; NOTE: plain setq on `tab-bar-show' does NOT take effect — it has a
;; custom :set that refreshes `tab-bar-lines' on all frames.  Must use
;; `customize-set-variable' or the top bar stays visible.
(customize-set-variable 'tab-bar-show nil)
(setq tab-bar-close-button-show nil
      tab-bar-new-button-show nil
      tab-bar-tab-hints t
      tab-bar-new-tab-choice "*scratch*"
      tab-bar-new-tab-to 'rightmost
      tab-bar-format '(tab-bar-format-tabs tab-bar-separator))

;; Single auto-named tab tracks the buffer name — name it "main" so the
;; modeline shows a workspace, not a second copy of the filename.
;; Deferred to window-setup: the first tab only settles once the initial
;; frame exists (at init-load time the tab list may still be empty).
;; Guard: skip when a session was restored (multi-tab/multi-frame, or
;; any explicitly named tab) so desktop frameset names survive.
(add-hook 'window-setup-hook
          (lambda ()
            (when (and (bound-and-true-p tab-bar-mode)
                       (not (seq-some (lambda (f)
                                        (> (length (frame-parameter f 'tabs)) 1))
                                      (frame-list)))
                       (seq-every-p (lambda (f)
                                      (let ((tabs (frame-parameter f 'tabs)))
                                        (or (null tabs)
                                            (seq-every-p
                                             (lambda (tab)
                                               (not (cdr (assq 'explicit-name tab))))
                                             tabs))))
                                    (frame-list)))
              (ignore-errors (tab-bar-rename-tab "main")))))

(defun nano/workspace-new-tab (arg)
  "New workspace tab, then prompt for its name (`SPC l n').
With prefix ARG, pass through to `tab-bar-new-tab'."
  (interactive "P")
  (tab-bar-new-tab arg)
  (call-interactively #'tab-bar-rename-tab))

;; 9a. Workspaces transient  (SPC l) — Spacemacs eyebrowse-TS emulation, zero-dep.
;; Bare `SPC l' shows live workspaces (`[1:main] | 2:code', current bracketed)
;; then reads one key, looping until RET/ESC/q (next/prev/TAB stay in loop).
;; Old `SPC l X' muscle memory preserved: after `SPC l' runs, the follow-up
;; X arrives via `read-key' (same letters as before, `d' renamed to `x').
;; `1..9' select-or-create (Spacemacs nth/new) with NO separate bindings,
;; so which-key has nothing verbose to display — functionality lives here.
(defun nano/workspace--tabs ()
  "Tabs of selected frame as (INDEX NAME CURRENT-P) list.  INDEX from 1."
  (let ((i 0)
        (cur (1+ (tab-bar--current-tab-index))))
    (mapcar (lambda (tab)
              (setq i (1+ i))
              (list i
                    (or (and (alist-get 'explicit-name tab)
                             (alist-get 'name tab))
                        (alist-get 'name tab)
                        (number-to-string i))
                    (= i cur)))
            (tab-bar-tabs))))

(defun nano/workspace--hint ()
  "One-liner workspace list + key legend, Spacemacs-TS style."
  (concat
   (mapconcat (lambda (w)
                (let ((s (format "%d:%s" (nth 0 w) (nth 1 w))))
                  (if (nth 2 w)
                      (propertize (concat "[" s "]") 'face 'warning)
                    s)))
              (nano/workspace--tabs) " | ")
   "  (1-9 go/new, n new, ]/[ next/prev, TAB last, l list, b buffer, c code, r rename, x close, q/C-g quit)"))

(defun nano/workspace-select-or-create (n)
  "Switch to workspace N; create trailing workspace when N beyond last.
Spacemacs nth/new parity — tab-bar is gapless, so N past end appends."
  (let ((count (length (tab-bar-tabs))))
    (if (<= n count)
        (let ((name (nth 1 (nth (1- n) (nano/workspace--tabs)))))
          (tab-bar-select-tab n)
          (message "Workspace: %d:%s" n name))
      (tab-bar-new-tab)
      (message "Workspace %d created" (length (tab-bar-tabs))))))

(defun nano/workspace-list-and-switch ()
  "Pick workspace via completing-read (`N: name', current marked).  `SPC l l'."
  (let* ((cands (mapcar (lambda (w)
                          (cons (format "%d: %s%s" (nth 0 w) (nth 1 w)
                                        (if (nth 2 w) " *" ""))
                                (nth 0 w)))
                        (nano/workspace--tabs)))
         (pick (completing-read "Workspace: " cands nil t)))
    (when pick
      (nano/workspace-select-or-create (cdr (assoc pick cands))))))

(defun nano/workspace-dispatch ()
  "Workspace transient.  Bound to bare `SPC l'."
  (interactive)
  (let ((done nil))
    (while (not done)
      (let ((ev (read-key (concat (nano/workspace--hint) "\nWorkspace: "))))
        (cond
         ((and (integerp ev) (>= ev ?1) (<= ev ?9))
          (nano/workspace-select-or-create (- ev ?0))
          (setq done t))
         ((eq ev ?n) (nano/workspace-new-tab nil) (setq done t))
         ((eq ev ?x)
          (if (= (length (tab-bar-tabs)) 1)
              (message "Last workspace cannot be closed")
            (tab-bar-close-tab)
            (message "Workspace closed")
            (setq done t)))
         ((eq ev ?r) (call-interactively #'tab-bar-rename-tab) (setq done t))
         ((eq ev ?\]) (tab-bar-switch-to-next-tab))
         ((eq ev ?\[) (tab-bar-switch-to-prev-tab))
         ((eq ev ?\t) (tab-bar-switch-to-last-tab))
         ((eq ev ?l) (nano/workspace-list-and-switch) (setq done t))
         ((eq ev ?c) (nano/quad-workspace-create) (setq done t))
         ((eq ev ?b) (call-interactively #'switch-to-buffer) (setq done t))
         ((memq ev (list ?q ?\C-g ?\r ?\e)) (setq done t) (message nil))
         ((eq ev ??) (message "Keys: 1-9 go/create, n new, ]/[ next/prev, TAB last, l list, b buffer, c code workspace, r rename, x close, q/C-g quit"))
         (t (message "Unknown workspace key: %s" (key-description (vector ev)))))))))

(define-key spacemacs-leader-map (kbd "l") 'nano/workspace-dispatch)

;; 9b. Vim-style cycle (Spacemacs eyebrowse `gt/gT' parity)
(define-key evil-motion-state-map (kbd "gt") 'tab-bar-switch-to-next-tab)
(define-key evil-motion-state-map (kbd "gT") 'tab-bar-switch-to-prev-tab)


;; 9c. Quad "code" workspace  (SPC l c)
;; ---------------------------------------------------------------------
;; One tab, four equal vertical columns, left to right:
;;   w1 magit status repo A | w2 OpenCode session repo A
;;   w3 OpenCode session repo B | w4 magit status repo B
;; Both repos are read up front, so a non-repo answer or a narrow frame
;; aborts before anything is created and the current layout survives.
;;
;; Columns: `split-window-right' three times yields w1..w4 in
;; `window-list' order with equal widths (§6e keeps them balanced).
;; `nano/window-split-quad-columns' is deliberately NOT reused — it
;; puts `*scratch*' in every pane.
;;
;; Placement, both halves: magit and the OpenCode client each display
;; their own buffer (`magit-display-buffer', `pop-to-buffer').  Magit
;; reuses §10c's quiet display binding.  OpenCode is asynchronous
;; (service start -> session create -> `opencode-session-open'), so the
;; window is supplied by `display-buffer-overriding-action' bound
;; INSIDE the callback: overriding beats `display-buffer-alist', which
;; stops §6f's scratch routing from parking the session in another pane.
;; Focus after creation is not meaningful — whichever callback lands
;; last selects its own column.
;;
;; Known limits: magit status buffers are per-repository, so a repo
;; already shown in another tab shares that same buffer here; and the
;; session panes are not restored by `SPC q r' (§5d/§10c restore the
;; tab and its magit buffers only).
;; Repo discovery for the prompt.  `magit-repository-directories' is
;; commonly nil (this box: nil), and `project-known-project-roots' only
;; fills as project.el is used, so the shipped reader offered an EMPTY
;; list — and when magit did answer, it returned (NAME . PATH) pairs of
;; which only NAME was used, which `expand-file-name' then resolved
;; against `default-directory' and failed with "not inside a git
;; repository".  Candidates are therefore full paths (the alist cdr,
;; tilde-abbreviated for display), plus a bounded scan of
;; `nano/quad-workspace-repo-roots' so a fresh Emacs still lists the
;; repos on disk.
(defcustom nano/quad-workspace-repo-roots '(("~" . 2))
  "Directories scanned for git repositories by `SPC l c'.
Each element is (DIRECTORY . DEPTH), like
`magit-repository-directories': DEPTH 0 adds DIRECTORY itself, N stops
N levels below it.  Purely additive: it only fills the repo prompt,
and never changes `magit-status' behaviour."
  :type '(repeat (cons directory integer))
  :group 'nano)

(defun nano/quad-workspace--repos-under (directory depth)
  "Return git repositories at DIRECTORY, DEPTH levels deep.
DIRECTORY itself is included when it is a repository, and descent
stops at repository roots (`.git' is never walked)."
  (let ((dir (file-name-as-directory (expand-file-name directory))))
    (when (file-accessible-directory-p dir)
      (append
       (when (file-directory-p (expand-file-name ".git" dir))
         (list dir))
       (when (and (> depth 0)
                  (not (file-directory-p (expand-file-name ".git" dir))))
         (mapcan (lambda (child)
                   (and (file-directory-p child)
                        (not (equal (file-name-nondirectory
                                     (directory-file-name child))
                                    ".git"))
                        (nano/quad-workspace--repos-under child (1- depth))))
                 (ignore-errors
                   (directory-files dir t directory-files-no-dot-files-regexp t))))))))

(defun nano/quad-workspace--repo-paths ()
  "Return repository directories to offer in the `SPC l c' prompt.
Sources: `magit-list-repos' when `magit-repository-directories' is set,
`project-known-project-roots', the current buffer's repository, and
`nano/quad-workspace-repo-roots'.  Entries are absolute directory names,
deduplicated, with `$HOME' abbreviated to a tilde."
  (require 'magit-repos nil t)
  (let ((paths (append
                ;; `magit-repos-alist' is (NAME . PATH): PATH is the repo.
                (ignore-errors (mapcar #'cdr (magit-repos-alist)))
                (ignore-errors (project-known-project-roots))
                ;; NOTE: `magit-toplevel' answers a STRING; it must be
                ;; wrapped, or `append' splices it into characters.
                (let ((top (ignore-errors (magit-toplevel default-directory))))
                  (when top (list top)))
                (mapcan (lambda (spec)
                          (nano/quad-workspace--repos-under
                           (car spec) (cdr spec)))
                        nano/quad-workspace-repo-roots))))
    (delete-dups
     (mapcar (lambda (p)
               (file-name-as-directory
                (abbreviate-file-name
                 (expand-file-name (directory-file-name p)))))
             (delq nil paths)))))

(defun nano/quad-workspace--read-repo (label)
  "Read a git repository for LABEL, re-prompting until one is found.
Candidates come from `nano/quad-workspace--repo-paths'; the prompt does
not require a match, so any directory path may be typed instead (an
empty answer falls back to `read-directory-name').  Returns a directory
name."
  (let ((cands (nano/quad-workspace--repo-paths))
        root)
    (while (not root)
      (let* ((pick (completing-read (format "%s: " label) cands nil nil))
             (dir (if (string-empty-p pick)
                      (read-directory-name (format "%s: " label) nil t)
                    (expand-file-name pick))))
        (setq root (ignore-errors (magit-toplevel dir)))
        (unless root
          (message "%s is not inside a git repository" dir))))
    (file-name-as-directory root)))

(defun nano/quad-workspace--place (window)
  "Return a `display-buffer' action function that displays into WINDOW."
  (lambda (buffer _alist)
    (set-window-buffer window buffer)
    window))

(defun nano/quad-workspace--magit (directory window)
  "Show DIRECTORY's magit status in WINDOW without disturbing the layout.
`magit-status-setup-buffer' always routes through `magit-display-buffer'
\(magit-mode.el), hence the §10c quiet binding around the call."
  ;; `require' must come FIRST: magit declares these as special
  ;; variables in its own `defcustom's, and let-binding one before that
  ;; makes it lexical, after which magit's `defcustom' signals
  ;; "Defining as dynamic an already lexical var" — i.e. the very first
  ;; `SPC l c' of a session would fail.  §10c gets away without this
  ;; because desktop restore always runs after magit has loaded.
  (require 'magit)
  (let ((magit-display-buffer-function #'nano/magit-desktop--display-quietly)
        (magit-display-buffer-noselect t))
    (set-window-buffer window (magit-status-setup-buffer directory))))

(defun nano/quad-workspace--opencode (directory window)
  "Create an OpenCode session for DIRECTORY and show it in WINDOW.
Goes through the same funnel as `SPC a c n' (`opencode--create-session'),
so the §27d default model applies."
  (require 'emacs-opencode)
  (opencode-run-server
   directory
   (lambda (connection)
     (let ((display-buffer-overriding-action
            (cons (nano/quad-workspace--place window) nil)))
       (opencode--create-session
        connection
        (lambda (session)
          (opencode-session-open session connection)))))))

(defun nano/quad-workspace-create ()
  "New workspace: magit A | opencode A | opencode B | magit B (SPC l c)."
  (interactive)
  (let ((a (nano/quad-workspace--read-repo "Repo 1 (left)"))
        (b (nano/quad-workspace--read-repo "Repo 2 (right)")))
    (tab-bar-new-tab)
    (delete-other-windows)
    (let* ((w1 (selected-window))
           (w2 (ignore-errors (split-window-right)))
           (w3 (and w2 (ignore-errors (split-window w2 nil 'right))))
           (w4 (and w3 (ignore-errors (split-window w3 nil 'right)))))
      (if (not (and w2 w3 w4))
          ;; Undo cleanly: drop the panes and the tab this command just
          ;; created, so a narrow frame leaves the previous workspace as
          ;; it was instead of stranding an empty one.
          (progn (delete-other-windows)
                 (when (> (length (tab-bar-tabs)) 1)
                   (tab-bar-close-tab))
                 (message "Quad workspace: frame too narrow for four columns"))
        (nano/quad-workspace--magit a w1)
        (nano/quad-workspace--magit b w4)
        (nano/quad-workspace--opencode a w2)
        (nano/quad-workspace--opencode b w3)
        (nano/balance-window-widths)
        (select-window w2)
        (tab-bar-rename-tab
         (format "%s|%s"
                 (file-name-nondirectory (directory-file-name a))
                 (file-name-nondirectory (directory-file-name b))))
        (message "Quad workspace: %s | %s" a b)))))

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
;; scoped to magit+elfeed only, not full collection).  §3 evil-want-* vars
;; already satisfy evil-collection requirements.
;; Lazy (zero startup cost): collection builds on first magit/elfeed
;; use via straight autoloads.  Pre-seed states NOW (cheap setqs,
;; evil already loaded in §3) so the FIRST status buffer never lands
;; in emacs state (SPC + j/k dead, "unusable") even if collection
;; setup is delayed or skipped — see `nano/evil-collection-ensure',
;; which re-seeds to normal after collection init (its j/k/s keymaps
;; are normal-state, so normal is the one state that always works).
(straight-use-package 'evil-collection)
(dolist (m '(magit-status-mode magit-log-mode magit-diff-mode
             magit-reflog-mode magit-refs-mode magit-revision-mode
             magit-stash-mode magit-stashes-mode magit-cherry-mode
             magit-process-mode git-rebase-mode))
  ;; normal, not motion: collection's magit keymaps (incl. `s' stage)
  ;; bind normal/visual only; motion would leave `s' dead pre-collection.
  (evil-set-initial-state m 'normal))
(dolist (m '(elfeed-search-mode elfeed-show-mode))
  (evil-set-initial-state m 'normal))
(setq evil-collection-mode-list '(magit magit-section elfeed))
(defvar nano/evil-collection-initialized nil
  "Non-nil once `evil-collection-init' ran (magit/elfeed share one init).")
(defvar nano/evil-collection-retries 0
  "Guard against infinite retries in `nano/evil-collection-ensure'.")
(defun nano/evil-collection-ensure ()
  "Init evil-collection once for `evil-collection-mode-list'.  Lazy entry.
Explicit `require' + setup call (no bare autoload reliance): the
collection's own with-eval-after-load block only fires when the
feature loads, so if setup ever silently skipped (failed autoload,
skewed rebuild), magit buffers landed in emacs state — j/k/s dead.
Deterministic here: load collection, run setup directly, then
re-assert evil states (collection re-seeds magit modes to
`evil-collection-magit-state' = normal, overriding our §10 motion
seed; final state must match its keymaps, which bind j/k/s for
normal).  One retry on failure, then warn."
  (unless nano/evil-collection-initialized
    (if (>= nano/evil-collection-retries 2)
        (warn "evil-collection init failed; magit/elfeed keys fallback to evil defaults")
      (setq nano/evil-collection-retries (1+ nano/evil-collection-retries))
      (if (not (require 'evil-collection nil t))
          (warn "evil-collection not loadable — magit/elfeed stay plain evil")
        (evil-collection-init evil-collection-mode-list)
        (setq nano/evil-collection-initialized t)
        ;; Re-assert post-collection states.  Collection magit keys
        ;; (j/k/s/…) are defined for normal/visual via
        ;; `evil-collection-magit-state'; seed normal so first magit
        ;; buffer is immediately usable.
        (dolist (m '(magit-status-mode magit-log-mode magit-diff-mode
                     magit-reflog-mode magit-refs-mode magit-revision-mode
                     magit-stash-mode magit-stashes-mode magit-cherry-mode
                     magit-process-mode git-rebase-mode))
          (evil-set-initial-state m 'normal))
        ;; Existing magit buffers stuck in a dead state get healed.
        (dolist (buf (buffer-list))
          (with-current-buffer buf
            (when (and (derived-mode-p 'magit-mode)
                       (memq evil-state '(emacs insert)))
              (evil-motion-state))))
        ;; Re-apply the magit M-0..M-9 winum rebind: collection setup
        ;; (just ran) re-copied stock show-level-*-all into the state
        ;; keymaps, re-shadowing winum on fresh launches — previously
        ;; only healed by the next `SPC f e r'.
        ;; Registered AFTER `evil-collection-init' above, so these fire
        ;; after the collection's own load hooks even when init was
        ;; triggered early (e.g. elfeed before magit's first load).
        (with-eval-after-load 'magit (nano/magit-winum-rebind))
        (with-eval-after-load 'magit-section (nano/magit-winum-rebind))
        (nano/magit-winum-rebind)))
    (when nano/evil-collection-initialized
      (setq nano/evil-collection-retries 0))))
(with-eval-after-load 'magit (nano/evil-collection-ensure))
(with-eval-after-load 'elfeed-search (nano/evil-collection-ensure))

;; SPC = leader inside magit (user choice).  evil-collection-magit
;; already moved stock SPC (diff-show-or-scroll) to S-SPC, so SPC is
;; free — bind it explicitly per state so overriding magit-mode-map
;; can never shadow the leader again.  No `,' major leader: Spacemacs
;; defines none for magit-status/log/diff (only with-editor/log-select).
(with-eval-after-load 'magit
  (with-eval-after-load 'evil
    (when (boundp 'magit-mode-map)
      (evil-define-key '(normal visual motion) magit-mode-map
        (kbd "SPC") spacemacs-leader-map))))

;; M-0..M-9 = winum inside magit (Spacemacs parity).
;; winum-keymap is minor-mode map; evil state maps (emulation) win,
;; so magit-section-mode-map M-1..M-4 (show-level-*-all,
;; magit-section.el) shadow winum in motion/normal.  Rebind here,
;; same technique as SPC above.  Covers all magit modes (parent map).
;; Displaced show-level-*-all -> C-M-1..C-M-4 (free, checked).
;; M-0 extra vs Spacemacs (they bind 1..9 only); keeps §6 0-or-10.
;; Applied on `magit-section' load, AND re-applied after
;; `evil-collection-init' (see `nano/evil-collection-ensure'): its
;; `evil-collection-magit-setup' re-copies the stock M-1..M-4 into the
;; state keymaps after this load hook ran — collection init fires at
;; `magit' load, `magit-section' already being loaded and rebound —
;; so without the re-run, stock show-level-*-all re-shadowed winum in
;; normal state on every fresh launch, only healed by the next
;; `SPC f e r'.
(defun nano/magit-winum-rebind ()
  "Bind M-0..M-9 to winum in `magit-section-mode-map'.
Covers every evil state magit uses (normal + motion).  Idempotent."
  (with-eval-after-load 'evil
    (when (boundp 'magit-section-mode-map)
      (evil-define-key '(normal motion) magit-section-mode-map
        (kbd "M-0") 'winum-select-window-0-or-10
        (kbd "M-1") 'winum-select-window-1
        (kbd "M-2") 'winum-select-window-2
        (kbd "M-3") 'winum-select-window-3
        (kbd "M-4") 'winum-select-window-4
        (kbd "M-5") 'winum-select-window-5
        (kbd "M-6") 'winum-select-window-6
        (kbd "M-7") 'winum-select-window-7
        (kbd "M-8") 'winum-select-window-8
        (kbd "M-9") 'winum-select-window-9
        (kbd "C-M-1") 'magit-section-show-level-1-all
        (kbd "C-M-2") 'magit-section-show-level-2-all
        (kbd "C-M-3") 'magit-section-show-level-3-all
        (kbd "C-M-4") 'magit-section-show-level-4-all))))
(with-eval-after-load 'magit-section (nano/magit-winum-rebind))

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

;; 10b. Blame  (SPC g b transient, SPC g B popup)
;; Spacemacs `SPC g b' parity, zero-dep repeat via `set-transient-map'
;; (§14 zoom pattern, no hydra/transient-state dep).  Entry starts
;; `magit-blame-addition' when not already blaming, then arms the
;; repeat map so p/n/b/r/... work without re-pressing SPC.
;; All magit-blame-* are straight autoloads — no `require' here,
;; zero startup cost.  Stock blame keys also work directly in the
;; buffer (`magit-blame-read-only-mode-map': p/P/n/N/b/r/f/B/c/q).
;; SPC left stock (scroll-up) in blame buffers; leader fallback C-SPC (§4).
(defvar nano/git-blame-full-hint-toggle nil
  "Non-nil shows full blame hint; `?' toggles.")

(defun nano/git-blame--hint ()
  "Minified or full hint for the blame repeat transient."
  (if nano/git-blame-full-hint-toggle
      "blame [?] help | p/P prev/same  n/N next/same  RET show | b add  r remove  f last-with  e echo  q quit | c style  Y hash  B popup  Q exit"
    "blame chunks: n/N/p/P/RET commits: b/r/f/e/q [?] help"))

(defun nano/git-blame-transient-activate ()
  "Re-arm blame repeat map with hint in echo area."
  (set-transient-map nano/git-blame-repeat-map t)
  (message "%s" (nano/git-blame--hint)))

(defun nano/git-blame-transient ()
  "Start blaming current file, then repeat (`SPC g b').
On-enter mirrors Spacemacs: no-op when already blaming."
  (interactive)
  (unless (bound-and-true-p magit-blame-mode)
    (call-interactively #'magit-blame-addition))
  (nano/git-blame-transient-activate))

(defmacro nano/git-blame--wrap (name target)
  "Define NAME wrapper calling TARGET then re-arming blame transient."
  `(defun ,name ()
     ,(format "Call `%s', then repeat." target)
     (interactive)
     (call-interactively #',target)
     (nano/git-blame-transient-activate)))

(nano/git-blame--wrap nano/git-blame-prev magit-blame-previous-chunk)
(nano/git-blame--wrap nano/git-blame-prev-same magit-blame-previous-chunk-same-commit)
(nano/git-blame--wrap nano/git-blame-next magit-blame-next-chunk)
(nano/git-blame--wrap nano/git-blame-next-same magit-blame-next-chunk-same-commit)
(nano/git-blame--wrap nano/git-blame-add magit-blame-addition)
(nano/git-blame--wrap nano/git-blame-rm magit-blame-removal)
(nano/git-blame--wrap nano/git-blame-final magit-blame-reverse)
(nano/git-blame--wrap nano/git-blame-echo-cmd magit-blame-echo)
(nano/git-blame--wrap nano/git-blame-cycle magit-blame-cycle-style)
(nano/git-blame--wrap nano/git-blame-hash magit-blame-copy-hash)
(nano/git-blame--wrap nano/git-blame-show magit-show-commit)

(defun nano/git-blame-quit-or-exit ()
  "Quit blaming, staying in transient while blame is active (`q').
Mirrors Spacemacs `:exit (not magit-blame-mode)': recursive blames
need one `q' per buffer before the transient exits."
  (interactive)
  (when (bound-and-true-p magit-blame-mode)
    (call-interactively #'magit-blame-quit))
  (if (bound-and-true-p magit-blame-mode)
      (nano/git-blame-transient-activate)
    (message "blame quit")))

(defun nano/git-blame-quit-transient ()
  "Exit blame transient, leaving blame overlays on (`Q')."
  (interactive)
  (message "blame transient quit"))

(defun nano/git-blame-popup-exit ()
  "Open stock `magit-blame' popup, exiting transient (`B')."
  (interactive)
  (call-interactively #'magit-blame))

(defun nano/git-blame-toggle-hint ()
  "Toggle full/minified blame hint (`?')."
  (interactive)
  (setq nano/git-blame-full-hint-toggle
        (not nano/git-blame-full-hint-toggle))
  (nano/git-blame-transient-activate))

(defvar nano/git-blame-repeat-map
  (let ((m (make-sparse-keymap)))
    (define-key m (kbd "p") 'nano/git-blame-prev)
    (define-key m (kbd "P") 'nano/git-blame-prev-same)
    (define-key m (kbd "n") 'nano/git-blame-next)
    (define-key m (kbd "N") 'nano/git-blame-next-same)
    (define-key m (kbd "RET") 'nano/git-blame-show)
    (define-key m (kbd "b") 'nano/git-blame-add)
    (define-key m (kbd "r") 'nano/git-blame-rm)
    (define-key m (kbd "f") 'nano/git-blame-final)
    (define-key m (kbd "e") 'nano/git-blame-echo-cmd)
    (define-key m (kbd "q") 'nano/git-blame-quit-or-exit)
    (define-key m (kbd "c") 'nano/git-blame-cycle)
    (define-key m (kbd "Y") 'nano/git-blame-hash)
    (define-key m (kbd "B") 'nano/git-blame-popup-exit)
    (define-key m (kbd "Q") 'nano/git-blame-quit-transient)
    (define-key m (kbd "?") 'nano/git-blame-toggle-hint)
    m)
  "Repeat keys active after one `SPC g b'.")

(define-key spacemacs-leader-map (kbd "g b") 'nano/git-blame-transient)
(define-key spacemacs-leader-map (kbd "g B") 'magit-blame)
(which-key-add-key-based-replacements
  "SPC g b" "blame transient"
  "SPC g B" "blame popup")

;; RET shows commit at point in blame buffers (Spacemacs parity).
;; Stock map binds `C-m' only; GUI `<return>' needs explicit RET.
(with-eval-after-load 'magit-blame
  (with-eval-after-load 'evil
    (when (boundp 'magit-blame-read-only-mode-map)
      (evil-define-key 'normal magit-blame-read-only-mode-map
        (kbd "RET") 'magit-show-commit))))

;; §10c  Magit buffers in the desktop session  (restart keeps them real)
;; ---------------------------------------------------------------------
;; magit buffers visit no file, so `desktop-save' skips them by default.
;; The frameset then keeps leaves pointing at buffers that are never
;; recreated, `tab-bar' swaps in a dead " *Old buffer magit: …*"
;; placeholder, and the workspace's git panes are lost on every restart
;; (reproduced: 3 tabs → tab 3 collapsed to a single placeholder window).
;; Two halves of the contract, both required:
;;   save    — a buffer-local `desktop-save-buffer' (set from
;;             `magit-mode-hook') that writes the mode, the repository
;;             directory and the live `magit-buffer-*' locals.
;;   restore — one `desktop-buffer-mode-handlers' entry per magit mode
;;             that rebuilds through magit's own *-setup-buffer function,
;;             so real sections are regenerated.  Poking the locals into
;;             a fresh buffer and calling `magit-refresh-buffer' is NOT
;;             enough: the refresh path also needs the mode-specific
;;             setup (e.g. `magit-log-margin') that only the setup
;;             function installs.
;; The rebuilt buffer is renamed to its saved name so the frameset leaf
;; re-binds to it, and display is suppressed — the frameset restores the
;; windows itself right after these handlers run.
(defconst nano/magit-desktop-modes
  '(magit-status-mode magit-log-mode magit-diff-mode magit-revision-mode
    magit-reflog-mode magit-refs-mode magit-stash-mode magit-stashes-mode
    magit-cherry-mode)
  "Magit modes saved to and restored from the desktop session.")

(defconst nano/magit-desktop-locals
  '(magit-buffer-revision magit-buffer-revision-oid magit-buffer-blob-oid
    magit-buffer-file-name magit-buffer-locked-p
    magit-buffer-diff-range magit-buffer-diff-range-oids
    magit-buffer-diff-type magit-buffer-diff-typearg magit-buffer-diff-args
    magit-buffer-diff-files magit-buffer-diff-files-suspended
    magit-buffer-log-revisions magit-buffer-log-args magit-buffer-log-files
    magit-buffer-refs-upstream magit-buffer-refs-args
    magit-buffer-cherry-upstream magit-buffer-cherry-range)
  "Buffer-local variables that say what a magit buffer is showing.")

(defun nano/magit-desktop-save-buffer (_dirname)
  "Desktop aux info for a magit buffer, nil in every other mode.
Called by `desktop-save' through the buffer-local value of
`desktop-save-buffer' installed by `nano/magit-desktop-enable'."
  (when (memq major-mode nano/magit-desktop-modes)
    ;; Only locals that are actually set: unbound ones would error while
    ;; writing the desktop file, and nil-valued ones are just noise.
    (list :mode major-mode
          :dir (or (ignore-errors (magit-toplevel)) default-directory)
          :locals (let (out)
                    (dolist (var nano/magit-desktop-locals)
                      (when (local-variable-p var)
                        (push (cons var (symbol-value var)) out)))
                    out))))

(defun nano/magit-desktop--misc (misc var)
  "Value of VAR in the :locals alist of magit desktop aux MISC."
  (cdr (assq var (plist-get misc :locals))))

(defun nano/magit-desktop--display-quietly (_buffer)
  "Display function that leaves the window layout untouched."
  (selected-window))

(defun nano/magit-desktop-rebuild (mode misc)
  "Rebuild the magit buffer described by MODE and MISC, and return it.
MISC is what `nano/magit-desktop-save-buffer' wrote for that buffer.
Returns nil when the repository directory is gone: the tab-bar then
shows its own ` *Old buffer …*' placeholder and every other workspace
still restores."
  (let* ((dir (expand-file-name (or (plist-get misc :dir) default-directory)))
         (reachable (file-accessible-directory-p dir))
         ;; Never bind a nonexistent directory as `default-directory':
         ;; that signals from the `let*' itself and aborts the restore.
         (default-directory (if reachable dir default-directory))
         ;; `magit-display-buffer' would select the new buffer's window
         ;; and, for some modes, pop a window — that fights the frameset
         ;; restore that runs right after these handlers.
         (magit-display-buffer-function #'nano/magit-desktop--display-quietly)
         (magit-display-buffer-noselect t)
         (get (lambda (var) (nano/magit-desktop--misc misc var))))
    (unless reachable
      (message "Magit desktop: %s is gone, its buffer was not restored" dir))
    (when reachable
      (pcase mode
        ('magit-status-mode
         (magit-status-setup-buffer dir))
        ('magit-log-mode
         (magit-log-setup-buffer
          (let ((revs (funcall get 'magit-buffer-log-revisions)))
            (cond ((null revs) '("HEAD"))
                  ((stringp revs) (list revs))
                  (revs)))
          (funcall get 'magit-buffer-log-args)
          (funcall get 'magit-buffer-log-files)
          (funcall get 'magit-buffer-locked-p)))
        ('magit-diff-mode
         (magit-diff-setup-buffer (funcall get 'magit-buffer-diff-range)
                                  (funcall get 'magit-buffer-diff-typearg)
                                  (funcall get 'magit-buffer-diff-args)
                                  (funcall get 'magit-buffer-diff-files)
                                  (funcall get 'magit-buffer-diff-type)
                                  (funcall get 'magit-buffer-locked-p)))
        ('magit-revision-mode
         (magit-revision-setup-buffer (funcall get 'magit-buffer-revision)
                                      (funcall get 'magit-buffer-diff-args)
                                      (funcall get 'magit-buffer-diff-files)))
        ('magit-reflog-mode
         (magit-reflog-setup-buffer (funcall get 'magit-buffer-revision)))
        ('magit-refs-mode
         (magit-refs-setup-buffer (funcall get 'magit-buffer-refs-upstream)
                                  (funcall get 'magit-buffer-refs-args)))
        ('magit-stash-mode
         (magit-stash-setup-buffer (funcall get 'magit-buffer-revision)
                                   (funcall get 'magit-buffer-diff-args)
                                   (funcall get 'magit-buffer-diff-files)))
        ('magit-stashes-mode
         (magit-stashes-setup-buffer))
        ('magit-cherry-mode
         (magit-cherry-setup-buffer (funcall get 'magit-buffer-revision)
                                    (funcall get 'magit-buffer-cherry-upstream)))))))

(defun nano/magit-desktop-handler (_file name misc)
  "`desktop-buffer-mode-handlers' entry for magit buffers.
FILE is always nil (magit buffers visit no file); NAME is the saved
buffer name; MISC is the aux info from `nano/magit-desktop-save-buffer'."
  (when (and misc (plist-get misc :mode))
    (let ((buffer (nano/magit-desktop-rebuild (plist-get misc :mode) misc)))
      (when (buffer-live-p buffer)
        (with-current-buffer buffer
          ;; Rename here: `desktop-create-buffer' only renames after the
          ;; handler returns, and the frameset leaf looks the buffer up
          ;; by this exact saved name.
          (unless (equal (buffer-name) name)
            (rename-buffer name t)))
        buffer))))

(defun nano/magit-desktop-enable ()
  "Opt magit buffers into `desktop-save' / `desktop-read'.  Idempotent."
  (add-hook 'magit-mode-hook
            (lambda ()
              (setq-local desktop-save-buffer #'nano/magit-desktop-save-buffer)))
  (dolist (mode nano/magit-desktop-modes)
    (add-to-list 'desktop-buffer-mode-handlers
                 (cons mode #'nano/magit-desktop-handler))))

;; Registered now, NOT from `magit-mode-hook' or `with-eval-after-load
;; magit': `desktop-read' runs from `after-init-hook' before magit is
;; loaded, and `desktop-load-file' loads magit only as it reaches the
;; first magit entry — i.e. after that entry's own handler lookup.  Late
;; registration silently dropped the first magit buffer of every session
;; ("… restored, 1 failed to restore"), which was the log pane here.
;; `desktop' itself is already loaded by §5d.
(with-eval-after-load 'desktop (nano/magit-desktop-enable))



;; ---------------------------------------------------------------------
;; §11  Project  (built-in project.el, SPC p)
;; ---------------------------------------------------------------------
;; Zero-dep: Emacs 30 built-in, detects .git roots, works with
;; fido-vertical from §8.  No projectile (heavier, caching daemon).
;; No `require': project commands autoload on first SPC p use.

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
;; Zero-dep: built-in project.el + xref + grep + fido-vertical (§8) only.
;; SPC s s lists buffer lines via completing-read (fido-vertical shows
;; all on empty input, flex filters as you type); s f / s g / s d below.
;; No `require' xref/grep: commands autoload; `xref-search-program'
;; setq is safe pre-load (defcustom keeps pre-set value).

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

(defvar nano/rg-files-cache nil
  "Alist (ROOT . (MTIME . FILES)) caching `rg --files' per project root.")

(defun nano/rg-files-cached (root)
  "Return `rg --files' list under ROOT, reusing cache when dir mtime same."
  (let* ((default-directory (file-name-as-directory root))
         (mtime (ignore-errors
                  (file-attribute-modification-time
                   (file-attributes default-directory))))
         (hit (assoc root nano/rg-files-cache)))
    (if (and hit (equal (cadr hit) mtime))
        (cddr hit)
      (let ((files (ignore-errors
                     (process-lines "rg" "--files" "--hidden"
                                    "--glob" "!.git/*"))))
        (setq nano/rg-files-cache
              (cons (cons root (cons mtime files))
                    (assoc-delete-all root nano/rg-files-cache)))
        files))))

(defun nano/rg-find-file ()
  "Find file by name with `rg --files'.  Bound to SPC s f.
Completing-read feeds fido-vertical (§8).  Falls back to
`project-find-file' when rg is missing or root is remote."
  (interactive)
  (let ((root (nano/search-root)))
    (if (and (nano/search-ensure-rg)
             (not (file-remote-p root)))
        (let ((files (nano/rg-files-cached root)))
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

(defun nano/search-grep-in-dir (regexp dir)
  "Grep REGEXP in DIR with rg, results in `*grep*'.  Bound to SPC s d.
Prompts DIR first (default `nano/search-root'), then REGEXP
\(default symbol at point).  Uses `rg --vimgrep' when present and
DIR is local — respects .gitignore, skips hidden/binary.  Else
falls back to built-in `rgrep' + one-time install hint."
  (interactive
   (let ((dir (read-directory-name "Grep in dir: " (nano/search-root) nil t)))
     (list (read-regexp "Search for: " (thing-at-point 'symbol)) dir)))
  (if (and (nano/search-ensure-rg)
           (not (file-remote-p dir)))
      (let ((cmd (mapconcat #'shell-quote-argument
                            (list "rg" "--vimgrep" "--smart-case" "--hidden"
                                  "--glob" "!.git/*" "-e" regexp dir)
                            " ")))
        (grep cmd))
    (rgrep regexp "*" dir)))

(defun nano/search-buffer-lines ()
  "Search lines in current buffer with completion.  Bound to SPC s s.
Shows all non-empty lines via `completing-read' (fido-vertical §8
lists all on empty input, flex filters as you type, like SPC f f).
RET jumps to chosen line, pushing mark first.  Initial input is
active region, else symbol at point (Spacemacs parity), else empty.
Skips empty lines, truncates long lines for display."
  (interactive)
  (let ((cands nil)
        (n 0)
        (truncated nil)
        (initial (if (use-region-p)
                     (buffer-substring-no-properties
                      (region-beginning) (region-end))
                   (or (thing-at-point 'symbol t) ""))))
    (save-excursion
      (save-restriction
        (widen)
        (goto-char (point-min))
        (while (not (eobp))
          (setq n (1+ n))
          (let ((text (string-trim
                       (buffer-substring-no-properties
                        (line-beginning-position) (line-end-position)))))
            (unless (string-empty-p text)
              (when (> (length text) 200)
                (setq text (concat (substring text 0 200) "…")))
              (push (format "%d: %s" n text) cands)))
          (forward-line 1)
          (when (and (> n 10000) (not truncated))
            (setq truncated t)
            (message "SPC s s: buffer >10000 lines, listing first 10000")
            (goto-char (point-max))))))
    (unless cands
      (user-error "SPC s s: no non-empty lines"))
    (let ((choice (completing-read "Search lines: " (nreverse cands) nil t
                                   initial nil nil)))
      (when (string-match "^\\([0-9]+\\): " choice)
        (let ((ln (string-to-number (match-string 1 choice))))
          (push-mark nil t)
          (save-restriction
            (widen)
            (goto-char (point-min))
            (forward-line (1- ln))
            (back-to-indentation))
          (ignore-errors (recenter))
          (message "line %d" ln))))))

(define-key spacemacs-leader-map (kbd "s s") 'nano/search-buffer-lines)
(define-key spacemacs-leader-map (kbd "s f") 'nano/rg-find-file)
(define-key spacemacs-leader-map (kbd "s g") 'nano/search-grep)
(define-key spacemacs-leader-map (kbd "s d") 'nano/search-grep-in-dir)
(which-key-add-key-based-replacements
  "SPC s s" "search lines"
  "SPC s f" "find file (rg)"
  "SPC s g" "grep project (rg)"
  "SPC s d" "grep dir (rg)")


;; ---------------------------------------------------------------------
;; §13  File sync  (built-in auto-revert, SPC b R fallback)
;; ---------------------------------------------------------------------
;; External edits (git pull, rg replace, other editor) auto-reflect.
;; Zero-dep: built-in autorevert.el only.  Unsaved buffers never
;; clobbered — auto-revert skips modified buffers.  SPC b R stays
;; as manual `revert-buffer' fallback (§5b).  No `require': the mode
;; call autoloads autorevert.el, then setqs apply.
(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t ; dired too
      auto-revert-verbose nil               ; quiet
      auto-revert-remote-files nil          ; skip TRAMP, perf
      auto-revert-use-notify t              ; inotify, no poll
      auto-revert-check-vc-info nil         ; perf, magit handles vc
      auto-revert-interval 5)               ; poll fallback only, notify is primary
(add-to-list 'global-auto-revert-ignore-modes 'Buffer-menu-mode)
(add-to-list 'global-auto-revert-ignore-modes 'elfeed-search-mode)
(add-to-list 'global-auto-revert-ignore-modes 'elfeed-show-mode)
(add-to-list 'global-auto-revert-ignore-modes 'magit-status-mode)


;; ---------------------------------------------------------------------
;; §14  Zoom  (buffer text-scale, SPC z x, repeat transient)
;; ---------------------------------------------------------------------
;; Buffer-only, Spacemacs `SPC z x' parity.  Zero-dep: built-in
;; text-scale.el only.  Frame zoom skipped (needs zoom-frm).
;; Step 0.5 matches Spacemacs `spacemacs/scale-up-or-down-font-size'.
;; Each entry re-arms `set-transient-map' (one-shot, keep-pred nil) so
;; + - 0 repeat without re-pressing SPC; q never re-arms so it exits,
;; as does any foreign key.
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
  (set-transient-map nano/zoom-repeat-map nil)
  (message "zoom [+/=/k] in [-/_/j] out [0] reset [q] quit (%+.1f)"
           (float (or (and (boundp 'text-scale-mode-amount)
                           text-scale-mode-amount)
                      0))))

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
  (setq overriding-terminal-local-map nil)
  (message "zoom quit"))

(define-key spacemacs-leader-map (kbd "z x +") 'nano/zoom-in)
(define-key spacemacs-leader-map (kbd "z x =") 'nano/zoom-in)
(define-key spacemacs-leader-map (kbd "z x k") 'nano/zoom-in)
(define-key spacemacs-leader-map (kbd "z x -") 'nano/zoom-out)
(define-key spacemacs-leader-map (kbd "z x _") 'nano/zoom-out)
(define-key spacemacs-leader-map (kbd "z x j") 'nano/zoom-out)
(define-key spacemacs-leader-map (kbd "z x 0") 'nano/zoom-reset)
(define-key spacemacs-leader-map (kbd "z x q") 'nano/zoom-quit)
(which-key-add-key-based-replacements
  "SPC z x +" "zoom in"
  "SPC z x =" "zoom in"
  "SPC z x k" "zoom in"
  "SPC z x -" "zoom out"
  "SPC z x _" "zoom out"
  "SPC z x j" "zoom out"
  "SPC z x 0" "reset zoom"
  "SPC z x q" "quit")


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


;; ---------------------------------------------------------------------
;; §16  Major-mode leader  (, + SPC m, V0 fallback + V1 org curated)
;; ---------------------------------------------------------------------
;; Spacemacs parity: `,' == `SPC m' (core-keybindings.el:103-132 uses
;; bind-map for this; we skip that dep).  V0 = show native mode map
;; anywhere; V1 = curated prefix per mode, buffer-local so it shadows
;; V0 only in that mode.  Org seed mirrors
;; layers/+emacs/org/packages.el:246-266 (dates), :312 (refile),
;; :380/:388 (insert template/link) — trimmed to user subset.
;; NOTE: `,' shadows evil `evil-repeat-find-char-reverse' — intended,
;; matches Spacemacs (`dotspacemacs-major-mode-leader-key ","').

;; 16a. V0 fallback — native mode bindings via which-key (zero upkeep).
(defun nano/v0-show-major-mode ()
  "Show native bindings of current major-mode.  V0 fallback for `,' / `SPC m'."
  (interactive)
  (which-key-show-major-mode))

(define-key evil-normal-state-map (kbd ",") 'nano/v0-show-major-mode)
(define-key evil-visual-state-map (kbd ",") 'nano/v0-show-major-mode)
(define-key evil-motion-state-map (kbd ",") 'nano/v0-show-major-mode)
(define-key spacemacs-leader-map (kbd "m") 'nano/v0-show-major-mode)
(which-key-add-key-based-replacements "SPC m" "major-mode")

;; 16b. V1 infra — per-mode curated prefix maps (no bind-map dep).
(defvar nano/major-mode-leader-maps (make-hash-table :test 'eq)
  "Hash MODE -> curated major-mode prefix keymap.")

(defun nano/major-mode-leader-map (mode)
  "Return curated prefix map for MODE, creating it on first use."
  (or (gethash mode nano/major-mode-leader-maps)
      (let ((m (make-sparse-keymap)))
        (puthash mode m nano/major-mode-leader-maps)
        m)))

(defun nano/set-leader-keys-for-major-mode (mode key def &rest bindings)
  "Bind KEY to DEF in MODE's curated map.  Accepts extra KEY DEF pairs.
Mimics `spacemacs/set-leader-keys-for-major-mode' without bind-map."
  (let ((map (nano/major-mode-leader-map mode)))
    (while key
      (define-key map (kbd key) def)
      (setq key (pop bindings) def (pop bindings)))))

(defun nano/declare-major-prefix (mode prefix label)
  "Label PREFIX (e.g. \"d\") as LABEL in MODE's curated map for which-key."
  (which-key-add-keymap-based-replacements
    (nano/major-mode-leader-map mode) prefix label))

(defun nano/activate-major-leader-locally (mode)
  "Shadow global `,' / `SPC m' with MODE's curated map in current buffer."
  (let ((map (nano/major-mode-leader-map mode)))
    (evil-local-set-key 'normal (kbd ",") map)
    (evil-local-set-key 'visual (kbd ",") map)
    (evil-local-set-key 'motion (kbd ",") map)
    (evil-local-set-key 'normal (kbd "SPC m") map)
    (evil-local-set-key 'visual (kbd "SPC m") map)
    (evil-local-set-key 'motion (kbd "SPC m") map)))

;; 16c. Org seed — dates, refile, insert (template + link only),
;; + babel execute (inline src_lang{} + #+BEGIN_SRC).
;; Mirrors layers/+emacs/org/packages.el:346-360, trimmed to
;; execute/navigate subset (no tangle/sessions/lob).
;; NOTE: more org bindings appended later — §18c (text/random),
;; §18c2 (tables), §21b (roam).  Edit those too for full `,' map.
(nano/declare-major-prefix 'org-mode "d" "dates")
(nano/declare-major-prefix 'org-mode "s" "subtree")
(nano/declare-major-prefix 'org-mode "i" "insert")
(nano/declare-major-prefix 'org-mode "b" "babel")
(nano/set-leader-keys-for-major-mode 'org-mode
                                     "dd" 'org-deadline
                                     "ds" 'org-schedule
                                     "dt" 'org-time-stamp
                                     "dT" 'org-time-stamp-inactive
                                     "sr" 'org-refile
                                     "ib" 'org-insert-structure-template ; #+begin_quote etc.
                                     "il" 'org-insert-link               ; URLs/links
                                     "be" 'org-babel-execute-maybe       ; inline + block Dwim
                                     "bc" 'org-ctrl-c-ctrl-c             ; native Dwim alias
                                     "bn" 'org-babel-next-src-block
                                     "bp" 'org-babel-previous-src-block
                                     "bv" 'org-babel-expand-src-block
                                     "bo" 'org-babel-open-src-block-result
                                     "bs" 'org-babel-execute-subtree
                                     "bb" 'org-babel-execute-buffer)
(which-key-add-keymap-based-replacements
  (nano/major-mode-leader-map 'org-mode)
  "dd" "deadline" "ds" "schedule"
  "dt" "timestamp" "dT" "inactive timestamp"
  "sr" "refile"
  "ib" "structure template" "il" "insert link"
  "be" "execute (inline/block)" "bc" "C-c C-c"
  "bn" "next src" "bp" "prev src"
  "bv" "expand src" "bo" "open result"
  "bs" "execute subtree" "bb" "execute buffer")

(defun nano/org-setup-major-leader ()
  "Activate curated `,' / `SPC m' map in org buffers."
  (nano/activate-major-leader-locally 'org-mode))
(add-hook 'org-mode-hook #'nano/org-setup-major-leader)
(put 'upcase-region 'disabled nil)


;; ---------------------------------------------------------------------
;; §17  Jump  (avy, SPC j, lazy)
;; ---------------------------------------------------------------------
;; Spacemacs `SPC j' parity, minimal pair only.
;; `avy' already vendored via link-hint (§15), so this reuses the
;; clone — no network fetch.  No `require': straight autoloads cover
;; both commands, zero startup cost.
;; j j = `avy-goto-char-timer' (type, pause jumps — Spacemacs jj default).
(straight-use-package 'avy)
(setq avy-background t
      avy-all-windows 'all-frames)

(define-key spacemacs-leader-map (kbd "j j") 'avy-goto-char-timer)
(define-key spacemacs-leader-map (kbd "j l") 'avy-goto-line)
(which-key-add-key-based-replacements
  "SPC j j" "jump to character"
  "SPC j l" "jump to line")


;; ---------------------------------------------------------------------
;; §18  Org  (autolist, links, tags, todo flow, babel, agenda, random, bullets)
;; ---------------------------------------------------------------------
;; Built-in org 9.7 + org-autolist + org-randomnote + built-in ob-* only.  Zero startup cost: no
;; `require 'org'; everything lazy via hook / with-eval-after-load.

;; 18pre. Link vars — MUST precede first org require (§18a pulls org
;; via org-autolist).  `org-mouse-1-follows-link' is read at org.el
;; load time; setting it after load misses (single-click stays 450ms
;; double-click gate).  `org-return-follows-link' is runtime-checked,
;; set here too so insert-state RET follows links from first load.
(setq org-mouse-1-follows-link t
      org-return-follows-link t)

;; 18a. RET auto-item, all lists (-, +, *, 1., - [ ]).
;;      Empty item + RET exits list.  Evil insert RET inherits map.
;;      Evil `o' / `O' bypass RET (raw newline), so shadow them
;;      buffer-locally: list -> new item below/above, empty -> exit,
;;      else plain evil open.  Ends in insert state like evil.
(straight-use-package 'org-autolist)
(add-hook 'org-mode-hook #'org-autolist-mode)

(with-eval-after-load 'evil
  (defun nano/org--empty-item-p ()
    "Non-nil if current line is an empty org list item."
    (save-excursion
      (beginning-of-line)
      (when (looking-at org-list-full-item-re)
        (goto-char (match-end 0))
        (eolp))))

  (defun nano/org--exit-empty-item ()
    "Exit empty item like autolist RET: outdent, else clear line."
    (condition-case nil
        (call-interactively #'org-outdent-item)
      (error (delete-region (line-beginning-position)
                            (line-end-position)))))

  (defun nano/org-open-below-item (count)
    "Evil `o' DWIM in org: continue item below, empty exits, else open."
    (interactive "p")
    (cond ((and (org-at-item-p) (nano/org--empty-item-p))
           (nano/org--exit-empty-item)
           (evil-insert-state 1))
          ((org-at-item-p)
           (end-of-line)
           (let ((checkbox (org-at-item-checkbox-p)))
             (dotimes (_ (or count 1))
               (if checkbox
                   (org-insert-todo-heading nil)
                 (org-insert-item)))))
          (t (evil-open-below count))))

  (defun nano/org-open-above-item (count)
    "Evil `O' DWIM in org: continue item above, empty exits, else open."
    (interactive "p")
    (cond ((and (org-at-item-p) (nano/org--empty-item-p))
           (nano/org--exit-empty-item)
           (evil-insert-state 1))
          ((org-at-item-p)
           (beginning-of-line)
           (let ((checkbox (org-at-item-checkbox-p)))
             (dotimes (_ (or count 1))
               (if checkbox
                   (org-insert-todo-heading nil)
                 (org-insert-item)))))
          (t (evil-open-above count))))

  (add-hook 'org-mode-hook
            (lambda ()
              (evil-local-set-key 'normal "o" #'nano/org-open-below-item)
              (evil-local-set-key 'normal "O" #'nano/org-open-above-item))))

;; 18b. Link open + agenda files — vars in §18pre (before org load).
;;      Machine-specific: gated on dir existence so portable machines
;;      without ~/Dropbox/org skip silently (warn once like §12 rg).
(defvar nano/org-directory (expand-file-name "~/Dropbox/org")
  "Root for agenda + roam notes.  Missing dir → org scope unset.")
(defvar nano/org-missing-warned nil
  "Non-nil once missing `nano/org-directory' warning was shown.")

(defun nano/org-ensure-directory ()
  "Return t if `nano/org-directory' exists, else warn once and return nil."
  (if (file-directory-p nano/org-directory)
      t
    (unless nano/org-missing-warned
      (setq nano/org-missing-warned t)
      (message "org dir %s missing, agenda/roam scope skipped" nano/org-directory))
    nil))

(defun nano/org-agenda-top-level-files ()
  "Return non-recursive *.org files directly under `nano/org-directory'.
Skips subdirs (e.g. roam/) so agenda scans fewer files.  Also skips
Emacs lock symlinks (.#*), auto-saves (#*#) and backups (*~): stale
ones are dangling/nonexistent and make `org-agenda-to-appt' prompt
[R]emove/[A]bort, stealing the next keypress after a TODO change."
  (when (file-directory-p nano/org-directory)
    (seq-filter (lambda (f)
                  (let ((n (file-name-nondirectory f)))
                    (and (string-suffix-p ".org" n)
                         (not (string-prefix-p ".#" n))
                         (not (and (string-prefix-p "#" n)
                                   (string-suffix-p "#" n)))
                         (not (string-suffix-p "~" n)))))
                (directory-files nano/org-directory t))))

(when (file-directory-p nano/org-directory)
  (setq org-agenda-files (nano/org-agenda-top-level-files))) ; agenda scope = top-level org dir only

;; 18b1. Evil RET DWIM — `evil-motion-state-map RET -> evil-ret' shadows
;; `org-mode-map RET -> org-return' in normal/motion, so RET on a link
;; just moved line (no open).  Plain `o' is `evil-open-below' by design
;; (see §18a DWIM); link open is `RET'/`, o'/`C-c C-o'.  Off-link RET
;; keeps `evil-ret' (next-line), on-link calls `org-open-at-point'
;; (covers `id:' roam + `https:' via `browse-url-default-browser'/xdg-open).
(defun nano/org-at-link-p ()
  "Non-nil when point is on an org link (incl. inside description)."
  (let ((ctx (ignore-errors (org-element-context))))
    (and ctx (eq (org-element-type ctx) 'link))))

(defun nano/org-link-external-p ()
  "Non-nil when org link at point would open a new buffer.
`file:' other-file and `id:' → t.  Fuzzy, custom-id, coderef,
same-file plus `http(s):' (external browser, no buffer) → nil
so those stay put."
  (let ((ctx (ignore-errors (org-element-context))))
    (when (and ctx (eq (org-element-type ctx) 'link))
      (let ((type (org-element-property :type ctx))
            (path (org-element-property :path ctx)))
        (cond ((or (null type) (string= type "fuzzy")
                   (string= type "custom-id") (string= type "coderef")) nil)
              ((or (string= type "http") (string= type "https")) nil)
              ((string= type "file")
               (let* ((raw (car (split-string (or path "") "::")))
                      (f (ignore-errors (expand-file-name raw default-directory)))
                      (cur (buffer-file-name)))
                 (if (or (null f) (null cur))
                     t
                   (not (string-equal (file-truename f) (file-truename cur))))))
              (t t))))))

(defun nano/org--open-in-current-window (&optional arg)
  "Follow org link at point in current window.
Shadows `org-link-frame-setup' `file' to `find-file' so `file:'
uses same window; `id:' maps through same entry to
`switch-to-buffer'.  Other entries untouched."
  (let ((org-link-frame-setup (cons '(file . find-file)
                                    org-link-frame-setup)))
    (org-open-at-point arg)))

(defun nano/org-open-at-point-in-scratch-window (&optional arg)
  "Open org link at point, external targets in `*scratch*' window.
`file:' other-file and `id:' relocate to scratch window; fuzzy,
same-file and `http(s):' open in place.  Single window or scratch
invisible → current window via `nano/org--open-in-current-window'.
Org-only; elfeed RET untouched (elfeed maps never bind this).
Focus follows to target."
  (interactive "P")
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in org-mode"))
  (if (not (ignore-errors (nano/org-link-external-p)))
      (org-open-at-point arg)
    (let ((target (nano/scratch-target-window))
          (origin (selected-window)))
      (if (not (nano/scratch-target-usable-p target origin))
          (nano/org--open-in-current-window arg)
        (let ((origin-buf (window-buffer origin))
              (shown-before (mapcar (lambda (w) (cons w (window-buffer w)))
                                    (window-list nil nil))))
          ;; Guard: §6f `switch-to-buffer' advice would move first;
          ;; suppress it so this single outer move owns the relocation.
          (let ((nano/scratch-redirect-in-progress t))
            (org-open-at-point arg))
          (nano/move-opened-buffer-to-target
           origin target origin-buf shown-before))))))

(defun nano/org-ret-dwim ()
  "Follow org link at point, else `evil-ret'.  Bound to RET in org normal/motion."
  (interactive)
  (if (and (derived-mode-p 'org-mode)
           (ignore-errors (nano/org-at-link-p)))
      (call-interactively #'nano/org-open-at-point-in-scratch-window)
    (call-interactively #'evil-ret)))

(with-eval-after-load 'org
  (with-eval-after-load 'evil
    (evil-define-key 'normal org-mode-map (kbd "RET") #'nano/org-ret-dwim)
    (evil-define-key 'normal org-mode-map (kbd "<return>") #'nano/org-ret-dwim)
    (evil-define-key 'motion org-mode-map (kbd "RET") #'nano/org-ret-dwim)
    (evil-define-key 'motion org-mode-map (kbd "<return>") #'nano/org-ret-dwim)))

;; 18b1b. Fold to cursor level — evil `zs' DWIM in org only.
;; `evil-motion-state-map zs' is `evil-scroll-start-column' globally;
;; shadow it buffer-locally via `org-mode-map' so other modes keep it.
;; Point anywhere inside a subtree folds whole buffer to that heading's
;; level (cursor at L2 → L3+ hidden).  `outline-hide-sublevels' (org
;; derives from outline) defaults to current level when called without
;; arg; pass LVL explicitly so body-text point (via `org-back-to-heading')
;; and echo message stay exact.  Errors when buffer has no heading.
(defun nano/org-fold-to-cursor-level ()
  "Hide everything below current heading's level, whole buffer.  Bound to `zs' in org."
  (interactive)
  (require 'outline)
  (let ((lvl (save-excursion
               (org-back-to-heading t)
               (org-current-level))))
    (unless lvl (user-error "No heading at point"))
    (outline-hide-sublevels lvl)
    (message "fold to level %d" lvl)))

(with-eval-after-load 'org
  (with-eval-after-load 'evil
    (evil-define-key 'normal org-mode-map "zs" #'nano/org-fold-to-cursor-level)
    (evil-define-key 'motion org-mode-map "zs" #'nano/org-fold-to-cursor-level)))

;; 18b2. Single-click mouse — belt-and-braces for §18pre: force
;; `mouse-1-click-follows-link' t buffer-locally (single short click
;; follows; long click sets point).  Guards machines where org.el
;; loaded before §18pre on first bootstrap.
(add-hook 'org-mode-hook
          (lambda () (setq-local mouse-1-click-follows-link t)))

;; 18b3. Autolist link guard — vendored `org-autolist' tests
;; `(eq 'org-link face)' which misses list faces like
;; `(org-link org-list-dt)' / fontified lists, so RET on a link inside
;; a list item inserted an item instead of following.  Patch here (not
;; in `straight/repos/') so `straight-pull-all' survives.
(with-eval-after-load 'org-autolist
  (defun nano/org-link-face-p ()
    "Non-nil when `face' text property at point includes `org-link'."
    (let ((f (get-text-property (point) 'face)))
      (cond ((eq f 'org-link) t)
            ((and (listp f) (memq 'org-link f)) t)
            (t nil))))
  (defun nano/org-on-link-p ()
    "Non-nil when on org link via element or face (font-lock off safe)."
    (or (ignore-errors (nano/org-at-link-p))
        (nano/org-link-face-p)))
  (ad-deactivate 'org-return)
  (defadvice org-return (around nano/org-autolist-return)
    "Autolist with link-face fix: follow link when on one, even in lists.
External `file:'/`id:' links relocate to `*scratch*' window via
open-then-move (link context stays in origin); scratch invisible
→ current window via `file . find-file' shadow; elfeed untouched."
    (let* ((el (org-element-at-point))
           (parent (plist-get (cadr el) :parent))
           (is-listitem (or (org-at-item-p)
                            (and (eq 'paragraph (car el))
                                 (eq 'item (car parent)))))
           (is-checkbox (plist-get (cadr parent) :checkbox)))
      (if (and is-listitem
               (not (and org-return-follows-link
                         (nano/org-on-link-p))))
          (if (and (eolp)
                   (org-at-item-p)
                   (<= (point) (org-autolist-beginning-of-item-after-bullet)))
              (condition-case nil
                  (call-interactively 'org-outdent-item)
                (error (delete-region (line-beginning-position)
                                      (line-end-position))))
            (cond (is-checkbox
                   (org-insert-todo-heading nil))
                  ((and (org-at-item-description-p)
                        (> (point) (org-autolist-beginning-of-item-after-bullet))
                        (< (point) (line-end-position)))
                   (newline))
                  (t (org-meta-return))))
        (if (and org-return-follows-link
                 (ignore-errors (nano/org-link-external-p))
                 (fboundp 'nano/move-opened-buffer-to-target))
            (let ((origin (selected-window))
                  (target (nano/scratch-target-window)))
              (if (not (nano/scratch-target-usable-p target origin))
                  (let ((org-link-frame-setup (cons '(file . find-file)
                                                    org-link-frame-setup)))
                    ad-do-it)
                (let ((origin-buf (window-buffer origin))
                      (shown-before (mapcar (lambda (w) (cons w (window-buffer w)))
                                            (window-list nil nil))))
                  ;; Guard: §6f advice suppressed; outer move owns relocation.
                  (let ((nano/scratch-redirect-in-progress t))
                    ad-do-it)
                  (nano/move-opened-buffer-to-target
                   origin target origin-buf shown-before))))
          ad-do-it))))
  (ad-activate 'org-return))

(with-eval-after-load 'org
  ;; Folded open: overview shows level-1 headers only.
  (setq org-startup-folded t)
  ;; Tags tight after headline: 0 = single space, no far-right pad.
  ;; nil stops realign on tag/todo edit.  Old files stay padded
  ;; until retag / `M-x org-align-tags'.
  (setq org-tags-column 0
        org-auto-align-tags nil)
  ;; TODO -> NEXT -> DONE.  `org-log-done' inserts CLOSED timestamp
  ;; on DONE, no note prompt.  `org-log-repeat' stays nil: builtin
  ;; default `time' forces a "- State DONE from ..." note via
  ;; post-command-hook on every repeater DONE (SCHEDULED/DEADLINE
  ;; with +/.+), on top of reschedule + LAST_REPEAT.  Cycle via
  ;; `C-c C-t' / `S-<left/right>' / `, t'.
  (setq org-todo-keywords '((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d)"))
        org-log-done 'time
        org-log-repeat nil)
  ;; Babel: inline src_lang{} + #+BEGIN_SRC.  Built-in ob-* only,
  ;; lazy here so zero startup cost.  Confirm stays t (prompt per
  ;; execute, safe).  Shell/python need system binaries.
  (org-babel-do-load-languages 'org-babel-load-languages
                               '((emacs-lisp . t) (shell . t) (python . t)))
  (setq org-confirm-babel-evaluate t
        org-src-tab-acts-natively t
        org-src-preserve-indentation t
        org-edit-src-content-indentation 0))

;; 18c. Curated leader additions (map created in §16c, hook already active).
;;      `, x' text menu mirrors Spacemacs layers/+emacs/org/packages.el:394-401
;;      (built-in `org-emphasize', zero dep).  `, xo' replaces old `, o'.
(defun nano/org-bold () "Bold region/word via `org-emphasize' *.  `, xb'." (interactive) (org-emphasize ?*))
(defun nano/org-code () "Code region/word via `org-emphasize' ~.  `, xc'." (interactive) (org-emphasize ?~))
(defun nano/org-italic () "Italic region/word via `org-emphasize' /.  `, xi'." (interactive) (org-emphasize ?/))
(defun nano/org-clear-emphasis () "Clear emphasis on region.  `, xr'." (interactive) (org-emphasize ?\s))
(defun nano/org-strike-through () "Strike region/word via `org-emphasize' +.  `, xs'." (interactive) (org-emphasize ?+))
(defun nano/org-underline () "Underline region/word via `org-emphasize' _.  `, xu'." (interactive) (org-emphasize ?_))
(defun nano/org-verbatim () "Verbatim region/word via `org-emphasize' =.  `, xv'." (interactive) (org-emphasize ?=))
(defun nano/org-insert-checkbox-item ()
  "Insert unchecked checkbox `- [ ]'.  Bound to `, i c' / `SPC m i c'.
DWIM: plain list item without box -> add `[ ]' in place via
`org-toggle-checkbox' with prefix; on box item -> new `- [ ]'
below via `org-insert-item'; off-list -> fresh `- [ ] ' on empty
line, else newline then `- [ ] '.  Ends in evil insert state.
Example: `- foo' -> `- [ ] foo'; empty line -> `- [ ] '."
  (interactive)
  (cond ((and (org-at-item-p) (not (org-at-item-checkbox-p)))
         (org-toggle-checkbox '(4)))
        ((org-insert-item t))
        ((save-excursion (beginning-of-line) (looking-at-p "[ \t]*$"))
         (beginning-of-line) (skip-chars-forward " \t") (insert "- [ ] "))
        (t (end-of-line) (newline) (insert "- [ ] ")))
  (when (fboundp 'evil-insert-state)
    (evil-insert-state 1)))
(nano/declare-major-prefix 'org-mode "x" "text")
(nano/set-leader-keys-for-major-mode 'org-mode
                                      "R" 'nano/org-random-current-buffer ; random headline, current buffer only
                                      "ic" 'nano/org-insert-checkbox-item ; unchecked `- [ ]' DWIM
                                      "ih" 'org-insert-heading ; same-level heading
                                      "xb" 'nano/org-bold
                                     "xc" 'nano/org-code
                                     "xi" 'nano/org-italic
                                     "xo" 'nano/org-open-at-point-in-scratch-window ; moved from `, o'
                                     "xr" 'nano/org-clear-emphasis
                                     "xs" 'nano/org-strike-through
                                     "xu" 'nano/org-underline
                                     "xv" 'nano/org-verbatim)
(which-key-add-keymap-based-replacements
  (nano/major-mode-leader-map 'org-mode)
  "R" "random note (buffer)"
  "ic" "insert checkbox" "ih" "insert heading"
  "xb" "bold" "xc" "code" "xi" "italic" "xo" "open link"
  "xr" "clear emphasis" "xs" "strike-through"
  "xu" "underline" "xv" "verbatim")

;; 18c2. Tables — Spacemacs `, t' parity (layers/+emacs/org/packages.el:316-343).
;;      Built-in org-table autoloads only, zero startup cost, zero dep.
;;      Replaces old `, t' todo cycle (unused; todo via `C-c C-t' /
;;      `S-<left/right>' / agenda `, t').  Example: `, tn' creates table,
;;      `, ta' realigns, `, tr' recalculates formulas.
(nano/declare-major-prefix 'org-mode "t" "tables")
(nano/declare-major-prefix 'org-mode "td" "delete")
(nano/declare-major-prefix 'org-mode "ti" "insert")
(nano/declare-major-prefix 'org-mode "tt" "toggle")
(nano/set-leader-keys-for-major-mode 'org-mode
                                      "ta" 'org-table-align
                                      "tb" 'org-table-blank-field
                                      "tc" 'org-table-convert
                                      "tdc" 'org-table-delete-column
                                      "tdr" 'org-table-kill-row
                                      "te" 'org-table-eval-formula
                                      "tE" 'org-table-export
                                      "tf" 'org-table-field-info
                                      "th" 'org-table-previous-field
                                      "tH" 'org-table-move-column-left
                                      "tic" 'org-table-insert-column
                                      "tih" 'org-table-insert-hline
                                      "tiH" 'org-table-hline-and-move
                                      "tir" 'org-table-insert-row
                                      "tI" 'org-table-import
                                      "tj" 'org-table-next-row
                                      "tJ" 'org-table-move-row-down
                                      "tK" 'org-table-move-row-up
                                      "tl" 'org-table-next-field
                                      "tL" 'org-table-move-column-right
                                      "tn" 'org-table-create
                                      "tN" 'org-table-create-with-table.el
                                      "tr" 'org-table-recalculate
                                      "tR" 'org-table-recalculate-buffer-tables
                                      "ts" 'org-table-sort-lines
                                      "ttf" 'org-table-toggle-formula-debugger
                                      "tto" 'org-table-toggle-coordinate-overlays
                                      "tw" 'org-table-wrap-region)
(which-key-add-keymap-based-replacements
  (nano/major-mode-leader-map 'org-mode)
  "ta" "align" "tb" "blank field" "tc" "convert"
  "tdc" "delete column" "tdr" "kill row"
  "te" "eval formula" "tE" "export" "tf" "field info"
  "th" "previous field" "tH" "move column left"
  "tic" "insert column" "tih" "insert hline"
  "tiH" "hline and move" "tir" "insert row"
  "tI" "import" "tj" "next row"
  "tJ" "move row down" "tK" "move row up"
  "tl" "next field" "tL" "move column right"
  "tn" "create" "tN" "create with table.el"
  "tr" "recalculate" "tR" "recalculate all"
  "ts" "sort lines"
  "ttf" "toggle formula debugger"
  "tto" "toggle coordinate overlays"
  "tw" "wrap region")

;; 18d. Random note — tasshin/org-randomnote (lazy, zero startup cost).
;;      Deps: dash + f (+ s via f), all lazy via straight autoloads.
;;      `org' built-in pin lives in §0 (must precede first
;;      org-dependent package) — not repeated here.
;;      `, R' wraps `org-randomnote' with candidates bound to
;;      `current-buffer', so agenda scope (§18b) stays intact for
;;      `M-x org-randomnote' while the binding stays buffer-local.
(straight-use-package 'org-randomnote)
(defvar org-randomnote-candidates)

(defun nano/org-random-current-buffer ()
  "Jump to random headline in current buffer.  Bound to `, R' / `SPC m R'."
  (interactive)
  (let ((org-randomnote-candidates 'current-buffer))
    (call-interactively #'org-randomnote)))

;; 18e. Agenda — built-in org-agenda only, lazy, zero startup cost.
;;      Top-level *.org under `nano/org-directory' (§18b), refreshed
;;      before each open so new files appear with no restart.
;;      Week starts Monday, span 7.  Skip DONE scheduled/deadline in
;;      agenda; todo-list shows ALL (scheduled included).
;;      Keys: SPC o a = dispatcher (pick `a' for week).
;;      Roam alias/tag live on SPC o A / T (§21) + `, r a' / `, r t'.
;;      Evil: motion state so SPC leader works, agenda keys intact.
;;      Deliberately NOT evil-collection-org-agenda: it binds SPC to
;;      `org-agenda-show', stealing SPC=leader (user choice).  Spacemacs
;;      parity keys below re-bound explicitly in motion instead.
(defvar nano/org-dir-mtime nil
  "Cached mtime of `nano/org-directory' for agenda refresh skip.")
(defvar nano/org-dir-files nil
  "Cached top-level agenda file list matching `nano/org-dir-mtime'.")

(defun nano/org-agenda-refresh-files (&optional force)
  "Set `org-agenda-files' to top-level *.org under `nano/org-directory'.
Skips the directory rescan when dir mtime is unchanged (same set of
files); pass FORCE to rescan unconditionally.  No-op (warn once via
`nano/org-ensure-directory') when dir missing."
  (when (nano/org-ensure-directory)
    (let ((mtime (ignore-errors
                   (file-attribute-modification-time
                    (file-attributes nano/org-directory)))))
      (when (or force (null nano/org-dir-files)
                (not (equal mtime nano/org-dir-mtime)))
        (setq nano/org-dir-files (nano/org-agenda-top-level-files)
              nano/org-dir-mtime mtime))
      (setq org-agenda-files nano/org-dir-files))))

(with-eval-after-load 'org-agenda
  (setq org-agenda-span 7
        org-agenda-start-on-weekday 1 ; Monday
        org-agenda-start-day nil      ; week containing today
        org-agenda-skip-scheduled-if-done t
        org-agenda-skip-deadline-if-done t
        org-agenda-todo-ignore-scheduled nil ; todo-list shows all
        org-agenda-todo-ignore-deadlines nil))

(advice-add 'org-agenda :before
            (lambda (&rest _) (nano/org-agenda-refresh-files)))
(advice-add 'org-todo-list :before
            (lambda (&rest _) (nano/org-agenda-refresh-files)))

(with-eval-after-load 'evil
  ;; Evil defaults `org-agenda-mode' to emacs state (evil-vars.el),
  ;; which hides SPC leader (bound only in normal/visual/motion).
  ;; Motion keeps agenda keys, enables SPC.  Seed now (evil loaded)
  ;; AND after org-agenda loads (covers load-order races), plus a
  ;; hook fallback: any agenda buffer still in emacs (e.g. restored
  ;; session, first-load race) drops into motion — no `i' press needed.
  (evil-set-initial-state 'org-agenda-mode 'motion))
(with-eval-after-load 'org-agenda
  (with-eval-after-load 'evil
    (evil-set-initial-state 'org-agenda-mode 'motion)))
(add-hook 'org-agenda-mode-hook #'nano/org-agenda-mode--remember-type)
(add-hook 'org-agenda-mode-hook
          (lambda ()
            (when (and (bound-and-true-p evil-mode)
                       (eq evil-state 'emacs))
              (evil-motion-state 1))))

(with-eval-after-load 'org-agenda
  (with-eval-after-load 'evil
    ;; SPC = leader (user choice) in every evil state used here.
    (evil-define-key '(normal visual motion) org-agenda-mode-map
      (kbd "SPC") spacemacs-leader-map)
    ;; Spacemacs evilified parity (`org/packages.el:609-638'), minus
    ;; transient `.'.  j/k = agenda-aware line motion (not raw
    ;; evil-next-line); M-j/k item, M-h/l earlier/later (span-relative:
    ;; week view = +-1 week, `C-u N' = N spans), J/K single-key week
    ;; hop (same fns, no META), gd grid, gr redo, M-RET show-and-scroll-up.
    ;; NOTE: J reclaims base `org-agenda-clock-goto' (still on `, Cj');
    ;; K was free (Spacemacs nils evil lookup).
    (evil-define-key 'motion org-agenda-mode-map
      "j" #'org-agenda-next-line
      "k" #'org-agenda-previous-line
      "J" #'org-agenda-earlier
      "K" #'org-agenda-later
      (kbd "M-j") #'org-agenda-next-item
      (kbd "M-k") #'org-agenda-previous-item
      (kbd "M-h") #'org-agenda-earlier
      (kbd "M-l") #'org-agenda-later
      "gd" #'org-agenda-toggle-time-grid
      "gr" #'org-agenda-redo
      (kbd "M-RET") #'org-agenda-show-and-scroll-up)))

;; Spacemacs `,/SPC m' agenda prefix (`org/packages.el:497-518',
;; transient `.' skipped — needs transient-state dep).
(nano/declare-major-prefix 'org-agenda-mode "d" "dates")
(nano/declare-major-prefix 'org-agenda-mode "i" "insert")
(nano/declare-major-prefix 'org-agenda-mode "c" "clock")
(nano/set-leader-keys-for-major-mode 'org-agenda-mode
                                     "a" 'org-agenda
                                     "c" 'org-capture
                                     "t" 'org-agenda-todo
                                     "T" 'org-agenda-todo
                                     "dd" 'org-agenda-deadline
                                     "ds" 'org-agenda-schedule
                                     "sr" 'org-agenda-refile
                                     "ie" 'org-agenda-set-effort
                                     "ip" 'org-agenda-priority
                                     "it" 'org-agenda-set-tags
                                     "Cc" 'org-agenda-clock-cancel
                                     "Ci" 'org-agenda-clock-in
                                     "Co" 'org-agenda-clock-out
                                     "Cj" 'org-agenda-clock-goto)
(which-key-add-keymap-based-replacements
  (nano/major-mode-leader-map 'org-agenda-mode)
  "a" "agenda" "c" "capture"
  "t" "todo" "T" "todo"
  "dd" "deadline" "ds" "schedule"
  "sr" "refile"
  "ie" "effort" "ip" "priority" "it" "tags"
  "Cc" "clock cancel" "Ci" "clock in"
  "Co" "clock out" "Cj" "clock goto")
(defun nano/org-agenda-setup-major-leader ()
  "Activate curated `,' / `SPC m' map in agenda buffers."
  (nano/activate-major-leader-locally 'org-agenda-mode))
(add-hook 'org-agenda-mode-hook #'nano/org-agenda-setup-major-leader)

(define-key spacemacs-leader-map (kbd "o a") 'org-agenda)
(which-key-add-key-based-replacements
  "SPC o a" "agenda (week)")

;; 18e2. Scheduled notify — built-in appt + notifications, on-time.
;;      Spacemacs uses org-alert cutoff 10; here warning 0 (fire at time).
;;      SCHEDULED-only with hh:mm (`:scheduled*'); DEADLINE/timestamp
;;      skipped per scope.  Per-item APPT_WARNTIME prop still overrides
;;      global 0 (org standard).  Zero-dep: appt + notifications built-in.
;;      Refresh each minute (top-level files only, cheap) + agenda/save/todo
;;      hooks.  D-Bus fail / tty / batch falls back to echo + mode-line.
;;      No `require' appt: `appt-activate' autoloads; setqs pre-load safe.
(setq appt-message-warning-time 0 ; on-time, not 10-early
      appt-display-interval 1     ; minute precision
      appt-audible nil
      appt-display-mode-line t)

(defun nano/appt-desktop-notify (min-to-app new-time msg)
  "Desktop notify for SCHEDULED item at NEW-TIME with MSG.
MIN-TO-APP ignored (warning 0).  D-Bus fail falls back to echo."
  (when (and (not noninteractive)
             (getenv "DBUS_SESSION_BUS_ADDRESS"))
    (ignore-errors
      (require 'notifications nil t)
      (when (fboundp 'notifications-notify)
        (notifications-notify :title "Org SCHEDULED"
                              :body (format "%s: %s" new-time msg)
                              :urgency 'normal :timeout 10000))))
  (message "Org SCHEDULED %s: %s" new-time msg))

(setq appt-disp-window-function #'nano/appt-desktop-notify
      appt-delete-window-function #'ignore)

(defvar nano/org-appt-last-mtime nil
  "Dir mtime at last successful appt rebuild; timer skips when same.")

(defun nano/org-appt-refresh (&optional force)
  "Rebuild appt list from SCHEDULED items with time.
Silent no-op when org dir missing.  With FORCE, rebuild
unconditionally; the minute timer passes none and skips the parse
when dir mtime is unchanged (saves/todo/agenda hooks force)."
  (when (nano/org-ensure-directory)
    (let ((mtime (ignore-errors
                   (file-attribute-modification-time
                    (file-attributes nano/org-directory)))))
      (when (or force (not (equal mtime nano/org-appt-last-mtime)))
        (nano/org-agenda-refresh-files force)
        (when (or (featurep 'org-agenda) (require 'org-agenda nil t))
          (let ((inhibit-message t))
            (ignore-errors (org-agenda-to-appt t nil :scheduled*)))
          (setq nano/org-appt-last-mtime mtime))))))

(defun nano/org-appt-refresh-force (&rest _)
  "Hook wrapper: forced appt rebuild (save/todo/agenda events)."
  (nano/org-appt-refresh t))

(unless noninteractive
  (appt-activate 1)
  (run-at-time nil 60 #'nano/org-appt-refresh)
  (add-hook 'window-setup-hook #'nano/org-appt-refresh-force)
  (add-hook 'org-agenda-finalize-hook #'nano/org-appt-refresh-force)
  (add-hook 'org-after-todo-state-change-hook #'nano/org-appt-refresh-force)
  (add-hook 'org-mode-hook
            (lambda ()
              (add-hook 'after-save-hook #'nano/org-appt-refresh-force nil t))))

;; 18f. Bullets — zero-dep Spacemacs parity (no org-superstar fetch).
;;      File keeps `*'; display composes leading stars per heading:
;;      first N-1 stars -> space (indent), last star -> bullet cycled
;;      by level over `nano/org-bullet-list' (■ ◆ ▲ ▶, Noto Sans Mono safe).
;;      Inherits `org-level-N' face (nano-theme strong) via prepend=nil
;;      side-effect matcher.  `org-hide-leading-stars' stays nil locally.
(defvar nano/org-bullet-list '(?■ ?◆ ?▲ ?▶)
  "Bullets cycled per org heading level (L1->■, L2->◆, ...).")

(defun nano/org-bullets--compose (beg end)
  "Compose stars in [BEG,END) to indent + bullet.  Font-lock side effect."
  (let* ((level (- end beg))
         (bullet (nth (% (1- level) (length nano/org-bullet-list))
                      nano/org-bullet-list)))
    (decompose-region beg end)
    (dotimes (i level)
      (compose-region (+ beg i) (+ beg i 1)
                      (if (< i (1- level)) ?\s bullet)))))

(defun nano/org-bullets-enable ()
  "Enable Spacemacs-style bullets in current org buffer."
  (unless (bound-and-true-p nano/org-bullets-enabled)
    (setq-local org-hide-leading-stars nil)
    (font-lock-add-keywords
     nil '(("^\\(\\*+\\) "
            (0 (progn (nano/org-bullets--compose
                       (match-beginning 1) (match-end 1))
                      nil))))
     t)
    (setq-local nano/org-bullets-enabled t))
  (when (bound-and-true-p font-lock-mode)
    (font-lock-flush)))

(add-hook 'org-mode-hook #'nano/org-bullets-enable)

;; 18g. Presentation — rlister/org-present, `, P' parity with ~/.spacemacs:685-687.
;;      Stock Spacemacs wires org-present command-only (`SPC SPC org-present');
;;      user config adds `, P'.  Same here: `, P' / `SPC m P' via curated map.
;;      Lazy: straight autoload only, zero startup cost.  Start/end hooks +
;;      h/l/q keys mirror layers/+emacs/org/packages.el:780-806.
(straight-use-package 'org-present)

(defun nano/org-present-start ()
  "Big text, inline images, hide cursor, read-only, evil normal."
  (when (fboundp 'org-present-big) (org-present-big))
  (when (fboundp 'org-display-inline-images) (org-display-inline-images))
  (when (fboundp 'org-present-hide-cursor) (org-present-hide-cursor))
  (when (fboundp 'org-present-read-only) (org-present-read-only))
  (when (fboundp 'evil-normal-state) (evil-normal-state 1)))

(defun nano/org-present-end ()
  "Restore text, images, cursor, write access after quit."
  (when (fboundp 'org-present-small) (org-present-small))
  (when (and (fboundp 'org-remove-inline-images)
             (not (bound-and-true-p org-startup-with-inline-images)))
    (org-remove-inline-images))
  (when (fboundp 'org-present-show-cursor) (org-present-show-cursor))
  (when (fboundp 'org-present-read-write) (org-present-read-write)))

(with-eval-after-load 'org-present
  (add-hook 'org-present-mode-hook #'nano/org-present-start)
  (add-hook 'org-present-mode-quit-hook #'nano/org-present-end)
  (with-eval-after-load 'evil
    (evil-define-key 'normal org-present-mode-keymap
      "h" #'org-present-prev
      "l" #'org-present-next
      "q" #'org-present-quit
      (kbd "<left>") #'org-present-prev
      (kbd "<right>") #'org-present-next)))

(nano/set-leader-keys-for-major-mode 'org-mode
                                     "P" 'org-present)
(which-key-add-keymap-based-replacements
  (nano/major-mode-leader-map 'org-mode)
  "P" "presentation")


;; ---------------------------------------------------------------------
;; §19  Insert  (SPC i, zero-dep lorem / password / uuid v4)
;; ---------------------------------------------------------------------
;; Spacemacs `SPC i' parity, minimal subset (spacemacs-editing layer:
;; `i l' lorem, `i p' password, `i U' uuid).  Zero-dep by design:
;; lorem-ipsum.el and uuidgen.el are absent from this Emacs build
;; (locate-library nil on 30.0.93), and password-generator is an
;; external dep — static text + `random' + `uuidgen' binary cover
;; all three with zero startup cost and no straight fetch.

;; 19a. Lorem ipsum — embedded text, no package.
;;      Paragraph = 4 random sentences joined; list = "- sentence" lines.
;;      Each slot sampled independently via built-in `random' (repeats
;;      allowed).  Plain = 1 unit, C-u N / M-N = N units.
(defvar nano/lorem-sentences
  '("Lorem ipsum dolor sit amet, consectetur adipiscing elit."
    "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
    "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris."
    "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum."
    "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia."
    "Curabitur pretium tincidunt lacus, nec iaculis eros aliquam vitae."
    "Phasellus ullamcorper velit eu nisi malesuada, a scelerisque odio ultrices."
    "Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere.")
  "Classic lorem ipsum sentences sampled randomly by §19 insert commands.")

(defun nano/lorem-random-sentence ()
  "Return one random sentence from `nano/lorem-sentences'."
  (nth (random (length nano/lorem-sentences)) nano/lorem-sentences))

(defun nano/insert-lorem-sentences (n)
  "Insert N random lorem ipsum sentences at point.  Bound to SPC i l s."
  (interactive "p")
  (dotimes (i (or n 1))
    (insert (nano/lorem-random-sentence))
    (insert (if (= i (1- (or n 1))) "\n" " "))))

(defun nano/insert-lorem-paragraphs (n)
  "Insert N random lorem ipsum paragraphs (4 sentences each).  SPC i l p."
  (interactive "p")
  (dotimes (p (or n 1))
    (dotimes (i 4)
      (insert (nano/lorem-random-sentence))
      (unless (= i 3) (insert " ")))
    (insert "\n")
    (unless (= p (1- (or n 1))) (insert "\n"))))

(defun nano/insert-lorem-list (n)
  "Insert N random lorem ipsum items as \"- sentence\" lines.  SPC i l l."
  (interactive "p")
  (dotimes (_i (or n 1))
    (insert "- " (nano/lorem-random-sentence) "\n")))

;; 19b. Password — built-in `random', alnum + symbols.
;;      Plain = `nano/password-length', C-u N / M-N = N chars,
;;      C-u alone prompts.  Copies to kill-ring + clipboard; echo
;;      shows length only, never the value.
(defvar nano/password-length 16
  "Default length for `nano/insert-password' (SPC i p p).")

(defvar nano/password-charset
  "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*-_=+"
  "Characters used by `nano/insert-password'.  No ambiguous filtering.")

(defun nano/insert-password (arg)
  "Generate password and insert at point.  Bound to SPC i p p.
With prefix ARG: numeric N uses N chars, plain C-u prompts."
  (interactive "P")
  (let* ((len (cond ((null arg) nano/password-length)
                    ((integerp arg) arg)
                    ((and (listp arg) (car arg)) (car arg))
                    (t (read-number "Password length: " nano/password-length))))
         (charset nano/password-charset)
         (clen (length charset))
         (pw (mapconcat (lambda (_) (string (aref charset (random clen))))
                        (number-sequence 1 len) "")))
    (kill-new pw)
    (when (fboundp 'gui-set-selection)
      (ignore-errors (gui-set-selection 'CLIPBOARD pw)))
    (insert pw)
    (message "Inserted %d-char password (copied)" len)))

;; 19c. UUID v4 — `uuidgen' binary, pure-elisp fallback.
;;      Lowercase RFC 4122 v4.  C-u also copies to kill-ring.
(defun nano/uuid-v4-fallback ()
  "Return random UUID v4 string without external tools."
  (format "%08x-%04x-4%03x-%04x-%012x"
          (random #x100000000) (random #x10000) (random #x1000)
          (logior #x8000 (random #x4000)) (random #x1000000000000)))

(defun nano/insert-uuid-v4 (arg)
  "Insert UUID v4 at point.  Bound to SPC i u / SPC i U.
With prefix ARG, also copy to kill-ring + clipboard."
  (interactive "P")
  (let ((uuid (or (and (executable-find "uuidgen")
                       (ignore-errors (car (process-lines "uuidgen"))))
                  (nano/uuid-v4-fallback))))
    (setq uuid (downcase uuid))
    (when arg
      (kill-new uuid)
      (when (fboundp 'gui-set-selection)
        (ignore-errors (gui-set-selection 'CLIPBOARD uuid))))
    (insert uuid)
    (message "Inserted UUID: %s" uuid)))

;; 19d. Bindings (Spacemacs mnemonics: i l s/p/l, i p p, i u;
;;      i U kept as Spacemacs-compat alias for i u).
(define-key spacemacs-leader-map (kbd "i l s") 'nano/insert-lorem-sentences)
(define-key spacemacs-leader-map (kbd "i l p") 'nano/insert-lorem-paragraphs)
(define-key spacemacs-leader-map (kbd "i l l") 'nano/insert-lorem-list)
(define-key spacemacs-leader-map (kbd "i p") 'nano/insert-password)
(define-key spacemacs-leader-map (kbd "i u") 'nano/insert-uuid-v4)
(which-key-add-key-based-replacements
  "SPC i" "insert"
  "SPC i l" "lorem ipsum"
  "SPC i l s" "insert sentences"
  "SPC i l p" "insert paragraphs"
  "SPC i l l" "insert list"
  "SPC i p" "insert password"
  "SPC i u" "insert UUID v4")


;; ---------------------------------------------------------------------
;; §20  Markdown  (jrblevin/markdown-mode, edit-only + GFM, lazy)
;; ---------------------------------------------------------------------
;; Zero startup cost: no `require', straight autoloads only.
;; `gfm-mode' derives from `markdown-mode'; both get same curated
;; `,' / `SPC m' map via §16 infra (two maps, one binding list).
;; Edit-only: no preview/export (needs external `markdown' binary).
;; `visual-line' already global (§2c), so no hook needed for wrap.
(straight-use-package 'markdown-mode)

;; 20a. File associations — GFM for README/GitHub, base for the rest.
;; NOTE: `add-to-list' prepends, so generic first, specific last.
(add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.markdown\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.mkd\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.mdx\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.github/.*\\.md\\'" . gfm-mode))
(add-to-list 'auto-mode-alist '("README\\.md\\'" . gfm-mode))

;; 20b. Defaults, applied lazily on first md open.
(with-eval-after-load 'markdown-mode
  (setq markdown-fontify-code-blocks-natively t
        markdown-hide-urls t
        markdown-asymmetric-header t
        markdown-list-indent-width 2
        markdown-indent-on-enter 'indent-and-new-item))

;; 20c. Curated leader — single-letter, matches C-c C-s mnemonics.
;;      b/i/c = bold/italic/code, l/I = link/image, q/p/P = quote/pre/gfm-block,
;;      n = list item, h = header dwim, f = footnote, o = open/follow (dwim),
;;      v = read-only view (no external processor needed).
(dolist (mode '(markdown-mode gfm-mode))
  (nano/set-leader-keys-for-major-mode mode
                                       "b" 'markdown-insert-bold
                                       "i" 'markdown-insert-italic
                                       "c" 'markdown-insert-code
                                       "s" 'markdown-insert-strike-through
                                       "l" 'markdown-insert-link
                                       "I" 'markdown-insert-image
                                       "q" 'markdown-insert-blockquote
                                       "p" 'markdown-insert-pre
                                       "P" 'markdown-insert-gfm-code-block
                                       "n" 'markdown-insert-list-item
                                       "h" 'markdown-insert-header-dwim
                                       "f" 'markdown-insert-footnote
                                       "o" 'markdown-do
                                       "v" 'markdown-view-mode)
  (which-key-add-keymap-based-replacements
    (nano/major-mode-leader-map mode)
    "b" "bold" "i" "italic"
    "c" "code" "s" "strikethrough"
    "l" "link" "I" "image"
    "q" "blockquote" "p" "pre" "P" "gfm code block"
    "n" "list item" "h" "header"
    "f" "footnote" "o" "open/follow" "v" "view mode"))

(defun nano/markdown-setup-major-leader ()
  "Activate curated `,' / `SPC m' map in markdown/gfm buffers."
  (nano/activate-major-leader-locally major-mode))
(add-hook 'markdown-mode-hook #'nano/markdown-setup-major-leader)
(add-hook 'gfm-mode-hook #'nano/markdown-setup-major-leader)


;; ---------------------------------------------------------------------
;; §21  Roam  (org-roam + sqlite-builtin, , r / SPC o, lazy)
;; ---------------------------------------------------------------------
;; Deps reused: dash/f/s (§18d via org-randomnote), magit-section
;; (§10 via magit build), org built-in 9.7 (§0 pin), sqlite
;; built-in (Emacs 30, no C compiler / binary needed).
;; New clones: org-roam + emacsql only.  Zero startup cost: no
;; `require', straight autoloads only; autosync runs lazily
;; on first org-roam load.
(straight-use-package 'emacsql)
(straight-use-package 'org-roam)

;; 21a. Paths — setqs BEFORE org-roam loads (cheap, no side effect).
;;      Directory under agenda root (§18b) so notes sync via Dropbox.
;;      Db absolute path: sqlite-builtin connector requires it.
;;      Dirs created lazily on first org-roam load, gated on
;;      `nano/org-directory' (§18b) so machines without Dropbox
;;      create nothing at startup.
(setq org-roam-directory (expand-file-name "roam" nano/org-directory)
      org-roam-db-location (locate-user-emacs-file "var/org-roam.db")
      org-roam-database-connector 'sqlite-builtin
      org-roam-db-update-on-save t
      org-roam-dailies-directory (expand-file-name "roam/daily" nano/org-directory))

(with-eval-after-load 'org-roam
  (when (nano/org-ensure-directory)
    (make-directory org-roam-directory t)
    (make-directory org-roam-dailies-directory t)
    (make-directory (file-name-directory org-roam-db-location) t))
  ;; `org-roam-setup' is obsolete — it only enables autosync.
  ;; Prefer autosync, fall back to setup on old vendored builds.
  (cond ((fboundp 'org-roam-db-autosync-mode)
         (org-roam-db-autosync-mode 1))
        ((fboundp 'org-roam-setup)
         (org-roam-setup))))

;; 21a1. `id:' open needs DB ready even before first roam command.
;; Lazy once per session on first org buffer (not at startup):
;; requires roam (autoloads already), then autosync.  Gated on dir.
(defvar nano/org-roam-autosync-done nil
  "Non-nil once `org-roam-db-autosync-mode' enabled this session.")
(defun nano/org-roam-ensure-autosync ()
  "Enable `org-roam-db-autosync-mode' once, for `id:' link opening."
  (when (and (not nano/org-roam-autosync-done)
             (nano/org-ensure-directory))
    (require 'org-roam nil t)
    (require 'org-id nil t)
    (when (fboundp 'org-roam-db-autosync-mode)
      (org-roam-db-autosync-mode 1)
      (setq nano/org-roam-autosync-done t))))
(add-hook 'org-mode-hook #'nano/org-roam-ensure-autosync)

;; 21b/c. Single source: (major-suffix global-suffix fn label).
;;      `, r' (+ `SPC m r') in org buffers reuses §16 infra; hook
;;      already active (§16c), so map shows once org loads.
;;      `SPC o' is global fallback for non-org buffers (same targets).
;;      Dailies need no extra dep (built into roam).
(defvar nano/org-roam-bindings
  '(("rf"  "o f"   org-roam-node-find              "find")
    ("ri"  "o i"   org-roam-node-insert            "insert")
    ("rc"  "o c"   org-roam-capture                "capture")
    ("rl"  "o l"   org-roam-buffer-toggle          "backlinks")
    ("rg"  "o g"   org-roam-graph                  "graph")
    ("rs"  "o s"   org-roam-db-sync                "sync")
    ("ra"  "o A"   org-roam-alias-add              "alias add")
    ("rt"  "o T"   org-roam-tag-add                "tag add")
    ("rdT" "o d T" org-roam-dailies-capture-today     "dailies today")
    ("rdY" "o d Y" org-roam-dailies-capture-yesterday "dailies yesterday")
    ("rdt" "o d t" org-roam-dailies-goto-today        "go today")
    ("rdy" "o d y" org-roam-dailies-goto-yesterday    "go yesterday")
    ("rdn" "o d n" org-roam-dailies-goto-tomorrow     "go tomorrow")
    ("rdd" "o d d" org-roam-dailies-goto-date         "go date"))
  "Roam commands shared by `, r' (§21b) and `SPC o' (§21c).")

(nano/declare-major-prefix 'org-mode "r" "roam")
(dolist (b nano/org-roam-bindings)
  (nano/set-leader-keys-for-major-mode 'org-mode (nth 0 b) (nth 2 b))
  (define-key spacemacs-leader-map (kbd (nth 1 b)) (nth 2 b))
  (which-key-add-keymap-based-replacements
    (nano/major-mode-leader-map 'org-mode) (nth 0 b) (nth 3 b))
  (which-key-add-key-based-replacements
    (concat "SPC " (nth 1 b)) (nth 3 b)))
(which-key-add-key-based-replacements "SPC o d" "dailies")

;; 21d. RET / TAB / nav semantics — Spacemacs-style "ghost highlight" for
;;      `org-roam-node' category.
;;      `org-roam-node-read' (org-roam-node.el) uses `completing-read'
;;      with REQUIRE-MATCH=nil: any literal string becomes a new node
;;      via `org-roam-node-create :title'.  With fido-vertical, the
;;      first candidate LOOKS selected (highlighted, RET would pick it)
;;      but was never actually chosen by the user.
;;      Spacemacs/vertico semantics (emulated):
;;        * the list is a passive menu: RET always submits the TYPED
;;          input (new node, or exact existing title);
;;        * moving into the list (C-j/C-k/C-n/C-p/arrows)
;;          actively selects the focused candidate (M-</M-> also map to
;;          nav, but stay stock — see the advice note below);
;;        * TAB fills the input with the currently focused candidate
;;          (preview) WITHOUT selecting it — after TAB, RET still
;;          creates/uses the literal text unless the user navigates
;;          again (navigation re-arms selection);
;;        * C-M-j keeps stock "force select first".
;;      Implementation: selection state is NOT the icomplete rotation
;;      (which auto-focuses entry 1 on every keystroke).  For roam
;;      prompts the nav commands are replaced by a selectrum/vertico-
;;      style mover that rebuilds the rotation from scratch each time
;;      (stateless), so a later refilter restarts at the top again.  RET
;;      and TAB are plain DWIM commands bound in `icomplete-fido-mode-map',
;;      delegating to stock behaviour for non-roam prompts.
;;
;;      The nav hook MUST be `:around', never `:override'.  These two
;;      commands are what C-n/C-p and <down>/<up> are bound to for EVERY
;;      prompt, so the non-roam branch has to reach the original: an
;;      `:override' advice that "falls back" by calling
;;      `icomplete-forward-completions' calls itself, and the first
;;      up/down in any file/choice prompt dies with
;;      `excessive-lisp-nesting' (1601).  `:around' passes the real
;;      original in as ORIG, which cannot re-enter.
;;      NOTE: plain RET must be `exit-minibuffer', NOT
;;      `minibuffer-complete-and-exit' — the latter expands a new
;;      prefix to the first flex match on first RET (still forces
;;      existing), while `exit-minibuffer' preserves the literal.
(defvar-local nano/org-roam--fido-navigated nil
  "Non-nil when user actively moved into the candidate list.
Set by nav commands, consumed by RET DWIM below.")

(defun nano/org-roam--fido-in-roam-p ()
  "Non-nil in a roam completion minibuffer."
  (and (minibufferp)
       (eq (ignore-errors (icomplete--category)) 'org-roam-node)))

(defun nano/org-roam--fido-mark-navigated ()
  "Flag current minibuffer as navigated for roam RET DWIM."
  (when (nano/org-roam--fido-in-roam-p)
    (setq nano/org-roam--fido-navigated t)))

(defun nano/org-roam--fido-setup ()
  "Reset nav flag on each minibuffer prompt (buffer reused across reads)."
  (setq-local nano/org-roam--fido-navigated nil))

(defun nano/org-roam--fido-proper (comps)
  "Return COMPS as a proper list, stripping a base-size tail.
`completion-all-sorted-completions' caches `(nconc all base-size)':
a fresh computation is dotted like (c1 c2 . 0) and even the sole
candidate is (c1 . 0).  `mapcar'/`butlast' die on that atom
(wrong-type-argument listp 0).  Walk conses while they are conses;
the base-size marker is dropped (roam tables are flat strings,
base 0, and force-complete recomputes when the cache is nil)."
  (let (out)
    (while (consp comps)
      (push (pop comps) out))
    (nreverse out)))

(defun nano/org-roam--fido-nav ()
  "Advance the roam candidate highlight one step (wrapping at the end).
Ignore any stale icomplete rotation and rebuild from the CURRENT
list, so each invocation moves exactly one entry.  Returns non-nil
when a rotation happened (stock contract), nil with <2 candidates.
ROAM ONLY — the advice below routes non-roam prompts to the real
stock command, so this must never call `icomplete-forward-completions'
(a call to it here would re-enter the advice and recurse)."
  (interactive)
  (let* ((beg (icomplete--field-beg))
         (end (icomplete--field-end))
         (comps (nano/org-roam--fido-proper
                 (completion-all-sorted-completions beg end)))
         (stepped nil))
    (when (consp (cdr comps))
      (completion--cache-all-sorted-completions
       beg end
       (nconc (cdr comps) (list (car comps))))
      (setq stepped t))
    (nano/org-roam--fido-mark-navigated)
    stepped))

(defun nano/org-roam--fido-nav-back ()
  "Backward variant of `nano/org-roam--fido-nav'.  ROAM ONLY."
  (interactive)
  (let* ((beg (icomplete--field-beg))
         (end (icomplete--field-end))
         (comps (nano/org-roam--fido-proper
                 (completion-all-sorted-completions beg end)))
         (stepped nil))
    ;; Rotate only when >= 2 candidates: consing the last element of
    ;; a single-entry list onto itself would DUPLICATE it in the
    ;; cache (a a) and RET would then force-complete a doubled title.
    (when (and (consp comps) (consp (cdr comps)))
      (completion--cache-all-sorted-completions
       beg end
       (cons (car (last comps)) (butlast comps)))
      (setq stepped t))
    (nano/org-roam--fido-mark-navigated)
    stepped))

(defun nano/icomplete-fido-ret-roam-dwim ()
  "RET DWIM for roam: literal (new node) unless navigated.
Plain RET -> `exit-minibuffer' (literal preserved; REQUIRE-MATCH
nil, so unique name creates node, exact title opens existing).
After navigation -> `icomplete-force-complete-and-exit' (select
highlighted).  Non-roam minibuffers fall back to `icomplete-fido-ret'."
  (interactive)
  (if (nano/org-roam--fido-in-roam-p)
      (if nano/org-roam--fido-navigated
          (progn (setq nano/org-roam--fido-navigated nil)
                 (call-interactively #'icomplete-force-complete-and-exit))
        (call-interactively #'exit-minibuffer))
    (call-interactively #'icomplete-fido-ret)))

(defun nano/icomplete-fido-tab-dwim ()
  "TAB DWIM for roam: fill input with focused candidate (preview).
Fills the input with the current first candidate via
`minibuffer-force-complete' (vertico `vertico-insert' parity:
after TAB the filled text IS the input, so the next RET
submits it).  Never sets the navigated/select state.  Non-roam
minibuffers fall back to `minibuffer-complete'."
  (interactive)
  (if (nano/org-roam--fido-in-roam-p)
      (minibuffer-force-complete nil nil 'dont-cycle)
    (minibuffer-complete)))

(defun nano/org-roam--icomplete-nav-a (orig &rest args)
  "Route forward nav: roam gets the stateless mover, the rest stock.
ORIG is the real `icomplete-forward-completions' bound by the
:around advice, so the non-roam branch cannot re-enter this advice."
  (if (nano/org-roam--fido-in-roam-p)
      (nano/org-roam--fido-nav)
    (apply orig args)))

(defun nano/org-roam--icomplete-nav-back-a (orig &rest args)
  "Route backward nav: roam gets the stateless mover, the rest stock."
  (if (nano/org-roam--fido-in-roam-p)
      (nano/org-roam--fido-nav-back)
    (apply orig args)))

(with-eval-after-load 'icomplete
  ;; DWIM commands in the fido map (harmless in non-roam prompts: they
  ;; delegate to stock behaviour there).  TAB: stock fido leaves TAB to
  ;; `minibuffer-local-completion-map' (`minibuffer-complete'), which is
  ;; exactly what the DWIM falls back to — no behaviour change outside roam.
  (define-key icomplete-fido-mode-map (kbd "RET") #'nano/icomplete-fido-ret-roam-dwim)
  (define-key icomplete-fido-mode-map (kbd "C-m") #'nano/icomplete-fido-ret-roam-dwim)
  (define-key icomplete-fido-mode-map (kbd "TAB") #'nano/icomplete-fido-tab-dwim)
  ;; Nav: :around, NOT :override.  These commands are what C-n/C-p and
  ;; <down>/<up> are bound to in `icomplete-vertical-mode-minibuffer-map',
  ;; so they run in EVERY completion prompt, not just roam.  With
  ;; :override the "fall back to stock" branch called the very symbol the
  ;; advice had replaced, i.e. itself: any up/down in any prompt recursed
  ;; until `excessive-lisp-nesting' (1601).  :around hands the real
  ;; original in as ORIG, so the non-roam path cannot re-enter.
  (advice-add 'icomplete-forward-completions :around
              #'nano/org-roam--icomplete-nav-a
              '((name . nano/org-roam--icomplete-nav)))
  (advice-add 'icomplete-backward-completions :around
              #'nano/org-roam--icomplete-nav-back-a
              '((name . nano/org-roam--icomplete-nav-back)))
  ;; M-</M-> (`icomplete-vertical-goto-first'/`-last') are NOT advised:
  ;; their stock bodies are `(while (icomplete-backward-completions))',
  ;; which relies on `icomplete-scroll' to terminate.  `icomplete-scroll'
  ;; is nil here, so a rotation-based replacement can never know when it
  ;; has reached the first entry and would spin forever.  Stock therefore
  ;; signals "Only works with `icomplete-scroll'" on M-< / M->, which is
  ;; the honest behaviour for this config; C-j/C-k and the arrows do the
  ;; stepping.
  )
(add-hook 'minibuffer-setup-hook #'nano/org-roam--fido-setup)


;; ---------------------------------------------------------------------
;; §22  Update/Reload  (SPC f e U pull+rebuild, SPC f e r reload init)
;; ---------------------------------------------------------------------
;; Spacemacs `SPC f e U' parity.  Floats latest, no lockfile.
;; `straight-pull-all' = fetch+merge only, then `straight-rebuild-all'
;; applies builds.  Blocking, may freeze briefly.  Restart after: SPC q r.
(defun nano/update-packages ()
  "Pull latest for all straight packages, then rebuild.  Bound to SPC f e U."
  (interactive)
  (message "Updating packages...")
  (straight-pull-all)
  (straight-rebuild-all)
  (message "Packages updated.  Restart with SPC q r."))
(define-key spacemacs-leader-map (kbd "f e U") 'nano/update-packages)

;; Reload init.el in-place — no restart needed for most edits.
;; File is written reload-safe: stale advice/hooks removed before
;; re-adding (init.el:741, init.el:838), keymaps/hooks/advice idempotent.
;; NOT re-applied: §2 font vars — `(require 'nano)' is a no-op after
;; first load, so set-before-require appearance needs SPC q r.
(defun nano/reload-init ()
  "Re-execute init.el (`user-init-file').  Bound to SPC f e r.
Covers bindings, defuns, setq, modeline, keymaps.  Font/theme-boot
changes still need SPC q r (nano load order)."
  (interactive)
  (message "Reloading init.el...")
  (load (or user-init-file (locate-user-emacs-file "init.el"))
        nil 'nomessage)
  (message "init.el reloaded.  Font/boot changes still need SPC q r."))
(define-key spacemacs-leader-map (kbd "f e r") 'nano/reload-init)
(which-key-add-key-based-replacements
  "SPC f e" "emacs/config"
  "SPC f e U" "update packages"
  "SPC f e r" "reload init")

;; ---------------------------------------------------------------------
;; §23  Web  (built-in eww + elfeed/ttrss, SPC a w, lazy)
;; ---------------------------------------------------------------------
;; Zero startup cost: no `require', straight autoloads only.  First
;; SPC a r builds elfeed + protocol + goodies.
;; Mirrors ~/Dropbox/scripts/spacemacs-private.el:127-254, renamed
;; `spacemacs/' -> `nano/'.  Spacemacs elfeed layer enables goodies by
;; default (`elfeed-enable-goodies t'): entry layout Tags|Title
;; (no feed, no date) + header totals + split-pane entry view.
;; Entry/header rendering via nano/ fns derived from goodies draw fns (powerline vendored as
;; goodies dep); split pane via built-in `display-buffer' (no popwin,
;; perf-first per Principles) instead of goodies/popwin switch-pane.
;; Evil via evil-collection-elfeed (normal state, pre-seeded + lazy
;; init in §10): readonly nav (j/k/q/RET) free, SPC falls through to
;; leader.  Spacemacs `evilified' extras below re-bound explicitly.
(straight-use-package 'elfeed)
(straight-use-package 'elfeed-protocol)
(straight-use-package 'elfeed-goodies)

(define-key spacemacs-leader-map (kbd "a r") 'elfeed)
(define-key spacemacs-leader-map (kbd "a w w") 'eww)
(define-key spacemacs-leader-map (kbd "a w r") 'eww-readable)
(which-key-add-key-based-replacements
  "SPC a r" "elfeed"
  "SPC a w w" "eww"
  "SPC a w r" "eww-readable")

;; 23a0. Evil-collection truce — deterministic nano keys.
;;      Collection setup binds theme ids by default keys in elfeed maps
;;      (scroll-down->SPC, refresh->gr, show quit->q), and its show-map
;;      binds defer via `after-load-functions', landing AFTER §23 key
;;      blocks depending on load history (magit-first, desktop restore).
;;      Result: SPC/gr/q randomly clobbered.  Fix both sides:
;;      `:enabled nil' (fn-scoped to elfeed maps only, magit untouched)
;;      stops collection binding the contested ids, and setup-hook
;;      re-applies nano keys after collection setup (last-writer wins).
;;      Must stay BEFORE first `evil-collection-init' (lazy, §10) —
;;      restart emacs after editing (no reloader).
(defun nano/elfeed-collection-allow-p (map-sym id)
  "t when evil-collection theme ID may bind in MAP-SYM.
Nil for contested ids in elfeed maps: frees SPC/S-SPC (scroll),
gr/gR (refresh), show q (quit) for nano keys."
  (not (and (memq map-sym '(elfeed-search-mode-map elfeed-show-mode-map
                            elfeed-tree-mode-map))
            (if (eq map-sym 'elfeed-show-mode-map)
                (memq id '(scroll-down scroll-up refresh refresh-all
                           quit quit-save quit-cancel))
              (memq id '(scroll-down scroll-up refresh refresh-all))))))
;; NOTE: `:enabled' function values MUST be anonymous lambdas —
;; `evil-collection-binding-enabled-p' funcalls only non-symbol
;; functions, a named symbol counts as plain truthy data.
(setq evil-collection-binding-overrides
      (let ((allow (lambda (map-sym id _keys _cmd)
                     (nano/elfeed-collection-allow-p map-sym id))))
        `((scroll-down :enabled ,allow)
          (scroll-up :enabled ,allow)
          (refresh :enabled ,allow)
          (refresh-all :enabled ,allow)
          (quit :enabled ,allow)
          (quit-save :enabled ,allow)
          (quit-cancel :enabled ,allow))))

(defun nano/elfeed-search-keys ()
  "SPC leader + Spacemacs search extras.  Re-applied via setup-hook."
  (evil-define-key '(normal visual motion) elfeed-search-mode-map
    (kbd "SPC") spacemacs-leader-map)
  ;; `b' browse + `r' mark-read re-bound explicitly: evil normal
  ;; `b' (backward-word) / `r' (replace) shadow native search keys,
  ;; and evil-collection-elfeed binds neither.
  (evil-define-key 'normal elfeed-search-mode-map
    "b" #'elfeed-search-browse-url
    "r" #'elfeed-search-untag-unread
    "c" #'elfeed-db-compact
    "gr" #'elfeed-update
    "gR" #'elfeed-search-update--force
    "gu" #'elfeed-unjam
    "o" #'elfeed-load-opml
    "K" #'nano/elfeed-toggle-sort-mode)
  ;; Spacemacs visual extras (`packages.el:49-53').
  (evil-define-key 'visual elfeed-search-mode-map
    "+" #'elfeed-search-tag-all
    "-" #'elfeed-search-untag-all
    "b" #'elfeed-search-browse-url
    "y" #'elfeed-search-yank))

(defun nano/elfeed-show-keys ()
  "SPC leader + Spacemacs show extras.  Re-applied via setup-hook.
`q' kills + closes split (`nano/elfeed-show-quit')."
  (evil-define-key '(normal visual motion) elfeed-show-mode-map
    (kbd "SPC") spacemacs-leader-map)
  ;; Native next/prev already route through switch/delete (§23a2),
  ;; so they stay in the split.
  (evil-define-key '(normal motion) elfeed-show-mode-map
    (kbd "C-j") #'elfeed-show-next
    (kbd "C-k") #'elfeed-show-prev
    "n" #'elfeed-show-next
    "p" #'elfeed-show-prev
    "q" #'nano/elfeed-show-quit))

(defun nano/elfeed-collection-setup-hook (mode _keymaps)
  "Re-apply nano elfeed keys after evil-collection setup for MODE."
  (when (eq mode 'elfeed)
    (when (and (boundp 'elfeed-search-mode-map)
               (keymapp elfeed-search-mode-map))
      (nano/elfeed-search-keys))
    (when (and (boundp 'elfeed-show-mode-map)
               (keymapp elfeed-show-mode-map))
      (nano/elfeed-show-keys))))
(add-hook 'evil-collection-setup-hook #'nano/elfeed-collection-setup-hook)

;; 23a0b. Search list never wraps — special case vs §2c global visual-line.
;;      elfeed sets `truncate-lines t' but global-visual-line re-wraps.
;;      Hook runs per buffer (incl. desktop restore); entry buffers keep wrap.
(defun nano/elfeed-search-no-wrap ()
  "Truncate long titles in *elfeed-search*.  Entry buffers keep wrap."
  (visual-line-mode -1)
  (setq-local truncate-lines t
              word-wrap nil))
(add-hook 'elfeed-search-mode-hook #'nano/elfeed-search-no-wrap)

;; 23a. Sort toggle — date (oldest first) <-> random, `K' in search.
;;      `elfeed-sort-order' default; per-buffer vars applied by fn below.
(setq elfeed-sort-order 'ascending)
(defvar nano/elfeed-sort-mode 'date
  "Active elfeed-search sort mode: `date' (oldest first) or `random'.")

(defvar nano/elfeed-random-ranks (make-hash-table :test 'eq)
  "Memoized random ranks per entry for elfeed random sort mode.")

(defun nano/elfeed-random-rank (entry)
  "Return stable random rank for ENTRY, assigning once per shuffle."
  (or (gethash entry nano/elfeed-random-ranks)
      (let ((r (random most-positive-fixnum)))
        (puthash entry r nano/elfeed-random-ranks)
        r)))

(defun nano/elfeed-apply-sort-mode ()
  "Apply `nano/elfeed-sort-mode' to current elfeed-search buffer."
  (pcase nano/elfeed-sort-mode
    ('date
     (setq-local elfeed-search-sort-order 'ascending)
     (setq-local elfeed-search-sort-function nil))
    ('random
     (clrhash nano/elfeed-random-ranks) ; fresh shuffle each apply
     (setq-local elfeed-search-sort-order 'ascending)
     (setq-local elfeed-search-sort-function
                 (lambda (a b)
                   (< (nano/elfeed-random-rank a)
                      (nano/elfeed-random-rank b))))))
  (elfeed-search-update :force)
  (force-mode-line-update t))

(defun nano/elfeed-toggle-sort-mode ()
  "Toggle elfeed-search between date (oldest-first) and random sort."
  (interactive nil elfeed-search-mode)
  (setq nano/elfeed-sort-mode
        (if (eq nano/elfeed-sort-mode 'date) 'random 'date))
  (nano/elfeed-apply-sort-mode)
  (message "elfeed sort: %s" nano/elfeed-sort-mode))

(defun nano/elfeed-sort-label ()
  "Short sort-mode label for header/modeline: OLDEST or RANDOM."
  (if (eq nano/elfeed-sort-mode 'random) "RANDOM" "OLDEST"))

(defun nano/elfeed-entry-line-draw (entry)
  "Print ENTRY as tags + title only (no feed column).
Same wide/narrow behavior as `elfeed-goodies/entry-line-draw',
minus the feed source column so titles gain its width."
  (let* ((title (or (elfeed-meta entry :title) (elfeed-entry-title entry) ""))
         (title-faces (elfeed-search--faces (elfeed-entry-tags entry)))
         (tags (mapcar #'symbol-name (elfeed-entry-tags entry)))
         (tags-str (concat "[" (mapconcat 'identity tags ",") "]"))
         (title-width (- (window-width) elfeed-goodies/tag-column-width 4))
         (tag-column (elfeed-format-column
                      tags-str (elfeed-clamp (length tags-str)
                                             elfeed-goodies/tag-column-width
                                             elfeed-goodies/tag-column-width)
                      :left)))
    (if (>= (window-width) (* (frame-width) elfeed-goodies/wide-threshold))
        (progn
          (insert (propertize tag-column 'face 'elfeed-search-tag-face) " ")
          (insert (propertize title 'face title-faces 'kbd-help title)))
      (insert (propertize title 'face title-faces 'kbd-help title)))))

(defun nano/elfeed-search-header-draw ()
  "Tags|Subject powerline header, no feed column.  Narrow keeps goodies tight layout."
  (if (zerop (elfeed-db-last-update))
      (elfeed-search--intro-header)
    (let* ((separator-left (intern (format "powerline-%s-%s"
                                           elfeed-goodies/powerline-default-separator
                                           (car powerline-default-separator-dir))))
           (separator-right (intern (format "powerline-%s-%s"
                                            elfeed-goodies/powerline-default-separator
                                            (cdr powerline-default-separator-dir))))
           (db-time (seconds-to-time (elfeed-db-last-update)))
           (stats (-elfeed/feed-stats))
           (search-filter (cond (elfeed-search-filter-active "")
                                (elfeed-search-filter elfeed-search-filter)
                                (""))))
      (if (>= (window-width) (* (frame-width) elfeed-goodies/wide-threshold))
          (let* ((update (format-time-string "%Y-%m-%d %H:%M:%S %z" db-time))
                 (lhs (list
                       (powerline-raw (-pad-string-to "Tags" (- elfeed-goodies/tag-column-width 6)) 'powerline-active2 'l)
                       (funcall separator-left 'powerline-active2 'mode-line)
                       (powerline-raw "Subject" 'mode-line 'l)))
                 (rhs (search-header/rhs separator-left separator-right search-filter stats update)))
            (concat (powerline-render lhs)
                    (powerline-fill 'mode-line (powerline-width rhs))
                    (powerline-render rhs)))
        (search-header/draw-tight separator-left separator-right search-filter stats db-time)))))

(defun nano/elfeed-search-header ()
  "elfeed-search header annotated with active sort mode."
  (concat (propertize (format "[%s] " (nano/elfeed-sort-label)) 'face 'font-lock-warning-face)
          (if (fboundp 'nano/elfeed-search-header-draw)
              (nano/elfeed-search-header-draw)
            (elfeed-search--header))))

(with-eval-after-load 'elfeed-search
  (when (require 'elfeed-goodies-search-mode nil t)
    ;; Entry layout Tags|Title, no feed column.  Narrow windows fall
    ;; back to title-only per wide-threshold.
    (setq elfeed-search-print-entry-function #'nano/elfeed-entry-line-draw)
    (elfeed-search-update :force))
  ;; Top header redundant with bottom modeline (§6b): kill it.
  ;; `elfeed-search-mode' sets buffer-local `header-line-format' via
  ;; `elfeed--header-line-format', so nil it per buffer (hook runs
  ;; after mode body) + neuter the generator for fresh buffers.
  ;; Counts/filter/sort/update stay visible in
  ;; `nano-modeline-elfeed-search-mode' below.
  (setq elfeed-search-header-function #'ignore)
  (add-hook 'elfeed-search-mode-hook #'nano/elfeed-kill-header-line))
(with-eval-after-load 'elfeed-tree
  (setq elfeed-tree-header-function #'ignore)
  (add-hook 'elfeed-tree-mode-hook #'nano/elfeed-kill-header-line))

;; Bottom modeline (§6b bar) sort indicator — overrides vendored
;; `nano-modeline-elfeed-search-mode' (nano-modeline.el:123) which
;; shows no sort state.  Sole sort/counts/filter/update display now
;; top header is gone (above).
(with-eval-after-load 'nano-modeline
  (defun nano-modeline-elfeed-search-mode ()
    (nano-modeline-compose (nano-modeline-status)
                           "Elfeed"
                           (concat "(" (nano/elfeed-sort-label) ") "
                                   "(" (elfeed-search--header) ")")
                           "")))

(defun nano/elfeed-kill-header-line ()
  "Nil buffer-local header line (reload-safe named hook fn)."
  (setq-local header-line-format nil))

(with-eval-after-load 'evil
  (with-eval-after-load 'elfeed-search
    ;; SPC = leader (user choice).  Collection binds no SPC here (§23a0
    ;; disables scroll-down/up), but bind explicitly so future upstream
    ;; SPC additions can't shadow it.
    ;; Spacemacs search extras (`elfeed/packages.el:34-42').
    (nano/elfeed-search-keys)))

;; 23a2. Split entry view — RET keeps search visible (Spacemacs parity).
;;      Built-in `display-buffer' right split, no popwin dep.
;;      `elfeed-show-entry' routes through `elfeed-show-entry-switch',
;;      so RET (`elfeed-search-show-entry') lands in the split.
(defun nano/elfeed-show-split (buff)
  "Display entry BUFF in right split, keeping *elfeed-search* visible."
  (let ((win (display-buffer-in-direction buff '((direction . right)))))
    (when (window-live-p win)
      (select-window win))))

(defun nano/elfeed-show-quit ()
  "Kill entry buffer, delete its window, refocus search.
Single-window frame keeps its window (bury instead of delete)."
  (interactive)
  (let ((search (get-buffer "*elfeed-search*"))
        (win (selected-window)))
    (kill-buffer (current-buffer))
    (when (and (window-live-p win)
               (> (count-windows) 1)
               (not (window-minibuffer-p win)))
      (delete-window win))
    (when-let ((swin (get-buffer-window search)))
      (select-window swin))))

(with-eval-after-load 'elfeed-show
  (setq elfeed-show-entry-switch #'nano/elfeed-show-split
        elfeed-show-entry-delete #'nano/elfeed-show-quit))

(with-eval-after-load 'evil
  (with-eval-after-load 'elfeed-show
    (nano/elfeed-show-keys)
    ;; Goodies ace-link (`packages.el:60-61'), after show map exists.
    (with-eval-after-load 'elfeed-goodies
      (evil-define-key 'normal elfeed-show-mode-map
        "o" #'elfeed-goodies/show-ace-link))))

;; 23b. ttrss via elfeed-protocol — hardcoded per user choice.
;;      Setqs cheap at startup; enable lazy but guaranteed on first use.
;;      Old nested with-eval-after-load elfeed+protocol never fired —
;;      nothing ever loaded elfeed-protocol, so fetcher hook missing
;;      and ttrss+ URLs fell through to plain HTTP (empty buffer).
;;      Secret lives in gitignored var/ttrss-pass (chmod 600),
;;      injected via :password-file — never in repo.
(setq elfeed-protocol-ttrss-maxsize 200)
(setq elfeed-protocol-ttrss-fetch-category-as-tag t)
(setq elfeed-feeds `(("ttrss+http://admin@grex-bravo:181"
                      :password-file ,(locate-user-emacs-file "var/ttrss-pass"))))

(defun nano/elfeed-protocol-ensure ()
  "Load + enable elfeed-protocol once, lazily on first elfeed use.
Idempotent: skips when `elfeed-protocol-fetcher' already hooked."
  (when (boundp 'elfeed-fetch-functions)
    (unless (memq #'elfeed-protocol-fetcher elfeed-fetch-functions)
      (require 'elfeed-protocol nil t)
      (when (fboundp 'elfeed-protocol-enable)
        (elfeed-protocol-enable)))))

(with-eval-after-load 'elfeed
  (nano/elfeed-protocol-ensure))
(add-hook 'elfeed-update-init-hook #'nano/elfeed-protocol-ensure)

;; Trim password-file content (upstream keeps trailing newline).
;; `string-trim' from subr-x (§7).  Guards editors adding newline.
(with-eval-after-load 'elfeed-protocol-common
  (advice-add 'elfeed-protocol-get-string-from-file
              :filter-return #'string-trim))

;; 23c. ttrss read/star/publish sync for existing entries.
;;      Protocol only reconciles headlines returned during update (new
;;      ids); state changed elsewhere never reaches downloaded entries.
;;      Auto hook after each update (Spacemacs parity) + manual command.
;;      Own `nano/' prefix avoids collision with upstream
;;      `elfeed-protocol-ttrss--*' internals.  Upstream `--parse-entries'
;;      call guarded by `fboundp'.
(with-eval-after-load 'elfeed-protocol
  (require 'cl-lib)
  (defun nano/elfeed-ttrss-existing-ids (host-url)
    "Return ttrss article ids of existing local elfeed entries.
HOST-URL is the ttrss host."
    (let* ((proto-id (elfeed-protocol-ttrss-id host-url))
           (seen (make-hash-table :test 'equal))
           (ids nil))
      (elfeed-db-visit (entry)
        (when (equal (elfeed-protocol-entry-protocol-id entry) proto-id)
          (let ((id (elfeed-meta entry :id)))
            (when (and id (not (gethash id seen)))
              (puthash id t seen)
              (push id ids)))))
      (nreverse ids)))

  (defun nano/elfeed-ttrss-sync-state-batch (host-url ids batches)
    "Sync state for one IDS chunk, then recurse on BATCHES."
    (if (not (fboundp 'elfeed-protocol-ttrss--parse-entries))
        (elfeed-log 'warn "nano/elfeed-ttrss: upstream parse-entries missing, aborting sync")
      (let* ((data-list `(("op" . "getArticle")
                          ("sid" . ,elfeed-protocol-ttrss-sid)
                          ("article_id" .
                           ,(apply #'elfeed-protocol-join-ids-to-str "," ids)))))
        (elfeed-protocol-ttrss-with-fetch
          host-url "POST" (json-encode-alist data-list)
          (elfeed-protocol-ttrss--parse-entries host-url content nil 'update)
          (if batches
              (funcall #'nano/elfeed-ttrss-sync-state-batch
                       host-url (car batches) (cdr batches))
            (elfeed-log 'debug "nano/elfeed-ttrss: existing state sync done"))))))

  (defun nano/elfeed-ttrss-split-ids (ids size)
    "Split integer list IDS into sublists of at most SIZE elements."
    (let ((result nil))
      (while ids
        (push (cl-subseq ids 0 (min size (length ids))) result)
        (setq ids (nthcdr size ids)))
      (nreverse result)))

  (defun nano/elfeed-ttrss-sync-read-state (host-url)
    "Sync read/unread/star/publish state for existing elfeed entries.
HOST-URL is ttrss host or protocol feed url."
    (interactive (list (elfeed-protocol-url
                        (completing-read "Protocol Feed: " (elfeed-protocol-feed-list)))))
    (let* ((host-url (elfeed-protocol-host-url host-url))
           (proto-id (elfeed-protocol-ttrss-id host-url)))
      (elfeed-protocol-ttrss-fetch-prepare
        host-url
        (let* ((ids (nano/elfeed-ttrss-existing-ids host-url))
               (batches (nano/elfeed-ttrss-split-ids ids 200)))
          (when ids
            (elfeed-log 'debug
                        "nano/elfeed-ttrss: syncing state of %d existing entries (in %d batches)"
                        (length ids) (length batches))
            (funcall #'nano/elfeed-ttrss-sync-state-batch
                     host-url (car batches) (cdr batches)))))))

  (defun nano/elfeed-ttrss-sync-read-state-hook (feed-url)
    "Sync existing-entry state after ttrss update.  For `elfeed-update-hooks'.
Feed-url is the protocol feed (\"ttrss+host\"): strip prefix first —
upstream passes it verbatim, and `elfeed-protocol-ttrss-id' prepends
unconditionally, so a raw use yields a doubled id and silently skips."
    (let* ((host (elfeed-protocol-url feed-url))
           (proto-id (and host (ignore-errors (elfeed-protocol-ttrss-id host)))))
      (when (and host proto-id
                 (ignore-errors (elfeed-protocol-meta-feed proto-id)))
        (ignore-errors (nano/elfeed-ttrss-sync-read-state host))))))

(add-hook 'elfeed-update-hooks #'nano/elfeed-ttrss-sync-read-state-hook)

;; 23d. Late-arriving ttrss entries redraw search (single `g r').
;;      `elfeed-protocol-fetcher' (elfeed-protocol.el) calls its `cb'
;;      synchronously, so `elfeed--update-feed' runs `elfeed-update-hook'
;;      BEFORE the async ttrss HTTP chain (`fetch-prepare -> login ->
;;      feed-list -> do-update -> parse-entries -> elfeed-db-add')
;;      lands.  The debounced redraw then shows the stale DB, and only
;;      the next `g r' (via `elfeed-update-init-hook' force) reveals the
;;      new posts.  The §23c state-sync batch (getArticle after update)
;;      never fires any update hook either.  Fix: redraw on every DB
;;      commit instead — covers main fetch + sync batch.  Debounce
;;      (1s `elfeed-search-update-delay') coalesces multi-batch adds;
;;      nil-safe when *elfeed-search* absent.
(with-eval-after-load 'elfeed-search
  (add-hook 'elfeed-db-update-hook #'elfeed-search--update-debounce))

;; ---------------------------------------------------------------------
;; §24  Select  (expand-region, SPC v, lazy)
;; ---------------------------------------------------------------------
;; Spacemacs `SPC v' parity: `er/expand-region' + repeat
;; (`v' expand, `V' contract, `r' reset, `ESC' quit).
;; Zero startup cost: no `require', straight autoloads only.
;; Leader already in normal/visual/motion (§4), so SPC v works there.
(straight-use-package 'expand-region)

;; Spacemacs fast keys (spacemacs-editing/packages.el:202-203).
(setq expand-region-contract-fast-key "V"
      expand-region-reset-fast-key "r")

(define-key spacemacs-leader-map (kbd "v") 'er/expand-region)
(which-key-add-key-based-replacements "SPC v" "expand region")

;; ---------------------------------------------------------------------
;; §25  Keepass  (keepass-mode, .kdbx open, evilified parity)
;; ---------------------------------------------------------------------
;; Spacemacs parity: `~/.spacemacs:162' lists `keepass-mode' in
;; `dotspacemacs-additional-packages', `:683' sets
;; `(evil-set-initial-state 'keepass-mode 'evilified)' — no layer,
;; no config.  Same here, minimal.
;; Deps: external `keepassxc-cli' binary (already /usr/bin), master
;; password prompted per open (`keepass-mode-ask-password').
;; Zero startup cost: no `require', straight autoloads only.
;; `auto-mode-alist' set here: upstream adds it top-level
;; (keepass-mode.el:116-117) which only runs on load, so without
;; this `.kdbx' would not trigger the mode on first open.
(straight-use-package '(keepass-mode :type git :host github :repo "ifosch/keepass-mode"))

(add-to-list 'auto-mode-alist '("\\.kdbx\\'" . keepass-mode))
(add-to-list 'auto-mode-alist '("\\.kdb\\'" . keepass-mode))

;; Evilified = motion state + native keys re-bound over evil shadows.
;; No evilified state in vanilla evil, so motion is the closest:
;; read-only list like Buffer-menu-mode (evil default motion family),
;; j/k/gg/G/C-u/C-d free, SPC leader available.  Native keepass keys
;; shadowed by motion (`b' = backward-word, `RET' = evil-ret) are
;; re-bound explicitly via `evil-define-key', buffer-local to
;; `keepass-mode-map'.  `u'/`c' are free in motion but bound anyway
;; so a future state switch can't regress them.  Seed both now (evil
;; loaded) and after keepass-mode loads (load-order race, same pattern
;; as org-agenda at §18d); hook fallback covers session-restore buffers
;; still stuck in emacs.
(with-eval-after-load 'evil
  (evil-set-initial-state 'keepass-mode 'motion))
(with-eval-after-load 'keepass-mode
  (with-eval-after-load 'evil
    (evil-set-initial-state 'keepass-mode 'motion)
    (evil-define-key '(normal visual motion) keepass-mode-map
      (kbd "SPC") spacemacs-leader-map)
    (evil-define-key 'motion keepass-mode-map
      (kbd "RET") 'keepass-mode-select
      (kbd "<backspace>") 'keepass-mode-back
      (kbd "DEL") 'keepass-mode-back
      "u" 'keepass-mode-copy-url
      "b" 'keepass-mode-copy-username
      "c" 'keepass-mode-copy-password)))
(add-hook 'keepass-mode-hook
          (lambda ()
            (when (and (bound-and-true-p evil-mode)
                       (eq evil-state 'emacs))
              (evil-motion-state 1))))

;; ---------------------------------------------------------------------
;; §26  Animal Spirit  (local autoload, SPC a a, lazy)
;; ---------------------------------------------------------------------
;; Spacemacs parity: `~/.spacemacs:158-160' adds `animal-spirit' via
;; `:fetcher file :path ~/animalspirit/emacs', `:690' binds `aa' plus
;; `(autoload 'animal-spirit "animal-spirit")'.  Same here, minimal.
;; Lightest path: `load-path' + `autoload', no straight clone (local
;; live edits apply instantly, survives `straight-pull-all').
;; Deps: built-in `transient' only (`animal-spirit.el:12').  No `require':
;; file provides `'animalspirit' (no hyphen), so require by filename fails.
;; Buffer sets `evil-normal-state' itself; SPC falls through to leader.
(add-to-list 'load-path (expand-file-name "~/animalspirit/emacs"))
(autoload 'animal-spirit "animal-spirit" nil t)

(define-key spacemacs-leader-map (kbd "a a") 'animal-spirit)
(which-key-add-key-based-replacements "SPC a a" "animal spirit")


;; ---------------------------------------------------------------------
;; §27  OpenCode v2  (jdormit/emacs-opencode, SPC a c, lazy)
;; ---------------------------------------------------------------------
;; Emacs client for OpenCode 2 (https://opencode.ai).  Talks to the
;; shared background service (`opencode service start'): one connection
;; + SSE event stream for all projects, auto-discovered/authenticated
;; from `~/.local/state/opencode/service.json'.  Requirements: Emacs
;; 29+, `opencode' binary on PATH, `request' from MELPA (the repo ships
;; no Package-Requires header, so it is installed explicitly below; the
;; client requires it) and `curl' on PATH for SSE streaming.
;;
;; Lazy, zero startup cost: no `require'; straight generates autoloads
;; from the repo's ;;;###autoload cookies, so every bound command
;; resolves before the package loads.  Exception: `SPC a c m' (mcp
;; list) shells out locally instead of autoloading — the package's
;; `opencode-mcp-status' is just `opencode mcp list' via
;; `async-shell-command', and autoloading it would load the whole
;; client.  First `SPC a c' press loads the package (plus `request'),
;; then nothing.
;;
;; Parity note vs the old sczi/opencode.el — no equivalent in this
;; package (verified against the vendored source): idle/last-notified
;; session jump (old `SPC a c i'/`l'), the Sessions panel and its `,'
;; map, share/unshare, message delete/revert, yank-code-block and
;; copy-conversation.  History selection is `opencode-open-session'
;; only.
;;
;; Default model: new sessions start on `nano/opencode-default-model'
;; (27d), handed straight to the create call by the advice.  It is
;; captured LEXICALLY, never in a dynamic variable: the first create of
;; an Emacs session resolves agents asynchronously, so a let-binding
;; around `opencode--create-session' is already unwound by then and a
;; dynamic flag injects nothing (header shows no model).
;;
;; §27d–h ride on the v2 API and are wired in ONE
;; `with-eval-after-load 'emacs-opencode' block below 27h: the package
;; provides `emacs-opencode', and nothing ever provides a bare `opencode'
;; feature, so `with-eval-after-load 'opencode' is a dead letter.
;;
;; Session buffers (`opencode-session-mode', text-mode derived, named
;; `*OpenCode: title*') render the package's own buffer-local
;; header-line on top: `title [agent] ⠹ … provider/model [variant]
;; tokens ctx% ($cost)'.  §6b moved nano's bar to `mode-line-format'
;; (bottom) and nils the default `header-line-format', so the package
;; header is ADDITIVE in these buffers: top line is the package's,
;; nano's bottom bar is unaffected.  (Unlike the old §27c, which
;; replaced the top bar — its branch/MCP segments are gone; MCP list
;; via `SPC a c m'.)  §6b's proc slot stays empty here: the package
;; sets no `mode-line-process'.
;;
;; Curated `,' / `SPC m' menus ride on §16 infra; the package's own C-c
;; map (C-c C-c send, C-c C-k interrupt, C-c C-a/-l/-v agent/model/
;; variant, C-c C-o slash command, C-c C-t reasoning, C-c C-f fork,
;; C-c C-x compact, TAB agent cycle) stays intact and shows in
;; which-key.  Point edits: transcript is editable; self-insert/yank/
;; delete redirect into the input area at the end.

(straight-use-package 'request)
(straight-use-package
 '(emacs-opencode :type git :host github :repo "jdormit/emacs-opencode"))

;; 27a0. Locate the CLI.  The official installer drops the binary in
;; ~/.opencode/bin, which is on PATH only for login shells; a GUI Emacs
;; started from a desktop session never sees it, so starting the server
;; and `SPC a c m' would fail with "opencode: command not found".
;; Prepended (not replacing) so a system-wide install still wins.
;; Reload-safe: the check is a no-op once the entry is present.
(defun nano/opencode-ensure-exec-path ()
  "Add OpenCode's install dir to `exec-path' and $PATH when present."
  (let ((dir (expand-file-name "~/.opencode/bin")))
    (when (and (file-directory-p dir)
               (not (member dir exec-path)))
      (setq exec-path (cons dir exec-path))
      (setenv "PATH" (concat dir path-separator (getenv "PATH"))))))
(nano/opencode-ensure-exec-path)

(defun nano/opencode-mcp-status ()
  "List OpenCode MCP connections via the CLI, without loading the package.
Mirrors the package's `opencode-mcp-status' (`opencode mcp list' via
`async-shell-command').  Honors `opencode-server-command' only when the
package is already loaded; defaulting to \"opencode\" avoids pulling in
the whole client for a shell-out."
  (interactive)
  (async-shell-command
   (format "%s mcp list"
           (executable-find (if (boundp 'opencode-server-command)
                                opencode-server-command
                              "opencode")))))

;; 27a. Global commands  (SPC a c).
;; `opencode' / `opencode-open-session' default to the project root and
;; prompt only with C-u.  Context commands use the active region, else
;; the 10 lines around point.
(define-key spacemacs-leader-map (kbd "a c n") 'opencode)
(define-key spacemacs-leader-map (kbd "a c o") 'opencode-open-session)
(define-key spacemacs-leader-map (kbd "a c a") 'opencode-ask)
(define-key spacemacs-leader-map (kbd "a c A") 'opencode-ask-contextual)
(define-key spacemacs-leader-map (kbd "a c s") 'opencode-send-to-session)
(define-key spacemacs-leader-map (kbd "a c S") 'opencode-send-context-to-session)
(define-key spacemacs-leader-map (kbd "a c m") 'nano/opencode-mcp-status)
(define-key spacemacs-leader-map (kbd "a c x") 'opencode-disconnect)
(define-key spacemacs-leader-map (kbd "a c R") 'opencode-restart)
(which-key-add-key-based-replacements
  "SPC a c" "opencode"
  "SPC a c n" "new session"
  "SPC a c o" "open session"
  "SPC a c a" "ask (new session)"
  "SPC a c A" "ask with context"
  "SPC a c s" "send to session"
  "SPC a c S" "send context to session"
  "SPC a c m" "mcp list"
  "SPC a c x" "disconnect"
  "SPC a c R" "restart service")

;; 27b. Curated `,' / `SPC m' menu — session buffer.
;; Groups: s session / a agent / m model / g git (magit).
;; Leaves are defined once the package is loaded — guaranteed in
;; `opencode-session-mode' buffers.  Magit leaves (27c) load their
;; module on first press.  No `c context' group: the package's only
;; context command (`opencode-send-context-to-session') captures the
;; snippet in the buffer it is called FROM, then re-prompts for a
;; directory + session — from a session buffer that means transcript
;; context and a double prompt.  Use the global `SPC a c S' from a
;; source buffer instead.
(nano/declare-major-prefix 'opencode-session-mode "s" "session")
(nano/declare-major-prefix 'opencode-session-mode "a" "agent")
(nano/declare-major-prefix 'opencode-session-mode "m" "model")
(nano/declare-major-prefix 'opencode-session-mode "g" "git")
(nano/set-leader-keys-for-major-mode 'opencode-session-mode
                                     "sn" 'opencode
                                     "so" 'opencode-open-session
                                     "sr" 'opencode-session-rename
                                     "sf" 'opencode-session-fork
                                     "sc" 'opencode-session-compact
                                     "sp" 'opencode-session-connect-provider
                                     "aa" 'opencode-session-select-agent
                                     "an" 'opencode-session-next-agent
                                     "ap" 'opencode-session-previous-agent
                                     "ar" 'opencode-session-refresh-agents
                                     "mm" 'opencode-session-select-model
                                     "mv" 'opencode-session-select-variant
                                     "m]" 'opencode-session-next-variant
                                     "m[" 'opencode-session-previous-variant
                                     "m0" 'opencode-session-clear-variant
                                     "go" 'opencode-magit
                                     "gs" 'opencode-magit-status
                                     "gd" 'opencode-magit-session-diff
                                     "gt" 'opencode-magit-turn-diff
                                     "i"  'opencode-command
                                     "t"  'opencode-session-toggle-reasoning
                                     "b"  'opencode-session-background
                                     "x"  'opencode-session-interrupt)
;; Reload-safe: the curated map survives `SPC f e r', so the removed
;; `cs' leaf and `c' prefix must be unbound here or stale keys linger.
(define-key (nano/major-mode-leader-map 'opencode-session-mode) (kbd "cs") nil)
(define-key (nano/major-mode-leader-map 'opencode-session-mode) (kbd "c") nil)

(which-key-add-keymap-based-replacements
  (nano/major-mode-leader-map 'opencode-session-mode)
  "sn" "new session" "so" "open session"
  "sr" "rename" "sf" "fork (at point)"
  "sc" "compact" "sp" "provider sign-in"
  "aa" "select agent" "an" "next agent"
  "ap" "previous agent" "ar" "refresh agents"
  "mm" "select model" "mv" "select variant"
  "m]" "next variant" "m[" "previous variant"
  "m0" "clear variant"
  "go" "changed worktrees" "gs" "magit status"
  "gd" "session diff" "gt" "turn diff"
  "i" "slash command" "t" "toggle thinking"
  "b" "background work" "x" "interrupt")

(defun nano/opencode-setup-major-leader ()
  "Activate curated `,' / `SPC m' map in opencode session buffers."
  (nano/activate-major-leader-locally 'opencode-session-mode))
(add-hook 'opencode-session-mode-hook #'nano/opencode-setup-major-leader)

;; 27b2. Session buffers start in insert state (§29 shell/eshell/term
;; precedent): the point is the editable input area at the end, and the
;; package's self-insert/yank/delete redirects only fire in insert.
;; Transcript navigation stays reachable via ESC normal state.
(with-eval-after-load 'evil
  (evil-set-initial-state 'opencode-session-mode 'insert))

;; 27c. Magit review — lazy.  `opencode-magit*' autoloads load
;; `emacs-opencode-magit' (requires magit) on first `, g' press, which
;; also binds its commands under C-c C-d in `opencode-session-mode-map'
;; (overview ret / status s / diff d / session diff a / turn diff t).

;; 27d. Default model for new sessions = `nano/opencode-default-model'.
;; `opencode--create-session' is the single funnel for interactive
;; creation (`SPC a c n', `a', `A'); it passes only `:agent', so the
;; server picks its own default.  Two advices thread the model through:
;; `opencode--create-session' let-binds a flag (which keeps the batch
;; runner `opencode-run' and its `opencode-client-session-create' call
;; untouched), and `opencode-client-session-create' fills in `:model'
;; when the caller did not pass one.  The alist keys match the server
;; API (`providerID' / `id'), and the reply's model flows back through
;; `opencode-session--update-session' into the session header.
(defcustom nano/opencode-default-model "opencode-go/glm-5.3-flash"
  "Model new OpenCode sessions start on, as \"provider/model\".
Empty or malformed means no injection, and the server default wins."
  :type 'string
  :group 'nano)

(defun nano/opencode--model-ref (spec)
  "Turn \"provider/model\" SPEC into the model alist the client sends.
Nil when SPEC is empty or malformed."
  (and (stringp spec)
       (string-match "\\`\\([^/]+\\)/\\([^/]+\\)\\'" spec)
       `((providerID . ,(match-string 1 spec))
         (id . ,(match-string 2 spec)))))

(defun nano/opencode--create-session-advice (orig connection on-created)
  "Create a session on CONNECTION on the 27d default model.
ORIG is `opencode--create-session'; CONNECTION and ON-CREATED pass
through unchanged.  The package funnels interactive creation through
ORIG, which passes only `:agent', so the server default would win.

The model is captured in the continuation rather than a dynamic
variable on purpose: ORIG hands the create call to
`opencode-session--ensure-agents', which answers ASYNCHRONOUSLY on the
first session of a session (empty agent cache), i.e. after any
let-binding around ORIG has been unwound.  That is exactly the bug
where the session header shows no model.  A lexical capture survives
that hop.
Falling back to ORIG when the setting is empty or malformed keeps the
server default as the documented escape hatch."
  (let ((model (nano/opencode--model-ref nano/opencode-default-model)))
    (if (null model)
        (funcall orig connection on-created)
      (opencode-session--ensure-agents
       connection
       (lambda (agents)
         (opencode-client-session-create
          connection
          :agent (car (member opencode-session-default-agent agents))
          :model model
          :success (lambda (&rest args)
                     (funcall on-created
                              (opencode--session-from-data
                               (plist-get args :data))))
          :error (lambda (&rest args)
                   (let ((detail (opencode-client-format-error args)))
                     (error "Failed to create OpenCode session%s"
                            (if detail (format " (%s)" detail) ""))))))))))

;; 27e. Cursor following is the package's own job.  The session buffer
;; is `text-mode' derived (no comint anywhere in this package), and the
;; renderer keeps tail windows pinned while streaming: it records
;; `follow-bottom' per window (window end at `point-max' and point past
;; the input start marker) in
;; `opencode-session--message-render-window-states' and restores it
;; after re-render.  Nothing to add; `C-c C-l' stays
;; `opencode-session-select-model', as the package binds it.

;; 27f. Permission gate: prompt in the session buffer, dunst notice
;; otherwise.  In this package every prompt path funnels through
;; `opencode-session--handle-permission-asked' -> `--defer-prompt' (a
;; zero-second timer that runs the prompt thunk inside the target
;; session buffer) -> `--prompt-permission' (a plain `completing-read').
;; The timer does not care where the user is looking, so a request
;; arriving while another buffer is selected used to steal the
;; minibuffer.  Advising `--prompt-permission' covers the arrival timer,
;; the re-prompt after reconnect (`--prompt-pending-requests') and our
;; own re-offer (27h) in one place.
;;
;; While the session buffer is the selected window the prompt opens as
;; usual and no notification fires.  Otherwise the request is parked in
;; `nano/opencode--pending' (27h) and dunst carries it; this box runs
;; dunst, which owns `org.freedesktop.Notifications'.  Clicking the
;; notification raises the session buffer and re-offers the prompt.  Each
;; request id notifies once.  Note that quitting the prompt with `C-g'
;; DENIES the request here (the package replies "reject" on quit); a
;; request is only recoverable while it is still parked.
(defcustom nano/opencode-notify-timeout 15000
  "Milliseconds an OpenCode notification stays on screen."
  :type 'integer
  :group 'nano)

(defvar nano/opencode--pending (make-hash-table :test #'equal)
  "Permission requests parked while their session buffer lacked focus.
Maps request id -> (permission connection state), as passed to
`opencode-session--prompt-permission'.")

(defvar nano/opencode--notified (make-hash-table :test #'equal)
  "Permission request ids already announced, to notify each once.
Cleared once nothing is pending any more (27h).")

(defun nano/opencode--session-buffer (session-id)
  "Return the live buffer for SESSION-ID, or nil."
  (when-let* ((buffer (and (stringp session-id)
                           (gethash session-id opencode-session--buffers))))
    (and (buffer-live-p buffer) buffer)))

(defun nano/opencode--notification-daemon-p ()
  "Return non-nil when a notification daemon owns the session bus name.
Probing first keeps `notifications-notify' from signalling on a box
with no desktop; the echo-area fallback then carries the message."
  (condition-case nil
      (progn
        (require 'dbus)
        (member "org.freedesktop.Notifications"
                (dbus-call-method :session
                                  "org.freedesktop.DBus"
                                  "/org/freedesktop/DBus"
                                  "org.freedesktop.DBus"
                                  "ListNames")))
    (error nil)))

(defun nano/opencode--raise-buffer (buffer)
  "Show live BUFFER in Emacs and give the frame input focus."
  (when (buffer-live-p buffer)
    (select-frame-set-input-focus (selected-frame))
    (pop-to-buffer buffer)
    buffer))

(defun nano/opencode--notify (title body urgency &optional buffer)
  "Show TITLE and BODY as a desktop notification, never signalling.
URGENCY is a `notifications-notify' urgency.  BUFFER, when given, is
raised in Emacs when the notification's default action fires (on this
box: middle click; see dunstrc's `mouse_middle_click = do_action').
Falls back to the echo area when dunst is not on the bus."
  (let ((shown
         (and (nano/opencode--notification-daemon-p)
              (condition-case nil
                  (progn
                    (require 'notifications nil t)
                    (when (fboundp 'notifications-notify)
                      (notifications-notify
                       :title title
                       :body body
                       :urgency urgency
                       :timeout nano/opencode-notify-timeout
                       :actions (when buffer '("default" "Open session"))
                       :on-action (when buffer
                                    (lambda (&rest _)
                                      (nano/opencode--raise-buffer buffer)
                                      (nano/opencode--reoffer))))))
                (error nil)))))
    (unless shown
      (message "%s -- %s" title body))))

(defun nano/opencode--permission-notify (request-id permission)
  "Announce the permission request REQUEST-ID once, via dunst.
PERMISSION is the request's alist.  Silent for an id already notified,
so the 27h re-offer never announces the same request twice."
  (unless (or (null request-id)
              (gethash request-id nano/opencode--notified))
    (puthash request-id t nano/opencode--notified)
    (nano/opencode--notify
     "OpenCode needs permission"
     (concat
      (opencode-session--permission-prompt-label permission)
      "\nRespond in Emacs: Allow once / Allow always / Deny")
     'critical
     (nano/opencode--session-buffer
      (alist-get 'sessionID permission)))))

(defun nano/opencode--prompt-permission-advice (orig permission connection state)
  "Prompt for PERMISSION only when its buffer is the one being read.
ORIG is `opencode-session--prompt-permission'; PERMISSION, CONNECTION
and STATE are its arguments.  The deferred prompt thunk runs inside the
target session buffer, so `current-buffer' is where the prompt would
appear.  Unfocused arrivals are parked for 27h's re-offer and announced
through dunst instead of taking the minibuffer."
  (if (nano/opencode--prompt-wanted-p)
      (progn
        (remhash (alist-get 'id permission) nano/opencode--pending)
        (funcall orig permission connection state))
    (let ((request-id (alist-get 'id permission)))
      (when request-id
        (puthash request-id (list permission connection state)
                 nano/opencode--pending))
      (nano/opencode--permission-notify request-id permission))))

;; 27h. Re-offer parked permission requests when their buffer gets focus.
;; When 27f parked a request, the package's own timer has already fired
;; and will not fire again, so the parked triple has to be offered by
;; hand.  The session buffer's own buffer-local `post-command-hook' is
;; the reliable signal: it is a permanent local in this Emacs (evil and
;; eldoc make it so), so a GLOBAL `add-hook' would write into whichever
;; buffer is current at load time and never reach a session buffer --
;; the hook has to be added per buffer from `opencode-session-mode-hook'
;; (and once for buffers that already exist when init loads).
;;
;; One entry per command: a prompt fires once per visit.  Answering it
;; removes the state through `opencode-session--remove-prompt', which
;; also drops our parked entry and, once nothing is pending anywhere,
;; clears the notified ids so a later request can notify again.  Quitting
;; a re-offered prompt denies the request (package behaviour).
(defvar nano/opencode-prompt-requires-frame-focus nil
  "Non-nil when a prompt also requires Emacs itself to be focused.
Leave nil to prompt whenever the session buffer is the selected window,
which is all a terminal or headless Emacs can report.  Set it to t to
stay quiet while another application has focus.")

(defun nano/opencode--focused-p (buffer)
  "Return non-nil when BUFFER is the selected window's buffer.
Does not insist on `frame-focus-state', which stays nil on a headless
box; see `nano/opencode-prompt-requires-frame-focus'."
  (and (buffer-live-p buffer)
       (eq buffer (window-buffer (selected-window)))
       (or (not nano/opencode-prompt-requires-frame-focus)
           (frame-focus-state (window-frame (selected-window))))))

(defun nano/opencode--prompt-quiet-p ()
  "Return non-nil when now is a bad moment to open a prompt.
The transient check uses `transient-active-prefix' rather than the
`transient--prefix' variable: the variable is deliberately kept as the
last prefix after an exit, so testing it stays true once a prompt has
been dismissed and then silently suppresses every later prompt."
  (or (active-minibuffer-window)
      (and (fboundp 'transient-active-prefix)
           (transient-active-prefix))))

(defun nano/opencode--prompt-wanted-p ()
  "Return non-nil when the current buffer may open a permission prompt.
The deferred prompt thunk runs inside the target session buffer, so
`current-buffer' is where the prompt would appear."
  (and (not (nano/opencode--prompt-quiet-p))
       (nano/opencode--focused-p (current-buffer))))

(defun nano/opencode--reoffer ()
  "Offer one parked permission request, when this buffer may be prompted.
Called from the session buffer's `post-command-hook' and from the
notification's click action.  An entry parked for a session WITHOUT a
buffer (a subagent request, which the package would have shown in any
live session buffer) is offered here as well, matching that fallback."
  (unless (zerop (hash-table-count nano/opencode--pending))
    (when (nano/opencode--prompt-wanted-p)
      (let* ((session-id (and opencode-session--session
                              (opencode-session-id opencode-session--session)))
             (entry (catch 'found
                      (maphash
                       (lambda (request-id triple)
                         (let* ((permission (nth 0 triple))
                                (perm-session (alist-get 'sessionID
                                                         permission)))
                           (when (or (equal perm-session session-id)
                                     (null (nano/opencode--session-buffer
                                            perm-session)))
                             (remhash request-id nano/opencode--pending)
                             (throw 'found triple))))
                       nano/opencode--pending)
                      nil)))
        (when entry
          (apply #'opencode-session--prompt-permission entry))))))

(defun nano/opencode--permission-focus-arm ()
  "Arm the 27h re-offer in the current session buffer."
  (add-hook 'post-command-hook #'nano/opencode--reoffer nil t))

(defun nano/opencode--permission-arm-all ()
  "Arm the 27h re-offer in every live session buffer.
Covers buffers created before init loaded or across a reload; the mode
hook handles new ones."
  (maphash (lambda (_id buffer)
             (when (buffer-live-p buffer)
               (with-current-buffer buffer
                 (nano/opencode--permission-focus-arm))))
           opencode-session--buffers))

(defun nano/opencode--prompt-removed-advice (_state)
  "Drop 27h bookkeeping when the package forgets a prompt STATE.
Called after `opencode-session--remove-prompt', i.e. when a request was
answered here or resolved in another client.  Once no request is parked
any more, forget the notified ids so a fresh request notifies again."
  (when (zerop (hash-table-count nano/opencode--pending))
    (clrhash nano/opencode--notified)))

(defun nano/opencode--api-check ()
  "Warn when a package symbol §27d–h relies on has changed.
Advice on a missing symbol succeeds silently in Emacs 31 and disables a
whole section without a trace -- which is exactly what happened to the
first attempt at 27d–h, written against the deleted v1 API."
  (dolist (sym '(opencode--create-session
                 opencode-client-session-create
                 opencode-session--prompt-permission
                 opencode-session--remove-prompt
                 opencode-session--handle-execution-ended
                 opencode-session--buffer-for-session
                 opencode-session--permission-prompt-label
                 opencode-session-id
                 opencode-session-title
                 opencode-session-info
                 opencode-session--event-data))
    (unless (fboundp sym)
      (display-warning
       'nano (format "emacs-opencode API changed: %s missing" sym))))
  (dolist (var '(opencode-session--buffers
                 opencode-session--subagent-parents))
    (unless (boundp var)
      (display-warning
       'nano (format "emacs-opencode API changed: %s missing" var)))))

;; The one wiring point for §27d–h.  `with-eval-after-load 'opencode' is
;; a dead letter here: the package provides `emacs-opencode', and nothing
;; ever provides the bare `opencode' feature.
(with-eval-after-load 'emacs-opencode
  (nano/opencode--api-check)
  ;; 27d. Default model for interactive creation only.
  (advice-remove 'opencode--create-session
                 #'nano/opencode--create-session-advice)
  (advice-add 'opencode--create-session :around
              #'nano/opencode--create-session-advice)
  ;; Reload-safe: an earlier 27d advised the client call itself.  The
  ;; model is now captured lexically in the create-session advice above,
  ;; so drop that stale advice if a previous init.el installed it.
  (advice-remove 'opencode-client-session-create
                 'nano/opencode--session-create-advice)
  ;; 27f. Permission gate.
  (advice-remove 'opencode-session--prompt-permission
                 #'nano/opencode--prompt-permission-advice)
  (advice-add 'opencode-session--prompt-permission :around
              #'nano/opencode--prompt-permission-advice)
  ;; 27h. Re-offer parked requests.
  (add-hook 'opencode-session-mode-hook #'nano/opencode--permission-focus-arm)
  (nano/opencode--permission-arm-all)
  (advice-remove 'opencode-session--remove-prompt
                 #'nano/opencode--prompt-removed-advice)
  (advice-add 'opencode-session--remove-prompt :after
              #'nano/opencode--prompt-removed-advice)
  ;; 27g. Finish notice.
  (advice-remove 'opencode-session--handle-execution-ended
                 #'nano/opencode--execution-ended-advice)
  (advice-add 'opencode-session--handle-execution-ended :after
              #'nano/opencode--execution-ended-advice))

;; 27g. Finish notice when a turn ends out of sight.
;; The turn boundary in this package is the `session.execution.*' event
;; family: `opencode-session--handle-execution-ended' runs for
;; succeeded, failed and interrupted and is reached through the package's
;; SSE handler registry, so advising it covers every tracked session.
;; (There is no `session.idle' event and no `opencode--handle-message'
;; here -- those were the old v1 package's names.)  Only sessions with a
;; live buffer announce anything: the title comes from that buffer, and
;; sessions Emacs never opened are none of this UI's business.  Skip
;; subagents (their parent aggregates; `opencode-session--subagent-parents'
;; is the registry), skip your own interrupts, and stay quiet while the
;; session buffer is the selected window -- watching the reply arrive is
;; the point; dunst is for when it is not.  Clicking opens the session.
(defun nano/opencode--execution-ended-advice (event data &optional _meta)
  "Notify when EVENT ends a turn that nobody is watching.
DATA is the event payload; the session id and the failure status come
from it.  See 27g's commentary for the skip list."
  (let* ((payload (opencode-session--event-data data))
         (session-id (alist-get 'sessionID payload))
         (buffer (and (stringp session-id)
                      (opencode-session--buffer-for-session session-id))))
    (when (and buffer
               (buffer-live-p buffer)
               (not (equal event "session.execution.interrupted"))
               (null (gethash session-id opencode-session--subagent-parents))
               (not (eq (window-buffer (selected-window)) buffer)))
      (let* ((failed (equal event "session.execution.failed"))
             (title (with-current-buffer buffer
                      (or (and opencode-session--session
                               (or (opencode-session-title
                                    opencode-session--session)
                                   (alist-get 'title
                                              (opencode-session-info
                                               opencode-session--session))))
                          (buffer-name buffer)))))
        (nano/opencode--notify
         (if failed "OpenCode turn failed" "OpenCode turn finished")
         (concat title
                 (if failed
                     "\nThe turn failed; click to open the session."
                   "\nThe turn has finished; click to open the session."))
         (if failed 'critical 'normal)
         buffer)))))

;; ---------------------------------------------------------------------
;; §27i  Session minimap  (SPC a c l, read-only roster)
;; ---------------------------------------------------------------------
;; One line per OpenCode session, refreshed every few seconds while the
;; buffer is on screen, so a wall of agents can be watched at once and
;; the one that needs a human stands out.
;;
;; Status is POLLED, not pushed.  Verified against OpenCode v2.3.0:
;;   - `opencode-client-session-active' (GET /api/session/active) returns
;;     a map of sessionID -> {type:"running"} for every live run, and
;;     empties as runs finish.  It stays empty on 1.x, hence the version
;;     note below.
;;   - `opencode-client-pending-permissions' (GET /api/permission/request)
;;     is LOCATION-SCOPED: one reply covers one project directory, so it
;;     is asked once per distinct session directory and merged.
;; Scope: only sessions with a LIVE Emacs buffer are listed (the package
;; registry `opencode-session--buffers', filtered by `buffer-live-p').
;; The roster is a window switcher for this Emacs, not a server
;; inventory, so a session started from the CLI or another editor stays
;; out of it.  State is still polled from the server, so the rows are
;; accurate for sessions whose buffer exists but is not selected.
;;
;; Layout: exactly three fields - status, name, directory - and every
;; line is capped at `nano/opencode-minimap-width' (80) columns, so the
;; roster reads the same in a narrow side window and a wide frame.
;;
;; Requires OpenCode 2.x: on 1.x `/api/session/active' is always `{}',
;; so every session would read as idle.  `nano/opencode-minimap--check'
;; says so in the echo area instead of lying.
;;
;; Three states, most urgent on top:
;;   needs you   a permission request is parked for that session
;;   working     the session has a running execution
;;   idle        nothing to do
;; RET opens the session by id (no buffer needed), `g' re-polls.

(defcustom nano/opencode-minimap-interval 5
  "Seconds between session-minimap refreshes while it is visible."
  :type 'number
  :group 'nano)

(defcustom nano/opencode-minimap-limit 200
  "Maximum number of sessions fetched before the roster filters them.
Only sessions with a live Emacs buffer are then listed, so this is a
cap on the server reply, not on the visible row count."
  :type 'integer
  :group 'nano)

(defcustom nano/opencode-minimap-width 80
  "Maximum roster line width, in columns.
Three fields share it: status, name, directory.  The directory column
absorbs whatever the other two leave, so the cap always holds."
  :type 'integer
  :group 'nano)

(defconst nano/opencode-minimap-state-width 3
  "Width of the roster's status column (2-char mark plus a space).")

(defconst nano/opencode-minimap-name-width 38
  "Width of the roster's session-name column.")

;; Status faces inherit BUFFER faces (`nano-face-popout'/`salient'/`faded'),
;; never the `nano-face-header-*' bar faces: those are modeline blocks and
;; carry a hardcoded `#fbf8ef' on `#7e7482', which is what painted every
;; roster row near-white on dark grey.  Buffer faces also follow the live
;; theme, so `SPC t n' recolours the roster with everything else.
(defface nano/opencode-minimap-waiting
  '((t :inherit nano-face-popout :weight bold))
  "Face for a session blocked on the user."
  :group 'nano)

(defface nano/opencode-minimap-busy
  '((t :inherit nano-face-salient))
  "Face for a session that is running."
  :group 'nano)

(defface nano/opencode-minimap-idle
  '((t :inherit nano-face-faded))
  "Face for a session with nothing to do."
  :group 'nano)

(defface nano/opencode-minimap-name
  '((t :inherit nano-face-faded))
  "Face for a roster row's name and directory fields."
  :group 'nano)

(defvar nano/opencode-minimap--sessions nil
  "Session alists from the last successful poll.")

(defvar nano/opencode-minimap--busy (make-hash-table :test 'equal)
  "Session ids with a running execution.")

(defvar nano/opencode-minimap--waiting (make-hash-table :test 'equal)
  "Session ids with a pending permission request, to its action.")

(defvar nano/opencode-minimap--timer nil
  "Repeating refresh timer, started on first open.")

(defvar nano/opencode-minimap--in-flight nil
  "Non-nil while a poll is outstanding, so ticks never overlap.")

(defvar nano/opencode-minimap--frame 0
  "Current spinner frame index.")

(defvar nano/opencode-minimap--spin-timer nil
  "Repeating spinner timer, started on first open.")

(defvar-local nano/opencode-minimap--marks nil
  "Markers at each row's state column, as (MARKER . STATE-KEY).
Rebuilt by every redraw; the spinner walks this list to repaint only
the marks, so animation never moves point or scrolls the window.")

(defvar-keymap nano/opencode-minimap-mode-map
  :parent special-mode-map
  "g" #'nano/opencode-minimap-refresh
  "RET" #'nano/opencode-minimap-visit)

(define-derived-mode nano/opencode-minimap-mode special-mode "OC-Roster"
  "Read-only roster of the OpenCode sessions this Emacs has open.
\\<nano/opencode-minimap-mode-map>
\\[nano/opencode-minimap-refresh] re-polls the server;
\\[nano/opencode-minimap-visit] opens the session on the current line."
  (setq truncate-lines t))

(defun nano/opencode-minimap--key (session)
  "Return the table key for SESSION.
`/api/session/active' is a JSON object, and this client interns object
keys into symbols, so the busy table is keyed by symbol while the
permission table is keyed by the plain string id."
  (intern (or (alist-get 'id session) "")))

(defconst nano/opencode-minimap-states
  '((waiting "!!" "needs you")
    (busy    "-"  "working")
    (idle    "."  "idle"))
  "Roster states as (KEY MARK LABEL), most urgent first.
ASCII on purpose: emoji need a colour-emoji font and geometric glyphs
(`●', `▶') need a font that carries them, and neither is guaranteed on
an arbitrary machine.  `!!', `-', `.` exist in every monospace font.

The busy mark is the first frame of `nano/opencode-minimap-spin-frames';
`nano/opencode-minimap--spin' cycles it in place, so a running session
visibly moves while a human scans the list.")

(defconst nano/opencode-minimap-spin-frames
  ["-" "\\" "|" "/"]
  "ASCII spinner frames for a running session.
All four are one character wide, so the live update is a plain
`subst-char-in-region': text properties, buttons and point survive it.")

(defcustom nano/opencode-minimap-spin-interval 0.35
  "Seconds between spinner frames while the roster is visible."
  :type 'number
  :group 'nano)

(defun nano/opencode-minimap--spin-char ()
  "Return the spinner character for the current frame."
  (aref nano/opencode-minimap-spin-frames
        (mod (or nano/opencode-minimap--frame 0)
             (length nano/opencode-minimap-spin-frames))))

(defun nano/opencode-minimap--state (session)
  "Return (KEY MARK LABEL FACE) describing SESSION's state.
A running session's MARK is the live spinner character."
  (let* ((id (alist-get 'id session))
         (busy (gethash (nano/opencode-minimap--key session)
                        nano/opencode-minimap--busy))
         (waiting (gethash id nano/opencode-minimap--waiting)))
    (pcase (cond (waiting 'waiting) (busy 'busy) (t 'idle))
      ('waiting (list 'waiting "!!" "needs you" 'nano/opencode-minimap-waiting))
      ('busy    (list 'busy (nano/opencode-minimap--spin-char)
                      "working" 'nano/opencode-minimap-busy))
      (_        (list 'idle "." "idle" 'nano/opencode-minimap-idle)))))

(defun nano/opencode-minimap--rank (state)
  "Return the sort rank of STATE, urgent first."
  (pcase state ('waiting 0) ('busy 1) (_ 2)))

(defun nano/opencode-minimap--order (a b)
  "Return non-nil when session A sorts before session B.
Urgent states first, then most recently updated."
  (let ((sa (car (nano/opencode-minimap--state a)))
        (sb (car (nano/opencode-minimap--state b))))
    (if (eq sa sb)
        (> (or (alist-get 'updated (alist-get 'time b)) 0)
           (or (alist-get 'updated (alist-get 'time a)) 0))
      (< (nano/opencode-minimap--rank sa)
         (nano/opencode-minimap--rank sb)))))

(defun nano/opencode-minimap--open-p (session)
  "Return non-nil when SESSION has a live Emacs session buffer.
The roster lists what this Emacs has open, so a session that exists on
the server but was never opened here (or whose buffer was killed) is
left out."
  (let ((buffer (and (bound-and-true-p opencode-session--buffers)
                     (gethash (or (alist-get 'id session) "")
                              opencode-session--buffers))))
    (and (bufferp buffer) (buffer-live-p buffer))))

(defun nano/opencode-minimap--directory-width ()
  "Return the columns left for the directory field.
Whatever the status and name columns do not use, minus one separator."
  (max 8 (- nano/opencode-minimap-width
            nano/opencode-minimap-state-width
            nano/opencode-minimap-name-width
            1)))

(defun nano/opencode-minimap--field (text width)
  "Return TEXT truncated to WIDTH columns and padded to fill it."
  (format (format "%%-%ds" width)
          (truncate-string-to-width (or text "") width 0 nil "...")))

(defun nano/opencode-minimap--insert (session)
  "Insert the roster line for SESSION and make it a button.
Exactly three fields - status, name, directory - capped at
`nano/opencode-minimap-width'; trailing padding is trimmed so no line
carries invisible whitespace."
  (let* ((state (nano/opencode-minimap--state session))
         (id (alist-get 'id session))
         (title (or (alist-get 'title session) "(untitled)"))
         (directory (or (alist-get 'directory (alist-get 'location session)) ""))
         (line (string-trim-right
                (concat
                 (nano/opencode-minimap--field (nth 1 state)
                                               nano/opencode-minimap-state-width)
                 (nano/opencode-minimap--field title nano/opencode-minimap-name-width)
                 " "
                 (truncate-string-to-width
                  (abbreviate-file-name directory)
                  (nano/opencode-minimap--directory-width) 0 nil "..."))))
         (start (point)))
    (let ((marker (copy-marker (point))))
      (insert (propertize (substring line 0 nano/opencode-minimap-state-width)
                          'face (nth 3 state))
              (propertize (substring line nano/opencode-minimap-state-width)
                          'face 'nano/opencode-minimap-name)
              "\n")
      (push (cons marker (car state)) nano/opencode-minimap--marks))
    (make-text-button start (save-excursion (goto-char start) (line-end-position))
                      'action #'nano/opencode-minimap--press
                      'session-id id 'directory directory
                      'help-echo (format "%s - RET opens this session"
                                         (nth 2 state)))))

(defun nano/opencode-minimap--redraw (buffer)
  "Render the roster into BUFFER from the cached poll results.
Point is kept on the same session when it was already on a row, so the
5 s refresh and the spinner never yank the cursor away."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (let* ((inhibit-read-only t)
             (at-point (and (button-at (point))
                            (button-get (button-at (point)) 'session-id)))
             (rows (sort (copy-sequence nano/opencode-minimap--sessions)
                         #'nano/opencode-minimap--order)))
        (setq nano/opencode-minimap--marks nil)
        (erase-buffer)
        (if (null rows)
            (insert (propertize "no open sessions - SPC a c n starts one\n"
                                'face 'nano/opencode-minimap-idle))
          (dolist (session rows)
            (nano/opencode-minimap--insert session)))
        (goto-char (point-min))
        (when at-point
          (let ((found nil))
            (while (and (not found) (not (eobp)))
              (if (equal at-point
                         (and (button-at (point))
                              (button-get (button-at (point)) 'session-id)))
                  (setq found t)
                (forward-line 1)))))
        (set-buffer-modified-p nil)))))

(defun nano/opencode-minimap--finish (buffer)
  "Clear the in-flight flag and redraw BUFFER."
  (setq nano/opencode-minimap--in-flight nil)
  (nano/opencode-minimap--redraw buffer))

(defun nano/opencode-minimap--poll-active (connection buffer)
  "Fill the busy table from CONNECTION, then redraw BUFFER."
  (opencode-client-session-active
   connection
   :success
   (lambda (&rest args)
     (clrhash nano/opencode-minimap--busy)
     (dolist (cell (plist-get args :data))
       (when (equal (alist-get 'type (cdr cell)) "running")
         (puthash (car cell) t nano/opencode-minimap--busy)))
     (nano/opencode-minimap--finish buffer))
   :error (lambda (&rest _) (nano/opencode-minimap--finish buffer))))

(defun nano/opencode-minimap--merge-permissions (connection directories done)
  "Ask CONNECTION for pending permissions in each of DIRECTORIES.
Merge the replies into `nano/opencode-minimap--waiting' and call DONE
once every directory answered, right or wrong: a roster that waits on a
broken project would never draw."
  (let* ((seen (delete-dups (delq nil (copy-sequence directories))))
         (left (length seen)))
    (if (zerop left)
        (funcall done)
      (dolist (directory seen)
        (let ((default-directory (file-name-as-directory directory)))
          (opencode-client-pending-permissions
           connection
           :success
           (lambda (&rest args)
             (dolist (permission (plist-get args :data))
               (puthash (alist-get 'sessionID permission)
                        (or (alist-get 'action permission) t)
                        nano/opencode-minimap--waiting))
             (when (zerop (cl-decf left)) (funcall done)))
           :error (lambda (&rest _)
                    (when (zerop (cl-decf left)) (funcall done)))))))))

(defun nano/opencode-minimap--poll (connection buffer sessions)
  "Poll permissions for SESSIONS then activity, and redraw BUFFER."
  (clrhash nano/opencode-minimap--waiting)
  (nano/opencode-minimap--merge-permissions
   connection
   (mapcar (lambda (session)
             (alist-get 'directory (alist-get 'location session)))
           sessions)
   (lambda () (nano/opencode-minimap--poll-active connection buffer))))

(defun nano/opencode-minimap--on-sessions (connection buffer)
  "Redraw BUFFER with CONNECTION's session list, then poll their state."
  (opencode-client-sessions
   connection
   :limit nano/opencode-minimap-limit
   :roots t
   :success (lambda (&rest args)
              (let ((sessions (seq-filter #'nano/opencode-minimap--open-p
                                          (append (plist-get args :data) nil))))
                (setq nano/opencode-minimap--sessions sessions)
                (nano/opencode-minimap--poll connection buffer sessions)))
   :error (lambda (&rest _)
            (nano/opencode-minimap--finish buffer)
            (message "OpenCode minimap: cannot list sessions"))))

(defun nano/opencode-minimap-refresh ()
  "Poll the OpenCode server and redraw the roster in the current buffer."
  (interactive)
  (unless nano/opencode-minimap--in-flight
    (setq nano/opencode-minimap--in-flight t)
    (let ((buffer (current-buffer))
          (directory (if (and default-directory
                              (file-directory-p default-directory))
                         default-directory
                       "~")))
      (condition-case err
          (progn
            (require 'emacs-opencode)
            (opencode-run-server
             directory
             (lambda (connection)
               (nano/opencode-minimap--on-sessions connection buffer))))
        (error
         (nano/opencode-minimap--finish buffer)
         (message "OpenCode minimap: %s" (error-message-string err)))))))

(defun nano/opencode-minimap--press (button)
  "Open BUTTON's session."
  (opencode-open-session-by-id (button-get button 'session-id)
                               (button-get button 'directory)))

(defun nano/opencode-minimap-visit ()
  "Open the session listed on the current line."
  (interactive)
  (if (button-at (point))
      (push-button)
    (user-error "No session on this line")))

(defun nano/opencode-minimap--spin-step (buffer)
  "Advance one spinner frame in BUFFER's roster rows.
Only the one-character state column of running rows is rewritten, via
`subst-char-in-region', so text properties, buttons and point survive
and nothing re-lays out."
  (setq nano/opencode-minimap--frame
        (1+ (or nano/opencode-minimap--frame 0)))
  (let ((char (aref (nano/opencode-minimap--spin-char) 0)))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (dolist (cell nano/opencode-minimap--marks)
          (let ((marker (car cell)))
            (when (and (eq (cdr cell) 'busy)
                       (marker-position marker)
                       (not (eq (char-after marker) char)))
              (subst-char-in-region marker (1+ marker)
                                    (char-after marker) char t))))))))

(defun nano/opencode-minimap--spin ()
  "Advance the spinner when the roster is on screen.
Idle frames cost one `get-buffer-window' call and nothing else."
  (when-let* ((buffer (get-buffer "*OpenCode Roster*")))
    (when (and (buffer-live-p buffer) (get-buffer-window buffer))
      (nano/opencode-minimap--spin-step buffer))))

(defun nano/opencode-minimap--tick ()
  "Refresh the roster when it is visible; stay silent otherwise."
  (when-let* ((buffer (get-buffer "*OpenCode Roster*")))
    (when (and (buffer-live-p buffer) (get-buffer-window buffer))
      (with-current-buffer buffer
        (nano/opencode-minimap-refresh)))))

(defun nano/opencode-minimap--server-version ()
  "Return the OpenCode server version string, or nil when unknown.
`opencode-connection-registration-file' carries it from v2 on; 1.x
registrations have no `version' field at all."
  (when (boundp 'opencode-connection-registration-file)
    (let ((file (opencode-connection-registration-file)))
      (when (file-readable-p file)
        (ignore-errors
          (with-temp-buffer
            (insert-file-contents file)
            (alist-get 'version (json-parse-buffer :object-type 'alist))))))))

(defun nano/opencode-minimap--check ()
  "Warn when the roster cannot tell running sessions apart.
On OpenCode 1.x `/api/session/active' always answers `{}', so every
session would read as idle: a minimap that never lights up is worse
than none.  Returns non-nil when the server is v2 or its version is
unknown (nothing to warn about)."
  (let ((version (nano/opencode-minimap--server-version)))
    (or (null version)
        (not (string-prefix-p "1." version))
        (progn
          (message "OpenCode minimap needs v2: server is %s, so running \
sessions cannot be detected.  Upgrade with `opencode upgrade --major'."
                   version)
          nil))))

;;;###autoload
(defun nano/opencode-minimap ()
  "Show the live roster of every OpenCode session (SPC a c l)."
  (interactive)
  (nano/opencode-minimap--check)
  (let ((buffer (get-buffer-create "*OpenCode Roster*")))
    (with-current-buffer buffer
      (unless (eq major-mode 'nano/opencode-minimap-mode)
        (nano/opencode-minimap-mode)))
    (pop-to-buffer buffer)
    (nano/opencode-minimap-refresh)
    (unless (timerp nano/opencode-minimap--timer)
      (setq nano/opencode-minimap--timer
            (run-with-timer nano/opencode-minimap-interval
                            nano/opencode-minimap-interval
                            #'nano/opencode-minimap--tick)))
    (unless (timerp nano/opencode-minimap--spin-timer)
      (setq nano/opencode-minimap--spin-timer
            (run-with-timer nano/opencode-minimap-spin-interval
                            nano/opencode-minimap-spin-interval
                            #'nano/opencode-minimap--spin)))
    buffer))

(define-key spacemacs-leader-map (kbd "a c l") #'nano/opencode-minimap)
(which-key-add-key-based-replacements "SPC a c l" "session minimap")


;; ---------------------------------------------------------------------
;; §28  Indentation  (global 2 spaces, Python 4)
;; ---------------------------------------------------------------------
;; Spaces everywhere (no TAB chars).  `setq-default' so file-local /
;; mode-local values still win.  Per-mode offsets mirror global 2;
;; Python alone uses 4.  All lazy/guarded: no `require', zero startup
;; cost.  Reload-safe via `SPC f e r'.
(setq-default indent-tabs-mode nil
              tab-width 2
              standard-indent 2)

;; JS / CSS / HTML built-ins (vars autoloaded with their modes).
(setq js-indent-level 2
      js-switch-indent-offset 2
      css-indent-offset 2
      sgml-basic-offset 2)

(with-eval-after-load 'nxml-mode
  (setq nxml-child-indent 2
        nxml-attribute-indent 2))

;; JSON: built-in js-json shares `js-indent-level' above; tree-sitter
;; and external `json-mode' guarded so no error when absent.
(with-eval-after-load 'json-ts-mode
  (when (boundp 'json-ts-mode-indent-offset)
    (setq json-ts-mode-indent-offset 2)))
(with-eval-after-load 'json-mode
  (when (boundp 'json-mode-indent-level)
    (setq json-mode-indent-level 2)))

;; Python exception: 4 spaces, guesser off (else it overrides per file).
(setq python-indent-offset 4
      python-indent-guess-indent-offset nil)
(defun nano/python-set-tab-width ()
  "Use 4-space tabs in Python buffers.  Named for reload safety."
  (setq-local tab-width 4))
(remove-hook 'python-mode-hook #'nano/python-set-tab-width)
(remove-hook 'python-ts-mode-hook #'nano/python-set-tab-width)
(add-hook 'python-mode-hook #'nano/python-set-tab-width)
(add-hook 'python-ts-mode-hook #'nano/python-set-tab-width)


;; ---------------------------------------------------------------------
;; §29  Shell  (builtins, SPC ' + SPC a t, lazy)
;; ---------------------------------------------------------------------
;; Zero-dep: built-in eshell/shell/term/ansi-term + project-eshell only.
;; No vterm/eat/shell-pop (compiler/fetch/split mgmt, add on demand).
;; Plain `switch-to-buffer' open; §6f scratch routing applies (visible
;; *scratch* window receives first open, focus follows).  Shell buffers
;; never persist via desktop (like *scratch*), no handler needed.
;; $SHELL respected (`explicit-shell-file-name' untouched, zsh here).
;; term char mode eats SPC: use C-SPC leader fallback (§4) or C-c C-j
;; line mode.  §2b2 term-sentinel advice already kills term buffer on exit.
;; No `require': all commands autoload.  Reload-safe via `SPC f e r'.
;; Example: `SPC '' eshell here, `SPC p '' eshell at project root.
(with-eval-after-load 'evil
  (evil-set-initial-state 'eshell-mode 'insert)
  (evil-set-initial-state 'shell-mode 'insert)
  (evil-set-initial-state 'term-mode 'insert))

(define-key spacemacs-leader-map (kbd "'") 'eshell)
(define-key spacemacs-leader-map (kbd "a t e") 'eshell)
(define-key spacemacs-leader-map (kbd "a t s") 'shell)
(define-key spacemacs-leader-map (kbd "a t t") 'term)
(define-key spacemacs-leader-map (kbd "a t a") 'ansi-term)
(define-key spacemacs-leader-map (kbd "p '") 'project-eshell)
(which-key-add-key-based-replacements
  "SPC '" "eshell"
  "SPC a t" "shell/terminal"
  "SPC a t e" "eshell"
  "SPC a t s" "shell"
  "SPC a t t" "term"
  "SPC a t a" "ansi-term"
  "SPC p '" "project eshell")

;; ---------------------------------------------------------------------
;; §30  Ghostel  (libghostty terminal, SPC a t g, lazy)
;; ---------------------------------------------------------------------
;; Second terminal backend next to the §29 builtins: a real VT engine
;; (libghostty-vt, the one inside Ghostty) as a native Emacs module --
;; true color, synchronized output, Kitty keyboard/graphics, hyperlinks,
;; OSC 7/133 shell integration injected for bash/zsh/fish, no rc edit.
;; Lazy: `ghostel' is autoloaded, so `SPC a t g' costs nothing until
;; first use; that call loads ghostel.el, which maps the native module.
;; Native module: pre-built libghostty .so, no zig toolchain needed.
;; `ghostel-module-directory' points at var/ghostel/ -- deliberately
;; outside straight's tree.  straight replaces package files on rebuild,
;; and swapping a mapped .so under a running Emacs corrupts its mmap.
;; Installed out-of-band: ghostel-module.so plus the
;; ghostel-module.version sidecar the loader version-checks before
;; mapping.  `M-x ghostel-download-module' re-fetches when the Elisp
;; side raises `ghostel--minimum-module-version'; `M-x
;; ghostel-module-compile' builds from source instead (needs zig 0.17.x).
;; Evil: starts in insert state like §29 shells -- typing reaches the
;; PTY, ESC returns to normal state, SPC (C-SPC fallback, §4) works
;; from there.  `evil-ghostel' (same repo, MELPA) adds vim operators
;; over the PTY; not installed, add if stock evil keys feel wrong.
;; Docs: https://dakra.github.io/ghostel/
(straight-use-package 'ghostel)

(setq ghostel-module-directory
      (expand-file-name "var/ghostel/" user-emacs-directory))

(with-eval-after-load 'evil
  (evil-set-initial-state 'ghostel-mode 'insert))

(define-key spacemacs-leader-map (kbd "a t g") 'ghostel)
(which-key-add-key-based-replacements
  "SPC a t g" "ghostel")

;; ---------------------------------------------------------------------
;; §31  Matrix chat  (alphapapa/ement.el, SPC a m, lazy)
;; ---------------------------------------------------------------------
;; Client: ement.el (GNU ELPA, recipe already in straight's local
;; gnu-elpa-mirror clone -> fetched from github.com/emacs-straight/ement).
;; No package.el (early-init.el), so straight is the only installer.
;; `straight-use-package' below BUILDS at init, like every other §N
;; package here — the first launch after this line is added clones and
;; byte-compiles ement plus its deps (map, persist, taxy,
;; taxy-magit-section, svg-lib; plz and transient were already built),
;; which costs ~30s and needs network ONCE.  What stays lazy is the
;; feature `require': no ement code runs until a SPC a m key is pressed.
;;
;; E2EE: none natively.  Encrypted rooms need either a proxy
;; (bhwdev/ement-e2ee, matrix-sdk-crypto based) or Pantalaimon (archived
;; 2025-06, libolm).  Not installed; plain-text rooms work out of the box.
;;
;; Why the wrappers: only `ement-connect' / `ement-room-list' /
;; `ement-directory' carry `;;;###autoload' cookies; the rest are NOT
;; autoloaded, so a direct `define-key' to them would be void-function
;; until something else loaded ement.  `nano/ement-command' below makes
;; each binding a named command that requires the owning feature first,
;; then calls the real command interactively (keeps `this-command',
;; prefix args, and which-key names).
;;
;; Evil: evil-collection ships modes/ement/ (already cloned here).  Added
;; to `evil-collection-mode-list' so the collection's deferred setup runs
;; on first ement load; §10's `nano/evil-collection-ensure' then covers it
;; like magit/elfeed.  Initial state seeded explicitly to normal for the
;; same reason §10/§23 do it: ement's modes derive from fundamental-mode /
;; magit-section-mode and would otherwise land in emacs state, dead keys.
;; Ement binds SPC to scroll-up-mark-read in `ement-room-mode-map'; the
;; evil state map's SPC (the leader) wins, so SPC opens the leader inside
;; room buffers — scroll with C-d/C-u or S-SPC there.
(straight-use-package 'ement)

;; Login persistence.  Ement keeps ONE thing across restarts: the
;; account's access token (plus user id / homeserver / device id).  The
;; password is never written anywhere — `read-passwd' feeds it straight
;; into the login request, and `ement--login-callback' stores only the
;; token the server hands back.  An access token can be revoked
;; server-side at any time (Element: Settings -> Sessions), so this is a
;; per-device key, not your credentials.
;;
;; BEWARE: `ement-save-sessions' has a `:set' function that installs
;; `ement--kill-emacs-hook'.  A plain `setq' sets the variable but never
;; installs the hook, so the value looks right, nothing is ever written,
;; and you re-login on every restart.  `customize-set-variable' runs the
;; `:set' — but only once ement is LOADED (before that the symbol has no
;; `:set' property, so it silently degrades to a plain set).  Set the
;; value here and add the hook explicitly, so neither the load order nor
;; a `:set' refactor can lose it.
;;
;; Also: `ement--write-sessions' uses `with-temp-file', and its kill hook
;; wraps everything in `ignore-errors' — a missing parent directory fails
;; SILENTLY and costs you the session.  Create the directory up front.
;;
;; Token expires or is revoked -> sync dies with M_UNKNOWN_TOKEN and the
;; saved session is not auto-cleared; re-login with `C-u SPC a m c'
;; (universal prefix forces a fresh login).
(setq ement-sessions-file
      (expand-file-name "var/ement/sessions.el" user-emacs-directory))
(make-directory (file-name-directory ement-sessions-file) t)
;; 0700: the file holds a live access token (ement chmods the file 0600
;; itself, but the directory is ours to set).
(ignore-errors
  (set-file-modes (file-name-directory ement-sessions-file) #o700))
(setq ement-save-sessions t)
(with-eval-after-load 'ement
  (add-hook 'kill-emacs-hook #'ement--kill-emacs-hook))
;; `restart-emacs' goes through `save-buffers-kill-emacs', so SPC q r
;; runs `kill-emacs-hook' like a normal quit; both paths save.

(defmacro nano/ement-command (name feature command docstring)
  "Define NAME as a lazy entry for Ement's COMMAND.
FEATURE is required first.  NAME stays a real named command so
which-key and `describe-key' report something readable."
  (declare (indent 3) (doc-string 4))
  `(defun ,name ()
     ,docstring
     (interactive)
     (require ,feature)
     (call-interactively ,command)))

(nano/ement-command nano/ement-connect 'ement #'ement-connect
  "Connect to Matrix (prompts for account on first use).  SPC a m c.")
(nano/ement-command nano/ement-disconnect 'ement #'ement-disconnect
  "Disconnect from the current Matrix session.  SPC a m x.")
(nano/ement-command nano/ement-kill-buffers 'ement #'ement-kill-buffers
  "Kill every Ement buffer, keeping the connection.  SPC a m k.")
(nano/ement-command nano/ement-room-list 'ement-room-list #'ement-room-list
  "Show the joined-rooms list.  SPC a m l.")
(nano/ement-command nano/ement-view-room 'ement #'ement-view-room
  "Switch to a room buffer, choosing the room.  SPC a m v.")
(nano/ement-command nano/ement-join-room 'ement #'ement-join-room
  "Join a room by ID or alias (\"#alias:server\").  SPC a m j.")
(nano/ement-command nano/ement-direct-message 'ement #'ement-send-direct-message
  "Send a direct message to a user (reuses/creates the DM room).  SPC a m d.")
(nano/ement-command nano/ement-directory 'ement-directory #'ement-directory
  "Browse the public room directory.  SPC a m p.")
(nano/ement-command nano/ement-directory-search 'ement-directory #'ement-directory-search
  "Search the public room directory.  SPC a m s.")
(nano/ement-command nano/ement-mentions 'ement #'ement-notify-switch-to-mentions-buffer
  "Jump to the *Ement Mentions* buffer.  SPC a m m.")
(nano/ement-command nano/ement-notifications 'ement #'ement-notify-switch-to-notifications-buffer
  "Jump to the *Ement Notifications* buffer.  SPC a m n.")

(define-key spacemacs-leader-map (kbd "a m c") 'nano/ement-connect)
(define-key spacemacs-leader-map (kbd "a m x") 'nano/ement-disconnect)
(define-key spacemacs-leader-map (kbd "a m k") 'nano/ement-kill-buffers)
(define-key spacemacs-leader-map (kbd "a m l") 'nano/ement-room-list)
(define-key spacemacs-leader-map (kbd "a m v") 'nano/ement-view-room)
(define-key spacemacs-leader-map (kbd "a m j") 'nano/ement-join-room)
(define-key spacemacs-leader-map (kbd "a m d") 'nano/ement-direct-message)
(define-key spacemacs-leader-map (kbd "a m p") 'nano/ement-directory)
(define-key spacemacs-leader-map (kbd "a m s") 'nano/ement-directory-search)
(define-key spacemacs-leader-map (kbd "a m m") 'nano/ement-mentions)
(define-key spacemacs-leader-map (kbd "a m n") 'nano/ement-notifications)
(which-key-add-key-based-replacements
  "SPC a m" "matrix"
  "SPC a m c" "connect"
  "SPC a m x" "disconnect"
  "SPC a m k" "kill buffers"
  "SPC a m l" "room list"
  "SPC a m v" "view room"
  "SPC a m j" "join room"
  "SPC a m d" "direct message"
  "SPC a m p" "room directory"
  "SPC a m s" "directory search"
  "SPC a m m" "mentions"
  "SPC a m n" "notifications")

;; evil-collection: opt in (one symbol).  Loaded at init time, before the
;; first `nano/evil-collection-ensure' call, so the deferred
;; `with-eval-after-load' for ement is registered in time.
(add-to-list 'evil-collection-mode-list 'ement)

;; §10's ensure only fires on magit/elfeed load; Ement can be the first
;; package touched in a session, so give it its own trigger.  Calling it
;; twice is a no-op (`nano/evil-collection-initialized').
(with-eval-after-load 'ement (nano/evil-collection-ensure))

;; Explicit normal state for ement's modes (see header note).  These
;; derive from fundamental-mode / magit-section-mode, which evil leaves in
;; emacs state, so without this the collection's normal-state bindings are
;; dead on first open.  ement-room buffers are read-only history plus
;; single-key editing verbs, so normal is the right base: j/k/n/p motion,
;; `a' write, `i' edit message (all from evil-collection-ement).
;; Runs at init (evil is already loaded, §3), so it lands before any
;; ement buffer exists and is not undone by the collection's own setup
;; (which never calls `evil-set-initial-state').
(with-eval-after-load 'evil
  (dolist (m '(ement-room-mode ement-notifications-mode
               ement-room-list-mode ement-directory-mode
               ement-describe-room-mode))
    (evil-set-initial-state m 'normal)))

;;; init.el ends here
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(org-agenda-files
   '("/home/ykgoon/Dropbox/org/data.org"
     "/home/ykgoon/Dropbox/org/exocortex.org"
     "/home/ykgoon/Dropbox/org/ideas.org"
     "/home/ykgoon/Dropbox/org/kakitangan.org"
     "/home/ykgoon/Dropbox/org/plays.org"
     "/home/ykgoon/Dropbox/org/read_later.org"
     "/home/ykgoon/Dropbox/org/stories.org"
     "/home/ykgoon/Dropbox/org/tin_shue.org"
     "/home/ykgoon/Dropbox/org/todo.org")))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(put 'erase-buffer 'disabled nil)
