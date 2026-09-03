(setq package-enable-at-startup nil)

;; Start maximized on desktop (X/Wayland) — before first frame created (no flicker).
;; Ignored in tty/batch. Re-asserted post-nano in init.el (nano-layout overwrites).
(add-to-list 'initial-frame-alist '(fullscreen . maximized))
(add-to-list 'default-frame-alist '(fullscreen . maximized))