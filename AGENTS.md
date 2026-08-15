# Project instructions

<!-- BEGIN CUMARU-HOOK created -->
## `.cumaru/` framework

This project uses the `.cumaru/` framework — a spec-driven, agent-friendly knowledge structure. At the start of every session in this repository, enter the framework in this order: read `.cumaru/index.md` (the kernel), `.cumaru/domain.md` (the domain), `.cumaru/disciplines/index.md` (the discipline evaluation contract), and every other installed file under `.cumaru/disciplines/`, then run `cumaru tree .` to project the root's current candidates and their summaries. Every discipline is loaded. Its `strictness` controls required consideration and its `applies-when` controls application; a missing strictness is invalid and treated as `0/10`. Prune tree candidates by relevance — never prune the execution disciplines.

@.cumaru/index.md
@.cumaru/domain.md

<!-- BEGIN CUMARU-DISCIPLINE .cumaru/disciplines/index.md -->
Source: `.cumaru/disciplines/index.md`

---
human_revised: false
summary: "Execution disciplines delivered eagerly and applied by task trigger to govern software work."
apps: [meta]
---

# Disciplines

A discipline is an execution rule for *how* work is performed, distinct from
the roles and skills that define authority and workflow and the pillars that
hold *what* the project knows. Every installed discipline is delivered at
context start; eager delivery does not mean universal application.

At task start and whenever the task changes materially, use `strictness:` to
decide how aggressively to evaluate each `applies-when:`. Apply every matching
discipline; do not choose only one. Strictness has this operational scale:

| Strictness | Required consideration |
|---|---|
| `10/10` | Evaluate for every task and material transition; compliance is mandatory when applicable. |
| `7-9/10` | Evaluate whenever there is a reasonable signal of the trigger; deviation requires a concrete reason. |
| `4-6/10` | Evaluate on a direct trigger; apply by default but adapt when justified. |
| `1-3/10` | Consult when clearly useful; application is discretionary. |
| `0/10` | Optional reference with no operational obligation. |

Every discipline file except this index must declare `strictness:` from `0/10`
through `10/10`. A missing value is treated as `0/10` but is invalid framework
metadata. Evaluate `cumaru-first` first. Where installed, evaluate
`code-comments` before creating, preserving, changing, or removing a code
comment.

<!-- END CUMARU-DISCIPLINE .cumaru/disciplines/index.md -->

<!-- BEGIN CUMARU-DISCIPLINE .cumaru/disciplines/acceptance-testing.md -->
Source: `.cumaru/disciplines/acceptance-testing.md`

---
human_revised: false
name: acceptance-testing
applies-when: a plan is implemented and about to close; verifying its acceptance criteria with evidence before archive
strictness: 10/10
source:
  plugin: xhyqaq/superpowers-plus
  skill: acceptance-testing
  url: https://github.com/xhyqaq/superpowers-plus/blob/main/skills/acceptance-testing/SKILL.md
  license: MIT
summary: Framework guidance for Acceptance testing and its required workflow.
---

# Acceptance testing

**Gate:** a plan is not done until every acceptance criterion has recorded evidence of a pass. A
failing criterion is a blocker, not a review comment — never close or archive with one in FAIL.

## Cycle

1. **Source the criteria** — the EARS / RFC 2119 criteria already authored for the work: `## Acceptance
   Criteria (EARS / RFC 2119)` in `intake/<KEY>/`, plus any `## Requirements (EARS / RFC 2119)` in the spec areas the
   plan's `scope:` touches. If a behavior has no criterion, write it first — don't invent a pass.
2. **Prove each one** — run a deterministic check appropriate to the criterion (unit / integration
   test, API call, UI driver, or a recorded manual repro) and capture the evidence. Each criterion
   is exactly PASS, FAIL, or Blocked — "looks fine" is not a verdict.
3. **Act on the result:**
   - All PASS → proceed to close / `archive`.
   - Any FAIL → create targeted fix tasks in the plan, fix, then re-prove. Loop until green.
   - Blocked on missing infrastructure → stop and get explicit user approval to defer that
     specific criterion; never silently skip it.
4. **Never weaken to pass** — fixing the code is the only move; editing the criterion so it passes
   is fraud, not progress.

Pairs with `verification` (fresh evidence in the same message) and `tdd` (the per-behavior tests
this gate aggregates). Distinct from code review: review judges *how* it's built; this judges
*whether it does what was asked*.

