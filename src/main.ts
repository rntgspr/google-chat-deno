import { WINDOW_CREATION_MS } from "@/util/constants.ts"
import { delay } from "@/util/delay.js"
import logger from "@/util/logger.ts"

/** Creates the application window and navigates it to Google Chat. */
export async function initMain(initUrl: string, showDevtools = false): Promise<Deno.BrowserWindow> {
  logger.info("main::init", { initUrl })

  const windowId = crypto.randomUUID().slice(0, 8)
  const win = new Deno.BrowserWindow({
    title: `Google Chat ${windowId}`,
    width: 1198,
    height: 768,
  })

  win.setApplicationMenu([
    {
      submenu: {
        label: "Google Chat Deno",
        items: [{ role: { role: "quit" } }],
      },
    },
    {
      submenu: {
        label: "Edit",
        items: [
          { role: { role: "undo" } },
          { role: { role: "redo" } },
          "separator",
          { role: { role: "cut" } },
          { role: { role: "copy" } },
          { role: { role: "paste" } },
        ],
      },
    },
  ])

  // Keep explicit setters until constructor handling is verified across desktop backends.
  win.setSize(1198, 768)

  // Keep explicit setters until constructor handling is verified across desktop backends.
  win.setTitle(`Google Chat ${windowId}`)

  if (showDevtools) win.openDevtools()

  await delay(WINDOW_CREATION_MS)

  win.navigate(initUrl)

  logger.info("main::done", { initUrl })

  return win
}
