---
human_revised: false
name: attachments
summary: Native Google Chat attachment loading through CEF subresource redirects.
depends-on: [specs/chat-host, specs/runtime/cef-subresource-redirects]
relates: [specs/session]
apps: [host, bundle]
---

# Chat attachments

## Overview

Google Chat attachment images enter the document through a same-origin endpoint that redirects to a signed
`lh3.googleusercontent.com` URL. The dedicated Laufey build embeds CEF 150.0.14, which follows this redirect natively.
The application does not discover, download, replace, or cache attachments itself.

## Requirements (EARS / RFC 2119)

- THE SYSTEM SHALL let Google Chat own attachment discovery, loading, rendering, and browser caching.
- WHEN an attachment image receives an HTTP redirect THE CEF BACKEND SHALL follow it as a renderer subresource.
- The application MUST NOT inject an attachment resolver, image cache, loading placeholder, or DOM replacement probe.
- The application MUST NOT disable browser security features to make redirected attachments load.
- Any CEF change MUST be validated against the same Chat attachment with application workarounds disabled.

## Decisions

- 2026-09-08: Upgrade the dedicated Laufey build from CEF 149.0.5 to 150.0.14 and remove the application workaround.
  Live before-and-after validation showed the same attachment fail under CEF 149 and load natively under CEF 150.
  The packaged app subsequently rendered attachments in `donner nine` and `Fernando Guazelli`, opened both through
  Chat's full image viewer, and logged no redirect-related network error.

## Known gaps

- Distributed builds depend on the version-pinned Laufey fork release until the CEF upgrade is available upstream;
  local development continues to use the dedicated sibling checkout.

## Files

Single concern file. Add implementation references only if the application regains attachment-specific code.

## Reference

<!-- cumaru:reference -->

| Link                               | Description                                                               |
| ---------------------------------- | ------------------------------------------------------------------------- |
| [entrypoint](src/app.ts)           | Starts the application without attachment-specific host or probes.        |
| [native-path test](src/app_test.ts) | Guards against restoring the removed attachment workaround in bootstrap. |

<!-- /cumaru:reference -->