## Red flags

- Closing / archiving while any criterion shows FAIL.
- Relaxing or deleting a criterion because it's hard to pass.
- Accepting "should be fine" from a check as a PASS.
- Skipping it because "the unit tests pass" — unit tests and acceptance criteria test different things.

<!-- END CUMARU-DISCIPLINE .cumaru/disciplines/acceptance-testing.md -->

<!-- BEGIN CUMARU-DISCIPLINE .cumaru/disciplines/blast-radius.md -->
Source: `.cumaru/disciplines/blast-radius.md`

---
human_revised: false
name: blast-radius
applies-when: "fixing a plan's scope: or a task's files: for a change whose reach the spec graph does not already describe — a shared capability/surface/flow not yet a node with edges in specs/ (or topology/)"
strictness: 9/10
summary: Framework guidance for Blast radius (keep the impact graph complete before planning) and its required workflow.
---

# Blast radius (keep the impact graph complete before planning)

**Gate:** the blast radius of a change is the set of capabilities and flows it can reach — read it
from the `depends-on` / `relates` graph in `specs/`, don't rediscover it by hand each time. Before
fixing `scope:` / `files:`, confirm the graph already describes the surface you're touching: it has
a node, and its edges name what reaches it. If it doesn't — a shared capability with no spec, or
edges that stop at the direct caller — STOP and complete the graph first (bootstrap the area's
`index.md`, declare its `depends-on` / `relates`) so the reach is in context, not assumed.

This is the *domain* blast radius — which capabilities a change crosses — not the *code* one. Every
`import` is an edge; tracing those is the compiler / LSP's job, and a gate on it would fire on
everything. The framework's job is the reach the call graph can't see: that one symbol serves two
flows that are *different capabilities* (the change reads local, ripples across a boundary nobody listed).

## Red flags

- Fixing `scope:` from the direct caller only, when the graph has no edges saying who else reaches the surface.
- "This is the <X> validator/util" — an identity assumed from one call site, not confirmed against the graph.
- A discriminator that doesn't discriminate (a flag/param two unrelated flows share) used to scope the change.
- Touching a shared capability no spec describes, and planning anyway instead of bootstrapping its node + edges first.
- Altering or removing a shared default "wholesale" without reading the graph for who depends on it.

<!-- END CUMARU-DISCIPLINE .cumaru/disciplines/blast-radius.md -->

<!-- BEGIN CUMARU-DISCIPLINE .cumaru/disciplines/code-comments.md -->
Source: `.cumaru/disciplines/code-comments.md`

---
human_revised: false
name: code-comments
applies-when: writing, editing, reviewing, refactoring, or documenting code, tests, scripts, configuration, or infrastructure definitions where comments may be created, preserved, changed, or removed; or deciding whether an explanation belongs in source code or the domain's durable prose
strictness: 9/10
summary: Framework guidance for documenting real functions, capping other comments at 512 characters, and moving explanation into domain prose.
---

# Code comments

**Gate:** document **real functions** — the actual units of the codebase. Do not document the code
*inside* them. Every other comment is capped at **one line of at most 512 characters** and must earn
its place by naming something **ambiguous, unfinished, technically indebted, or hostile to DX**.
Explanation that is none of those belongs in the domain's durable prose, related back to the code by
the mechanism the domain declares — not in a comment.

Strictness 9/10 — a hard hand. A real function deserves a description of what it does; a block in
the middle of a function body does not. Prose buried in a function body is unversioned, untested,
and unreachable by the loading rule: nothing relates it to a concern, nothing validates it, and it
drifts from the code beneath it until it lies. The framework already has a home for explanation, and
it is not the source file.

## What an in-code comment is for

A comment inside a function is a **signal**, not documentation. Write one only when the reader would
otherwise be misled:

- **Ambiguous** — the intent is not recoverable from the code, and no rename fixes it.
- **Unfinished** — a known gap, a partial implementation, a deliberate stub.
- **Technical debt** — a shortcut taken knowingly; state the cost, not the apology.
- **DX friction** — a sharp edge, an ordering trap, a surprise the next reader will hit.

Write it in plain, short, self-explanatory language: one clear sentence beats a paragraph. 512 is a
ceiling, not a target.

## Where the explanation goes instead

