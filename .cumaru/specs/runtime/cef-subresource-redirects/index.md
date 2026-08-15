---
human_revised: false
name: cef-subresource-redirects
summary: Resolved CEF 149 redirected-subresource regression and the validated CEF 150 upgrade.
depends-on: []
relates: [specs/chat-host]
apps: [bundle]
---

# CEF subresource redirects

## Overview

HTTP redirects for renderer-initiated subresources are supported CEF behavior and normally require
no setting or command-line switch. Laufey 0.6.1 instead embeds CEF
`149.0.5+g6770623+chromium-149.0.7827.197`, an exact build affected by a confirmed CEF regression.
Direct `<img>` loads work, while the same valid bytes behind even a same-origin `302` fail with
`net::ERR_INVALID_ARGUMENT` before the destination request reaches Chromium's network stack.

CEF's intercepted redirect path restarts the subresource request so interception can run again. In
the affected build, that restart carries forward network-generated `Sec-Fetch-*` headers. Chromium
149's `RestrictForbiddenSecurityHeaders` validation sees them as forbidden renderer-supplied headers
and rejects the restarted request. Direct subresources never restart; browser-initiated navigations
use a different validation path. This explains why a hidden navigation can cross the same redirect
that an image cannot.

The upstream correction strips `Sec-Fetch-*` before restart so the network layer regenerates them.
CEF issue [#4203](https://github.com/chromiumembedded/cef/issues/4203) reproduces the same `<img>`
failure on the exact bundled build; issues [#4189](https://github.com/chromiumembedded/cef/issues/4189)
and [#4198](https://github.com/chromiumembedded/cef/issues/4198) cover the general regression. PR
[#4190](https://github.com/chromiumembedded/cef/pull/4190) carries the fix, and CEF `150.0.14` is
reported working. The dedicated Laufey build now pins CEF
`150.0.14+g7c1aa68+chromium-150.0.7871.129`. Live validation with the application workaround disabled showed the same
Chat attachment fail under CEF 149 and load natively under CEF 150.

## Requirements (EARS / RFC 2119)

- The project MUST treat renderer subresource redirects as supported CEF behavior with a versioned
  regression, not as an application configuration requirement.
- WHEN the CEF backend is `149.0.5+g6770623` THE SYSTEM SHALL treat redirected renderer
  subresources as affected by `ERR_INVALID_ARGUMENT`.
- Any backend claimed to fix this issue MUST use CEF `150.0.14` or later, or contain the equivalent
  of CEF PR #4190, and MUST be validated against a known affected Chat attachment with application
  workarounds disabled.
- Diagnostic use of `--disable-features=RestrictForbiddenSecurityHeaders` MUST be limited to the
  local reproduction and MUST NOT run against Chat or any authenticated profile.
- The diagnostic flag MUST NOT be added to `run.sh`, `dev.sh`, or shipped configuration; it disables
  security validation rather than repairing CEF's redirect restart.
- Application code MUST NOT attempt to strip the stale request headers because Laufey exposes no
  `CefResourceRequestHandler` or equivalent HTTP interception surface.
- WHEN a patched Laufey backend is evaluated THE SYSTEM SHALL reproduce the failure on the previous
  backend and validate native loading on the candidate backend before removing application code.
- A distributed Chat build claiming the redirect fix MUST identify the exact Laufey release and embedded CEF version
  in its release metadata.

## Decisions

- 2026-08-15: Keep this regression in its own runtime subarea so the upstream evidence, regression
  contract, and potential Laufey contribution remain reachable without expanding the general
  runtime overview.
- 2026-08-15: Test `RestrictForbiddenSecurityHeaders` once as a local causal diagnostic, never as a
  product workaround.
- 2026-09-08: Upgrade Laufey to CEF 150.0.14 after a live before-and-after test reproduced the failure on 149 and
  confirmed native attachment loading on 150.
- 2026-09-08: Revalidate the packaged app with the resolver absent: attachments rendered in the `donner nine` and
  `Fernando Guazelli` conversations, both opened in Chat's full image viewer, and the CEF log contained no
  `ERR_INVALID_ARGUMENT` or network error.

## Files

Single-issue subarea. Future CEF pin changes MUST repeat the live attachment validation with application workarounds
disabled.
