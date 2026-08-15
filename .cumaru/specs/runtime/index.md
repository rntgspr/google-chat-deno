---
human_revised: false
name: runtime
summary: Verified deno desktop and CEF capabilities, constraints, bootstrap contract, and packaging surface.
depends-on: []
relates: [specs/session, specs/chat-host]
apps: [host, bundle]
---

# Runtime

## Overview

The application is built on the experimental `deno desktop` runtime with the CEF backend. CEF is
the only viable backend currently measured: it runs Google Chat, while the macOS `webview` backend
authenticates successfully and is then refused as an unsupported browser. The trade is a large
Chromium-backed bundle and reliance on Laufey behavior that is incompletely documented.

The runtime provides browser windows, navigation, menus, and developer tools. It does not provide
the navigation interception, user-agent control, or configurable CEF profile path expected from a
mature web wrapper. The local application owns the session-persistence workaround.

## Verified API surface

The live `Deno.BrowserWindow` surface includes navigation, reload, visibility, focus, close,
position, size, title, opacity, resizability, always-on-top state, application/context menus,
developer tools, JavaScript execution, bindings, and native input/window callbacks. Unknown
constructor options are ignored silently, so invented settings MUST NOT be treated as supported.

## Backends

| Backend | Google Chat | Session | Current use |
|---------|-------------|---------|-------------|
| `cef` | Runs | Ephemeral without launcher workaround | Required |
| `webview` | Refused after sign-in | Persistent by bundle identifier | Rejected |
| `raw` | Not a web-client host | Not applicable | Rejected |

## Requirements (EARS / RFC 2119)

### Platform selection

- The application MUST use the CEF backend while Google Chat rejects `webview`.
- A runtime upgrade MUST revalidate Chat loading, session persistence, and redirected attachment
  behavior.
- THE SYSTEM SHALL NOT invent unsupported browser-window options to compensate for absent runtime
  capabilities.

### Security and absent capabilities

- THE SYSTEM SHALL NOT disable browser security to compensate for redirected subresources.
- External navigation MUST be treated as an unresolved security gap because the runtime exposes no
  interception or window-open policy.
- The application MUST NOT depend on document-start injection or user-agent overrides because the
  runtime exposes neither capability.
- CEF profile persistence MUST remain a launcher concern until the runtime exposes a supported
  profile path.

## Decisions

- 2026-09-04: Keep CEF despite bundle size because engine compatibility is load-bearing.
- 2026-09-04: Isolate bootstrap and the CEF redirect regression below this index
  so the runtime overview remains current rather than becoming an experiment log.

## Known gaps

- There is no navigation interception equivalent to Electron's window-open policy.
- The application depends on a dedicated Laufey build until its CEF 150 pin is available upstream.
- WebAuthn/passkey authentication fails under the measured CEF build, although Google's fallback
  verification flow succeeds.
- Experimental runtime behavior has a short shelf life and requires live revalidation on upgrades.

## Files

- [bootstrap.md](bootstrap.md) — entrypoint, local server, package configuration, permissions, and
  macOS bundle assets.
- [cef-subresource-redirects/](cef-subresource-redirects/) — the resolved CEF 149 redirect regression and its validation.

## Reference

<!-- cumaru:reference -->
| Link | Description |
|------|-------------|
| [desktop configuration](deno.json) | Selects CEF and declares the runtime-facing application package. |
<!-- /cumaru:reference -->
