import { initMain } from "@/main.ts"
import { serveBootPage } from "@/server/index.ts"
import { CHAT_URL, RUNTIME_BOOT_MS } from "@/util/constants.ts"
import { delay } from "@/util/delay.js"
import logger from "@/util/logger.ts"

if (import.meta.main) {
  logger.info("app::init")

  serveBootPage()
  await delay(RUNTIME_BOOT_MS)

  await initMain(CHAT_URL, false)
}
