---
human_revised: false
name: chat-host
summary: Google Chat compatibility, authenticated remote hosting, and browser-visible capabilities.
depends-on: [specs/runtime]
relates: [specs/session]
apps: [host]
---

# Chat host

## Overview

The product is the remote Google Chat web client rendered inside a CEF window controlled by the
Deno host. The host creates the window and navigates it to Chat without injecting page-side code.

Google accepts the default CEF Chromium user agent and completes its ordinary sign-in flow. Passkey
authentication is unavailable in the measured backend, but Google falls back to phone-based
verification. The macOS `webview` backend completes authentication and is then redirected to Chat's
unsupported-browser page, making CEF mandatory.

## Hosting boundary

The main window navigates directly to `https://chat.google.com/u/0/app/home`. Google Chat owns its
document lifecycle, attachment rendering, and browser cache. The application does not install host
bindings or execute scripts in the page.

## Requirements (EARS / RFC 2119)

- The host MUST tolerate Google redirecting an authenticated session to its canonical Chat URL.
- THE SYSTEM SHALL NOT spoof the user agent; the runtime default is internally consistent and
  accepted by Chat.
- THE SYSTEM SHALL NOT inject application code into the Chat document without a current product requirement.
- THE SYSTEM SHALL NOT widen allowed document origins or disable web security to implement a Chat
  feature.
- Redirected image attachments MUST follow the resolution contract in [attachments](attachments/).

## Decisions

- 2026-09-08: Keep the host outside the Chat document after CEF 150 restored native redirected
  attachment loading.

## Known gaps

- No application-layer policy can intercept external navigations before they replace the
  authenticated Chat document.

## Files

- [attachments/](attachments/) — native redirected-image behavior under the dedicated CEF build.

## Reference

Source ownership is delegated to the attachment subarea and runtime bootstrap concern.
