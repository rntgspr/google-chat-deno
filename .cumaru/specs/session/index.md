---
human_revised: false
name: session
summary: Why the CEF profile is thrown away on every launch, and the launcher that redirects it to a durable directory so the Google session survives.
depends-on: [specs/runtime]
relates: [specs/chat-host]
apps: [launcher, host]
---

# Session

A chat client that demands a full Google login on every launch is not usable, so durable
browser state is a precondition for this project rather than a refinement.

The CEF backend stores its entire browser profile — cookies, local storage, the lot — in

```
$TMPDIR/laufey_cef_<pid>/
```

A new pid on every launch means a new empty profile on every launch, inside a directory the
operating system also reclaims on its own schedule. This is the backend's behavior, not a
misconfiguration: there is no cache-path, profile, or storage option in `deno.json`, in the
documentation, or anywhere in the binary's strings.

## The launcher

The path is unusable as configuration but perfectly predictable as a *name* — the pid is the
process's own. Creating the symlink from inside the application loses a race, because CEF
initializes its profile before any user code runs. Doing it from a shell wrapper wins, because
`$$` is the shell's pid and **`exec` replaces the process while keeping that pid**: the link
already exists when the binary starts.

```sh
mkdir -p "$DURABLE"
rm -rf "${TMPDIR}laufey_cef_$$"
ln -s "$DURABLE" "${TMPDIR}laufey_cef_$$"
exec "$APP"
```

CEF writes through the link without noticing. Verified: 3.6 MB of profile data landed in the
durable directory, `Default/Cookies` among it, and a restart came back signed in — Chat rendered
at t+30s with no login prompt.

## Requirements (EARS / RFC 2119)

- The application MUST be launched through the wrapper; launching the binary directly gets a throwaway profile and loses the session.
- The wrapper MUST create the symlink before `exec`, and MUST name it with its own pid.
- The durable profile MUST live outside `$TMPDIR`, since the OS reclaims that directory.
- WHEN the ephemeral path already exists THE SYSTEM SHALL remove it before linking.
- The application MUST be compiled with permission to read `HOME` / `TMPDIR` and to write the durable directory.

## Decisions

- The durable profile lives at `~/Library/Application Support/com.rntgspr.google-chat-deno/cef`, matching where a macOS app is expected to keep its data and keyed to the bundle identifier declared in `deno.json`.
- The symlink is created by a shell wrapper rather than by the host process, because only the pre-`exec` position wins the race against CEF's own initialization. This was measured, not assumed: the in-process attempt failed with `File exists`, and CEF was already writing to the temp directory by the time user code ran.

## Known gaps

- **This is a workaround against an undocumented internal path.** If `deno desktop` renames the directory, drops the pid suffix, or moves the profile, sessions start silently vanishing again with no error to point at. Any runtime upgrade must re-verify it.
- The right fix is upstream: a cache-path option on the CEF backend. Until that exists, the wrapper is load-bearing and cannot be dropped.
- The `webview` backend persists correctly on its own — `~/Library/WebKit/<bundle-id>/` plus a `.binarycookies` file — and needs no wrapper at all. It is unusable for a different reason; see [chat-host](../chat-host/index.md).

## Files

Single-concern area.

## Reference

<!-- cumaru:reference -->
| Link | Description |
|------|-------------|
| [run.sh](run.sh) | Creates the pid-named symlink to the durable profile, then `exec`s the app. |
<!-- /cumaru:reference -->