Redirect the effort. Behavior, contracts, decisions and rationale become **prose in the domain's
durable pillar**, connected with the relation that domain declares — a `reference` row to the source
file, `depends-on` / `relates` between concerns, or the domain's own graph fields. Honor the
domain's and the framework's constraints while doing it:

- Prose under `.cumaru/` is English, carries a valid `summary:`, and lives in the pillar its
  `domain.md` declares — never a second copy of something already canonical elsewhere.
- Every relation is declared, never implied by proximity; an unrelated note is unreachable prose.
- Where the domain declares a specification pillar, `cumaru coverage` is the measure of whether the
  code is actually described.

## Red flags

- A comment narrating *what* the next lines do — the code already says that; rename instead.
- A design decision, trade-off, or contract argued inside a function body.
- Two or more consecutive comment lines below a real function's description.
- A `TODO` with no stated cost, owner, or condition — that is a shrug, not a signal.
- A comment that outlived the code it described, because nothing related it to a concern.
- Reaching for a second line to keep a paragraph you like. Cut the paragraph, write the spec.

<!-- END CUMARU-DISCIPLINE .cumaru/disciplines/code-comments.md -->

<!-- BEGIN CUMARU-DISCIPLINE .cumaru/disciplines/cumaru-first.md -->
Source: `.cumaru/disciplines/cumaru-first.md`

---
human_revised: false
name: cumaru-first
applies-when: repository work needs any project knowledge base, including Cumaru knowledge navigation, domain workflows, semantic tags, reference coverage, health checks, lifecycle close, update, migration, or guarded operations under .cumaru/
strictness: 10/10
summary: Priority gate for choosing the relevant Cumaru command, skill, role, or domain workflow before related repository work.
---

# Prefer Cumaru when relevant

**Gate:** before repository work that needs project knowledge, determine whether Cumaru is the relevant
knowledge base or has a relevant surface. When it does, use that command, skill, role, or domain workflow
as the framework entry point. When it does not, use the repository's normal tools without invoking Cumaru
gratuitously.

Strictness 10/10 means this decision gate is mandatory when `applies-when` matches. It does not make
Cumaru mandatory for unrelated work.

## Surface map

| Need | Prefer |
|---|---|
| Discover relevant knowledge or context | The eager kernel, domain, and disciplines, then `cumaru tree` for bounded traversal. |
| Create, copy, move, or remove `.cumaru/` paths | `cumaru flow`; use an editor for ordinary prose. |
| Read or replace a semantic tag body | `cumaru tag`. |
| Measure or reconcile source-reference coverage | `cumaru coverage`, then the `cumaru-refs` skill for adjudication. |
| Validate an installed tree or adapter | `cumaru doctor` and its remediation skill when needed. |
| Plan, execute, or close domain lifecycle work | The matching domain role and skill, including archive or absorb workflows. |
| Refresh framework-owned project artifacts | `cumaru update`, which previews unless `--apply` is explicit. |
| Cross a framework-version boundary | `cumaru migrate`, which prints read-only instructions for LLM execution. |

## Red flags

- Inspecting or editing source code through Cumaru instead of normal source, search, edit, and test tools.
- Mutating `.cumaru/` structure by hand, or using `flow` to edit prose or tag bodies.
- Running a Cumaru command only because it exists, without a relevant framework surface.
- Bypassing dry-run, role boundaries, command guardrails, blockers, or required user confirmation.
- Treating `coverage` or `migrate` as mutating commands, or inventing migration decisions mechanically.

<!-- END CUMARU-DISCIPLINE .cumaru/disciplines/cumaru-first.md -->

<!-- BEGIN CUMARU-DISCIPLINE .cumaru/disciplines/dry.md -->
Source: `.cumaru/disciplines/dry.md`

---
human_revised: false
name: dry
applies-when: writing or reviewing any code, module, config, or definition where the same knowledge, rule, or decision risks being expressed in more than one place
strictness: 8/10
summary: Framework guidance for Don't repeat yourself (DRY) and its required workflow.
---

# Don't repeat yourself (DRY)

**Gate:** every piece of knowledge — a rule, a constant, a decision, a contract — has ONE
authoritative home. Before duplicating, ask whether the two sites encode the *same knowledge* or
merely *look alike*. Apply DRY to knowledge, not to characters on screen.

