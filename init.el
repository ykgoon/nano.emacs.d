;;; init.el --- nano-emacs via straight.el -*- lexical-binding: t -*-
;;; Commentary:
;; Single-file config for rougier/nano-emacs, managed by straight.el.
;; Launch with: emacs --init-directory ~/nano.emacs.d
;; Restart required after edits (no live reloader).
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
;;   §6  Window management  (winum, header-line, double/triple columns, uniform widths)
;;   §7  Theme toggle + persistence  (SPC T n)
;;   §8  Completion  (built-in icomplete-vertical, helm-like list)
;;   §9  Workspace  (built-in tab-bar, SPC l, name in modeline)
;;   §10 Git  (magit + delta, SPC g)
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
;;   §22  Update  (float latest, SPC f e U pull+rebuild)
;;   §23  Web  (built-in eww + elfeed/ttrss, SPC a w, lazy)
;;   §24  Select  (expand-region, SPC v, lazy)
;;   §25  Keepass  (keepass-mode, .kdbx open, evilified parity)
;;   §26  Animal Spirit  (local autoload, SPC a a, lazy)
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

;; Maximized desktop startup — re-assert after nano-layout.el:22 overwrote alists.
;; early-init.el sets same before first frame (no flicker); this ensures persistence.
;; (add-to-list 'initial-frame-alist '(fullscreen . maximized))
;; (add-to-list 'default-frame-alist '(fullscreen . maximized))
;; Fallback: init.el runs after initial frame creation, so explicitly maximize
;; the live frame (tty/batch ignored, graphic only).
;; (add-hook 'window-setup-hook (lambda () (when (display-graphic-p)
;;                                         (set-frame-parameter nil 'fullscreen 'maximized))))


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
(define-key spacemacs-leader-map (kbd "f r") 'recentf-open-files)
(define-key spacemacs-leader-map (kbd "f D") 'nano/delete-current-buffer-file)
(define-key spacemacs-leader-map (kbd "f R") 'nano/rename-current-buffer-file)
(which-key-add-key-based-replacements
  "SPC f s" "save file"
  "SPC f S" "save all"
  "SPC f D" "delete file"
  "SPC f R" "rename file")

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
Without prefix ARG, prompt starts in current dir; with ARG, full old path.
Creates parent dirs after confirm.  Errors when buffer visits no file."
  (interactive "P")
  (let ((old (buffer-file-name)))
    (unless (and old (file-exists-p old))
      (user-error "Buffer %s visits no file" (buffer-name)))
    (let* ((old-dir (file-name-directory old))
           (old-short (file-name-nondirectory old))
           (path (read-file-name "New name: " (if arg old old-dir)))
           (new (if (string= (file-name-nondirectory path) "")
                    (concat path old-short)
                  path)))
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
(define-key spacemacs-leader-map (kbd "b Y") 'nano/copy-whole-buffer-to-clipboard)
(which-key-add-key-based-replacements
  "SPC TAB" "last buffer"
  "SPC b D" "kill buffers by pattern"
  "SPC b R" "revert buffer"
  "SPC b e" "erase buffer"
  "SPC b s" "scratch buffer"
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
;; SPC w 2 / SPC w 3 (double/triple columns) defined in §6c — kept with its implementation.

;; 5d. Quit / session  (SPC q)
;; SPC q q / SPC q r save + restore file buffers, window splits (§6),
;; tab-bar workspaces (§9), and all frames via built-in desktop-save-mode
;; frameset (var/desktop/).  Quit-only save (`desktop-auto-save-timeout'
;; nil); kill-hook re-save also silent.  Restart keeps --init-directory
;; since builtin `restart-emacs' re-execs same argv.
;; Tab-bar MUST be on BEFORE `desktop-save-mode' reads, else frameset
;; restores without tabs (workspaces lost).
(require 'tab-bar)
(tab-bar-mode 1)
;; NOTE: plain setq on `tab-bar-show' does NOT take effect — custom :set
;; refreshes `tab-bar-lines'.  Full tab-bar config lives in §9; this
;; early hide keeps first frame clean before §9 re-asserts.
(customize-set-variable 'tab-bar-show nil)
(require 'desktop)
(setq desktop-dirname (locate-user-emacs-file "var/desktop")
      desktop-path (list desktop-dirname)
      desktop-save t
      desktop-load-locked-desktop nil
      desktop-restore-eager 10
      desktop-restore-frames t
      desktop-restore-reuses-frames t
      desktop-restore-in-current-display t
      desktop-auto-save-timeout nil)
(make-directory desktop-dirname t)
(desktop-save-mode 1)

(defun nano/desktop-ensure-dir ()
  "Return desktop dir, creating it.  Never nil — avoids `Directory:' prompt.
`desktop-save-in-desktop-dir' falls back to interactive `desktop-save'
when `desktop-dirname' is nil; explicit dir here keeps quit silent."
  (let ((dir (or desktop-dirname (locate-user-emacs-file "var/desktop"))))
    (make-directory dir t)
    (setq desktop-dirname dir)
    dir))

(defun nano/desktop-save-silently ()
  "Non-interactive desktop save.  Never prompts for directory."
  (let ((desktop-save t))
    (desktop-save (nano/desktop-ensure-dir))))

(defun nano/restart-emacs-restore ()
  "Save desktop session, then restart.  Bound to SPC q r."
  (interactive)
  (nano/desktop-save-silently)
  (let ((desktop-save t)) ; kill-hook re-save also silent, no second prompt
    (restart-emacs)))

(defun nano/quit-save-silently ()
  "Save desktop silently, then quit (still prompts for unsaved files).
Bound to SPC q q."
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
;; (args FILENAME BUFNAME MISC, returns live buffer). `org-agenda-list'
;; is autoloaded (built-in org), zero startup cost. Elfeed needs nothing:
;; it already sets `desktop-save-buffer' and restores its entry.
(defun nano/desktop-restore-org-agenda (_file _name _misc)
  "Rebuild agenda buffer for desktop restore.  Returns live buffer."
  (unless (fboundp 'org-agenda-list)
    (require 'org-agenda))
  (when (fboundp 'nano/org-agenda-refresh-files)
    (nano/org-agenda-refresh-files))
  (org-agenda-list)
  (get-buffer org-agenda-buffer-name))
(add-to-list 'desktop-buffer-mode-handlers
             '(org-agenda-mode . nano/desktop-restore-org-agenda))
(with-eval-after-load 'desktop
  (add-hook 'org-agenda-mode-hook
            (lambda () (setq-local desktop-save-buffer t))))

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
;; §6  Window management  (winum, header-line, double/triple columns, uniform widths)
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
;;     Layout: [N] [RO/RW/**] filename (detail) ... position <workspace> %p
;;     Redefines `nano-modeline-compose' (same signature, so every mode
;;     benefits) instead of patching nano source.  Single auto-named tab
;;     tracks the buffer name, which used to render `<init.el> ... init.el'
;;     (workspace + file duplicated); workspace now lives far-right and the
;;     initial tab is named "main" in §9, so no adjacency dup.
(defface nano-face-header-active nil
  "Green highlight for selected window modeline blocks."
  :group 'nano)

(defun nano/apply-modeline-active-face ()
  "Paint `nano-face-header-active' green per theme.  Re-applied after refresh."
  (if (and (boundp 'nano-theme-var) (string= nano-theme-var "light"))
      (set-face-attribute 'nano-face-header-active nil
                          :foreground "#FFFFFF" :background "#2F9E44"
                          :box `(:line-width 1 :color ,nano-color-background :style nil))
    (set-face-attribute 'nano-face-header-active nil
                        :foreground "#2E3440" :background "#A3BE8C"
                        :box `(:line-width 1 :color ,nano-color-background :style nil))))

(nano/apply-modeline-active-face)
(when (fboundp 'nano-refresh-theme)
  (advice-add 'nano-refresh-theme :after #'nano/apply-modeline-active-face))

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

;; Drop the old status-prefix advice on reload; the redefinition below
;; renders winum + workspace as their own blocks instead.
(advice-remove 'nano-modeline-compose 'nano-winum-prefix)

(with-eval-after-load 'nano-modeline
  (defun nano-modeline-compose (status name primary secondary)
    "Spacemacs-block modeline: winum, RO/RW/**, filename, far-right workspace + scroll percent."
    (let* ((char-width    (window-font-width nil 'mode-line))
           (space-up       +0.15)
           (space-down     -0.20)
           (winum (nano/winum-number-string))
           (ws    (nano/workspace-name-string))
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
           (sep (propertize " " 'face 'nano-face-header-default
                            'display `(raise ,space-down)))
           (head (concat
                  (or winum "")
                  sep
                   prefix
                   (propertize (concat " " name " ")
                               'face (if active
                                         'nano-face-header-active
                                       'nano-face-header-strong))
                  (propertize primary 'face 'nano-face-header-default
                              'display `(raise ,space-up))))
            (pct-text (concat " " (nano/modeline-scroll-percent) " "))
            (pct-display (propertize pct-text
                           'face 'nano-face-header-default
                           'display `(raise ,space-up)))
            ;; Literal % must be doubled for mode-line: :eval output is
            ;; %-expanded, so single trailing % in "NN%" gets eaten.
            ;; Escape after width math so filler count uses display width.
            (pct (propertize (string-replace "%" "%%" pct-text)
                           'face 'nano-face-header-default
                           'display `(raise ,space-up)))
            (right (concat secondary
                           (propertize " " 'face 'nano-face-header-default
                                       'display `(raise ,space-down))
                           (or ws "")
                           pct))
            (right-for-width (concat secondary
                                     (propertize " " 'face 'nano-face-header-default
                                                 'display `(raise ,space-down))
                                     (or ws "")
                                     pct-display))
            (available-width (- (window-total-width)
                                (length head) (length right-for-width)
                                (/ (window-right-divider-width) char-width)))
           (available-width (max 1 available-width)))
      (concat head
              (propertize (make-string available-width ?\ )
                          'face 'nano-face-header-default)
              (propertize right 'face `(:inherit nano-face-header-default
                                                 :foreground ,nano-color-faded)))))
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

;; 6c. Double / triple vertical split — SPC w 2 / SPC w 3
;;     (basic SPC w splits live in §5c — this extends that group).
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
          (nano/balance-window-widths))
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
          (nano/balance-window-widths))
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
  "Advice target: rebalance widths after split/delete. Skips minibuffer."
  (unless (window-minibuffer-p (selected-window))
    (nano/balance-window-widths)))

(advice-add 'split-window-right :after #'nano/balance-widths-after-split)
(advice-add 'split-window-below :after #'nano/balance-widths-after-split)
(advice-add 'delete-window :after #'nano/balance-widths-after-split)
(advice-add 'delete-other-windows :after #'nano/balance-widths-after-split)

(define-key spacemacs-leader-map (kbd "w =") 'nano/balance-window-widths)
(which-key-add-key-based-replacements "SPC w =" "balance widths")


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

;; 7b. Trailing whitespace — true red in file buffers, Spacemacs red parity.
;;     Mechanism is NOT theme-only: `show-trailing-whitespace' enables the
;;     highlight, `trailing-whitespace' face colors it.  Nano maps that face
;;     to `nano-face-subtle' (nano-theme.el:124), so override to true red here.
;;     `nano-refresh-theme' re-applies nano faces, so re-assert via advice.
;;     Exempt: read-only + special-mode buffers (eww derives from
;;     special-mode, plus help/magit/...) never highlight — their trailing
;;     spaces are renderer output, not user dirt.
(setq-default show-trailing-whitespace t)

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
(dolist (b (buffer-list))
  (with-current-buffer b (nano/disable-trailing-whitespace-maybe)))

(defun nano/toggle-trailing-whitespace ()
  "Toggle trailing-whitespace highlight in editable buffers.  Bound to SPC t w.
Exempt buffers (read-only / special-mode) stay off when enabling."
  (interactive)
  (let ((v (not (default-value 'show-trailing-whitespace))))
    (setq-default show-trailing-whitespace v)
    (dolist (b (buffer-list))
      (with-current-buffer b
        (setq show-trailing-whitespace
              (and v (not (nano/trailing-whitespace-inhibit-p))))))
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
(tab-bar-mode 1) ; already on via §5d (before desktop read); idempotent here.
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
   "  (1-9 go/new, n new, ]/[ next/prev, TAB last, l list, b buffer, r rename, x close, q quit)"))

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
         ((eq ev ?b) (call-interactively #'switch-to-buffer) (setq done t))
         ((memq ev (list ?q ?\r ?\e)) (setq done t) (message nil))
         ((eq ev ??) (message "Keys: 1-9 go/create, n new, ]/[ next/prev, TAB last, l list, b buffer, r rename, x close, q quit"))
         (t (message "Unknown workspace key: %s" (key-description (vector ev)))))))))

(define-key spacemacs-leader-map (kbd "l") 'nano/workspace-dispatch)

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
;; scoped to magit+elfeed only, not full collection).  §3 evil-want-* vars
;; already satisfy evil-collection requirements.
;; Lazy (zero startup cost): collection builds on first magit/elfeed
;; use via straight autoloads.  Pre-seed states NOW (cheap setqs,
;; evil already loaded in §3) so the FIRST status buffer lands in
;; motion, not emacs — deferring the seed until after magit loads
;; stuck the first buffer in emacs state (SPC + j/k dead, "unusable").
;; Keymaps are global, so late `evil-collection-init' still fixes keys
;; in existing buffers; only the state seed is timing-sensitive.
(straight-use-package 'evil-collection)
(dolist (m '(magit-status-mode magit-log-mode magit-diff-mode
             magit-reflog-mode magit-refs-mode magit-revision-mode
             magit-stash-mode magit-stashes-mode magit-cherry-mode
             magit-process-mode git-rebase-mode
             elfeed-search-mode elfeed-show-mode))
  (evil-set-initial-state m (if (memq m '(elfeed-search-mode elfeed-show-mode))
                               'normal 'motion)))
(setq evil-collection-mode-list '(magit elfeed))
(defvar nano/evil-collection-initialized nil
  "Non-nil once `evil-collection-init' ran (magit/elfeed share one init).")
(defun nano/evil-collection-ensure ()
  "Init evil-collection once for `evil-collection-mode-list'.  Lazy entry."
  (unless nano/evil-collection-initialized
    (when (require 'evil-collection nil t)
      (evil-collection-init evil-collection-mode-list)
      (setq nano/evil-collection-initialized t))))
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
(with-eval-after-load 'magit-section
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
;; Zero-dep: built-in project.el + xref + grep + fido-vertical (§8) only.
;; SPC s s lists buffer lines via completing-read (fido-vertical shows
;; all on empty input, flex filters as you type); s f / s g / s d below.
(require 'xref)
(require 'grep)

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
symbol at point.  Skips empty lines, truncates long lines for display."
  (interactive)
  (let ((cands nil)
        (n 0)
        (truncated nil))
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
                                   nil nil (thing-at-point 'symbol))))
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
;; NOTE: more org bindings appended later — §18c (todo/text/random),
;; §21b (roam).  Edit those too for full `,' map.
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
Skips subdirs (e.g. roam/) so agenda scans fewer files."
  (when (file-directory-p nano/org-directory)
    (directory-files nano/org-directory t "\\.org$")))

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

(defun nano/org-ret-dwim ()
  "Follow org link at point, else `evil-ret'.  Bound to RET in org normal/motion."
  (interactive)
  (if (and (derived-mode-p 'org-mode)
           (ignore-errors (nano/org-at-link-p)))
      (call-interactively #'org-open-at-point)
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
    "Autolist with link-face fix: follow link when on one, even in lists."
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
        ad-do-it)))
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
(nano/declare-major-prefix 'org-mode "x" "text")
(nano/set-leader-keys-for-major-mode 'org-mode
                                     "t" 'org-todo           ; cycle TODO->NEXT->DONE
                                     "R" 'nano/org-random-current-buffer ; random headline, current buffer only
                                     "xb" 'nano/org-bold
                                     "xc" 'nano/org-code
                                     "xi" 'nano/org-italic
                                     "xo" 'org-open-at-point ; moved from `, o'
                                     "xr" 'nano/org-clear-emphasis
                                     "xs" 'nano/org-strike-through
                                     "xu" 'nano/org-underline
                                     "xv" 'nano/org-verbatim)
(which-key-add-keymap-based-replacements
  (nano/major-mode-leader-map 'org-mode)
  "t" "todo cycle" "R" "random note (buffer)"
  "xb" "bold" "xc" "code" "xi" "italic" "xo" "open link"
  "xr" "clear emphasis" "xs" "strike-through"
  "xu" "underline" "xv" "verbatim")

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
(defun nano/org-agenda-refresh-files ()
  "Set `org-agenda-files' to top-level *.org under `nano/org-directory'.
No-op (warn once via `nano/org-ensure-directory') when dir missing."
  (when (nano/org-ensure-directory)
    (setq org-agenda-files (nano/org-agenda-top-level-files))))

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
    ;; evil-next-line); M-j/k item, M-h/l earlier/later, gd grid,
    ;; gr redo, M-RET show-and-scroll-up.
    (evil-define-key 'motion org-agenda-mode-map
      "j" #'org-agenda-next-line
      "k" #'org-agenda-previous-line
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
(require 'appt)
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

(defun nano/org-appt-refresh ()
  "Rebuild appt list from SCHEDULED items with time.  Silent no-op when org dir missing."
  (when (nano/org-ensure-directory)
    (nano/org-agenda-refresh-files)
    (when (or (featurep 'org-agenda) (require 'org-agenda nil t))
      (ignore-errors (org-agenda-to-appt t nil :scheduled*)))))

(unless noninteractive
  (appt-activate 1)
  (run-at-time nil 60 #'nano/org-appt-refresh)
  (add-hook 'window-setup-hook #'nano/org-appt-refresh)
  (add-hook 'org-agenda-finalize-hook #'nano/org-appt-refresh)
  (add-hook 'org-after-todo-state-change-hook #'nano/org-appt-refresh)
  (add-hook 'org-mode-hook
            (lambda ()
              (add-hook 'after-save-hook #'nano/org-appt-refresh nil t))))

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
;;      Paragraph = 4 sentences joined; list = "- sentence" lines.
;;      Plain = 1 unit, C-u N / M-N = N units.
(defvar nano/lorem-sentences
  '("Lorem ipsum dolor sit amet, consectetur adipiscing elit."
    "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
    "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris."
    "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum."
    "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia."
    "Curabitur pretium tincidunt lacus, nec iaculis eros aliquam vitae."
    "Phasellus ullamcorper velit eu nisi malesuada, a scelerisque odio ultrices."
    "Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere.")
  "Classic lorem ipsum sentences cycled by §19 insert commands.")

(defun nano/insert-lorem-sentences (n)
  "Insert N lorem ipsum sentences at point.  Bound to SPC i l s."
  (interactive "p")
  (dotimes (i (or n 1))
    (insert (nth (% i (length nano/lorem-sentences)) nano/lorem-sentences))
    (insert (if (= i (1- (or n 1))) "\n" " "))))

(defun nano/insert-lorem-paragraphs (n)
  "Insert N lorem ipsum paragraphs (4 sentences each).  SPC i l p."
  (interactive "p")
  (dotimes (p (or n 1))
    (dotimes (i 4)
      (insert (nth (% (+ (* p 4) i) (length nano/lorem-sentences))
                   nano/lorem-sentences))
      (insert " "))
    (insert "\n")
    (unless (= p (1- (or n 1))) (insert "\n"))))

(defun nano/insert-lorem-list (n)
  "Insert N lorem ipsum items as \"- sentence\" lines.  SPC i l l."
  (interactive "p")
  (dotimes (i (or n 1))
    (insert "- " (nth (% i (length nano/lorem-sentences)) nano/lorem-sentences) "\n")))

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


;; ---------------------------------------------------------------------
;; §22  Update  (float latest, SPC f e U pull+rebuild)
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
(which-key-add-key-based-replacements
  "SPC f e" "emacs/config"
  "SPC f e U" "update packages")

;; ---------------------------------------------------------------------
;; §23  Web  (built-in eww + elfeed/ttrss, SPC a w, lazy)
;; ---------------------------------------------------------------------
;; Zero startup cost: no `require', straight autoloads only.  First
;; `SPC a w r' builds elfeed + protocol + goodies.
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

(define-key spacemacs-leader-map (kbd "a w e") 'eww)
(define-key spacemacs-leader-map (kbd "a w r") 'elfeed)
(which-key-add-key-based-replacements
  "SPC a w e" "eww"
  "SPC a w r" "elfeed")

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

(defun nano/elfeed-apply-sort-mode ()
  "Apply `nano/elfeed-sort-mode' to current elfeed-search buffer."
  (pcase nano/elfeed-sort-mode
    ('date
     (setq-local elfeed-search-sort-order 'ascending)
     (setq-local elfeed-search-sort-function nil))
    ('random
     (setq-local elfeed-search-sort-order 'ascending)
     (setq-local elfeed-search-sort-function
                 (lambda (_a _b) (eq (random 2) 0)))))
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
  (unless (featurep 'elfeed-goodies-search-mode)
    (message "nano: elfeed-goodies-search-mode missing, using built-in header"))
  (setq elfeed-search-header-function #'nano/elfeed-search-header))

;; Bottom modeline (§6b bar) sort indicator — overrides vendored
;; `nano-modeline-elfeed-search-mode' (nano-modeline.el:123) which
;; shows no sort state.  Top powerline header keeps its own [label]
;; prefix as fallback; this is the visible one on the bottom bar.
(with-eval-after-load 'nano-modeline
  (defun nano-modeline-elfeed-search-mode ()
    (nano-modeline-compose (nano-modeline-status)
                           "Elfeed"
                           (concat "(" (nano/elfeed-sort-label) ") "
                                   "(" (elfeed-search--header) ")")
                           "")))

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
           (ids nil))
      (elfeed-db-visit (entry)
        (when (equal (elfeed-protocol-entry-protocol-id entry) proto-id)
          (let ((id (elfeed-meta entry :id)))
            (when (and id (not (member id ids)))
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
