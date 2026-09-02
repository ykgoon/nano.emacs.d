# AGENTS.md

Emacs distro on [rougier/nano-emacs](https://github.com/rougier/nano-emacs), managed by straight.el. Not a git repo. No tests/CI/lint.

## Launch / layout
- NOT `~/.emacs.d`: `~/.emacs.d` hosts a different production distro — never touch it.
- Always launch with `emacs --init-directory ~/nano.emacs.d` (Emacs 30 supports this). Needs `Noto Sans Mono` system-wide.
- `init.el` — only real config: bootstraps straight.el, sets font, installs `nano`, `(require 'nano)`. Everything resolves off `user-emacs-directory` (= launch dir).
- `early-init.el` — `package-enable-at-startup nil`; package.el disabled.
- `straight/repos/` — vendored git clones of every package. `straight/build-cache.el` = straight recipe cache. `elpa/`, `eln-cache/`, `auto-save-list/` = caches/runtime; ignore unless packaging.
- Sanity check: `emacs --init-directory ~/nano.emacs.d --batch --eval '(message "nano=%s" (featurep (quote nano)))'`
- Testing: if `emacs` run needed, use no-window mode (`--batch` or `-nw`) so output visible to agent; never launch GUI emacs

## Gotchas
- Package versions are NOT pinned; straight pulls latest commit on bootstrap.
- First bootstrap needs network: if `straight/repos/straight.el/bootstrap.el` is absent, `install.el` is fetched from `radian-software/straight.el/develop`.
- Restart emacs after editing `init.el`; no reloader.
- Font/theme tweaks must run BEFORE `(require 'nano)` or nano defaults override them.

## Workflow
- Add a package: add `(straight-use-package '(pkg :type git :host github :repo "user/pkg"))` + `(require 'pkg)` in `init.el`.
- Edited a vendored package under `straight/repos/`? `M-x straight-rebuild-package RET <pkg>`, or `M-x straight-pull-all` to sync upstream.

## Principles
- Performance first. New features -> lightest solution wins. Prefer built-ins / minimal deps, lazy-load, fast startup. Justify heavy packages.