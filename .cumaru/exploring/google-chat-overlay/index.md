---
human_revised: false
status: idea
summary: Explore hosting a custom interactive overlay above the Google Chat page through runtime JavaScript injection.
apps: [host]
---

# Google Chat overlay

## Idea

Run a custom application surface above the remote Google Chat interface while keeping Chat as the primary page hosted by
the existing CEF window.

The leading hypothesis is an in-page overlay injected by the Deno host. A readiness check would detect when the main
frame and relevant Chat DOM are available before JavaScript mounts an isolated application root above the page.

## Context

The current host creates one `Deno.BrowserWindow` and navigates it directly to Google Chat. The dedicated Laufey CEF
backend and the current Deno `BrowserWindow` binding support evaluating JavaScript in a loaded window. The binding
returns an envelope shaped like `{ ok: true, value: <script result> }`, which the host must unwrap before deciding that
the mount succeeded.

Google Chat is a remote single-page application. Its navigation and rerendering may replace DOM subtrees without a full
page load, so a startup-only injection is unlikely to be durable. The overlay lifecycle needs a readiness check,
idempotent mounting, and recovery after relevant DOM changes.

A Shadow DOM root can reduce CSS collisions, but it is not a security boundary. Code running in the Google Chat page can
still discover or interfere with an injected overlay unless the runtime offers an isolated JavaScript world.

A local CEF smoke test proved that the host can append an `<aside>` after an application-owned root and render isolated
Shadow DOM content inside it. The production script also rejects every origin except `https://chat.google.com`. The
authenticated Google Chat page remains unverified because the local test profile redirected to Google sign-in; the host
correctly refused to inject into that authentication origin.

## Confirmed architecture

`Overlay` is the domain term for an independently built and managed extension of the hosted Google Chat page. Deno
Desktop uses `BrowserWindow`, `executeJs`, and `bindings`; it does not define either `overlay` or `probe` as a platform
concept. A readiness check is an internal implementation detail, not a first-class domain unit.

The overlay rack is the sole owner of the bridge to `BrowserWindow`. Each overlay declares pure Deno-side binding
functions without `this`. The rack registers them by stable names following `overlay:<overlay-id>:invoke:<method-id>`
and is responsible for revoking their handlers when an overlay is removed.

### Execution and isolation

The overlay runs in the Google Chat page's main JavaScript world; it is not hosted in an iframe or a local page. The
host checks the `https://chat.google.com` origin, appends one idempotent `<aside>` as the last child of `document.body`,
and attaches an open Shadow DOM root. This avoids coupling to Chat-owned DOM subtrees and isolates CSS, but it is not a
security boundary from Google Chat JavaScript.

The translator's browser output consists of ordered IIFEs. A styles IIFE installs the content of one CSS source file in
a `<style>` element inside the Shadow DOM root and places its rules in a dedicated CSS layer. An application IIFE then
mounts the interactive Vite surface into that root.

### Build and rack contract

`overlay/_build/` is invoked by the Deno application backend. In development it watches overlay source trees and writes
fresh IIFEs plus a generated asset catalog. In packaged builds it compiles those same source trees once and makes the
resulting assets available to the application. The exact packaged asset location remains a spike because the current
`dist/` directory is also the macOS application bundle output.

An overlay definition declares its identifier, ordered asset entries, and named bindings. Its `bindings.ts` exports only
pure Deno-side functions. The rack offers `add`, `run`, `reload`, and `remove`; `add` registers catalog metadata and the
corresponding `BrowserWindow` bindings, while `remove` invokes explicit disposal, removes DOM resources, clears
listeners and timers, and revokes the overlay's binding handlers. Garbage collection is a consequence of disposal, not
the lifecycle mechanism.

The source tree will separate the Deno application host, shared overlay internals, and concrete overlays:

```text
src/
├── app/
│   ├── index.ts
│   └── main.ts
├── server/
├── util/
└── overlay/
    ├── _build/
    ├── _rack/
    └── translator/
        ├── definition.ts
        ├── bindings.ts
        └── vite/
```

