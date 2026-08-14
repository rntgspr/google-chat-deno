---
human_revised: false
name: runtime
summary: What `deno desktop` actually provides — the verified BrowserWindow API surface, the three backends, and the capabilities it does not expose.
depends-on: []
relates: [specs/session, specs/chat-host]
apps: [host, bundle]
---

# Runtime

`deno desktop` shipped in Deno 2.9 and is **experimental** — the CLI prints
`deno desktop is experimental and subject to change` on every build. Its published
documentation covers locally-served application content and is silent on the three
capabilities a third-party-page wrapper needs: script injection, navigation
interception, and user-agent control. Everything recorded here was established by
probing the runtime directly, not read from docs.

The build step compiles the entrypoint into a signed `.app` bundle in one command,
downloading the selected backend on first use. For CEF that is `laufey` (the backend's
own name) plus the Chromium Embedded Framework — ~307 MB on disk per bundle.

## Verified API surface

`Deno.BrowserWindow.prototype` carries only `constructor`; the real methods sit one
level down the chain. The full set, read from a live instance:

```
bind, unbind, executeJs, navigate, reload, openDevtools,
show, hide, focus, close, isClosed, isVisible,
getPosition, setPosition, getSize, setSize, setTitle,
getOpacity, setOpacity, isResizable, setResizable, isAlwaysOnTop, setAlwaysOnTop,
setApplicationMenu, showContextMenu, getNativeWindow, windowId,
onload, onclose, onfocus, onblur, onresize, onmove,
onclick, ondblclick, oncontextmenuclick, onmenuclick,
onkeydown, onkeyup, onmousedown, onmouseup, onmouseenter, onmouseleave, onmousemove, onwheel
```

`Deno.Tray` and `Deno.Dock` exist as separate classes. The window constructor **ignores
unknown options silently** — passing invented option names neither throws nor warns, so
the option bag cannot be discovered by probing.

## Backends

`--backend` accepts `webview`, `cef`, and `raw`. The choice is decisive for this project,
and the two viable options fail in opposite directions — see [chat-host](../chat-host/index.md)
and [session](../session/index.md) for the evidence.

| | `cef` | `webview` |
|---|---|---|
| Engine | bundled Chromium (CEF) | WKWebView on macOS |
| Google Chat | runs | **refused — "Unsupported browser"** |
| Session persistence | **ephemeral by default** | persistent per bundle id |
| Bundle size | ~307 MB | small |

## Requirements (EARS / RFC 2119)

### Boot contract

- The runtime MUST be given something to serve: it waits for a local application server and, on a 15-second timeout, navigates the window itself — clobbering any navigation the host already performed.
- The host MUST therefore either serve local content with `Deno.serve()` or defer its own `navigate()` until after that timeout.
- WHEN no entrypoint is passed AND no supported framework is detected in the directory THE SYSTEM SHALL refuse to build, so a non-framework app MUST pass its entrypoint explicitly.

### Permissions

- The bundle MUST be compiled with the permissions it needs; a missing permission is a hard runtime failure, not a prompt.
- Reading `HOME` / `TMPDIR` and writing a profile directory MUST be granted at compile time via `--allow-env`, `--allow-read`, and `--allow-write`.

### Host / page bridge

- `win.bind(name, handler)` MUST be used to expose a host function; the page calls it as `bindings.<name>(...)`.
- The bridge DOES reach a remote origin — verified against `accounts.google.com` and `chat.google.com` — although the documentation describes only locally-served content.
- Arguments and return values cross as JSON.
- `executeJs` MUST NOT be relied on for its return value: it resolves to `{"ok":true,"value":{}}` regardless of what the evaluated expression produced. Results MUST come back through a binding instead.

### Embedding page-side code

- Page-side scripts MUST live in their own `.js` files and be pulled in as text imports (`with { type: "text" }`), not written as template literals inside the host module.
- Text imports require no unstable flag on Deno 2.9.5.
- The compiler MUST embed a text-imported file into the bundle; the build output names it under `Embedded Files`, which is the way to confirm it shipped.

### Absent capabilities

- There is **no** navigation interception — no `will-navigate`, no window-open handler, no equivalent of Electron's `setWindowOpenHandler`. `onload` fires after the fact.
- There is **no** document-start script injection — no preload option, no init script. `executeJs` runs against an already-loaded page.
- There is **no** user-agent API on the window, and no user-agent option in the `desktop` block.
- There is **no** storage, profile, or cache-path configuration anywhere in the `desktop` block, which carries only `app`, `backend`, `output`, `macos`, `release`, and `errorReporting`.

## Decisions

- CEF is the chosen backend despite ~307 MB per bundle, because the `webview` backend cannot load the product at all. Trading size for engine consistency is not a choice that is available here.
- The host serves a trivial local page purely to satisfy the boot contract, then navigates away to Chat. The alternative — racing the runtime's own navigation — loses.
- Page-side code lives in `probe.js` as real JavaScript rather than a string inside the host module: a template literal gets no highlighting, no linting, and no editor support, and this code is long enough for that to matter.

## Known gaps

- The absent navigation hook has no known workaround. In the Electron original this is the load-bearing security control: an allowlist decides which hosts may open inside the window carrying the Google session, and everything else goes to the system browser. Nothing in this runtime can express that today.
- WebAuthn / passkey fails under CEF (`challenge/pk/error`) on an account that has a passkey registered. Not blocking — Google falls back to 2-Step Verification — but it is a real capability gap.
- Experimental status means every finding here has a shelf life; the CLI says so itself.

## Files

Single area for now; splits when one of these grows.

## Reference

<!-- cumaru:reference -->
| Link | Description |
|------|-------------|
| [main.ts](src/main.ts) | Host process: window, boot-contract server, `bind` bridge, and the page probe. |
| [probe.js](src/probe.js) | Page-side script, embedded into the bundle via a text import. |
| [deno.json](deno.json) | The `desktop` block — app identity, backend selection, output paths. |
<!-- /cumaru:reference -->
