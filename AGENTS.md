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

## Quad workspace (§9c)
- `SPC l c` = new tab, four equal columns: magit A | opencode A | opencode B | magit B. Both repos are read first, so a non-repo answer or an unsplittable frame aborts before anything is created (the tab is closed again).
- `SPC l` is a `read-key` loop (`nano/workspace-dispatch`), NOT a prefix map — new workspace commands are new `cond` branches, not `define-key "l X"`. The hint line and the `?` legend carry the key.
- Magit placement: `magit-status-setup-buffer` always routes through `magit-display-buffer`; bind §10c's `nano/magit-desktop--display-quietly` + `magit-display-buffer-noselect t`, then `set-window-buffer`. **`(require 'magit)` must come before that `let`** — let-binding `magit-display-buffer-function` before magit's `defcustom` runs makes it lexical and magit then dies with "Defining as dynamic an already lexical var". On the first `SPC l c` of a session that would be the whole command.
- OpenCode placement: the client is async (service → create → `opencode-session-open` → `pop-to-buffer`), so there is no buffer to relocate. `display-buffer-overriding-action` is bound INSIDE the callback to a closure that `set-window-buffer`s the pane; overriding beats `display-buffer-alist`, so §6f's scratch routing cannot hijack it. `(require 'emacs-opencode)` first — `opencode--create-session` is not autoloaded.
- Limits: magit buffers are per-repository, so a repo open in another tab shares the buffer; session panes are not restored by `SPC q r` (tab + magit only, §10c).

## OpenCode (§27)
- CLI must be installed: `curl -fsSL https://opencode.ai/install | bash` (lands in `~/.opencode/bin`). `27a0` adds that dir to `exec-path`/`$PATH`, so GUI Emacs works without a login shell.
- Tree-sitter grammars `markdown` + `markdown-inline` are required for session buffers; install once with `M-x treesit-install-language-grammar` (built libs land in `~/.emacs.d/tree-sitter/`).
- State DB: `~/.local/share/opencode/opencode.db` (override root with `XDG_DATA_HOME`). `session.model` + `message.data` hold the model per session/message. Useful for checking what model a session actually ran (`sqlite3 -readonly ...`).
- **API reality (2026-11-13):** the client provides `emacs-opencode`, NEVER a bare `opencode` feature — `with-eval-after-load 'opencode` is a dead letter and everything in §27d–h is wired in ONE `with-eval-after-load 'emacs-opencode` block after 27h. Commits 27d–h of 2026-11-12 were written against the deleted v1 package (`sczi/opencode.el`) and silently did nothing; `advice-add` on a missing symbol succeeds without error in Emacs 31, so nothing fails loudly. `nano/opencode--api-check` warns if a relied-on symbol disappears (run `M-x` load + `emacs --batch ... --eval '(require (quote emacs-opencode))'` after any straight pull to see it).
- Default model (27d): new sessions start on `nano/opencode-default-model` = `opencode-go/glm-5.3-flash`. Two advices: `opencode--create-session :around` let-binds `nano/opencode--inject-model` (so the batch runner `opencode-run` is untouched), `opencode-client-session-create :around` fills `:model` when absent. Keys are `providerID`/`id` (server API), and the created session's model shows in the header via `opencode-session--update-session`.
- Cursor follow (27e): nothing custom. The session buffer is `text-mode` derived — there is NO comint in this package — and the renderer itself pins tail windows (`opencode-session--message-render-window-states`, `follow-bottom`). `C-c C-l` is `opencode-session-select-model`; never bind over it.
- Permission gate (27f+27h): every prompt funnels through `opencode-session--prompt-permission` (via `--defer-prompt`, a 0 s timer running the thunk inside the target session buffer, so `current-buffer` there is the prompt's home). The `:around` advice prompts when `nano/opencode--prompt-wanted-p` (selected window + no live minibuffer + no active transient), otherwise parks `(permission connection state)` in `nano/opencode--pending` and notifies via dunst once per request id (`nano/opencode--notified`). Re-offer runs from the session buffer's **buffer-local** `post-command-hook` (`nano/opencode--reoffer`, armed per buffer by `opencode-session-mode-hook` + `--permission-arm-all`) — a global `add-hook` there lands in one startup buffer and never reaches session buffers. Cleanup rides `opencode-session--remove-prompt :after`; notified ids clear once nothing is parked. `C-g` at the prompt DENIES (the package replies "reject" on quit) — a request is recoverable only while parked. Notification transport: dunst on the session bus (`org.freedesktop.Notifications`); `notifications-notify` with actions; this dunstrc maps `mouse_middle_click = do_action`, so the click action needs a MIDDLE click. No daemon → echo-area fallback.
- Finish notice (27g): `opencode-session--handle-execution-ended :after` (`session.execution.succeeded|failed|interrupted` — there is NO `session.idle` and no `opencode--handle-message` in v2). Skips interrupts, subagents (`opencode-session--subagent-parents`), sessions without a live buffer, and sessions whose buffer IS the selected window (watching the reply is the point; dunst is for when it is not). Title from the buffer's `opencode-session--session`; failed turns use critical urgency.

## Session minimap (§27i)
- `SPC a c l` = `nano/opencode-minimap`: read-only `*OpenCode Roster*`, one line per root session, refreshed every `nano/opencode-minimap-interval` (5 s) while the window is visible. `RET` opens the session by id, `g` re-polls.
- Three states, most urgent first: `!!` needs you (pending permission), spinner working (running execution), `.` idle. **ASCII only, deliberately** — emoji need a colour-emoji font and geometric glyphs need a font that carries them; `fc-match` on the devbox shows even "DejaVu Sans Mono" resolving to Adwaita Mono, so nothing beyond ASCII is safe. The face (`error`/`warning`/`shadow` inherits) carries the colour; the characters carry the state.
- Status is POLLED, not pushed, so the roster works for sessions with no buffer: `GET /api/session/active` (map sessionID -> `{type:"running"}`) for working, `GET /api/permission/request` for needs-you. The latter is **location-scoped**, so it is fetched once per distinct session directory and merged — one call only ever sees one project.
- **Requires OpenCode 2.x.** On 1.x `/api/session/active` is always `{}`, so every session would read idle; `nano/opencode-minimap--check` warns in the echo area instead of lying. Upgrade with `opencode upgrade --major`.
- The spinner animates by `subst-char-in-region` over one character per running row, addressed by a marker in each buffer's `nano/opencode-minimap--marks`, so text properties, buttons and point survive and nothing re-lays out. Frames are `- \ | /` (all one char wide, hence subst rather than re-render). The tick costs one `get-buffer-window` when the roster is hidden.
- `--marks` is **buffer-local** and rebuilt by every redraw; write it and read it inside the roster buffer only.
- Redraw preserves point: if point was on a session row it is restored to the same session, so the 5 s poll and the spinner never yank the cursor.
- The `-`/spinner is invisible in a chat transcript or a saved buffer dump — it only moves in a live window. To see it: open the roster, or `sit-for` with the buffer in a window (batch `--eval` timers do fire this way).

## Ghostel (§30)
- `SPC a t g` = `ghostel` (libghostty-vt terminal, `dakra/ghostel` from MELPA via straight). Separate from the §29 builtins; both exist side by side.
- Native module lives at `var/ghostel/ghostel-module.so` + `ghostel-module.version`, set by `ghostel-module-directory`. Deliberately outside `straight/` — straight replaces package dirs on rebuild, and re-mapping a live `.so` under a running Emacs breaks its mmap.
- Install/refresh by hand: download `ghostel-module-x86_64-linux.so` from the GitHub release into that dir and write the matching version to `ghostel-module.version`. `M-x ghostel-download-module` does the same in-process; `M-x ghostel-module-compile` needs zig 0.17.x.
- The loader refuses to map a module whose sidecar version is below `ghostel--minimum-module-version` (Elisp side), so a version bump in the package needs a matching module refresh — symptom is "Module version X on disk is older than required Y".
- Starts in evil insert state (like §29 shells). Shell integration (OSC 7 directory tracking, OSC 133 prompt nav) is injected for bash/zsh/fish automatically, no rc edits.
- `evil-ghostel` (same repo, MELPA) is available but not installed; it maps vim operators onto the PTY.

## Session restore (§5d + §10c)
- `SPC q q` / `SPC q r` save to `var/desktop/.emacs.desktop`: every tab (workspace) with its name, each tab's window layout, every file buffer, and — since §10c — every magit buffer. `tab-bar` must be on before `desktop-save-mode` reads, else framesets come back without tabs.
- `desktop-load-locked-desktop` is `'check-pid`, not nil: a lock left by a crash/kill is ignored once that PID is gone, while a live second Emacs still refuses. With nil, one crash silently emptied the next session ("Desktop file in use; not loaded").
- Magit buffers visit no file, so `desktop-save` never saved them; the frameset then pointed at buffers that were never recreated and `tab-bar` substituted ` *Old buffer magit: …*`. §10c adds the `desktop-save-buffer` + `desktop-buffer-mode-handlers` pair. Rebuild goes through magit's own `*-setup-buffer` functions — the refresh path alone fails without the mode setup (e.g. `magit-log-margin` is unbound, `wrong-type-argument number-or-marker-p`).
- Handlers are registered at init (`with-eval-after-load 'desktop`), **not** from `magit-mode-hook`/`with-eval-after-load 'magit`: `desktop-read` runs from `after-init-hook` before magit loads, and `desktop-load-file` loads magit only when it reaches the first magit entry — after that entry's handler lookup. Registering late drops exactly one magit buffer per session ("1 failed to restore").
- A magit buffer whose repository directory is gone is skipped (nil from the handler, placeholder shown); binding a nonexistent `default-directory` would signal and abort the whole restore.

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
