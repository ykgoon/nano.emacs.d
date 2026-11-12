# nano.emacs.d

Minimal [rougier/nano-emacs](https://github.com/rougier/nano-emacs) distro. `straight.el` manage packages. No `package.el`.

## Prereqs

- Emacs 30+ (`--init-directory` needed)
- Git
- `Noto Sans Mono` font installed
- Network (first bootstrap fetch deps)

Check deps:

```sh
emacs --version          # need 30+
fc-list | grep "Noto Sans Mono"
git --version
```

Install font (if missing):

```sh
# Debian/Ubuntu
sudo apt install fonts-noto
# Arch
sudo pacman -S noto-fonts-mono
# macOS
brew install --cask font-noto-sans-mono
```

## Fresh install

```sh
# 1. clone
git clone <this-repo-url> ~/nano.emacs.d

# 2. launch (first run bootstraps straight.el + nano + evil + which-key)
emacs --init-directory ~/nano.emacs.d

# 3. verify
emacs --init-directory ~/nano.emacs.d --batch --eval '(message "nano=%s" (featurep (quote nano)))'
# expect: nano=t
```

No manual `straight.el` install. `init.el:8-14` fetch `install.el` from `radian-software/straight.el/develop` if `straight/repos/straight.el/bootstrap.el` absent.

Never touch `~/.emacs.d`. That dir = production distro. This one lives isolated at `~/nano.emacs.d`.

## Layout

```
~/nano.emacs.d/
├── early-init.el   # (package-enable-at-startup nil) — kill package.el
├── init.el         # only real config
└── straight/       # vendored clones + build-cache.el — ignore
    eln-cache/ elpa/ auto-save-list/ — runtime cache — ignore
```

`init.el` order matter:

1. bootstrap `straight.el` (`init.el:4-15`)
2. silence native-comp / warnings (`init.el:18-23`)
3. set `nano-font-family-monospaced` (`init.el:25`)
4. `straight-use-package` nano, `require` (`init.el:27-30`) — font/theme tweaks must go BEFORE this line
5. disable GUI chrome, evil/which-key, SPC leader (`init.el:35-108`)

## Usage

```sh
emacs --init-directory ~/nano.emacs.d              # GUI
emacs --init-directory ~/nano.emacs.d -nw           # terminal
emacs --init-directory ~/nano.emacs.d --batch --eval '...'  # headless
```

SPC leader (evil normal/visual/motion + `C-SPC` everywhere):

| Keys | Action |
|------|--------|
| `SPC SPC` / `SPC :` | `execute-extended-command` |
| `SPC f f` | `find-file` |
| `SPC f s` / `SPC f S` | `save-buffer` / `save-some-buffers` |
| `SPC f r` | `recentf-open-files` |
| `SPC b b` / `SPC b d` | `switch-to-buffer` / `kill-current-buffer` |
| `SPC b n` / `SPC b p` | `next-buffer` / `previous-buffer` |
| `SPC w /` / `SPC w -` | `split-window-right` / `split-window-below` |
| `SPC w d` / `SPC w m` | `delete-window` / `delete-other-windows` |
| `SPC w h/j/k/l` | `evil-window-*` |
| `SPC q q` / `SPC q Q` | `save-buffers-kill-terminal` / `kill-emacs` |
| `SPC s s` | `isearch-forward` |

## OpenCode

Editor client for [OpenCode](https://opencode.ai), `SPC a c` (§27).

```sh
curl -fsSL https://opencode.ai/install | bash   # CLI -> ~/.opencode/bin
```

Emacs finds that dir itself (`27a0`), so GUI sessions work without a
login shell. Session buffers also need the `markdown` and
`markdown-inline` Tree-sitter grammars:

```elisp
;; M-x treesit-install-language-grammar RET markdown RET  (twice: also markdown-inline)
```

New sessions default to the model OpenCode last used in *any* session
(CLI, TUI, or Emacs), read from `~/.local/share/opencode/opencode.db`
(§27d). Example: run `opencode run --model opencode/glm-5.3-flash-free "hi"`,
then `SPC a c n` — the session starts on `glm-5.3-flash-free` instead of
the package default `big-pickle`.

| Keys | Action |
|------|--------|
| `SPC a c n` | new session |
| `SPC a c o` | open past session |
| `SPC a c a` / `A` | ask / ask with context |
| `SPC a c m` | MCP list |
| `SPC a c x` / `R` | disconnect / restart service |

Refresh the default model by hand after switching models outside Emacs:
`M-x nano/opencode-refresh-last-model`.

The cursor follows streamed replies. Scroll up to read history and the
view stays put; `C-c C-l` jumps back to the newest output and resumes
following.

When OpenCode asks for permission (allow once / allow always / deny), a
desktop notification fires even if the session buffer is in focus.
Clicking it raises that session. Without a notification daemon the
message falls back to the echo area instead of erroring.

A notice is also sent when a turn finishes, naming the session; clicking
it opens that session. Subagent sessions and turns paused for a
permission request stay quiet.

Permission prompts only ever appear when the session buffer is the one
you are looking at. If a request arrives while you are in another
buffer, window, frame or workspace, the minibuffer is left alone and the
desktop notice tells you instead; the request stays queued and the prompt
appears the moment you return to the session. Dismissing it with `C-g`
keeps it queued, so leaving and coming back offers it again — no need to
abort the session and retry.

If Emacs cannot find `opencode`, check `27a0` added `~/.opencode/bin` to
`exec-path`; session buffers also need the `markdown` and
`markdown-inline` Tree-sitter grammars.

## Customize

Add package in `init.el`:

```elisp
(straight-use-package '(pkg :type git :host github :repo "user/pkg"))
(require 'pkg)
```

Restart emacs after edit — no reloader.

Rebuild after editing vendored code under `straight/repos/`:

```
M-x straight-rebuild-package RET <pkg>
M-x straight-pull-all  ; sync upstream
```

Font/theme change -> put BEFORE `(require 'nano)` else nano defaults override.

Heavy package? Justify. Prefer builtins, minimal deps, lazy-load. Performance first.

## Gotchas

- Versions not pinned — straight pulls latest commit on bootstrap.
- First launch need network.
- Warnings suppressed from popup (`init.el:35-36` `display-buffer-no-window` for `*Warnings*`), still view via `C-h e`.
- No tests/CI/lint in repo.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `font not found` / fallback font | Install `Noto Sans Mono`, `fc-cache -fv`, restart |
| Bootstrap fail / network error | Check network, remove `straight/repos/straight.el`, relaunch |
| `~/.emacs.d` conflict | Always use `--init-directory ~/nano.emacs.d` |
| Changes not apply | Restart emacs — no hot reload |
| Corrupt straight cache | `rm -rf straight/build-cache.el elpa/ eln-cache/` then relaunch |
