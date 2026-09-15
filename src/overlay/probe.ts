import { delay } from "@/util/delay.js"

const OVERLAY_ID = "google-chat-deno-overlay"
const DEFAULT_ATTEMPTS = 40
const DEFAULT_INTERVAL_MS = 250

interface OverlayWindow {
  executeJs(script: string): Promise<unknown>
}

interface OverlayInjectionOptions {
  attempts?: number
  intervalMs?: number
  wait?: (milliseconds: number) => Promise<void>
}

/** Builds the idempotent page script that mounts the isolated overlay host. */
export function createOverlayProbeScript(): string {
  return `(() => {
    const overlayId = ${JSON.stringify(OVERLAY_ID)};

    if (location.origin !== "https://chat.google.com") return false;
    if (document.readyState === "loading" || !document.body) return false;

    const existing = document.getElementById(overlayId);
    if (existing instanceof HTMLElement) return true;

    const aside = document.createElement("aside");
    aside.id = overlayId;
    aside.setAttribute("aria-label", "Google Chat Deno overlay");

    const shadow = aside.attachShadow({ mode: "open" });
    const style = document.createElement("style");
    style.textContent = \`
      :host {
        all: initial;
        contain: layout style paint;
        pointer-events: none;
        position: fixed;
        right: 16px;
        top: 16px;
        z-index: 2147483647;
      }

      #app {
        background: #17211b;
        border: 1px solid #5f806b;
        border-radius: 10px;
        box-shadow: 0 8px 24px rgb(0 0 0 / 24%);
        box-sizing: border-box;
        color: #ecf7ef;
        font: 600 12px/1.2 system-ui, sans-serif;
        padding: 10px 12px;
        pointer-events: auto;
      }
    \`;

    const app = document.createElement("div");
    app.id = "app";
    app.textContent = "Overlay probe active";

    shadow.append(style, app);
    document.body.append(aside);

    return true;
  })()`
}

/** Probes the remote page until the overlay is mounted or the attempt budget expires. */
export async function injectOverlay(
  window: OverlayWindow,
  options: OverlayInjectionOptions = {},
): Promise<void> {
  const attempts = options.attempts ?? DEFAULT_ATTEMPTS
  const intervalMs = options.intervalMs ?? DEFAULT_INTERVAL_MS
  const wait = options.wait ?? delay
  const script = createOverlayProbeScript()

  for (let attempt = 0; attempt < attempts; attempt += 1) {
    try {
      const result = await window.executeJs(script)
      const mounted = result === true || (
        typeof result === "object" &&
        result !== null &&
        Reflect.get(result, "ok") === true &&
        Reflect.get(result, "value") === true
      )

      if (mounted) return
    } catch {
      // The CEF renderer may not accept JavaScript while navigation is changing documents.
    }

    if (attempt < attempts - 1) await wait(intervalMs)
  }

  throw new Error("overlay probe did not find a ready Google Chat document")
}
