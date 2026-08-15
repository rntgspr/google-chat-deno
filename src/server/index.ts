import logger from "@/util/logger.ts"
import BOOTSTRAP_PAGE from "../../assets/bootstrap.html" with { type: "text" }

/** Serves the bootstrap document. */
function handleRequest(): Response {
  return new Response(`${BOOTSTRAP_PAGE}`, {
    headers: { "content-type": "text/html" },
  })
}

/**
 * Serves a placeholder page so the runtime stops waiting for an application
 * server. The page is never meant to be seen — the window is navigated to Chat
 * once the runtime has finished booting.
 */
export function serveBootPage() {
  const server = Deno.serve(
    { hostname: "127.0.0.1", port: 0, onListen: () => {} },
    handleRequest,
  )
  const address = server.addr as Deno.NetAddr
  const bootUrl = `http://${address.hostname}:${address.port}/`

  logger.info("serveBootPage::finished", { bootUrl })

  return { bootUrl, server }
}
