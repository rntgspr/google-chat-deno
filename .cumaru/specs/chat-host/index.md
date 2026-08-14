---
human_revised: false
name: chat-host
summary: Hosting the Google Chat web client — what Google accepts, the user agent it sees, the sign-in path, and the page-side hooks that survive.
depends-on: [specs/runtime]
relates: [specs/session]
apps: [host]
---

# Chat host

The product is the Google Chat web client rendered in a window this project controls. Google
does not offer an API for any of it, so every desktop behavior has to be built by observing and
patching the page from the host side. This area records what Google actually permits, verified
against a live account.

## What Google accepts

**The engine is the gate, not the user agent.** Under the CEF backend Chat loads and runs
normally. Under the `webview` backend — WKWebView, the Safari engine — sign-in completes and
cookies are written, but Chat itself then redirects to
`chat.google.com/u/0/error/browser-not-supported/` and refuses to render. The rejection lands
*after* authentication, which makes the failure mode worth remembering: a working login proves
nothing about whether the product will run.

Sign-in itself was never blocked. Google served the ordinary `GlifWebSignIn` flow, recognized the
account, and progressed through its normal challenge chain. The one step that failed was the
passkey challenge (`challenge/pk/error`) on an account that does have a passkey registered — CEF
does not carry the platform-authenticator integration WebAuthn needs. Google falls back to
2-Step Verification and the phone prompt path completes without trouble.

## The user agent

No disguise is required, and none is available — the runtime exposes no user-agent API. What the
page sees under CEF is a clean, self-consistent Chrome:

```
Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36
  (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36

navigator.userAgentData -> Chromium/149, Not)A;Brand/24, platform macOS
```

The header, `navigator.userAgent`, and `navigator.userAgentData` all agree, and nothing names
the application or the framework.

## Page-side hooks

The host reaches the page through `executeJs` and the page reaches back through `bind` —
confirmed working against a remote Google origin, which the runtime's documentation never
promised. On that basis:

- `window.Notification` can be replaced, and the replacement survives the full navigation chain from sign-in to the loaded Chat shell.
- `input[name="q"]` still exists, so focusing Chat's own search from the host remains viable.
- The favicon carries the unread signal in its filename, observed switching live from `chat_2026_logo_favicon_no_dot_64px.png` to `chat_2026_logo_favicon_dot_64px.png` when a message arrived. Two states, distinguished by a `dot` / `no_dot` segment — simpler than the three URL patterns the Electron original matched.

## Requirements (EARS / RFC 2119)

- The application MUST use the CEF backend; the `webview` backend is refused by Chat.
- The host MUST NOT depend on `executeJs` return values; page state MUST be reported through a binding.
- WHEN the host patches the page THE SYSTEM SHALL re-apply the patch after navigation, because `executeJs` runs against an already-loaded document and every navigation discards it.
- The host MUST tolerate Google redirecting `mail.google.com/chat/u/0` to `chat.google.com/u/0/app/home`.
- THE SYSTEM SHALL NOT attempt to spoof the user agent; the default is consistent and unremarkable, and the runtime offers no way to change it anyway.

## Decisions

- The Electron original's user-agent spoofing has no counterpart here and should not be recreated. That code existed to hide an `Electron/` token and an app name from Google; neither appears in this runtime's user agent.

## Known gaps

- **The `Notification` override works by luck, not by design.** `executeJs` runs after load, so it only holds because Chat reads `window.Notification` lazily at call time rather than capturing it during boot. If that ever changes, the override silently stops working — and there is no document-start injection to fall back on.
- Every navigation drops the patch until the host re-applies it, leaving a window in which a notification would slip through unwrapped.
- The unread-count selectors from the Electron original (`div[data-tooltip="Chat"]`, `div[data-tooltip="Spaces"]`) match nothing on the current Chat and still need rediscovery — deliberately deferred. The favicon signal, by contrast, is already understood; only the numeric count is missing.
- Notification delivery end-to-end (a real notification firing, and a click reaching the host through the `notificationClicked` binding) has not been exercised yet. The binding is wired; the path is unproven.

## Files

Single-concern area.

## Reference

<!-- cumaru:reference -->
| Link | Description |
|------|-------------|
| [main.ts](src/main.ts) | Navigation to Chat, the probe loop, and the bindings the page calls back through. |
| [probe.js](src/probe.js) | Runs inside Chat: reads identity and landmarks, installs the `Notification` wrapper. |
<!-- /cumaru:reference -->
