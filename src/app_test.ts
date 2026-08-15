import appSource from "./app.ts" with { type: "text" }

/** Throws when a test condition is false. */
function assert(condition: boolean, message: string): void {
  if (!condition) throw new Error(message)
}

Deno.test("application relies on native redirected attachment loading", () => {
  assert(!appSource.includes("initImageResolver"), "expected no image resolver wiring")
  assert(!appSource.includes("chatImagesBindings"), "expected no attachment binding workaround")
  assert(!appSource.includes("imagesCacheBindings"), "expected no attachment cache workaround")
})
