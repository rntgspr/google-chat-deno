---
human_revised: false
scope: [specs/runtime]
status: in-progress
summary: Cmd+Q must quit the app; a quit menu item is already wired but the shortcut was never seen working live.
apps: [host]
aux: []
---

# Cmd+Q quits the app

## Overview

The macOS convention is that Cmd+Q quits the application. `src/main.ts` already calls
`win.setApplicationMenu` with a single "Google Chat" submenu holding one `{ role: "quit" }`
item, so the wiring exists — but the user reports the shortcut does not end the app, and no
live checkpoint has ever recorded the menu bar or the shortcut working. Whether the defect is
in the role mapping, the menu installation, or nowhere (it actually works) is unknown.

`specs/runtime` records `setApplicationMenu`, `showContextMenu`, and `onmenuclick` on the
verified API surface, with no documented semantics for roles — like everything else in this
runtime, behavior has to be established by running it.

## Acceptance Criteria (EARS / RFC 2119)

- WHEN the user presses Cmd+Q THE SYSTEM SHALL terminate the application process cleanly.
- WHEN the app runs THE SYSTEM SHALL show a menu bar whose application menu carries a visible
  Quit item.
- The plan MUST record what the menu bar actually shows before any change to the menu code.

## Plan / DAG

| Task | Title | Status | Depends on |
|------|-------|--------|-----------|
| [T1](t1.md) | Reproduce: capture menu bar and Cmd+Q behavior live | pending | — |
| [T2](t2.md) | Fix or attribute — role handling or runtime blocker | pending | T1 |

## Out of scope

- Any other menu item or keyboard shortcut beyond quitting.
- Windows/Linux menu conventions — macOS only so far.

## Risks

- If the `quit` role is not implemented by the laufey backend, the fix may require an explicit
  handler (`onmenuclick`) calling `win.close()`; if even that cannot terminate cleanly, the plan
  ends in a documented runtime gap.
- Live validation needs the user at the keyboard.
