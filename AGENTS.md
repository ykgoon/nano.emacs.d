# AGENTS.md

Emacs distro on [rougier/nano-emacs](https://github.com/rougier/nano-emacs), managed by straight.el. Local git repo only (syncthing path, no remote). No tests/CI/lint.

## Launch / layout
- Needs `Noto Sans Mono` system-wide.
- `init.el` — only real config: bootstraps straight.el, sets font, installs `nano`, `(require 'nano)`. Everything resolves off `user-emacs-directory` (= launch dir).
- `early-init.el` — `package-enable-at-startup nil`; package.el disabled.
- `straight/repos/` — vendored git clones of every package. `straight/build-cache.el` = straight recipe cache. `elpa/`, `eln-cache/`, `auto-save-list/` = caches/runtime; ignore unless packaging.
- Sanity check: `emacs --batch --eval '(setq user-emacs-directory "~/.emacs.d/")' -l ~/.emacs.d/init.el --eval '(message "nano=%s" (featurep (quote nano)))'`
- Testing: if `emacs` run needed, use no-window mode (`--batch` or `-nw`) so output visible to agent; never launch GUI emacs

## Gotchas
- Package versions are NOT pinned; straight pulls latest commit on bootstrap.
- First bootstrap needs network: if `straight/repos/straight.el/bootstrap.el` is absent, `install.el` is fetched from `radian-software/straight.el/develop`.
- Edits reload via `SPC f e r` (`nano/reload-init`, §22): re-runs init.el in-place, covers bindings/defuns/setq. Font/boot changes still need restart (`SPC q r`) — §2 vars are set-before-require and `(require 'nano)` is a no-op on reload.
- Font/theme tweaks must run BEFORE `(require 'nano)` or nano defaults override them.

## OpenCode (§27)
- CLI must be installed: `curl -fsSL https://opencode.ai/install | bash` (lands in `~/.opencode/bin`). `27a0` adds that dir to `exec-path`/`$PATH`, so GUI Emacs works without a login shell.
- Tree-sitter grammars `markdown` + `markdown-inline` are required for session buffers; install once with `M-x treesit-install-language-grammar` (built libs land in `~/.emacs.d/tree-sitter/`).
- State DB: `~/.local/share/opencode/opencode.db` (override root with `XDG_DATA_HOME`). `session.model` + `message.data` hold the model per session/message.
- Default model (27d): new sessions adopt the model OpenCode last used in **any** session, read read-only from that DB (`nano/opencode-last-used-model`). `M-x nano/opencode-refresh-last-model` refreshes on demand. Without this, new sessions fall back to the package default `opencode/big-pickle` unless a model was picked in Emacs.
- Cursor follow (27e): `comint-move-point-for-output` is nil, so comint never scrolls session windows; §27e adds a sticky filter pair instead of setting it (setting it to `all` fights the user's scroll-back). Pre-output filter records tail windows, post-output filter pins them. `C-c C-l` re-attaches after scrolling away.
- Permission notifications (27f): the package only toasts when the session buffer is inactive, so §27f advises `opencode--permission-request` to notify once per permission id regardless of focus. `opencode-toast-function` is replaced with a signal-safe notifier that probes for `org.freedesktop.Notifications` first and degrades to the echo area (devbox has **no** notification daemon, so the stock notifier logs a dbus error on every call).

## Workflow
- Add a package: add `(straight-use-package '(pkg :type git :host github :repo "user/pkg"))` + `(require 'pkg)` in `init.el`.
- Edited a vendored package under `straight/repos/`? `M-x straight-rebuild-package RET <pkg>`, or `M-x straight-pull-all` to sync upstream.

## Principles
- Performance first. New features -> lightest solution wins. Prefer built-ins / minimal deps, lazy-load, fast startup. Justify heavy packages.
- When design new UX/UI or behavior where there is no reference to emulate, employ design principles found in `./DESIGN.md`.

## UX/UI Reference
- Future features needing UX/UI design — learn from Spacemacs as primary reference (mnemonic SPC leader, which-key, transient states, layer organization).
- Spacemacs impl at `~/spacemacs.emacs.d` — read-only reference. Inspect via `Read`/`Grep` (e.g., `core/core-keybindings.el`, `core/core-documentation.el`, `layers/`); never `Edit`/`Write` there. Complements Launch rule: `~/spacemacs.emacs.d` hosts Spacemacs distro — do not modify, read only.
- This repo currently minimal (`init.el` already seeds `spacemacs-leader-map` + `which-key`); future builds extend that pattern while staying light.