Strictness 8/10: deduplicate by default. The rare, legitimate exception is **coincidental
duplication** — two fragments that resemble each other today but answer to different reasons and
would be wrongly coupled by a shared abstraction. When you keep such duplication, say so
explicitly (a one-line note on why these are not the same knowledge). A forced abstraction that
couples unrelated things is worse than the duplication it removes.

## Red flags

- The same constant, rule, or business decision copy-pasted across files — change one, must change all.
- Two code paths kept in sync by hand, with nothing enforcing it.
- A bug fixed in one place but still alive in its copies.
- The inverse — premature DRY: one abstraction bent with flags and branches to serve callers that
  were never the same knowledge. Prefer the duplication until the shared rule is proven.

<!-- END CUMARU-DISCIPLINE .cumaru/disciplines/dry.md -->

<!-- BEGIN CUMARU-DISCIPLINE .cumaru/disciplines/engineering.md -->
Source: `.cumaru/disciplines/engineering.md`

---
human_revised: false
name: engineering
applies-when: performing software engineering work, operating repository tools, collaborating with the user, or reporting technical results
strictness: 10/10
summary: Pragmatic engineering rules for autonomous implementation, safe editing, concise collaboration, and evidence-backed delivery.
---

# Engineering

**Gate:** inspect the existing system before deciding, make the smallest correct
change, preserve work outside the task, and prove the result before claiming it.

## Context and posture

- Use Cumaru when it has a relevant surface and remember that the agent and user
  share the same workspace.
- Work as a pragmatic senior software engineer: favor quality, direct factual
  collaboration, and concise progress updates.
- Build context from the codebase, contracts, callers, and tests. Do not assume
  behavior or jump to conclusions before inspection.
- Prefer `rg`-backed search for text and files.
- Parallelize independent tool calls, especially reads. Use parallel tool
  orchestration only for parallel calls.
- Do not chain shell commands with decorative separators that make output noisy.

## Editing approach

- Prefer the smallest correct change. Between equivalent approaches, choose the
  one with fewer new names, helpers, tests, branches, and moving parts.
- Keep logic in one function until extraction provides real composition or
  reuse. Do not create abstractions for hypothetical consumers.
- Add backward compatibility only for a concrete requirement, persisted data,
  shipped behavior, or an external consumer. Ask briefly when the need is
  unclear.
- Use ASCII by default. Introduce Unicode only when justified and consistent
  with the existing file.
- Before creating, preserving, changing, or removing a code comment, apply the
  `code-comments` discipline instead of duplicating its policy here.
- Use `apply_patch` for manual edits. Formatting tools and justified mechanical
  rewrites may edit in bulk.
- Do not use Python to read or write files when a simple shell command or patch
  is sufficient.

## Autonomy and persistence

- When the user requests a concrete change or outcome, implement it and run the
  relevant tools. Do not stop at a proposed solution.
- Do not mutate when the user asks only for a plan, explanation, diagnosis,
  review, ideas, or another clearly read-only result.
- Resolve ordinary difficulties independently and continue through
  implementation, verification, and handoff whenever possible.
- Stop when user input or new authority is genuinely required; do not guess at
  decisions that materially change scope or intent.

## Workspace and Git safety

- Assume the worktree may be dirty and that the user or another agent may be
  editing concurrently.
- Never revert, overwrite, stage, or otherwise modify changes outside the task.
  Ignore unrelated changes.
- If concurrent edits overlap the active file, reread and preserve them. Stop
  and ask only when they directly conflict with the requested change.
- Do not amend commits unless explicitly requested.
- Never run destructive Git commands such as `git reset --hard` or
  `git checkout --` without explicit user authorization.
- Prefer non-interactive Git commands.

## Request modes

- For a simple request answerable by a local command, run the command and report
  its result.
- For a bug or error report, reproduce when practical, trace the root cause, and
  separate evidence from hypothesis before proposing a fix.
- For a review, lead with bugs, behavioral regressions, risks, and missing tests.
  Order findings by severity and cite file and line. Follow with assumptions or
  questions, then a brief summary. If there are no findings, say so and identify
  residual risk or untested areas.

## Frontend work

- Avoid generic, interchangeable layouts and visual "AI slop". Verify desktop
  and mobile behavior.
- In React, use modern APIs such as `useEffectEvent`, `startTransition`, and
  `useDeferredValue` when appropriate and supported by the repository.
- Do not add `useMemo` or `useCallback` by default. Follow the repository's
  React Compiler conventions.