The Vite application surface belongs to `overlay/translator/vite/`. Generated IIFEs and their catalog are disposable
artifacts outside `src/`.

## Planned delivery sequence

1. **P0 — `maintenance-source-layout`** completed on 2026-09-14: it moved the Deno entrypoint and window host into
   `src/app/` and updated every affected import, script, configuration entry, test, and domain reference. Overlay
   source directories remain deferred to their owning delivery plans.
2. `maintenance-overlay-build` defines overlay source inputs and compiles ordered IIFE assets plus an artifact catalog.
3. `maintenance-overlay-rack` catalogs overlays, registers their named bindings on `BrowserWindow`, and manages add,
   run, reload, disposal, and binding revocation.
4. `maintenance-overlay-translator` implements the first concrete overlay, including the end-of-body `<aside>`, Shadow
   DOM root, ordered styles and application IIFEs, and the Vite-built translator interface.

This exploration remains active through the completion of every plan in this sequence. This is an explicit project-level
exception to the default Cumaru promotion lifecycle: do not remove or absorb this exploration when the first plan
starts.

## Options / sketches

### 1. Inject an overlay into the Google Chat page

- Check page readiness by evaluating a small expression from the host.
- Append one idempotently identified `<aside>` as the last child of `document.body`, outside the Chat-owned application
  root.
- Attach a high-z-index fixed overlay with a Shadow DOM root for style isolation and a dedicated `#app` mount point.
- Use a `MutationObserver` or host-side readiness checker to restore the mount after SPA transitions.
- Bridge required host capabilities through the Laufey JavaScript interop surface rather than exposing broad native
  access.

This is the leading option because the overlay naturally follows the Chat window's position, size, focus, and lifecycle.

### 2. Create a separate native overlay window

- Create a frameless, always-on-top window aligned with the Google Chat window.
- Use click passthrough or dynamically switch hit testing around interactive regions.
- Synchronize movement, resizing, visibility, and focus with the main window.

This would provide a stronger separation from the remote page, but the current Laufey documentation states that
transparent windows are not supported by the CEF backend. The option therefore requires either new CEF transparency
support, another backend, or acceptance of an opaque overlay region.

### 3. Host Chat inside a local shell page

- Load a local application shell and embed Google Chat below the custom UI.

This is unlikely to work because Google controls whether Chat may be embedded by another origin. Treat it as rejected
unless a concrete runtime experiment disproves the expected framing restrictions.

## Open questions

- Which page signal is stable enough to declare Google Chat ready after authentication and during SPA navigation?
- Must the overlay accept pointer and keyboard input, or is it initially read-only?
- What host capabilities and Chat data does the overlay need?
- Is same-page JavaScript visibility acceptable, or does the application require a real security boundary from Google
  Chat?
- Should overlay state survive page reloads independently from Chat's DOM?
- Should the host keep checking after the first successful mount so a full reload can recreate the overlay?
- Can the overlay be implemented without selectors tied to unstable internal Chat markup?
- Does the current Deno Desktop binding API support unregistration, or must the rack retain stable binding shims that
  reject calls after handler revocation?
- Should packaged IIFEs be embedded as source text or copied into the macOS application bundle resources?

## Promotion / drop criteria

Complete the planned delivery sequence when a spike proves that the packaged Deno host can inject an idempotent visible
overlay after Google Chat loads, recover it after a representative SPA DOM replacement or reload, and support the
required interaction model without unacceptable coupling to private Chat markup.

Before the translator plan, decide whether same-page isolation is sufficient and document any Laufey runtime changes
required by the chosen option.

After the final plan closes, retain or drop this exploration only with explicit user direction. Drop it if the Deno
binding cannot evaluate JavaScript reliably, if Google Chat lifecycle changes make reinjection unacceptably brittle, or
if the required security boundary forces a transparent native overlay that the selected backend cannot support within
acceptable scope.
