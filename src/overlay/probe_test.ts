import { strictEqual } from "node:assert"
import mainSource from "@/main.ts" with { type: "text" }
import { createOverlayProbeScript, injectOverlay } from "@/overlay/probe.ts"

Deno.test("overlay probe script appends one isolated aside at the end of the body", () => {
  const script = createOverlayProbeScript()

  strictEqual(script.includes('document.createElement("aside")'), true)
  strictEqual(script.includes("document.body.append(aside)"), true)
  strictEqual(script.includes('attachShadow({ mode: "open" })'), true)
  strictEqual(script.includes("document.querySelector"), false)
  strictEqual(script.indexOf("location.origin") < script.indexOf("document.getElementById"), true)
})

Deno.test("overlay injection retries until the page accepts the aside", async () => {
  let attempts = 0
  let waits = 0

  const window = {
    executeJs(_script: string): Promise<unknown> {
      attempts += 1

      return Promise.resolve({ ok: true, value: attempts === 2 })
    },
  }

  await injectOverlay(window, {
    attempts: 3,
    intervalMs: 1,
    wait: () => {
      waits += 1

      return Promise.resolve()
    },
  })

  strictEqual(attempts, 2)
  strictEqual(waits, 1)
})

Deno.test("main starts the overlay probe after navigating to Chat", () => {
  const navigation = mainSource.indexOf("win.navigate(initUrl)")
  const injection = mainSource.indexOf("injectOverlay(win)")

  strictEqual(navigation >= 0, true)
  strictEqual(injection > navigation, true)
})