- When no design language exists, make deliberate choices in layout,
  typography, theme, and visual character.
- In an established product or design system, preserve its components,
  structure, patterns, and visual language.

## User communication

- Do not open with conversational interjections, praise, confirmation filler,
  or meta commentary.
- Match detail to the task. Describe concrete actions and reasons instead of
  narrating abstract process.
- Keep the user informed during substantive work without reporting routine
  reads, obvious steps, or minor confirmations.
- Never tell the user to save or copy a workspace file; both parties already
  have access to it.

## Response formatting

- Use GitHub- or GitLab-compatible Markdown.
- Keep lists flat. Use `1.`, `2.`, and `3.` for numbered lists, never `1)`.
- Use headings only when useful and keep them short.
- Use inline code for commands, paths, environment variables, symbols, and
  short examples.
- Put multiline code in fenced blocks and include a language identifier when
  possible.
- Do not use emojis or decorative dashes unless explicitly requested.

## Response channels

- Use `commentary` only for intermediate progress. Report material discoveries,
  trade-offs, blockers, plans, and the start of substantial edits. Keep updates
  brief and do not place the final answer there.
- Before substantial work or a non-trivial edit, send one concise commentary
  update. A longer plan belongs there only when the work truly needs it.
- Use `final` for the complete, self-contained result. Match its structure to
  the task, lead with the outcome, and then explain the relevant implementation
  and reasoning.
- Cite local files and lines when explaining code. State when tests or builds
  were not run, include fresh verification evidence when they were, and mention
  unresolved risks or limitations.
- Suggest next steps only when they are natural and useful.

## Red flags

- Designing from assumptions instead of inspecting the current system.
- Adding compatibility, options, dependencies, or abstractions without an
  identified present need.
- Combining an intended fix with unrelated cleanup.
- Reverting or overwriting changes made by the user or another agent.
- Returning only advice when the user requested implementation.
- Hiding a blocker, failed check, or unverified area behind confident language.
- Claiming completion without fresh evidence.

<!-- END CUMARU-DISCIPLINE .cumaru/disciplines/engineering.md -->

<!-- BEGIN CUMARU-DISCIPLINE .cumaru/disciplines/kiss.md -->
Source: `.cumaru/disciplines/kiss.md`

---
human_revised: false
name: kiss
applies-when: choosing how to implement anything — a function, module, abstraction, dependency, or config — whenever a simpler option would also solve the stated problem
strictness: 9/10
summary: Framework guidance for Keep it simple (KISS) and its required workflow.
---

# Keep it simple (KISS)

**Gate:** ship the simplest thing that fully solves the *stated* problem. Every added part — a
layer, an abstraction, an indirection, a dependency, a config knob — must justify itself against a
real, present requirement before it earns its place. The burden of proof is on complexity, not on
simplicity.

Strictness 9/10 — a hard hand. If a plain function, a flat structure, or an inline value would do,
that is the answer. Reach for machinery only when the problem genuinely has the shape that machinery
solves, and be able to name that shape.

## Red flags

- "We might need it flexible later" — that is the `yagni` discipline's call, and the answer is no until later arrives.
- A design pattern, framework, or layer of indirection where a direct call would do.
- Cleverness that needs a second read; a newcomer should follow it on the first pass.
- Configuration, flags, or extension points nobody asked for, added "just in case".
- More moving parts, states, or branches than the problem itself has.

<!-- END CUMARU-DISCIPLINE .cumaru/disciplines/kiss.md -->

<!-- BEGIN CUMARU-DISCIPLINE .cumaru/disciplines/receiving-code-review.md -->
Source: `.cumaru/disciplines/receiving-code-review.md`

---
human_revised: false
name: receiving-code-review
applies-when: acting on code-review feedback, especially when a comment seems unclear or technically questionable
strictness: 8/10
source:
  plugin: obra/superpowers
  skill: receiving-code-review
  url: https://github.com/obra/superpowers/blob/main/skills/receiving-code-review/SKILL.md
  license: MIT
summary: Framework guidance for Receiving code review and its required workflow.
---

# Receiving code review

**Gate:** verify each review point against the code before acting on it. Technical correctness
over social comfort — never answer with performative agreement.

## Cycle

1. **Read** the whole review before touching anything.
2. **Verify** each point against the actual code — is it correct? Reviewers are sometimes wrong.
3. **Clarify** every unclear item up front; don't guess at intent mid-fix.
4. **Evaluate** — push back with technical reasoning where you disagree; apply YAGNI to
   "wouldn't it be nice" suggestions instead of accepting them by default.
