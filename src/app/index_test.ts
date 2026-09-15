import appSource from "./index.ts" with { type: "text" }
import devSource from "../../dev.sh" with { type: "text" }

/** Throws when a test condition is false. */
function assert(condition: boolean, message: string): void {
  if (!condition) throw new Error(message)
}

Deno.test("application entrypoint relies on native redirected attachment loading", () => {
  assert(!appSource.includes("initImageResolver"), "expected no image resolver wiring")
  assert(!appSource.includes("chatImagesBindings"), "expected no attachment binding workaround")
  assert(!appSource.includes("imagesCacheBindings"), "expected no attachment cache workaround")
})

Deno.test("development launcher defaults to the relocated application entrypoint", () => {
  assert(devSource.includes('ENTRY="${ENTRY:-src/app/index.ts}"'), "expected relocated default entrypoint")
})