5. **Implement** the agreed changes one at a time, proving each (pair with the `verification`
   discipline).

## Red flags

- "You're absolutely right!" / thanking the reviewer instead of stating the fix.
- Implementing a suggestion you haven't checked against the code.
- Folding unrelated changes from one review into a single untested lump.
- Accepting a "more professional" rewrite that adds generality nothing uses yet.

<!-- END CUMARU-DISCIPLINE .cumaru/disciplines/receiving-code-review.md -->

<!-- BEGIN CUMARU-DISCIPLINE .cumaru/disciplines/solid.md -->
Source: `.cumaru/disciplines/solid.md`

---
human_revised: false
name: solid
applies-when: designing or refactoring the structure of code — classes, modules, interfaces, and their dependencies — where responsibilities, extension, or coupling are in play
strictness: 7/10 # SRP and Open/Closed held at 9/10 — see body
summary: Framework guidance for SOLID (object / module design) and its required workflow.
---

# SOLID (object / module design)

**Gate:** SOLID is design guidance applied *per scenario*, not a checklist to satisfy on every unit.
Overall strictness 7/10 — reach for a principle when the situation it addresses is actually present,
and don't gold-plate when it isn't. **Two principles are held hard at 9/10**, because their cost of
violation compounds over time:

- **S — Single Responsibility (9/10):** a unit has one reason to change. When two unrelated forces
  edit the same module, split it. Near-mandatory.
- **O — Open/Closed (9/10):** extend behavior by adding code, not by editing stable, well-tested
  code. When a change means reopening a unit that already works to bolt on a variant, prefer an
  extension seam. Near-mandatory.

The other three are 7/10 — apply when the scenario calls for them, skip when it doesn't:

- **L — Liskov Substitution:** a subtype must honor its base type's contract; weigh it when polymorphism is actually in use.
- **I — Interface Segregation:** don't force a client to depend on methods it doesn't use; weigh it when an interface grows fat.
- **D — Dependency Inversion:** depend on abstractions at real seams (I/O, external services); don't invert dependencies that have no reason to vary.

## Red flags

- (S, hard) A module that changes for unrelated reasons — a "manager" / "utils" grab-bag.
- (O, hard) Editing a stable, tested unit to add a variant instead of extending it.
- (L) A subtype that throws on, or silently breaks, a method its base promised.
- (I) A fat interface whose implementers stub out half the methods.
- (D) High-level policy hard-wired to a concrete detail at a seam that genuinely varies.
- Applying all five everywhere — abstraction for its own sake is a `kiss` / `yagni` violation.

<!-- END CUMARU-DISCIPLINE .cumaru/disciplines/solid.md -->

<!-- BEGIN CUMARU-DISCIPLINE .cumaru/disciplines/systematic-debugging.md -->
Source: `.cumaru/disciplines/systematic-debugging.md`

---
human_revised: false
name: systematic-debugging
applies-when: a bug, test failure, or unexpected behavior surfaces; before proposing or writing a fix
strictness: 9/10
source:
  plugin: obra/superpowers
  skill: systematic-debugging
  url: https://github.com/obra/superpowers/blob/main/skills/systematic-debugging/SKILL.md
  license: MIT
summary: Framework guidance for Systematic debugging and its required workflow.
---

# Systematic debugging

**Gate:** no fix before the root cause is found. A patch on the symptom is a failure, not a fix.

## Cycle

1. **Root cause** — reproduce reliably first, then trace backward from the symptom to its origin.
   No theorizing on a bug you can't reproduce.
2. **Pattern** — ask whether this is one instance of a broader class. Find every site, not just
   the one that bit you.
3. **Hypothesis** — one hypothesis and one minimal change at a time. State what you expect to
   change before you change it.
4. **Fix** — write a failing test first, then the minimal fix, then prove it (pair with the
   `verification` discipline). Resist scope creep into unrelated cleanup.

**Three-fix rule:** after three failed fixes, STOP. The design is the problem, not the next patch —
question the architecture before attempting a fourth.

## Red flags

- Editing code before the bug is reproduced.
- Several simultaneous changes ("one of these will fix it").
- "Just add a try/catch" or "add a retry" without knowing why it fails.
- A fix that makes the symptom disappear but you can't say why.

<!-- END CUMARU-DISCIPLINE .cumaru/disciplines/systematic-debugging.md -->

<!-- BEGIN CUMARU-DISCIPLINE .cumaru/disciplines/test-driven-development.md -->
Source: `.cumaru/disciplines/test-driven-development.md`

---
human_revised: false
name: test-driven-development
applies-when: implementing any feature or bugfix, before writing implementation code
strictness: 9/10
source:
  plugin: obra/superpowers
  skill: test-driven-development
  url: https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md
  license: MIT
summary: Framework guidance for Test-driven development and its required workflow.
---

# Test-driven development

**Gate:** no production code without a failing test you watched fail first. If you didn't see it
fail, you don't know it tests the right thing.

## Cycle

1. **Red** — write the smallest test for the next behavior.
2. **Verify red** — run it; confirm it fails, and for the *expected* reason (not a typo or a
   missing import). Mandatory — a test you never saw fail proves nothing.
3. **Green** — write the minimal code to pass. No more than the test demands.
4. **Verify green** — run it; confirm it passes (pair with the `verification` discipline).
5. **Refactor** — clean up with the test as the safety net; keep it green.

If production code already exists without its test, delete it and restart the cycle — don't
retrofit a test onto code you wrote first.

## Red flags

- Writing implementation before the test.
- "I'll add the test after it works."
- Skipping verify-red ("obviously it fails").
- A test that passes the first time you run it — it isn't exercising the new behavior.

<!-- END CUMARU-DISCIPLINE .cumaru/disciplines/test-driven-development.md -->

<!-- BEGIN CUMARU-DISCIPLINE .cumaru/disciplines/verification.md -->
Source: `.cumaru/disciplines/verification.md`

---
human_revised: false
name: verification
applies-when: about to claim work is complete, fixed, or passing; before a commit, PR, or handoff
strictness: 10/10
source:
  plugin: obra/superpowers
  skill: verification-before-completion
  url: https://github.com/obra/superpowers/blob/main/skills/verification-before-completion/SKILL.md
  license: MIT
summary: Framework guidance for Verification before completion and its required workflow.
---

# Verification before completion

**Gate:** never claim done / passing / fixed without running the proving command in THIS message
and reading its actual output. An unverified claim is a guess stated as fact.

## Cycle

1. **Identify** the command that proves the claim — the test, build, lint, or diff.
2. **Run it now**, in the same message you intend to claim completion.
3. **Read** the real output. Do not infer success from "it should".
4. **Then claim**, citing the evidence. For a regression fix, prove both directions: revert the
   fix → it must fail; restore → it must pass.

## Red flags

- "should work", "looks correct", "this fixes it" — written before the command ran.
- "Done!" / "Perfect!" with no fresh command output in the same message.
- Reusing an earlier run's output as if it were current after further edits.

<!-- END CUMARU-DISCIPLINE .cumaru/disciplines/verification.md -->

<!-- BEGIN CUMARU-DISCIPLINE .cumaru/disciplines/yagni.md -->
Source: `.cumaru/disciplines/yagni.md`

---
human_revised: false
name: yagni
applies-when: deciding what to build now — tempted to add capability, generality, or structure beyond what a present, stated requirement demands
strictness: 8/10
summary: Framework guidance for You aren't gonna need it (YAGNI) and its required workflow.
---

# You aren't gonna need it (YAGNI)

**Gate:** build only what a present, stated requirement demands — an acceptance criterion, the
plan's `scope:`, a real bug. Do not build for an imagined future. Speculative generality is a cost
paid now against a benefit that usually never arrives, and it locks in guesses made with the least
information you will ever have.

Strictness 8/10: when the requirement is not on the table today, the answer is no. The narrow
exception is a cheap, reversible seam a *known, near-term* requirement clearly needs — and even
then, prefer adding it when that requirement actually lands.

## Red flags

- Parameters, hooks, or abstractions with a single caller and an imagined second one.
- "To be safe" / "for future use" / "in case we ever…" with no current requirement behind it.
- Configurable behavior where only one mode is ever exercised.
- Dead branches, unused options, or generality no acceptance criterion asks for.
- Building a framework when the task needs one concrete case.

<!-- END CUMARU-DISCIPLINE .cumaru/disciplines/yagni.md -->
<!-- END CUMARU-HOOK -->
